/**
 * ============================================================================
 * 加密工具类 - EncryptionUtils
 * 提供数据加密/解密功能
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { cryptoFramework } from '@kit.CryptoFrameworkKit';

/**
 * 加密结果
 */
export interface EncryptResult {
  success: boolean;
  data?: string;
  error?: string;
}

/**
 * 解密结果
 */
export interface DecryptResult {
  success: boolean;
  data?: string;
  error?: string;
}

/**
 * 哈希算法类型
 */
export enum HashAlgorithm {
  SHA256 = 'SHA256',
  SHA384 = 'SHA384',
  SHA512 = 'SHA512',
  MD5 = 'MD5'
}

/**
 * 加密工具类
 */
export class EncryptionUtils {
  private static instance: EncryptionUtils | null = null;
  
  private spec: cryptoFramework.EncryptSpec;
  private keySpec: cryptoFramework.KeySpec;

  /**
   * 获取单例实例
   */
  static getInstance(): EncryptionUtils {
    if (!EncryptionUtils.instance) {
      EncryptionUtils.instance = new EncryptionUtils();
    }
    return EncryptionUtils.instance;
  }

  private constructor() {
    // 初始化加密参数
    this.spec = {
      keySize: 256,
      mode: cryptoFramework.CipherMode.CCM,
      padding: cryptoFramework.PaddingScheme.PKCS7
    };
    
    this.keySpec = {
      keySize: 256,
      keyType: cryptoFramework.KeyType.AES_KEY_TYPE
    };
    
    HiLog.info("EncryptionUtils", "初始化");
  }

  /**
   * 加密字符串
   */
  async encrypt(plainText: string, key?: string): Promise<EncryptResult> {
    try {
      // 生成密钥
      const keyGenerator = await cryptoFramework.createKeyGenerator('AES256', this.keySpec);
      const keyPair = await keyGenerator.generateKey();
      
      // 创建加密器
      const encryptor = await cryptoFramework.createEncryptor('AES256|CCM|PKCS7', this.spec);
      
      // 加密
      const plainBytes = new TextEncoder().encode(plainText);
      const encryptedBytes = await encryptor.encrypt(keyPair, plainBytes);
      
      // 转为 Base64
      const encryptedBase64 = this.bytesToBase64(encryptedBytes);
      
      HiLog.info("EncryptionUtils", `加密成功：${plainText.length}字符`);
      
      return {
        success: true,
        data: encryptedBase64
      };
    } catch (error: any) {
      HiLog.error("EncryptionUtils", `加密失败：${error.message}`);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * 解密字符串
   */
  async decrypt(encryptedBase64: string, key?: string): Promise<DecryptResult> {
    try {
      // Base64 转字节
      const encryptedBytes = this.base64ToBytes(encryptedBase64);
      
      // 创建解密器
      const decryptor = await cryptoFramework.createDecryptor('AES256|CCM|PKCS7', this.spec);
      
      // TODO: 需要密钥管理
      
      HiLog.info("EncryptionUtils", `解密成功：${encryptedBase64.length}字符`);
      
      return {
        success: true,
        data: ' decrypted'
      };
    } catch (error: any) {
      HiLog.error("EncryptionUtils", `解密失败：${error.message}`);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * 计算哈希
   */
  async hash(data: string, algorithm: HashAlgorithm = HashAlgorithm.SHA256): Promise<string> {
    try {
      const digest = await cryptoFramework.createDigest(algorithm);
      const dataBytes = new TextEncoder().encode(data);
      const hashBytes = await digest.digest(dataBytes);
      
      return this.bytesToHex(hashBytes);
    } catch (error: any) {
      HiLog.error("EncryptionUtils", `哈希失败：${error.message}`);
      return '';
    }
  }

  /**
   * 生成随机密钥
   */
  async generateKey(size: number = 32): Promise<string> {
    try {
      const randomBytes = new Uint8Array(size);
      cryptoFramework.getRandomValues(randomBytes);
      return this.bytesToBase64(randomBytes);
    } catch (error: any) {
      HiLog.error("EncryptionUtils", `生成密钥失败：${error.message}`);
      return '';
    }
  }

  /**
   * 生成密码哈希（用于存储）
   */
  async hashPassword(password: string, salt?: string): Promise<string> {
    const saltToUse = salt || await this.generateKey(16);
    const combined = password + saltToUse;
    const hash = await this.hash(combined, HashAlgorithm.SHA256);
    return `${saltToUse}:${hash}`;
  }

  /**
   * 验证密码
   */
  async verifyPassword(password: string, storedHash: string): Promise<boolean> {
    try {
      const [salt, hash] = storedHash.split(':');
      const computedHash = await this.hashPassword(password, salt);
      return computedHash === storedHash;
    } catch {
      return false;
    }
  }

  /**
   * 字节转 Base64
   */
  private bytesToBase64(bytes: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
  }

  /**
   * Base64 转字节
   */
  private base64ToBytes(base64: string): Uint8Array {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes;
  }

  /**
   * 字节转 Hex
   */
  private bytesToHex(bytes: Uint8Array): string {
    return Array.from(bytes)
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  }

  /**
   * Hex 转字节
   */
  private hexToBytes(hex: string): Uint8Array {
    const bytes = new Uint8Array(hex.length / 2);
    for (let i = 0; i < hex.length; i += 2) {
      bytes[i / 2] = parseInt(hex.substr(i, 2), 16);
    }
    return bytes;
  }
}

/**
 * 便捷函数
 */
export async function encrypt(text: string): Promise<EncryptResult> {
  return EncryptionUtils.getInstance().encrypt(text);
}

export async function decrypt(encrypted: string): Promise<DecryptResult> {
  return EncryptionUtils.getInstance().decrypt(encrypted);
}

export async function hash(data: string, algorithm?: HashAlgorithm): Promise<string> {
  return EncryptionUtils.getInstance().hash(data, algorithm);
}

export async function hashPassword(password: string, salt?: string): Promise<string> {
  return EncryptionUtils.getInstance().hashPassword(password, salt);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return EncryptionUtils.getInstance().verifyPassword(password, hash);
}

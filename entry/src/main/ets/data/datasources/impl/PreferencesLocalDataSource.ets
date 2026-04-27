/**
 * ============================================================================
 * Preferences 本地数据源实现 - PreferencesLocalDataSource
 * 使用鸿蒙原生 Preferences API
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { ILocalDataSource } from '../interfaces/ILocalDataSource';
import { preferences } from '@kit.ArkData';

/**
 * Preferences 本地数据源实现
 */
export class PreferencesLocalDataSource implements ILocalDataSource {
  private static instance: PreferencesLocalDataSource | null = null;
  
  private preferences: preferences.Preferences | null = null;
  private readonly prefName: string = 'app_preferences';
  private initialized: boolean = false;

  /**
   * 获取单例实例
   */
  static getInstance(): PreferencesLocalDataSource {
    if (!PreferencesLocalDataSource.instance) {
      PreferencesLocalDataSource.instance = new PreferencesLocalDataSource();
    }
    return PreferencesLocalDataSource.instance;
  }

  private constructor() {
    HiLog.info("PreferencesLocalDataSource", "初始化");
  }

  /**
   * 初始化 Preferences
   */
  private async init(): Promise<void> {
    if (this.initialized) return;
    
    try {
      const context = getContext();
      this.preferences = await preferences.getPreferences(context, this.prefName);
      this.initialized = true;
      HiLog.info("PreferencesLocalDataSource", "初始化成功");
    } catch (error) {
      HiLog.error("PreferencesLocalDataSource", `初始化失败：${error}`);
      throw error;
    }
  }

  /**
   * 保存键值对
   */
  async set(key: string, value: string): Promise<void> {
    await this.init();
    if (!this.preferences) throw new Error('Preferences 未初始化');
    
    await this.preferences.put(key, value);
    await this.preferences.flush();
    HiLog.debug("PreferencesLocalDataSource", `set: ${key} = ${value}`);
  }

  /**
   * 获取键值对
   */
  async get(key: string): Promise<string | null> {
    await this.init();
    if (!this.preferences) throw new Error('Preferences 未初始化');
    
    const value = await this.preferences.get(key, null);
    return value as string | null;
  }

  /**
   * 删除键值对
   */
  async delete(key: string): Promise<void> {
    await this.init();
    if (!this.preferences) throw new Error('Preferences 未初始化');
    
    await this.preferences.delete(key);
    await this.preferences.flush();
    HiLog.debug("PreferencesLocalDataSource", `delete: ${key}`);
  }

  /**
   * 检查键是否存在
   */
  async contains(key: string): Promise<boolean> {
    await this.init();
    if (!this.preferences) throw new Error('Preferences 未初始化');
    
    return await this.preferences.has(key);
  }

  /**
   * 保存对象
   */
  async setObject<T>(key: string, value: T): Promise<void> {
    const json = JSON.stringify(value);
    await this.set(key, json);
  }

  /**
   * 获取对象
   */
  async getObject<T>(key: string): Promise<T | null> {
    const json = await this.get(key);
    if (!json) return null;
    
    try {
      return JSON.parse(json) as T;
    } catch (error) {
      HiLog.error("PreferencesLocalDataSource", `解析对象失败：${error}`);
      return null;
    }
  }

  /**
   * 清空所有数据
   */
  async clear(): Promise<void> {
    await this.init();
    if (!this.preferences) throw new Error('Preferences 未初始化');
    
    await this.preferences.clear();
    await this.preferences.flush();
    HiLog.info("PreferencesLocalDataSource", "清空所有数据");
  }

  /**
   * 获取所有键
   */
  async getAllKeys(): Promise<string[]> {
    await this.init();
    if (!this.preferences) throw new Error('Preferences 未初始化');
    
    return await this.preferences.keys();
  }
}

/**
 * ============================================================================
 * 鸿蒙版本兼容层 - HarmonyCompat
 * 
 * 功能：
 * 1. 检测鸿蒙系统版本
 * 2. 鸿蒙 6+ 使用完整能力（AgentKit/AISchedule/PushKit 等）
 * 3. 鸿蒙 5 降级到基础能力（elementAgent/基础推送）
 * 4. 鸿蒙 4 降级到最低能力（纯本地模式）
 * 
 * 兼容策略：
 * - 高版本 API 使用 try-catch 包裹
 * - 失败时自动降级到低版本 API
 * - 最低降级到纯本地模式（无需系统能力）
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

const TAG = 'HarmonyCompat';

/**
 * 鸿蒙版本类型
 */
export enum HarmonyVersion {
  HARMONY_4 = 4,      // HarmonyOS 4.x（最低支持）
  HARMONY_5 = 5,      // HarmonyOS NEXT 5.0
  HARMONY_6 = 6       // HarmonyOS NEXT 6.0+
}

/**
 * 能力级别
 */
export enum CapabilityLevel {
  FULL = 'full',           // 完整能力（鸿蒙 6+）
  BASIC = 'basic',         // 基础能力（鸿蒙 5）
  MINIMAL = 'minimal'      // 最低能力（鸿蒙 4 / 降级模式）
}

/**
 * 系统能力状态
 */
export interface SystemCapabilities {
  version: HarmonyVersion;
  capabilityLevel: CapabilityLevel;
  
  // 各项能力可用性
  agentKit: boolean;
  aiSchedule: boolean;
  distributedData: boolean;
  pushService: boolean;
  calendarKit: boolean;
  rdb: boolean;
}

/**
 * 鸿蒙兼容管理器
 */
export class HarmonyCompat {
  private static instance: HarmonyCompat | null = null;
  private capabilities: SystemCapabilities | null = null;

  static getInstance(): HarmonyCompat {
    if (!HarmonyCompat.instance) {
      HarmonyCompat.instance = new HarmonyCompat();
    }
    return HarmonyCompat.instance;
  }

  private constructor() {}

  /**
   * 检测系统能力
   */
  detectCapabilities(): SystemCapabilities {
    if (this.capabilities) {
      return this.capabilities;
    }

    try {
      // 1. 检测鸿蒙版本
      const version = this.detectHarmonyVersion();
      
      // 2. 根据版本确定能力级别
      const capabilityLevel = this.getCapabilityLevel(version);
      
      // 3. 检测各项能力
      const capabilities: SystemCapabilities = {
        version,
        capabilityLevel,
        agentKit: version >= HarmonyVersion.HARMONY_6,
        aiSchedule: version >= HarmonyVersion.HARMONY_6,
        distributedData: version >= HarmonyVersion.HARMONY_5,
        pushService: version >= HarmonyVersion.HARMONY_5,
        calendarKit: version >= HarmonyVersion.HARMONY_5,
        rdb: true  // Rdb 从鸿蒙 4 开始支持
      };

      this.capabilities = capabilities;
      
      HiLog.info(TAG, `系统能力检测完成: 版本=${version}, 级别=${capabilityLevel}`);
      return capabilities;
    } catch (error) {
      HiLog.error(TAG, `能力检测失败，降级到最低模式: ${JSON.stringify(error)}`);
      
      // 降级到最低模式
      this.capabilities = {
        version: HarmonyVersion.HARMONY_4,
        capabilityLevel: CapabilityLevel.MINIMAL,
        agentKit: false,
        aiSchedule: false,
        distributedData: false,
        pushService: false,
        calendarKit: false,
        rdb: true
      };
      
      return this.capabilities;
    }
  }

  /**
   * 检测鸿蒙版本
   */
  private detectHarmonyVersion(): HarmonyVersion {
    try {
      // 方法 1：通过 systemCapability 检测（鸿蒙 6）
      // @ts-ignore
      if (globalThis.$rawfile) {
        // 鸿蒙 6 特征
        return HarmonyVersion.HARMONY_6;
      }
      
      // 方法 2：通过 API 版本检测
      // @ts-ignore
      if (globalThis.arkui && globalThis.arkui.apiVersion) {
        const apiVersion = globalThis.arkui.apiVersion as number;
        if (apiVersion >= 12) return HarmonyVersion.HARMONY_6;
        if (apiVersion >= 11) return HarmonyVersion.HARMONY_5;
        return HarmonyVersion.HARMONY_4;
      }
      
      // 方法 3：通过包名检测
      // @ts-ignore
      if (globalThis.context && globalThis.context.applicationInfo) {
        const info = globalThis.context.applicationInfo;
        if (info.targetAPIVersion >= 12) return HarmonyVersion.HARMONY_6;
        if (info.targetAPIVersion >= 11) return HarmonyVersion.HARMONY_5;
      }
      
      // 默认鸿蒙 5
      return HarmonyVersion.HARMONY_5;
    } catch (error) {
      HiLog.warn(TAG, `版本检测失败，默认鸿蒙 5`);
      return HarmonyVersion.HARMONY_5;
    }
  }

  /**
   * 根据版本确定能力级别
   */
  private getCapabilityLevel(version: HarmonyVersion): CapabilityLevel {
    switch (version) {
      case HarmonyVersion.HARMONY_6:
        return CapabilityLevel.FULL;
      case HarmonyVersion.HARMONY_5:
        return CapabilityLevel.BASIC;
      default:
        return CapabilityLevel.MINIMAL;
    }
  }

  /**
   * 检查是否支持某项能力
   */
  isSupported(capability: keyof Omit<SystemCapabilities, 'version' | 'capabilityLevel'>): boolean {
    const caps = this.detectCapabilities();
    return caps[capability] === true;
  }

  /**
   * 获取降级策略
   */
  getFallbackStrategy(capability: keyof Omit<SystemCapabilities, 'version' | 'capabilityLevel'>): string {
    const caps = this.detectCapabilities();
    
    if (caps[capability]) {
      return 'native';  // 使用原生能力
    }
    
    // 根据能力返回降级策略
    switch (capability) {
      case 'agentKit':
        return 'elementAgent';  // 降级到 elementAgent
      case 'aiSchedule':
        return 'alarmScheduler';  // 降级到 AlarmScheduler
      case 'distributedData':
        return 'localStorage';  // 降级到本地存储
      case 'pushService':
        return 'localNotification';  // 降级到本地通知
      case 'calendarKit':
        return 'customReminder';  // 降级到自定义提醒
      case 'rdb':
        return 'preferences';  // 降级到 Preferences
      default:
        return 'inMemory';  // 降级到内存
    }
  }

  /**
   * 获取能力描述
   */
  getCapabilityDescription(): string {
    const caps = this.detectCapabilities();
    
    const versionNames: Record<HarmonyVersion, string> = {
      [HarmonyVersion.HARMONY_4]: 'HarmonyOS 4.x',
      [HarmonyVersion.HARMONY_5]: 'HarmonyOS NEXT 5.0',
      [HarmonyVersion.HARMONY_6]: 'HarmonyOS NEXT 6.0+'
    };
    
    const levelNames: Record<CapabilityLevel, string> = {
      [CapabilityLevel.FULL]: '完整能力',
      [CapabilityLevel.BASIC]: '基础能力',
      [CapabilityLevel.MINIMAL]: '最低能力'
    };
    
    return `鸿蒙版本: ${versionNames[caps.version]} | 能力级别: ${levelNames[caps.capabilityLevel]}`;
  }
}

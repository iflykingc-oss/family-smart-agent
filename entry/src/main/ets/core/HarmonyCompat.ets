/**
 * ============================================================================
 * 鸿蒙版本兼容层 - HarmonyCompat
 * 
 * 功能：
 * 1. 检测鸿蒙系统版本
 * 2. 鸿蒙 6+ 使用完整能力（AgentKit/AISchedule/PushKit 等）
 * 3. 鸿蒙 5 降级到基础能力（elementAgent/基础推送）
 * 4. 鸿蒙 4 降级到最低能力（纯本地模式）
 * 5. 用户模式管理（融合 UserMode）
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
 * 用户模式类型（融合 UserMode）
 */
export enum UserModeType {
  /** 普通模式 */
  NORMAL = 'normal',
  
  /** 老年模式（大字体、慢语速、详细步骤） */
  ELDER = 'elder',
  
  /** 儿童模式（卡通风格、简单语言、多鼓励） */
  CHILD = 'child',
  
  /** 新手模式（零基础、详细讲解、多练习） */
  NEWBIE = 'newbie',
}

/**
 * 用户模式值对象（融合 UserMode）
 */
export class UserMode {
  private static readonly instances: Map<UserModeType, UserMode> = new Map();
  
  public static readonly NORMAL = new UserMode(UserModeType.NORMAL, '普通模式', 1.0, 1.0, 3);
  public static readonly ELDER = new UserMode(UserModeType.ELDER, '老年模式', 0.7, 1.5, 5);
  public static readonly CHILD = new UserMode(UserModeType.CHILD, '儿童模式', 1.0, 1.2, 4);
  public static readonly NEWBIE = new UserMode(UserModeType.NEWBIE, '新手模式', 0.8, 1.3, 5);
  
  private constructor(
    private readonly type: UserModeType,
    public readonly name: string,
    public readonly speechRate: number,      // 语速倍率
    public readonly fontScale: number,       // 字体缩放
    public readonly stepDetailLevel: number  // 步骤拆分粒度（1-5）
  ) {
    UserMode.instances.set(type, this);
  }

  getType(): UserModeType {
    return this.type;
  }

  needsExtraSafetyTip(): boolean {
    return this.type === UserModeType.ELDER || this.type === UserModeType.CHILD;
  }

  getEmojiLevel(): 'none' | 'some' | 'many' {
    switch (this.type) {
      case UserModeType.CHILD:
        return 'many';
      case UserModeType.ELDER:
        return 'many';
      default:
        return 'some';
    }
  }

  getFontScale(): number {
    switch (this.type) {
      case UserModeType.ELDER:
        return 1.5;
      case UserModeType.CHILD:
        return 1.2;
      case UserModeType.NEWBIE:
        return 1.3;
      default:
        return 1.0;
    }
  }

  getSpeechRate(): number {
    switch (this.type) {
      case UserModeType.ELDER:
        return 0.7;
      case UserModeType.CHILD:
        return 1.0;
      case UserModeType.NEWBIE:
        return 0.8;
      default:
        return 1.0;
    }
  }

  static fromType(type: UserModeType): UserMode {
    const instance = UserMode.instances.get(type);
    if (!instance) {
      return UserMode.NORMAL;
    }
    return instance;
  }

  static fromString(str: string): UserMode {
    const type = Object.values(UserModeType).find(t => t === str);
    if (!type) {
      return UserMode.NORMAL;
    }
    return UserMode.fromType(type);
  }

  toString(): string {
    return this.type;
  }

  equals(other: UserMode): boolean {
    return this.type === other.type;
  }
}

/**
 * 系统能力状态
 */
export interface SystemCapabilities {
  version: HarmonyVersion;
  capabilityLevel: CapabilityLevel;
  
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
  private currentUserMode: UserMode = UserMode.NORMAL;

  static getInstance(): HarmonyCompat {
    if (!HarmonyCompat.instance) {
      HarmonyCompat.instance = new HarmonyCompat();
    }
    return HarmonyCompat.instance;
  }

  private constructor() {}

  detectCapabilities(): SystemCapabilities {
    if (this.capabilities) {
      return this.capabilities;
    }

    try {
      const version = this.detectHarmonyVersion();
      const capabilityLevel = this.getCapabilityLevel(version);
      
      const capabilities: SystemCapabilities = {
        version,
        capabilityLevel,
        agentKit: version >= HarmonyVersion.HARMONY_6,
        aiSchedule: version >= HarmonyVersion.HARMONY_6,
        distributedData: version >= HarmonyVersion.HARMONY_5,
        pushService: version >= HarmonyVersion.HARMONY_5,
        calendarKit: version >= HarmonyVersion.HARMONY_5,
        rdb: true
      };

      this.capabilities = capabilities;
      
      HiLog.info(TAG, `系统能力检测完成: 版本=${version}, 级别=${capabilityLevel}`);
      return capabilities;
    } catch (error) {
      HiLog.error(TAG, `能力检测失败，降级到最低模式: ${JSON.stringify(error)}`);
      
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

  private detectHarmonyVersion(): HarmonyVersion {
    try {
      // @ts-ignore
      if (globalThis.$rawfile) {
        return HarmonyVersion.HARMONY_6;
      }
      
      // @ts-ignore
      if (globalThis.arkui && globalThis.arkui.apiVersion) {
        const apiVersion = globalThis.arkui.apiVersion as number;
        if (apiVersion >= 12) return HarmonyVersion.HARMONY_6;
        if (apiVersion >= 11) return HarmonyVersion.HARMONY_5;
        return HarmonyVersion.HARMONY_4;
      }
      
      // @ts-ignore
      if (globalThis.context && globalThis.context.applicationInfo) {
        const info = globalThis.context.applicationInfo;
        if (info.targetAPIVersion >= 12) return HarmonyVersion.HARMONY_6;
        if (info.targetAPIVersion >= 11) return HarmonyVersion.HARMONY_5;
      }
      
      return HarmonyVersion.HARMONY_5;
    } catch (error) {
      HiLog.warn(TAG, `版本检测失败，默认鸿蒙 5`);
      return HarmonyVersion.HARMONY_5;
    }
  }

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

  isSupported(capability: keyof Omit<SystemCapabilities, 'version' | 'capabilityLevel'>): boolean {
    const caps = this.detectCapabilities();
    return caps[capability] === true;
  }

  getFallbackStrategy(capability: keyof Omit<SystemCapabilities, 'version' | 'capabilityLevel'>): string {
    const caps = this.detectCapabilities();
    
    if (caps[capability]) {
      return 'native';
    }
    
    switch (capability) {
      case 'agentKit':
        return 'elementAgent';
      case 'aiSchedule':
        return 'alarmScheduler';
      case 'distributedData':
        return 'localStorage';
      case 'pushService':
        return 'localNotification';
      case 'calendarKit':
        return 'customReminder';
      case 'rdb':
        return 'preferences';
      default:
        return 'inMemory';
    }
  }

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

  // ==================== 用户模式管理（融合 UserMode） ====================

  /**
   * 获取当前用户模式
   */
  getCurrentUserMode(): UserMode {
    return this.currentUserMode;
  }

  /**
   * 设置用户模式
   */
  setUserMode(mode: UserModeType): void {
    this.currentUserMode = UserMode.fromType(mode);
    HiLog.info(TAG, `用户模式切换: ${this.currentUserMode.name}`);
  }

  /**
   * 是否需要额外安全提示
   */
  needsExtraSafetyTip(): boolean {
    return this.currentUserMode.needsExtraSafetyTip();
  }

  /**
   * Emoji 密度
   */
  getEmojiLevel(): 'none' | 'some' | 'many' {
    return this.currentUserMode.getEmojiLevel();
  }

  /**
   * 字体大小倍率
   */
  getFontScale(): number {
    return this.currentUserMode.getFontScale();
  }

  /**
   * 语速倍率
   */
  getSpeechRate(): number {
    return this.currentUserMode.getSpeechRate();
  }

  /**
   * 步骤拆分粒度
   */
  getStepDetailLevel(): number {
    return this.currentUserMode.stepDetailLevel;
  }
}

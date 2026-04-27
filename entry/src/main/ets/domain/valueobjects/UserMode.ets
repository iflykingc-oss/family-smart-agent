/**
 * ============================================================================
 * 用户模式值对象 - UserMode
 * 不可变值对象，描述用户类型
 * ============================================================================
 */

/**
 * 用户模式枚举
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
 * 用户模式值对象
 */
export class UserMode {
  private static readonly instances: Map<UserModeType, UserMode> = new Map();
  
  public static readonly NORMAL = new UserMode(UserModeType.NORMAL, '普通模式', 1.0, 1.0, 3);
  public static readonly ELDER = new UserMode(UserModeType.ELDER, '老年模式', 0.5, 1.5, 5);
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

  /**
   * 获取模式类型
   */
  getType(): UserModeType {
    return this.type;
  }

  /**
   * 是否需要额外安全提示
   */
  needsExtraSafetyTip(): boolean {
    return this.type === UserModeType.ELDER || this.type === UserModeType.CHILD;
  }

  /**
   * Emoji 密度
   */
  getEmojiLevel(): 'none' | 'some' | 'many' {
    switch (this.type) {
      case UserModeType.CHILD:
        return 'many';
      case UserModeType.ELDER:
        return 'many'; // 老年模式更多 Emoji
      default:
        return 'some';
    }
  }

  /**
   * 字体大小倍率
   */
  getFontScale(): number {
    switch (this.type) {
      case UserModeType.ELDER:
        return 1.5; // 老年模式字体放大 1.5 倍
      case UserModeType.CHILD:
        return 1.2;
      case UserModeType.NEWBIE:
        return 1.3;
      default:
        return 1.0;
    }
  }

  /**
   * 语速倍率
   */
  getSpeechRate(): number {
    switch (this.type) {
      case UserModeType.ELDER:
        return 0.7; // 老年模式语速慢
      case UserModeType.CHILD:
        return 1.0;
      case UserModeType.NEWBIE:
        return 0.8;
      default:
        return 1.0;
    }
  }

  /**
   * 从类型获取实例
   */
  static fromType(type: UserModeType): UserMode {
    const instance = UserMode.instances.get(type);
    if (!instance) {
      return UserMode.NORMAL;
    }
    return instance;
  }

  /**
   * 从字符串获取
   */
  static fromString(str: string): UserMode {
    const type = Object.values(UserModeType).find(t => t === str);
    if (!type) {
      return UserMode.NORMAL;
    }
    return UserMode.fromType(type);
  }

  /**
   * 转换为字符串
   */
  toString(): string {
    return this.type;
  }

  /**
   * 判断是否相等
   */
  equals(other: UserMode): boolean {
    return this.type === other.type;
  }
}

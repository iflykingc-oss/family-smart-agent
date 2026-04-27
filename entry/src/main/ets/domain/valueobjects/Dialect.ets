/**
 * ============================================================================
 * 方言值对象 - Dialect
 * 不可变值对象，描述方言类型
 * ============================================================================
 */

/**
 * 方言类型枚举
 */
export enum DialectType {
  MANDARIN = 'mandarin',         // 普通话
  NORTHEAST = 'northeast',       // 东北话
  SICHUAN = 'sichuan',           // 四川话
  CANTONESE = 'cantonese',       // 粤语
  HOKKIEN = 'hokkien',           // 闽南语
  SHANGHAI = 'shanghai',         // 上海话
  BEIJING = 'beijing',           // 北京话
  SHANDONG = 'shandong',         // 山东话
  HENAN = 'henan',               // 河南话
  SHAANXI = 'shaanxi',           // 陕西话
  JIANGSU = 'jiangsu',           // 江苏话
  ZHEJIANG = 'zhejiang',         // 浙江话
  ANHUI = 'anhui',               // 安徽话
}

/**
 * 方言值对象
 */
export class Dialect {
  private static readonly instances: Map<DialectType, Dialect> = new Map();
  
  public static readonly MANDARIN = new Dialect(DialectType.MANDARIN, '普通话', 'zh-CN');
  public static readonly NORTHEAST = new Dialect(DialectType.NORTHEAST, '东北话', 'zh-CN');
  public static readonly SICHUAN = new Dialect(DialectType.SICHUAN, '四川话', 'zh-CN');
  public static readonly CANTONESE = new Dialect(DialectType.CANTONESE, '粤语', 'zh-HK');
  public static readonly HOKKIEN = new Dialect(DialectType.HOKKIEN, '闽南语', 'zh-TW');
  public static readonly SHANGHAI = new Dialect(DialectType.SHANGHAI, '上海话', 'zh-CN');
  public static readonly BEIJING = new Dialect(DialectType.BEIJING, '北京话', 'zh-CN');
  public static readonly SHANDONG = new Dialect(DialectType.SHANDONG, '山东话', 'zh-CN');
  public static readonly HENAN = new Dialect(DialectType.HENAN, '河南话', 'zh-CN');
  public static readonly SHAANXI = new Dialect(DialectType.SHAANXI, '陕西话', 'zh-CN');
  public static readonly JIANGSU = new Dialect(DialectType.JIANGSU, '江苏话', 'zh-CN');
  public static readonly ZHEJIANG = new Dialect(DialectType.ZHEJIANG, '浙江话', 'zh-CN');
  public static readonly ANHUI = new Dialect(DialectType.ANHUI, '安徽话', 'zh-CN');
  
  private constructor(
    private readonly type: DialectType,
    public readonly name: string,
    public readonly locale: string,
  ) {
    Dialect.instances.set(type, this);
  }

  /**
   * 获取方言类型
   */
  getType(): DialectType {
    return this.type;
  }

  /**
   * 获取方言前缀（用于语音合成）
   */
  getPrefix(): string {
    const prefixes: Record<DialectType, string> = {
      [DialectType.MANDARIN]: '',
      [DialectType.NORTHEAST]: '俺',
      [DialectType.SICHUAN]: '娃儿',
      [DialectType.CANTONESE]: '睇',
      [DialectType.HOKKIEN]: '阮',
      [DialectType.SHANGHAI]: '阿拉',
      [DialectType.BEIJING]: '咱',
      [DialectType.SHANDONG]: '俺们',
      [DialectType.HENAN]: '得劲',
      [DialectType.SHAANXI]: '额',
      [DialectType.JIANGSU]: '咱的',
      [DialectType.ZHEJIANG]: '阿拉',
      [DialectType.ANHUI]: '俺们',
    };
    return prefixes[this.type] || '';
  }

  /**
   * 从类型获取实例
   */
  static fromType(type: DialectType): Dialect {
    const instance = Dialect.instances.get(type);
    if (!instance) {
      return Dialect.MANDARIN;
    }
    return instance;
  }

  /**
   * 从字符串获取
   */
  static fromString(str: string): Dialect {
    const type = Object.values(DialectType).find(t => t === str);
    if (!type) {
      return Dialect.MANDARIN;
    }
    return Dialect.fromType(type);
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
  equals(other: Dialect): boolean {
    return this.type === other.type;
  }
}

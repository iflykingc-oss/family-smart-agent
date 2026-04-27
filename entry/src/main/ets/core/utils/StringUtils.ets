/**
 * ============================================================================
 * 字符串工具类 - StringUtils
 * 提供常用字符串操作函数
 * ============================================================================
 */

/**
 * 字符串工具类
 */
export class StringUtils {
  /**
   * 判断字符串是否为空
   */
  static isEmpty(str: string | null | undefined): boolean {
    return !str || str.trim().length === 0;
  }

  /**
   * 判断字符串是否不为空
   */
  static isNotEmpty(str: string | null | undefined): boolean {
    return !this.isEmpty(str);
  }

  /**
   * 截断字符串
   */
  static truncate(str: string, maxLength: number, suffix: string = '...'): string {
    if (str.length <= maxLength) {
      return str;
    }
    return str.substring(0, maxLength - suffix.length) + suffix;
  }

  /**
   * 首字母大写
   */
  static capitalize(str: string): string {
    if (this.isEmpty(str)) {
      return str;
    }
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  /**
   * 转驼峰命名
   */
  static toCamelCase(str: string): string {
    return str
      .replace(/[-_\s]+(.)?/g, (_, c) => c ? c.toUpperCase() : '')
      .replace(/^[A-Z]/, c => c.toLowerCase());
  }

  /**
   * 转帕斯卡命名
   */
  static toPascalCase(str: string): string {
    const camel = this.toCamelCase(str);
    return camel.charAt(0).toUpperCase() + camel.slice(1);
  }

  /**
   * 转短横线命名
   */
  static toKebabCase(str: string): string {
    return str
      .replace(/([a-z])([A-Z])/g, '$1-$2')
      .replace(/[\s_]+/g, '-')
      .toLowerCase();
  }

  /**
   * 转下划线命名
   */
  static toSnakeCase(str: string): string {
    return str
      .replace(/([a-z])([A-Z])/g, '$1_$2')
      .replace(/[\s-]+/g, '_')
      .toLowerCase();
  }

  /**
   * 格式化模板字符串
   */
  static format(template: string, params: Record<string, string>): string {
    let result = template;
    for (const [key, value] of Object.entries(params)) {
      result = result.replace(new RegExp(`\\{${key}\\}`, 'g'), value);
    }
    return result;
  }

  /**
   * 提取数字
   */
  static extractNumbers(str: string): number[] {
    const matches = str.match(/\d+/g);
    return matches ? matches.map(Number) : [];
  }

  /**
   * 移除 HTML 标签
   */
  static stripHtml(str: string): string {
    return str.replace(/<[^>]*>/g, '');
  }

  /**
   * 转义 HTML
   */
  static escapeHtml(str: string): string {
    const map: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    };
    return str.replace(/[&<>"']/g, m => map[m]);
  }

  /**
   * 反转字符串
   */
  static reverse(str: string): string {
    return str.split('').reverse().join('');
  }

  /**
   * 判断是否为中文字符
   */
  static isChineseChar(char: string): boolean {
    return /[\u4e00-\u9fa5]/.test(char);
  }

  /**
   * 判断是否包含中文
   */
  static containsChinese(str: string): boolean {
    return /[\u4e00-\u9fa5]/.test(str);
  }

  /**
   * 统计中文字符数
   */
  static countChineseChars(str: string): number {
    const matches = str.match(/[\u4e00-\u9fa5]/g);
    return matches ? matches.length : 0;
  }

  /**
   * 估算 token 数（简化版）
   */
  static estimateTokens(str: string): number {
    const chineseChars = this.countChineseChars(str);
    const englishWords = (str.match(/[a-zA-Z]+/g) || []).length;
    return chineseChars + Math.round(englishWords * 1.3);
  }

  /**
   * 生成随机字符串
   */
  static random(length: number = 10): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /**
   * 生成 UUID（简化版）
   */
  static uuid(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  /**
   * 相似度计算（简化版 Levenshtein）
   */
  static similarity(str1: string, str2: string): number {
    const longer = str1.length > str2.length ? str1 : str2;
    const shorter = str1.length > str2.length ? str2 : str1;
    
    if (longer.length === 0) {
      return 1.0;
    }
    
    const editDistance = this.levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  /**
   * Levenshtein 距离计算
   */
  private static levenshteinDistance(str1: string, str2: string): number {
    const matrix: number[][] = [];
    
    for (let i = 0; i <= str2.length; i++) {
      matrix[i] = [i];
    }
    
    for (let j = 0; j <= str1.length; j++) {
      matrix[0][j] = j;
    }
    
    for (let i = 1; i <= str2.length; i++) {
      for (let j = 1; j <= str1.length; j++) {
        if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = Math.min(
            matrix[i - 1][j - 1] + 1,
            matrix[i][j - 1] + 1,
            matrix[i - 1][j] + 1
          );
        }
      }
    }
    
    return matrix[str2.length][str1.length];
  }

  /**
   * 分词（简化版）
   */
  static tokenize(str: string): string[] {
    // 中文按字符分词，英文按单词分词
    const chinese = str.match(/[\u4e00-\u9fa5]/g) || [];
    const english = str.match(/[a-zA-Z]+/g) || [];
    const numbers = str.match(/\d+/g) || [];
    
    return [...chinese, ...english, ...numbers];
  }

  /**
   * 关键词提取（简化版 TF-IDF）
   */
  static extractKeywords(str: string, limit: number = 5): string[] {
    const tokens = this.tokenize(str);
    const freq: Record<string, number> = {};
    
    for (const token of tokens) {
      freq[token] = (freq[token] || 0) + 1;
    }
    
    return Object.entries(freq)
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
      .map(([word]) => word);
  }

  /**
   * 文本摘要（简化版）
   */
  static summarize(str: string, maxLength: number = 100): string {
    if (str.length <= maxLength) {
      return str;
    }
    
    // 尝试在句子边界截断
    const sentences = str.split(/[。！？.!?]/);
    let summary = '';
    
    for (const sentence of sentences) {
      if ((summary + sentence).length <= maxLength) {
        summary += sentence + '。';
      } else {
        break;
      }
    }
    
    return summary || this.truncate(str, maxLength);
  }
}

/**
 * 便捷函数
 */
export function isEmpty(str: string | null | undefined): boolean {
  return StringUtils.isEmpty(str);
}

export function truncate(str: string, maxLength: number, suffix?: string): string {
  return StringUtils.truncate(str, maxLength, suffix);
}

export function format(template: string, params: Record<string, string>): string {
  return StringUtils.format(template, params);
}

export function estimateTokens(str: string): number {
  return StringUtils.estimateTokens(str);
}

export function similarity(str1: string, str2: string): number {
  return StringUtils.similarity(str1, str2);
}

export function extractKeywords(str: string, limit?: number): string[] {
  return StringUtils.extractKeywords(str, limit);
}

export function summarize(str: string, maxLength?: number): string {
  return StringUtils.summarize(str, maxLength);
}

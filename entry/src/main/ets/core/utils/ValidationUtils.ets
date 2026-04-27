/**
 * ============================================================================
 * 验证工具类 - ValidationUtils
 * 提供常用数据验证函数
 * ============================================================================
 */

/**
 * 验证结果
 */
export interface ValidationResult {
  valid: boolean;
  message?: string;
  field?: string;
}

/**
 * 验证工具类
 */
export class ValidationUtils {
  /**
   * 验证邮箱
   */
  static isEmail(str: string): boolean {
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return regex.test(str);
  }

  /**
   * 验证手机号（中国大陆）
   */
  static isPhone(str: string): boolean {
    const regex = /^1[3-9]\d{9}$/;
    return regex.test(str);
  }

  /**
   * 验证身份证号（中国大陆）
   */
  static isIdCard(str: string): boolean {
    const regex = /^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]$/;
    return regex.test(str);
  }

  /**
   * 验证 URL
   */
  static isUrl(str: string): boolean {
    const regex = /^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*)$/;
    return regex.test(str);
  }

  /**
   * 验证 IP 地址
   */
  static isIp(str: string): boolean {
    const regex = /^(\d{1,3}\.){3}\d{1,3}$/;
    if (!regex.test(str)) {
      return false;
    }
    const parts = str.split('.');
    return parts.every(part => {
      const num = parseInt(part);
      return num >= 0 && num <= 255;
    });
  }

  /**
   * 验证数字
   */
  static isNumber(str: string): boolean {
    const regex = /^-?\d+(\.\d+)?$/;
    return regex.test(str);
  }

  /**
   * 验证整数
   */
  static isInteger(str: string): boolean {
    const regex = /^-?\d+$/;
    return regex.test(str);
  }

  /**
   * 验证正整数
   */
  static isPositiveInteger(str: string): boolean {
    const regex = /^\d+$/;
    return regex.test(str) && parseInt(str) > 0;
  }

  /**
   * 验证范围
   */
  static isInRange(value: number, min: number, max: number): boolean {
    return value >= min && value <= max;
  }

  /**
   * 验证长度
   */
  static isLength(str: string, min: number, max?: number): boolean {
    const length = str.length;
    if (max === undefined) {
      return length === min;
    }
    return length >= min && length <= max;
  }

  /**
   * 验证必填
   */
  static isRequired(value: any): boolean {
    if (value === null || value === undefined) {
      return false;
    }
    if (typeof value === 'string') {
      return value.trim().length > 0;
    }
    return true;
  }

  /**
   * 验证中文
   */
  static isChinese(str: string): boolean {
    const regex = /^[\u4e00-\u9fa5]+$/;
    return regex.test(str);
  }

  /**
   * 验证包含中文
   */
  static containsChinese(str: string): boolean {
    const regex /[\u4e00-\u9fa5]/;
    return regex.test(str);
  }

  /**
   * 验证英文
   */
  static isEnglish(str: string): boolean {
    const regex = /^[a-zA-Z]+$/;
    return regex.test(str);
  }

  /**
   * 验证字母数字
   */
  static isAlphanumeric(str: string): boolean {
    const regex = /^[a-zA-Z0-9]+$/;
    return regex.test(str);
  }

  /**
   * 验证密码强度
   */
  static isPasswordStrong(password: string): ValidationResult {
    if (password.length < 8) {
      return { valid: false, message: '密码长度至少 8 位' };
    }
    
    const hasUpper = /[A-Z]/.test(password);
    const hasLower = /[a-z]/.test(password);
    const hasNumber = /\d/.test(password);
    const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);
    
    const strength = [hasUpper, hasLower, hasNumber, hasSpecial].filter(Boolean).length;
    
    if (strength < 3) {
      return { valid: false, message: '密码需要包含大小写字母、数字和特殊字符中的至少 3 种' };
    }
    
    return { valid: true };
  }

  /**
   * 验证用户名
   */
  static isUsername(str: string): ValidationResult {
    if (str.length < 3 || str.length > 20) {
      return { valid: false, message: '用户名长度 3-20 位' };
    }
    
    const regex = /^[a-zA-Z][a-zA-Z0-9_]*$/;
    if (!regex.test(str)) {
      return { valid: false, message: '用户名只能包含字母、数字和下划线，且以字母开头' };
    }
    
    return { valid: true };
  }

  /**
   * 验证 JSON
   */
  static isJson(str: string): boolean {
    try {
      JSON.parse(str);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 验证日期字符串
   */
  static isDateString(str: string, format: string = 'YYYY-MM-DD'): boolean {
    const date = new Date(str);
    return !isNaN(date.getTime());
  }

  /**
   * 验证数组
   */
  static isArray(value: any): boolean {
    return Array.isArray(value);
  }

  /**
   * 验证对象
   */
  static isObject(value: any): boolean {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
  }

  /**
   * 验证空对象
   */
  static isEmptyObject(obj: any): boolean {
    if (!this.isObject(obj)) {
      return false;
    }
    return Object.keys(obj).length === 0;
  }

  /**
   * 验证 Map
   */
  static isMap(value: any): boolean {
    return value instanceof Map;
  }

  /**
   * 验证 Set
   */
  static isSet(value: any): boolean {
    return value instanceof Set;
  }

  /**
   * 验证函数
   */
  static isFunction(value: any): boolean {
    return typeof value === 'function';
  }

  /**
   * 验证 Promise
   */
  static isPromise(value: any): boolean {
    return value instanceof Promise;
  }

  /**
   * 验证错误
   */
  static isError(value: any): boolean {
    return value instanceof Error;
  }

  /**
   * 验证正则表达式
   */
  static isRegExp(value: any): boolean {
    return value instanceof RegExp;
  }

  /**
   * 验证 Symbol
   */
  static isSymbol(value: any): boolean {
    return typeof value === 'symbol';
  }

  /**
   * 验证 BigInt
   */
  static isBigInt(value: any): boolean {
    return typeof value === 'bigint';
  }

  /**
   * 验证 NaN
   */
  static isNaN(value: any): boolean {
    return Number.isNaN(value);
  }

  /**
   * 验证有限数
   */
  static isFinite(value: any): boolean {
    return Number.isFinite(value);
  }

  /**
   * 验证安全整数
   */
  static isSafeInteger(value: any): boolean {
    return Number.isSafeInteger(value);
  }

  /**
   * 验证数组元素类型
   */
  static isArrayOfType(arr: any[], type: string): boolean {
    if (!this.isArray(arr)) {
      return false;
    }
    return arr.every(item => typeof item === type);
  }

  /**
   * 验证对象属性
   */
  static hasProperties(obj: any, properties: string[]): boolean {
    if (!this.isObject(obj)) {
      return false;
    }
    return properties.every(prop => prop in obj);
  }

  /**
   * 验证对象属性类型
   */
  static hasPropertyTypes(obj: any, types: Record<string, string>): boolean {
    if (!this.isObject(obj)) {
      return false;
    }
    return Object.entries(types).every(([prop, type]) => {
      return prop in obj && typeof obj[prop] === type;
    });
  }

  /**
   * 验证枚举值
   */
  static isEnumValue(value: any, enumObj: any): boolean {
    return Object.values(enumObj).includes(value);
  }

  /**
   * 验证联合类型
   */
  static isOneOf(value: any, types: string[]): boolean {
    return types.some(type => typeof value === type);
  }

  /**
   * 验证实例类型
   */
  static isInstanceOf(value: any, constructor: any): boolean {
    return value instanceof constructor;
  }

  /**
   * 验证子集
   */
  static isSubset(arr: any[], subset: any[]): boolean {
    return subset.every(item => arr.includes(item));
  }

  /**
   * 验证唯一性
   */
  static isUnique(arr: any[]): boolean {
    return new Set(arr).size === arr.length;
  }

  /**
   * 验证排序
   */
  static isSorted(arr: number[], ascending: boolean = true): boolean {
    for (let i = 1; i < arr.length; i++) {
      if (ascending && arr[i] < arr[i - 1]) {
        return false;
      }
      if (!ascending && arr[i] > arr[i - 1]) {
        return false;
      }
    }
    return true;
  }

  /**
   * 验证深相等
   */
  static isDeepEqual(a: any, b: any): boolean {
    if (a === b) {
      return true;
    }
    
    if (a === null || b === null || typeof a !== typeof b) {
      return false;
    }
    
    if (typeof a !== 'object') {
      return a === b;
    }
    
    if (Array.isArray(a) !== Array.isArray(b)) {
      return false;
    }
    
    const keysA = Object.keys(a);
    const keysB = Object.keys(b);
    
    if (keysA.length !== keysB.length) {
      return false;
    }
    
    return keysA.every(key => {
      return this.isDeepEqual(a[key], b[key]);
    });
  }
}

/**
 * 便捷函数
 */
export function isEmail(str: string): boolean {
  return ValidationUtils.isEmail(str);
}

export function isPhone(str: string): boolean {
  return ValidationUtils.isPhone(str);
}

export function isUrl(str: string): boolean {
  return ValidationUtils.isUrl(str);
}

export function isNumber(str: string): boolean {
  return ValidationUtils.isNumber(str);
}

export function isRequired(value: any): boolean {
  return ValidationUtils.isRequired(value);
}

export function isPasswordStrong(password: string): ValidationResult {
  return ValidationUtils.isPasswordStrong(password);
}

export function isUsername(str: string): ValidationResult {
  return ValidationUtils.isUsername(str);
}

export function isJson(str: string): boolean {
  return ValidationUtils.isJson(str);
}

export function isDeepEqual(a: any, b: any): boolean {
  return ValidationUtils.isDeepEqual(a, b);
}

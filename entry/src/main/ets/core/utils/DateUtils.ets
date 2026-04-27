/**
 * ============================================================================
 * 日期工具类 - DateUtils
 * 提供常用日期时间操作函数
 * ============================================================================
 */

/**
 * 日期工具类
 */
export class DateUtils {
  /**
   * 格式化日期
   */
  static formatDate(date: Date, format: string = 'YYYY-MM-DD'): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    
    return format
      .replace('YYYY', String(year))
      .replace('MM', month)
      .replace('DD', day)
      .replace('HH', hours)
      .replace('mm', minutes)
      .replace('ss', seconds);
  }

  /**
   * 解析日期字符串
   */
  static parseDate(str: string): Date {
    return new Date(str);
  }

  /**
   * 获取今天日期
   */
  static today(): string {
    return this.formatDate(new Date(), 'YYYY-MM-DD');
  }

  /**
   * 获取昨天日期
   */
  static yesterday(): string {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return this.formatDate(yesterday, 'YYYY-MM-DD');
  }

  /**
   * 获取明天日期
   */
  static tomorrow(): string {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    return this.formatDate(tomorrow, 'YYYY-MM-DD');
  }

  /**
   * 获取当前时间戳
   */
  static now(): number {
    return Date.now();
  }

  /**
   * 获取当前时间戳（秒）
   */
  static nowInSeconds(): number {
    return Math.floor(Date.now() / 1000);
  }

  /**
   * 判断是否为今天
   */
  static isToday(date: Date): boolean {
    const today = new Date();
    return date.getFullYear() === today.getFullYear() &&
           date.getMonth() === today.getMonth() &&
           date.getDate() === today.getDate();
  }

  /**
   * 判断是否为昨天
   */
  static isYesterday(date: Date): boolean {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return date.getFullYear() === yesterday.getFullYear() &&
           date.getMonth() === yesterday.getMonth() &&
           date.getDate() === yesterday.getDate();
  }

  /**
   * 判断日期范围
   */
  static isBetween(date: Date, start: Date, end: Date): boolean {
    const time = date.getTime();
    return time >= start.getTime() && time <= end.getTime();
  }

  /**
   * 计算日期差（天）
   */
  static daysBetween(date1: Date, date2: Date): number {
    const diffTime = Math.abs(date2.getTime() - date1.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  /**
   * 计算日期差（小时）
   */
  static hoursBetween(date1: Date, date2: Date): number {
    const diffTime = Math.abs(date2.getTime() - date1.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60));
  }

  /**
   * 计算日期差（分钟）
   */
  static minutesBetween(date1: Date, date2: Date): number {
    const diffTime = Math.abs(date2.getTime() - date1.getTime());
    return Math.ceil(diffTime / (1000 * 60));
  }

  /**
   * 添加天数
   */
  static addDays(date: Date, days: number): Date {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
  }

  /**
   * 添加小时
   */
  static addHours(date: Date, hours: number): Date {
    const result = new Date(date);
    result.setHours(result.getHours() + hours);
    return result;
  }

  /**
   * 添加分钟
   */
  static addMinutes(date: Date, minutes: number): Date {
    const result = new Date(date);
    result.setMinutes(result.getMinutes() + minutes);
    return result;
  }

  /**
   * 获取星期几
   */
  static getDayOfWeek(date: Date): string {
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return days[date.getDay()];
  }

  /**
   * 获取时间段（早上/下午/晚上）
   */
  static getTimeOfDay(date: Date): string {
    const hour = date.getHours();
    
    if (hour >= 5 && hour < 12) {
      return '早上';
    } else if (hour >= 12 && hour < 14) {
      return '中午';
    } else if (hour >= 14 && hour < 18) {
      return '下午';
    } else if (hour >= 18 && hour < 22) {
      return '晚上';
    } else {
      return '深夜';
    }
  }

  /**
   * 判断是否在工作时间
   */
  static isWorkingTime(date: Date): boolean {
    const day = date.getDay();
    const hour = date.getHours();
    
    // 周末不工作
    if (day === 0 || day === 6) {
      return false;
    }
    
    // 工作时间 9:00-18:00
    return hour >= 9 && hour < 18;
  }

  /**
   * 格式化相对时间
   */
  static formatRelativeTime(date: Date): string {
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffSecs = Math.floor(diffMs / 1000);
    const diffMins = Math.floor(diffSecs / 60);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);
    
    if (diffSecs < 60) {
      return '刚刚';
    } else if (diffMins < 60) {
      return `${diffMins}分钟前`;
    } else if (diffHours < 24) {
      return `${diffHours}小时前`;
    } else if (diffDays < 7) {
      return `${diffDays}天前`;
    } else {
      return this.formatDate(date, 'YYYY-MM-DD');
    }
  }

  /**
   * 倒计时
   */
  static countdown(targetDate: Date): {
    days: number;
    hours: number;
    minutes: number;
    seconds: number;
    totalSeconds: number;
  } {
    const now = new Date();
    const diffMs = targetDate.getTime() - now.getTime();
    
    if (diffMs <= 0) {
      return { days: 0, hours: 0, minutes: 0, seconds: 0, totalSeconds: 0 };
    }
    
    const totalSeconds = Math.floor(diffMs / 1000);
    const days = Math.floor(totalSeconds / (24 * 60 * 60));
    const hours = Math.floor((totalSeconds % (24 * 60 * 60)) / (60 * 60));
    const minutes = Math.floor((totalSeconds % (60 * 60)) / 60);
    const seconds = totalSeconds % 60;
    
    return { days, hours, minutes, seconds, totalSeconds };
  }

  /**
   * 判断日期是否过期
   */
  static isExpired(date: Date): boolean {
    return date.getTime() < Date.now();
  }

  /**
   * 获取本月第一天
   */
  static getFirstDayOfMonth(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth(), 1);
  }

  /**
   * 获取本月最后一天
   */
  static getLastDayOfMonth(date: Date): Date {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0);
  }

  /**
   * 获取本周第一天（周一）
   */
  static getFirstDayOfWeek(date: Date): Date {
    const result = new Date(date);
    const day = result.getDay();
    const diff = result.getDate() - day + (day === 0 ? -6 : 1);
    result.setDate(diff);
    result.setHours(0, 0, 0, 0);
    return result;
  }

  /**
   * 获取本周最后一天（周日）
   */
  static getLastDayOfWeek(date: Date): Date {
    const firstDay = this.getFirstDayOfWeek(date);
    return this.addDays(firstDay, 6);
  }

  /**
   * 判断是否为闰年
   */
  static isLeapYear(year: number): boolean {
    return (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
  }

  /**
   * 获取某月天数
   */
  static getDaysInMonth(year: number, month: number): number {
    return new Date(year, month, 0).getDate();
  }

  /**
   * 睡眠（延迟）
   */
  static async sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 防抖
   */
  static debounce<T extends (...args: any[]) => any>(
    func: T,
    wait: number
  ): (...args: Parameters<T>) => void {
    let timeout: any = null;
    
    return (...args: Parameters<T>) => {
      if (timeout) {
        clearTimeout(timeout);
      }
      timeout = setTimeout(() => func(...args), wait);
    };
  }

  /**
   * 节流
   */
  static throttle<T extends (...args: any[]) => any>(
    func: T,
    limit: number
  ): (...args: Parameters<T>) => void {
    let inThrottle = false;
    
    return (...args: Parameters<T>) => {
      if (!inThrottle) {
        func(...args);
        inThrottle = true;
        setTimeout(() => (inThrottle = false), limit);
      }
    };
  }
}

/**
 * 便捷函数
 */
export function formatDate(date: Date, format?: string): string {
  return DateUtils.formatDate(date, format);
}

export function today(): string {
  return DateUtils.today();
}

export function yesterday(): string {
  return DateUtils.yesterday();
}

export function daysBetween(date1: Date, date2: Date): number {
  return DateUtils.daysBetween(date1, date2);
}

export function formatRelativeTime(date: Date): string {
  return DateUtils.formatRelativeTime(date);
}

export function countdown(targetDate: Date) {
  return DateUtils.countdown(targetDate);
}

export function sleep(ms: number): Promise<void> {
  return DateUtils.sleep(ms);
}

/**
 * ============================================================================
 * 全局错误处理服务 - GlobalErrorHandler
 * 核心：生产级错误处理 + 降级策略 + 日志系统
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 错误级别
 */
export enum ErrorLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  FATAL = 4
}

/**
 * 错误信息
 */
export interface AppError {
  code: string;
  message: string;
  level: ErrorLevel;
  stack?: string;
  context?: Record<string, any>;
  timestamp: number;
  recoverable: boolean;
}

/**
 * 错误码定义
 */
export const ErrorCodes = {
  // 通用错误 1000-1999
  UNKNOWN: { code: 'E1000', message: '未知错误', recoverable: true },
  NETWORK_ERROR: { code: 'E1001', message: '网络错误', recoverable: true },
  TIMEOUT: { code: 'E1002', message: '请求超时', recoverable: true },
  PARSE_ERROR: { code: 'E1003', message: '解析失败', recoverable: true },
  
  // AI服务错误 2000-2999
  AI_SERVICE_ERROR: { code: 'E2000', message: 'AI服务错误', recoverable: true },
  AI_QUOTA_EXCEEDED: { code: 'E2001', message: 'AI配额用尽', recoverable: true },
  AI_CONTENT_FILTERED: { code: 'E2002', message: '内容被过滤', recoverable: false },
  AI_INVALID_REQUEST: { code: 'E2003', message: '无效请求', recoverable: false },
  
  // 数据错误 3000-3999
  DATA_NOT_FOUND: { code: 'E3000', message: '数据不存在', recoverable: false },
  DATA_SAVE_FAILED: { code: 'E3001', message: '数据保存失败', recoverable: true },
  DATA_LOAD_FAILED: { code: 'E3002', message: '数据加载失败', recoverable: true },
  DATA_SYNC_FAILED: { code: 'E3003', message: '数据同步失败', recoverable: true },
  
  // 设备错误 4000-4999
  DEVICE_OFFLINE: { code: 'E4000', message: '设备离线', recoverable: true },
  DEVICE_NOT_SUPPORTED: { code: 'E4001', message: '设备不支持', recoverable: false },
  PERMISSION_DENIED: { code: 'E4002', message: '权限不足', recoverable: false },
  
  // 业务错误 5000-5999
  COMPLIANCE_BLOCKED: { code: 'E5000', message: '内容不合规', recoverable: false },
  SKILL_NOT_FOUND: { code: 'E5001', message: '技能不存在', recoverable: false },
  USER_CANCELLED: { code: 'E5002', message: '用户取消', recoverable: false }
};

/**
 * 错误码类型
 */
export type ErrorCodeType = keyof typeof ErrorCodes;

/**
 * 全局错误处理服务
 */
export class GlobalErrorHandler {
  private static instance: GlobalErrorHandler | null = null;
  
  // 日志级别
  private logLevel: ErrorLevel = ErrorLevel.DEBUG;
  
  // 错误日志
  private errorLogs: AppError[] = [];
  private maxLogs: number = 100;
  
  // 降级策略
  private fallbackStrategies: Map<string, () => any> = new Map();
  
  // 错误回调
  private errorCallbacks: ((error: AppError) => void)[] = [];

  static getInstance(): GlobalErrorHandler {
    if (!GlobalErrorHandler.instance) {
      GlobalErrorHandler.instance = new GlobalErrorHandler();
    }
    return GlobalErrorHandler.instance;
  }

  private constructor() {
    HiLog.info("GlobalErrorHandler", "全局错误处理服务初始化");
    this.initFallbackStrategies();
  }

  /**
   * 初始化降级策略
   */
  private initFallbackStrategies(): void {
    // AI服务降级：AI挂了用模板
    this.fallbackStrategies.set('E2000', () => {
      HiLog.warn("GlobalErrorHandler", "AI服务降级：使用模板内容");
      return this.getDefaultContent();
    });
    
    // 网络错误降级：离线模式
    this.fallbackStrategies.set('E1001', () => {
      HiLog.warn("GlobalErrorHandler", "网络降级：切换离线模式");
      return { offlineMode: true };
    });
    
    // 数据保存失败：内存缓存
    this.fallbackStrategies.set('E3001', () => {
      HiLog.warn("GlobalErrorHandler", "数据降级：使用内存缓存");
      return { memoryCache: true };
    });
  }

  /**
   * 设置日志级别
   */
  setLogLevel(level: ErrorLevel): void {
    this.logLevel = level;
  }

  /**
   * 获取默认内容（降级用）
   */
  private getDefaultContent(): any {
    return {
      skillName: 'Excel基础',
      steps: [
        { title: '认识Excel', content: 'Excel由行和列组成', keyPoint: '行列编号' },
        { title: '单元格', content: '每个格子叫单元格', keyPoint: '如A1' }
      ],
      quiz: { question: 'Excel由什么组成？', answer: true, feedback: '正确！' }
    };
  }

  /**
   * 处理错误
   */
  handleError(
    code: ErrorCodeType,
    message?: string,
    context?: Record<string, any>
  ): AppError {
    const errorDef = ErrorCodes[code];
    
    const error: AppError = {
      code: errorDef.code,
      message: message || errorDef.message,
      level: ErrorLevel.ERROR,
      context,
      timestamp: Date.now(),
      recoverable: errorDef.recoverable
    };
    
    // 记录日志
    this.logError(error);
    
    // 触发回调
    this.notifyError(error);
    
    return error;
  }

  /**
   * 包装try-catch
   */
  async wrapAsync<T>(
    fn: () => Promise<T>,
    fallbackCode?: ErrorCodeType,
    fallbackValue?: T
  ): Promise<T> {
    try {
      return await fn();
    } catch (error: any) {
      const code = fallbackCode || 'E1000';
      this.handleError(code, error.message);
      
      if (fallbackValue !== undefined) {
        return fallbackValue;
      }
      
      // 尝试降级策略
      const fallback = this.fallbackStrategies.get(ErrorCodes[code].code);
      if (fallback) {
        return fallback() as T;
      }
      
      throw error;
    }
  }

  /**
   * 包装同步try-catch
   */
  wrapSync<T>(
    fn: () => T,
    fallbackCode?: ErrorCodeType,
    fallbackValue?: T
  ): T {
    try {
      return fn();
    } catch (error: any) {
      const code = fallbackCode || 'E1000';
      this.handleError(code, error.message);
      
      if (fallbackValue !== undefined) {
        return fallbackValue;
      }
      
      return this.fallbackStrategies.get(ErrorCodes[code].code)?.() as T || fallbackValue as T;
    }
  }

  /**
   * 记录错误日志
   */
  private logError(error: AppError): void {
    // 添加到日志队列
    this.errorLogs.push(error);
    
    // 保持日志数量限制
    if (this.errorLogs.length > this.maxLogs) {
      this.errorLogs.shift();
    }
    
    // 输出到HiLog
    const levelStr = ErrorLevel[error.level];
    HiLog.error(`[${error.code}] ${error.message}`, error.context || {});
  }

  /**
   * 通知错误回调
   */
  private notifyError(error: AppError): void {
    for (const callback of this.errorCallbacks) {
      try {
        callback(error);
      } catch (e) {
        HiLog.error("GlobalErrorHandler", `错误回调异常: ${e}`);
      }
    }
  }

  /**
   * 注册错误回调
   */
  onError(callback: (error: AppError) => void): void {
    this.errorCallbacks.push(callback);
  }

  /**
   * 获取错误日志
   */
  getErrorLogs(limit?: number): AppError[] {
    if (limit) {
      return this.errorLogs.slice(-limit);
    }
    return [...this.errorLogs];
  }

  /**
   * 清除错误日志
   */
  clearErrorLogs(): void {
    this.errorLogs = [];
  }

  /**
   * 获取错误统计
   */
  getErrorStats(): {
    total: number;
    byLevel: Record<string, number>;
    byCode: Record<string, number>;
    recentTrend: 'up' | 'down' | 'stable';
  } {
    const stats = {
      total: this.errorLogs.length,
      byLevel: {} as Record<string, number>,
      byCode: {} as Record<string, number>,
      recentTrend: 'stable' as 'up' | 'down' | 'stable'
    };
    
    for (const error of this.errorLogs) {
      stats.byLevel[error.level.toString()] = (stats.byLevel[error.level.toString()] || 0) + 1;
      stats.byCode[error.code] = (stats.byCode[error.code] || 0) + 1;
    }
    
    // 计算最近趋势（简化版）
    const recent = this.errorLogs.slice(-10);
    const older = this.errorLogs.slice(-20, -10);
    if (recent.length > older.length) {
      stats.recentTrend = 'up';
    } else if (recent.length < older.length) {
      stats.recentTrend = 'down';
    }
    
    return stats;
  }

  /**
   * 报告错误（发送到服务器）
   */
  async reportError(error: AppError): Promise<void> {
    HiLog.info("GlobalErrorHandler", `上报错误: ${error.code}`);
    // 实际应该发送到错误收集服务
    // await fetch('/api/error/report', { method: 'POST', body: JSON.stringify(error) });
  }

  /**
   * 断言（调试用）
   */
  assert(condition: boolean, code: ErrorCodeType, message?: string): void {
    if (!condition) {
      this.handleError(code, message);
    }
  }
}

/**
 * 生产级日志服务
 */
export class Logger {
  private static instance: Logger | null = null;
  
  private tag: string;
  private enableConsole: boolean = true;
  private enableRemote: boolean = false;

  static getInstance(tag: string): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    Logger.instance.tag = tag;
    return Logger.instance;
  }

  private constructor() {}

  /**
   * 调试日志
   */
  debug(message: string, context?: any): void {
    this.log(ErrorLevel.DEBUG, message, context);
  }

  /**
   * 信息日志
   */
  info(message: string, context?: any): void {
    this.log(ErrorLevel.INFO, message, context);
  }

  /**
   * 警告日志
   */
  warn(message: string, context?: any): void {
    this.log(ErrorLevel.WARN, message, context);
  }

  /**
   * 错误日志
   */
  error(message: string, context?: any): void {
    this.log(ErrorLevel.ERROR, message, context);
  }

  /**
   * 致命日志
   */
  fatal(message: string, context?: any): void {
    this.log(ErrorLevel.FATAL, message, context);
  }

  private log(level: ErrorLevel, message: string, context?: any): void {
    const timestamp = new Date().toISOString();
    const levelStr = ErrorLevel[level];
    const logMessage = `[${timestamp}] [${levelStr}] [${this.tag}] ${message}`;
    
    // 输出到HiLog
    HiLog.info(this.tag, logMessage);
    
    // 输出到Console（开发模式）
    if (this.enableConsole) {
      const consoleMsg = context ? `${logMessage} ${JSON.stringify(context)}` : logMessage;
      switch (level) {
        case ErrorLevel.DEBUG:
        case ErrorLevel.INFO:
          console.log(consoleMsg);
          break;
        case ErrorLevel.WARN:
          console.warn(consoleMsg);
          break;
        case ErrorLevel.ERROR:
        case ErrorLevel.FATAL:
          console.error(consoleMsg);
          break;
      }
    }
  }
}

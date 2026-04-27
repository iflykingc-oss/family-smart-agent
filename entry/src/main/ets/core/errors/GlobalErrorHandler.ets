/**
 * ============================================================================
 * 全局错误处理器 - GlobalErrorHandler
 * 核心：统一异常捕获、降级策略、错误日志
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { AppError, ErrorCode, ErrorLevel } from './AppError';
import { publishEvent } from '../events/EventBus';
import { ErrorOccurredEvent } from '../events/DomainEvents';

/**
 * 错误处理配置
 */
export interface ErrorHandlingConfig {
  /** 是否显示错误提示 */
  showErrorToast: boolean;
  
  /** 是否记录错误日志 */
  enableLogging: boolean;
  
  /** 是否上报错误 */
  enableReporting: boolean;
  
  /** 降级模式（API 失败时用模板） */
  fallbackMode: boolean;
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: ErrorHandlingConfig = {
  showErrorToast: true,
  enableLogging: true,
  enableReporting: false,
  fallbackMode: true,
};

/**
 * 全局错误处理器
 */
export class GlobalErrorHandler {
  private static instance: GlobalErrorHandler | null = null;
  
  private config: ErrorHandlingConfig;
  private errorHistory: AppError[] = [];
  private readonly maxHistorySize: number = 100;

  /**
   * 获取单例实例
   */
  static getInstance(config?: Partial<ErrorHandlingConfig>): GlobalErrorHandler {
    if (!GlobalErrorHandler.instance) {
      GlobalErrorHandler.instance = new GlobalErrorHandler(config);
    }
    return GlobalErrorHandler.instance;
  }

  private constructor(config?: Partial<ErrorHandlingConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    HiLog.info("GlobalErrorHandler", "全局错误处理器初始化");
  }

  /**
   * 处理错误
   */
  handleError(error: any, context?: string): AppError {
    // 转换为 AppError
    const appError = this.convertToAppError(error, context);
    
    // 记录错误
    this.recordError(appError);
    
    // 发布错误事件
    this.publishErrorEvent(appError);
    
    // 显示错误提示
    if (this.config.showErrorToast) {
      this.showErrorToast(appError);
    }
    
    return appError;
  }

  /**
   * 异步处理错误（带降级）
   */
  async handleAsyncError<T>(
    fn: () => Promise<T>,
    fallbackValue: T,
    context?: string
  ): Promise<T> {
    try {
      return await fn();
    } catch (error: any) {
      const appError = this.handleError(error, context);
      
      // 降级模式
      if (this.config.fallbackMode) {
        HiLog.warn("GlobalErrorHandler", `降级处理：${context}`);
        return fallbackValue;
      }
      
      throw appError;
    }
  }

  /**
   * 同步处理错误（带降级）
   */
  handleSyncError<T>(
    fn: () => T,
    fallbackValue: T,
    context?: string
  ): T {
    try {
      return fn();
    } catch (error: any) {
      const appError = this.handleError(error, context);
      
      // 降级模式
      if (this.config.fallbackMode) {
        HiLog.warn("GlobalErrorHandler", `降级处理：${context}`);
        return fallbackValue;
      }
      
      throw appError;
    }
  }

  /**
   * 转换为 AppError
   */
  private convertToAppError(error: any, context?: string): AppError {
    if (error instanceof AppError) {
      return error;
    }
    
    // 网络错误
    if (error.message?.includes('network') || error.message?.includes('timeout')) {
      return AppError.network(context, { originalError: error });
    }
    
    // 数据错误
    if (error.message?.includes('not found') || error.message?.includes('不存在')) {
      return AppError.dataNotFound(context, { originalError: error });
    }
    
    // AI 服务错误
    if (error.message?.includes('AI') || error.message?.includes('LLM')) {
      return AppError.aiService(context, { originalError: error });
    }
    
    // 默认未知错误
    return AppError.unknown(context || error.message, { originalError: error });
  }

  /**
   * 记录错误
   */
  private recordError(error: AppError): void {
    if (!this.config.enableLogging) return;
    
    this.errorHistory.push(error);
    if (this.errorHistory.length > this.maxHistorySize) {
      this.errorHistory.shift();
    }
    
    // 输出日志
    switch (error.level) {
      case ErrorLevel.DEBUG:
      case ErrorLevel.INFO:
        HiLog.info("GlobalErrorHandler", error.message);
        break;
      case ErrorLevel.WARN:
        HiLog.warn("GlobalErrorHandler", error.message);
        break;
      case ErrorLevel.ERROR:
      case ErrorLevel.FATAL:
        HiLog.error("GlobalErrorHandler", error.message);
        break;
    }
  }

  /**
   * 发布错误事件
   */
  private publishErrorEvent(error: AppError): void {
    if (!this.config.enableReporting) return;
    
    publishEvent(new ErrorOccurredEvent({
      userId: undefined, // TODO: 从上下文获取
      errorCode: ErrorCode[error.code],
      errorMessage: error.message,
      stack: error.stack,
    }));
  }

  /**
   * 显示错误提示
   */
  private showErrorToast(error: AppError): void {
    // 简化实现：记录日志
    const toastMessage = this.getToastMessage(error);
    console.warn(`[错误提示] ${toastMessage}`);
  }

  /**
   * 获取 Toast 消息
   */
  private getToastMessage(error: AppError): string {
    switch (error.code) {
      case 1001: // NETWORK_ERROR
        return '网络连接失败，请检查网络';
      case 1002: // TIMEOUT
        return '请求超时，请重试';
      case 3000: // DATA_NOT_FOUND
        return '数据不存在';
      case 4000: // AI_SERVICE_ERROR
        return 'AI 服务暂时不可用';
      default:
        return error.message;
    }
  }

  /**
   * 获取错误历史
   */
  getErrorHistory(limit?: number): AppError[] {
    if (limit) {
      return this.errorHistory.slice(-limit);
    }
    return [...this.errorHistory];
  }

  /**
   * 清除错误历史
   */
  clearErrorHistory(): void {
    this.errorHistory = [];
  }

  /**
   * 获取错误统计
   */
  getErrorStats(): {
    total: number;
    byLevel: Record<string, number>;
    recentErrors: number; // 最近 1 小时错误数
  } {
    const byLevel: Record<string, number> = {};
    this.errorHistory.forEach(error => {
      const level = ErrorLevel[error.level];
      byLevel[level] = (byLevel[level] || 0) + 1;
    });
    
    const oneHourAgo = Date.now() - 3600000;
    const recentErrors = this.errorHistory.filter(e => e.timestamp > oneHourAgo).length;
    
    return {
      total: this.errorHistory.length,
      byLevel,
      recentErrors,
    };
  }

  /**
   * 更新配置
   */
  updateConfig(config: Partial<ErrorHandlingConfig>): void {
    this.config = { ...this.config, ...config };
    HiLog.info("GlobalErrorHandler", `配置更新：${JSON.stringify(config)}`);
  }
}

/**
 * 便捷错误处理函数
 */
export function handleError(error: any, context?: string): AppError {
  return GlobalErrorHandler.getInstance().handleError(error, context);
}

export async function handleAsyncError<T>(
  fn: () => Promise<T>,
  fallbackValue: T,
  context?: string
): Promise<T> {
  return GlobalErrorHandler.getInstance().handleAsyncError(fn, fallbackValue, context);
}

export function handleSyncError<T>(
  fn: () => T,
  fallbackValue: T,
  context?: string
): T {
  return GlobalErrorHandler.getInstance().handleSyncError(fn, fallbackValue, context);
}

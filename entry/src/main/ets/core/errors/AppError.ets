/**
 * ============================================================================
 * 应用错误基类 - AppError
 * 核心：统一错误处理体系
 * ============================================================================
 */

/**
 * 错误级别
 */
export enum ErrorLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  FATAL = 4,
}

/**
 * 错误码定义
 */
export enum ErrorCode {
  // ==================== 通用错误 1000-1999 ====================
  UNKNOWN = 1000,
  NETWORK_ERROR = 1001,
  TIMEOUT = 1002,
  PARSE_ERROR = 1003,
  VALIDATION_ERROR = 1004,
  
  // ==================== 算法错误 2000-2999 ====================
  ALGORITHM_ERROR = 2000,
  FSRS_ERROR = 2001,
  BKT_ERROR = 2002,
  RECOMMENDATION_ERROR = 2003,
  CLASSIFICATION_ERROR = 2004,
  EVALUATION_ERROR = 2005,
  
  // ==================== 数据错误 3000-3999 ====================
  DATA_NOT_FOUND = 3000,
  DATA_SAVE_FAILED = 3001,
  DATA_LOAD_FAILED = 3002,
  DATA_SYNC_FAILED = 3003,
  DATABASE_ERROR = 3004,
  
  // ==================== AI 服务错误 4000-4999 ====================
  AI_SERVICE_ERROR = 4000,
  AI_QUOTA_EXCEEDED = 4001,
  AI_CONTENT_FILTERED = 4002,
  AI_INVALID_REQUEST = 4003,
  AI_RATE_LIMITED = 4004,
  
  // ==================== 设备错误 5000-5999 ====================
  DEVICE_OFFLINE = 5000,
  DEVICE_NOT_SUPPORTED = 5001,
  PERMISSION_DENIED = 5002,
  STORAGE_FULL = 5003,
  
  // ==================== 业务错误 6000-6999 ====================
  COMPLIANCE_BLOCKED = 6000,
  SKILL_NOT_FOUND = 6001,
  USER_CANCELLED = 6002,
  INVALID_STATE = 6003,
  OPERATION_FAILED = 6004,
}

/**
 * 应用错误类
 */
export class AppError extends Error {
  /** 错误码 */
  public readonly code: ErrorCode;
  
  /** 错误级别 */
  public readonly level: ErrorLevel;
  
  /** 时间戳 */
  public readonly timestamp: number;
  
  /** 上下文信息 */
  public readonly context?: Record<string, any>;
  
  /** 是否可恢复 */
  public readonly recoverable: boolean;
  
  /** 原始错误 */
  public readonly originalError?: any;

  constructor(
    code: ErrorCode,
    message?: string,
    context?: Record<string, any>,
    originalError?: any
  ) {
    super(message || AppError.getDefaultMessage(code));
    
    this.code = code;
    this.level = this.determineLevel(code);
    this.timestamp = Date.now();
    this.context = context;
    this.recoverable = this.isRecoverable(code);
    this.originalError = originalError;
    
    // 保持正确的原型链
    Object.setPrototypeOf(this, AppError.prototype);
  }

  /**
   * 获取默认错误消息
   */
  private static getDefaultMessage(code: ErrorCode): string {
    const messages: Record<ErrorCode, string> = {
      [ErrorCode.UNKNOWN]: '未知错误',
      [ErrorCode.NETWORK_ERROR]: '网络错误',
      [ErrorCode.TIMEOUT]: '请求超时',
      [ErrorCode.PARSE_ERROR]: '解析失败',
      [ErrorCode.VALIDATION_ERROR]: '数据校验失败',
      
      [ErrorCode.ALGORITHM_ERROR]: '算法错误',
      [ErrorCode.FSRS_ERROR]: 'FSRS 算法错误',
      [ErrorCode.BKT_ERROR]: 'BKT 算法错误',
      [ErrorCode.RECOMMENDATION_ERROR]: '推荐算法错误',
      [ErrorCode.CLASSIFICATION_ERROR]: '分类算法错误',
      [ErrorCode.EVALUATION_ERROR]: '评估算法错误',
      
      [ErrorCode.DATA_NOT_FOUND]: '数据不存在',
      [ErrorCode.DATA_SAVE_FAILED]: '数据保存失败',
      [ErrorCode.DATA_LOAD_FAILED]: '数据加载失败',
      [ErrorCode.DATA_SYNC_FAILED]: '数据同步失败',
      [ErrorCode.DATABASE_ERROR]: '数据库错误',
      
      [ErrorCode.AI_SERVICE_ERROR]: 'AI 服务错误',
      [ErrorCode.AI_QUOTA_EXCEEDED]: 'AI 配额用尽',
      [ErrorCode.AI_CONTENT_FILTERED]: '内容被过滤',
      [ErrorCode.AI_INVALID_REQUEST]: '无效请求',
      [ErrorCode.AI_RATE_LIMITED]: '请求频率超限',
      
      [ErrorCode.DEVICE_OFFLINE]: '设备离线',
      [ErrorCode.DEVICE_NOT_SUPPORTED]: '设备不支持',
      [ErrorCode.PERMISSION_DENIED]: '权限不足',
      [ErrorCode.STORAGE_FULL]: '存储空间不足',
      
      [ErrorCode.COMPLIANCE_BLOCKED]: '内容不合规',
      [ErrorCode.SKILL_NOT_FOUND]: '技能不存在',
      [ErrorCode.USER_CANCELLED]: '用户取消',
      [ErrorCode.INVALID_STATE]: '无效状态',
      [ErrorCode.OPERATION_FAILED]: '操作失败',
    };
    
    return messages[code] || '未知错误';
  }

  /**
   * 确定错误级别
   */
  private determineLevel(code: ErrorCode): ErrorLevel {
    if (code >= 5000) return ErrorLevel.FATAL;
    if (code >= 4000) return ErrorLevel.ERROR;
    if (code >= 3000) return ErrorLevel.WARN;
    return ErrorLevel.INFO;
  }

  /**
   * 判断是否可恢复
   */
  private isRecoverable(code: ErrorCode): boolean {
    const recoverableCodes: ErrorCode[] = [
      ErrorCode.NETWORK_ERROR,
      ErrorCode.TIMEOUT,
      ErrorCode.DEVICE_OFFLINE,
      ErrorCode.AI_RATE_LIMITED,
      ErrorCode.DATA_SYNC_FAILED,
    ];
    return recoverableCodes.includes(code);
  }

  /**
   * 转换为 JSON
   */
  toJSON(): object {
    return {
      code: this.code,
      message: this.message,
      level: ErrorLevel[this.level],
      timestamp: this.timestamp,
      context: this.context,
      recoverable: this.recoverable,
      stack: this.stack,
    };
  }

  /**
   * 创建未知错误
   */
  static unknown(message?: string, context?: any): AppError {
    return new AppError(ErrorCode.UNKNOWN, message, context);
  }

  /**
   * 创建网络错误
   */
  static network(message?: string, context?: any): AppError {
    return new AppError(ErrorCode.NETWORK_ERROR, message, context);
  }

  /**
   * 创建数据错误
   */
  static dataNotFound(resource?: string, context?: any): AppError {
    return new AppError(
      ErrorCode.DATA_NOT_FOUND,
      resource ? `${resource} 不存在` : '数据不存在',
      context
    );
  }

  /**
   * 创建 AI 服务错误
   */
  static aiService(message?: string, context?: any): AppError {
    return new AppError(ErrorCode.AI_SERVICE_ERROR, message, context);
  }
}

/**
 * 算法错误
 */
export class AlgorithmError extends AppError {
  constructor(message: string, context?: any, originalError?: any) {
    super(ErrorCode.ALGORITHM_ERROR, message, context, originalError);
    Object.setPrototypeOf(this, AlgorithmError.prototype);
  }
}

/**
 * 数据错误
 */
export class RepositoryError extends AppError {
  constructor(message: string, context?: any, originalError?: any) {
    super(ErrorCode.DATA_SAVE_FAILED, message, context, originalError);
    Object.setPrototypeOf(this, RepositoryError.prototype);
  }
}

/**
 * AI 服务错误
 */
export class LLMServiceError extends AppError {
  constructor(message: string, context?: any, originalError?: any) {
    super(ErrorCode.AI_SERVICE_ERROR, message, context, originalError);
    Object.setPrototypeOf(this, LLMServiceError.prototype);
  }
}

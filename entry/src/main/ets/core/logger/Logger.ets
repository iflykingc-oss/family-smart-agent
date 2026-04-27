/**
 * ============================================================================
 * 日志服务 - Logger
 * 核心：统一日志管理，支持多级别日志
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 日志级别
 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  FATAL = 4,
}

/**
 * 日志条目
 */
export interface LogEntry {
  level: LogLevel;
  tag: string;
  message: string;
  timestamp: number;
  context?: any;
}

/**
 * 日志服务接口
 */
export interface ILogger {
  debug(tag: string, message: string, context?: any): void;
  info(tag: string, message: string, context?: any): void;
  warn(tag: string, message: string, context?: any): void;
  error(tag: string, message: string, context?: any): void;
  fatal(tag: string, message: string, context?: any): void;
}

/**
 * 日志服务配置
 */
export interface LoggerConfig {
  minLevel: LogLevel;
  enableConsole: boolean;
  enableHiLog: boolean;
  enableRemote: boolean;
  maxBufferSize: number;
}

/**
 * 默认日志配置
 */
const DEFAULT_CONFIG: LoggerConfig = {
  minLevel: LogLevel.DEBUG,
  enableConsole: true,
  enableHiLog: true,
  enableRemote: false,
  maxBufferSize: 1000,
};

/**
 * 日志服务
 */
export class Logger implements ILogger {
  private static instance: Logger | null = null;
  
  private config: LoggerConfig;
  private buffer: LogEntry[] = [];
  private tag: string = 'App';

  /**
   * 获取单例实例
   */
  static getInstance(config?: Partial<LoggerConfig>): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger(config);
    }
    return Logger.instance;
  }

  private constructor(config?: Partial<LoggerConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * 设置日志标签
   */
  setTag(tag: string): void {
    this.tag = tag;
  }

  /**
   * 设置日志级别
   */
  setLevel(level: LogLevel): void {
    this.config.minLevel = level;
  }

  /**
   * 调试日志
   */
  debug(tag: string, message: string, context?: any): void {
    this.log(LogLevel.DEBUG, tag, message, context);
  }

  /**
   * 信息日志
   */
  info(tag: string, message: string, context?: any): void {
    this.log(LogLevel.INFO, tag, message, context);
  }

  /**
   * 警告日志
   */
  warn(tag: string, message: string, context?: any): void {
    this.log(LogLevel.WARN, tag, message, context);
  }

  /**
   * 错误日志
   */
  error(tag: string, message: string, context?: any): void {
    this.log(LogLevel.ERROR, tag, message, context);
  }

  /**
   * 致命日志
   */
  fatal(tag: string, message: string, context?: any): void {
    this.log(LogLevel.FATAL, tag, message, context);
  }

  /**
   * 核心日志方法
   */
  private log(level: LogLevel, tag: string, message: string, context?: any): void {
    // 检查日志级别
    if (level < this.config.minLevel) {
      return;
    }

    // 创建日志条目
    const entry: LogEntry = {
      level,
      tag: `${this.tag}/${tag}`,
      message,
      timestamp: Date.now(),
      context,
    };

    // 添加到缓冲区
    this.buffer.push(entry);
    if (this.buffer.length > this.config.maxBufferSize) {
      this.buffer.shift();
    }

    // 输出到 HiLog
    if (this.config.enableHiLog) {
      this.writeToHiLog(level, entry);
    }

    // 输出到 Console
    if (this.config.enableConsole) {
      this.writeToConsole(level, entry);
    }

    // 输出到远程（未来扩展）
    if (this.config.enableRemote && level >= LogLevel.ERROR) {
      this.writeToRemote(entry);
    }
  }

  /**
   * 写入 HiLog
   */
  private writeToHiLog(level: LogLevel, entry: LogEntry): void {
    const logMessage = `[${entry.tag}] ${entry.message}`;
    
    switch (level) {
      case LogLevel.DEBUG:
        HiLog.debug(entry.tag, logMessage);
        break;
      case LogLevel.INFO:
        HiLog.info(entry.tag, logMessage);
        break;
      case LogLevel.WARN:
        HiLog.warn(entry.tag, logMessage);
        break;
      case LogLevel.ERROR:
      case LogLevel.FATAL:
        HiLog.error(entry.tag, logMessage);
        break;
    }
  }

  /**
   * 写入 Console
   */
  private writeToConsole(level: LogLevel, entry: LogEntry): void {
    const timestamp = new Date(entry.timestamp).toISOString();
    const levelStr = LogLevel[level];
    const contextStr = entry.context ? ` ${JSON.stringify(entry.context)}` : '';
    const logMessage = `[${timestamp}] [${levelStr}] [${entry.tag}] ${entry.message}${contextStr}`;

    switch (level) {
      case LogLevel.DEBUG:
      case LogLevel.INFO:
        console.log(logMessage);
        break;
      case LogLevel.WARN:
        console.warn(logMessage);
        break;
      case LogLevel.ERROR:
      case LogLevel.FATAL:
        console.error(logMessage);
        break;
    }
  }

  /**
   * 写入远程（未来扩展）
   */
  private async writeToRemote(entry: LogEntry): Promise<void> {
    // TODO: 实现远程日志上报
    // await fetch('/api/logs', { method: 'POST', body: JSON.stringify(entry) });
  }

  /**
   * 获取日志缓冲区
   */
  getBuffer(limit?: number): LogEntry[] {
    if (limit) {
      return this.buffer.slice(-limit);
    }
    return [...this.buffer];
  }

  /**
   * 清空缓冲区
   */
  clearBuffer(): void {
    this.buffer = [];
  }

  /**
   * 导出日志
   */
  exportLogs(format: 'json' | 'csv' = 'json'): string {
    if (format === 'json') {
      return JSON.stringify(this.buffer, null, 2);
    }
    
    // CSV 格式
    const headers = ['timestamp', 'level', 'tag', 'message'];
    const rows = this.buffer.map(entry => [
      entry.timestamp,
      LogLevel[entry.level],
      entry.tag,
      entry.message.replace(/"/g, '""'),
    ]);
    
    return [headers.join(','), ...rows.map(row => row.join(','))].join('\n');
  }
}

/**
 * 便捷日志函数
 */
export const logger = Logger.getInstance();

export function debug(tag: string, message: string, context?: any): void {
  logger.debug(tag, message, context);
}

export function info(tag: string, message: string, context?: any): void {
  logger.info(tag, message, context);
}

export function warn(tag: string, message: string, context?: any): void {
  logger.warn(tag, message, context);
}

export function error(tag: string, message: string, context?: any): void {
  logger.error(tag, message, context);
}

export function fatal(tag: string, message: string, context?: any): void {
  logger.fatal(tag, message, context);
}

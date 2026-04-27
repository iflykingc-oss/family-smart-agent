/**
 * ============================================================================
 * 性能监控 - PerformanceMonitor
 * 监控应用性能指标
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 性能指标
 */
export interface PerformanceMetrics {
  queryTime: number;      // 查询时间
  cacheHitRate: number;   // 缓存命中率
  memoryUsage: number;    // 内存使用
  concurrency: number;    // 并发数
}

/**
 * 性能监控
 */
export class PerformanceMonitor {
  private static instance: PerformanceMonitor | null = null;
  
  private metrics: Map<string, number[]> = new Map();
  private readonly maxSamples: number = 100;

  /**
   * 获取单例实例
   */
  static getInstance(): PerformanceMonitor {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor();
    }
    return PerformanceMonitor.instance;
  }

  private constructor() {
    HiLog.info("PerformanceMonitor", "初始化");
  }

  /**
   * 记录性能指标
   */
  record(metric: string, value: number): void {
    if (!this.metrics.has(metric)) {
      this.metrics.set(metric, []);
    }
    
    const values = this.metrics.get(metric)!;
    values.push(value);
    
    // 限制样本数量
    if (values.length > this.maxSamples) {
      values.shift();
    }
  }

  /**
   * 开始计时
   */
  startTimer(label: string): () => void {
    const startTime = Date.now();
    
    return () => {
      const duration = Date.now() - startTime;
      this.record(label, duration);
      HiLog.debug("PerformanceMonitor", `${label}: ${duration}ms`);
    };
  }

  /**
   * 获取平均性能指标
   */
  getAverage(metric: string): number {
    const values = this.metrics.get(metric);
    if (!values || values.length === 0) {
      return 0;
    }
    
    const sum = values.reduce((a, b) => a + b, 0);
    return sum / values.length;
  }

  /**
   * 获取性能报告
   */
  getReport(): PerformanceMetrics {
    return {
      queryTime: this.getAverage('query_time'),
      cacheHitRate: this.getAverage('cache_hit_rate'),
      memoryUsage: this.getAverage('memory_usage'),
      concurrency: this.getAverage('concurrency'),
    };
  }

  /**
   * 检查性能是否达标
   */
  checkThresholds(): { passed: boolean; issues: string[] } {
    const issues: string[] = [];
    
    const queryTime = this.getAverage('query_time');
    if (queryTime > 50) {
      issues.push(`查询时间过长：${queryTime.toFixed(2)}ms (>50ms)`);
    }
    
    const cacheHitRate = this.getAverage('cache_hit_rate');
    if (cacheHitRate < 0.8) {
      issues.push(`缓存命中率过低：${(cacheHitRate * 100).toFixed(1)}% (<80%)`);
    }
    
    return {
      passed: issues.length === 0,
      issues,
    };
  }

  /**
   * 清空指标
   */
  clear(): void {
    this.metrics.clear();
  }
}

/**
 * 便捷函数
 */
export function recordPerformance(metric: string, value: number): void {
  PerformanceMonitor.getInstance().record(metric, value);
}

export function startTimer(label: string): () => void {
  return PerformanceMonitor.getInstance().startTimer(label);
}

/**
 * ============================================================================
 * 数据流程优化器 - DataFlowOptimizer
 * 目标：优化数据流转，减少不必要的读写和序列化
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 数据操作类型
 */
export enum DataOperation {
  READ = 'read',
  WRITE = 'write',
  UPDATE = 'update',
  DELETE = 'delete',
  BATCH = 'batch'
}

/**
 * 数据缓存策略
 */
export enum CacheStrategy {
  NONE = 'none',          // 不缓存
  READ_THROUGH = 'read_through',     // 读穿透
  WRITE_THROUGH = 'write_through',   // 写穿透
  WRITE_BEHIND = 'write_behind'      // 写回
}

/**
 * 数据配置
 */
export interface DataConfig {
  enableCache: boolean;
  cacheStrategy: CacheStrategy;
  batchSize: number;
  debounceTime: number;   // 防抖时间（毫秒）
  maxRetries: number;
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: DataConfig = {
  enableCache: true,
  cacheStrategy: CacheStrategy.READ_THROUGH,
  batchSize: 10,
  debounceTime: 100,
  maxRetries: 3
};

/**
 * 数据流程优化器
 */
export class DataFlowOptimizer {
  private static instance: DataFlowOptimizer | null = null;
  
  private config: DataConfig;
  private cache: Map<string, any> = new Map();
  private pendingWrites: Map<string, any> = new Map();
  private writeTimers: Map<string, any> = new Map();
  private operationStats: Map<DataOperation, number> = new Map();

  /**
   * 获取单例实例
   */
  static getInstance(config?: Partial<DataConfig>): DataFlowOptimizer {
    if (!DataFlowOptimizer.instance) {
      DataFlowOptimizer.instance = new DataFlowOptimizer(config);
    }
    return DataFlowOptimizer.instance;
  }

  private constructor(config?: Partial<DataConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.initStats();
    HiLog.info("DataFlowOptimizer", "初始化");
  }

  /**
   * 读取数据
   */
  async read<T>(key: string, loader?: () => Promise<T>): Promise<T | null> {
    this.recordOperation(DataOperation.READ);
    
    // 检查缓存
    if (this.config.enableCache && this.cache.has(key)) {
      HiLog.info("DataFlowOptimizer", `缓存命中：${key}`);
      return this.cache.get(key) as T;
    }
    
    // 从存储加载
    if (loader) {
      const data = await loader();
      
      // 写入缓存
      if (this.config.enableCache && 
          this.config.cacheStrategy === CacheStrategy.READ_THROUGH) {
        this.cache.set(key, data);
      }
      
      return data;
    }
    
    return null;
  }

  /**
   * 写入数据
   */
  async write<T>(key: string, value: T, writer?: (value: T) => Promise<void>): Promise<void> {
    this.recordOperation(DataOperation.WRITE);
    
    // 防抖写入
    if (this.config.debounceTime > 0) {
      this.debounceWrite(key, value, writer);
    } else {
      await this.doWrite(key, value, writer);
    }
  }

  /**
   * 批量写入
   */
  async batchWrite<T>(
    items: Array<{ key: string; value: T }>,
    writer?: (items: Array<{ key: string; value: T }>) => Promise<void>
  ): Promise<void> {
    this.recordOperation(DataOperation.BATCH);
    
    // 分组
    const batches = this.chunkArray(items, this.config.batchSize);
    
    for (const batch of batches) {
      if (writer) {
        await writer(batch);
      }
      
      // 更新缓存
      if (this.config.enableCache) {
        for (const item of batch) {
          this.cache.set(item.key, item.value);
        }
      }
    }
    
    HiLog.info("DataFlowOptimizer", `批量写入：${items.length}项，${batches.length}批`);
  }

  /**
   * 更新数据
   */
  async update<T>(
    key: string,
    updater: (current: T) => T,
    writer?: (value: T) => Promise<void>
  ): Promise<void> {
    this.recordOperation(DataOperation.UPDATE);
    
    // 读取当前值
    const current = await this.read<T>(key);
    if (!current) {
      HiLog.warn("DataFlowOptimizer", `数据不存在：${key}`);
      return;
    }
    
    // 应用更新
    const updated = updater(current);
    
    // 写入
    await this.write(key, updated, writer);
  }

  /**
   * 删除数据
   */
  async delete(key: string, deleter?: (key: string) => Promise<void>): Promise<void> {
    this.recordOperation(DataOperation.DELETE);
    
    // 从缓存删除
    if (this.config.enableCache) {
      this.cache.delete(key);
    }
    
    // 从存储删除
    if (deleter) {
      await deleter(key);
    }
    
    HiLog.info("DataFlowOptimizer", `删除：${key}`);
  }

  /**
   * 预加载数据
   */
  async preload<T>(keys: string[], loader: (key: string) => Promise<T>): Promise<void> {
    HiLog.info("DataFlowOptimizer", `预加载：${keys.length}个键`);
    
    const promises = keys.map(key => this.read(key, () => loader(key)));
    await Promise.all(promises);
  }

  /**
   * 清理缓存
   */
  clearCache(pattern?: string): void {
    if (pattern) {
      const regex = new RegExp(pattern);
      for (const key of this.cache.keys()) {
        if (regex.test(key)) {
          this.cache.delete(key);
        }
      }
      HiLog.info("DataFlowOptimizer", `清理缓存（模式）：${pattern}`);
    } else {
      this.cache.clear();
      HiLog.info("DataFlowOptimizer", "清理全部缓存");
    }
  }

  /**
   * 刷新待写入数据
   */
  async flushPendingWrites(): Promise<void> {
    const entries = Array.from(this.pendingWrites.entries());
    
    for (const [key, value] of entries) {
      await this.doWrite(key, value);
    }
    
    HiLog.info("DataFlowOptimizer", `刷新待写入：${entries.length}项`);
  }

  /**
   * 获取操作统计
   */
  getOperationStats(): Record<string, number> {
    const stats: Record<string, number> = {};
    
    for (const [op, count] of this.operationStats.entries()) {
      stats[op] = count;
    }
    
    return stats;
  }

  /**
   * 获取缓存统计
   */
  getCacheStats(): {
    size: number;
    hitRate: number;
    memoryUsage: number;
  } {
    return {
      size: this.cache.size,
      hitRate: 0, // TODO: 计算命中率
      memoryUsage: this.estimateMemoryUsage()
    };
  }

  // ==================== 私有方法 ====================

  /**
   * 初始化统计
   */
  private initStats(): void {
    this.operationStats.set(DataOperation.READ, 0);
    this.operationStats.set(DataOperation.WRITE, 0);
    this.operationStats.set(DataOperation.UPDATE, 0);
    this.operationStats.set(DataOperation.DELETE, 0);
    this.operationStats.set(DataOperation.BATCH, 0);
  }

  /**
   * 记录操作
   */
  private recordOperation(operation: DataOperation): void {
    const count = this.operationStats.get(operation) || 0;
    this.operationStats.set(operation, count + 1);
  }

  /**
   * 防抖写入
   */
  private debounceWrite<T>(
    key: string,
    value: T,
    writer?: (value: T) => Promise<void>
  ): void {
    // 清除之前的定时器
    if (this.writeTimers.has(key)) {
      clearTimeout(this.writeTimers.get(key));
    }
    
    // 存入待写入
    this.pendingWrites.set(key, value);
    
    // 设置新定时器
    const timer = setTimeout(async () => {
      await this.doWrite(key, value, writer);
      this.writeTimers.delete(key);
    }, this.config.debounceTime);
    
    this.writeTimers.set(key, timer);
  }

  /**
   * 执行写入
   */
  private async doWrite<T>(
    key: string,
    value: T,
    writer?: (value: T) => Promise<void>
  ): Promise<void> {
    // 重试逻辑
    let retries = 0;
    
    while (retries < this.config.maxRetries) {
      try {
        if (writer) {
          await writer(value);
        }
        
        // 更新缓存
        if (this.config.enableCache && 
            this.config.cacheStrategy !== CacheStrategy.NONE) {
          this.cache.set(key, value);
        }
        
        // 从待写入移除
        this.pendingWrites.delete(key);
        
        HiLog.info("DataFlowOptimizer", `写入成功：${key}`);
        return;
      } catch (error: any) {
        retries++;
        HiLog.warn("DataFlowOptimizer", `写入失败（${retries}/${this.config.maxRetries}）：${key}`);
        
        if (retries >= this.config.maxRetries) {
          HiLog.error("DataFlowOptimizer", `写入失败：${key}`);
          throw error;
        }
      }
    }
  }

  /**
   * 分块数组
   */
  private chunkArray<T>(array: T[], size: number): T[][] {
    const chunks: T[][] = [];
    
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    
    return chunks;
  }

  /**
   * 估算内存使用
   */
  private estimateMemoryUsage(): number {
    // 简化估算：每项约 1KB
    return this.cache.size * 1024;
  }
}

/**
 * 便捷函数
 */
export async function readData<T>(key: string, loader?: () => Promise<T>): Promise<T | null> {
  return DataFlowOptimizer.getInstance().read(key, loader);
}

export async function writeData<T>(
  key: string,
  value: T,
  writer?: (value: T) => Promise<void>
): Promise<void> {
  return DataFlowOptimizer.getInstance().write(key, value, writer);
}

export async function batchWriteData<T>(
  items: Array<{ key: string; value: T }>,
  writer?: (items: Array<{ key: string; value: T }>) => Promise<void>
): Promise<void> {
  return DataFlowOptimizer.getInstance().batchWrite(items, writer);
}

export async function updateData<T>(
  key: string,
  updater: (current: T) => T,
  writer?: (value: T) => Promise<void>
): Promise<void> {
  return DataFlowOptimizer.getInstance().update(key, updater, writer);
}

export async function deleteData(key: string, deleter?: (key: string) => Promise<void>): Promise<void> {
  return DataFlowOptimizer.getInstance().delete(key, deleter);
}

export function preloadData<T>(keys: string[], loader: (key: string) => Promise<T>): Promise<void> {
  return DataFlowOptimizer.getInstance().preload(keys, loader);
}

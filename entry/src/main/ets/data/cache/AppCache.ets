/**
 * ============================================================================
 * 应用缓存 - AppCache
 * 核心：LRU 缓存，提升查询性能
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 缓存项
 */
export interface CacheItem<T> {
  value: T;
  timestamp: number;
  expireAt: number;
}

/**
 * 缓存配置
 */
export interface CacheConfig {
  maxSize: number;
  defaultTTL: number; // 默认过期时间（毫秒）
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: CacheConfig = {
  maxSize: 100,
  defaultTTL: 300000, // 5 分钟
};

/**
 * 应用缓存（LRU）
 */
export class AppCache {
  private static instance: AppCache | null = null;
  
  private cache: Map<string, CacheItem<any>> = new Map();
  private config: CacheConfig;

  /**
   * 获取单例实例
   */
  static getInstance(config?: Partial<CacheConfig>): AppCache {
    if (!AppCache.instance) {
      AppCache.instance = new AppCache(config);
    }
    return AppCache.instance;
  }

  private constructor(config?: Partial<CacheConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    HiLog.info("AppCache", `缓存初始化，最大容量：${this.config.maxSize}`);
  }

  /**
   * 获取缓存
   */
  get<T>(key: string): T | null {
    const item = this.cache.get(key);
    if (!item) {
      return null;
    }
    
    // 检查是否过期
    if (Date.now() > item.expireAt) {
      this.cache.delete(key);
      return null;
    }
    
    // 更新访问时间（LRU）
    this.cache.delete(key);
    this.cache.set(key, item);
    
    return item.value as T;
  }

  /**
   * 设置缓存
   */
  set<T>(key: string, value: T, ttl?: number): void {
    // 检查容量
    if (this.cache.size >= this.config.maxSize) {
      // 删除最旧的项
      const firstKey = this.cache.keys().next().value;
      if (firstKey) {
        this.cache.delete(firstKey);
      }
    }
    
    const expireAt = Date.now() + (ttl || this.config.defaultTTL);
    this.cache.set(key, {
      value,
      timestamp: Date.now(),
      expireAt,
    });
    
    HiLog.debug("AppCache", `设置缓存：${key}`);
  }

  /**
   * 删除缓存
   */
  delete(key: string): void {
    this.cache.delete(key);
    HiLog.debug("AppCache", `删除缓存：${key}`);
  }

  /**
   * 清空缓存
   */
  clear(): void {
    this.cache.clear();
    HiLog.info("AppCache", "清空缓存");
  }

  /**
   * 检查缓存是否存在
   */
  has(key: string): boolean {
    const item = this.cache.get(key);
    if (!item) {
      return false;
    }
    
    // 检查是否过期
    if (Date.now() > item.expireAt) {
      this.cache.delete(key);
      return false;
    }
    
    return true;
  }

  /**
   * 获取缓存统计
   */
  getStats(): {
    size: number;
    maxSize: number;
    hitRate: number;
  } {
    return {
      size: this.cache.size,
      maxSize: this.config.maxSize,
      hitRate: 0, // TODO: 统计命中率
    };
  }

  /**
   * 清理过期缓存
   */
  cleanup(): void {
    const now = Date.now();
    const keysToDelete: string[] = [];
    
    this.cache.forEach((item, key) => {
      if (now > item.expireAt) {
        keysToDelete.push(key);
      }
    });
    
    keysToDelete.forEach(key => this.cache.delete(key));
    
    if (keysToDelete.length > 0) {
      HiLog.info("AppCache", `清理${keysToDelete.length}个过期缓存`);
    }
  }
}

/**
 * 缓存装饰器
 */
export function Cached(ttl?: number, keyPrefix?: string) {
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;
    const cache = AppCache.getInstance();
    
    descriptor.value = async function (...args: any[]) {
      const cacheKey = `${keyPrefix || propertyKey}:${JSON.stringify(args)}`;
      
      // 尝试从缓存获取
      const cached = cache.get(cacheKey);
      if (cached !== null) {
        return cached;
      }
      
      // 执行原方法
      const result = await originalMethod.apply(this, args);
      
      // 设置缓存
      cache.set(cacheKey, result, ttl);
      
      return result;
    };
    
    return descriptor;
  };
}

/**
 * 便捷缓存函数
 */
export function getFromCache<T>(key: string): T | null {
  return AppCache.getInstance().get<T>(key);
}

export function setToCache<T>(key: string, value: T, ttl?: number): void {
  AppCache.getInstance().set(key, value, ttl);
}

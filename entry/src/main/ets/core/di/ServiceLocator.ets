/**
 * ============================================================================
 * 服务定位器 - ServiceLocator
 * 核心：依赖注入容器，统一管理所有服务实例
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 服务类型映射
 */
export interface ServiceMap {
  // 算法服务
  'IFSRScheduler': any;
  'IBKTTracker': any;
  'ILearningPathRecommender': any;
  'ISceneClassifier': any;
  'IProjectEvaluator': any;
  
  // 数据服务
  'IUserRepository': any;
  'ISkillRepository': any;
  'ILearningRecordRepository': any;
  
  // 应用服务
  'ILLMService': any;
  'IInteractionService': any;
  'ISceneClassificationService': any;
  'IAnalyticsService': any;
  'IGrowthService': any;
}

/**
 * 服务键类型
 */
export type ServiceKey = keyof ServiceMap;

/**
 * 服务定位器
 */
export class ServiceLocator {
  private static instance: ServiceLocator | null = null;
  
  // 服务实例缓存
  private services: Map<ServiceKey, any> = new Map();
  
  // 服务工厂
  private factories: Map<ServiceKey, () => any> = new Map();
  
  // 是否已初始化
  private initialized: boolean = false;

  /**
   * 获取单例实例
   */
  static getInstance(): ServiceLocator {
    if (!ServiceLocator.instance) {
      ServiceLocator.instance = new ServiceLocator();
    }
    return ServiceLocator.instance;
  }

  private constructor() {
    HiLog.info("ServiceLocator", "服务定位器初始化");
  }

  /**
   * 注册服务实例
   */
  register<T extends ServiceKey>(key: T, instance: ServiceMap[T]): void {
    if (this.services.has(key)) {
      HiLog.warn("ServiceLocator", `服务 ${key} 已被注册，将覆盖`);
    }
    this.services.set(key, instance);
    HiLog.info("ServiceLocator", `服务 ${key} 已注册`);
  }

  /**
   * 注册服务工厂（延迟初始化）
   */
  registerFactory<T extends ServiceKey>(key: T, factory: () => ServiceMap[T]): void {
    this.factories.set(key, factory);
    HiLog.info("ServiceLocator", `服务工厂 ${key} 已注册`);
  }

  /**
   * 获取服务实例
   */
  get<T extends ServiceKey>(key: T): ServiceMap[T] {
    // 先查缓存
    if (this.services.has(key)) {
      return this.services.get(key);
    }
    
    // 查工厂
    if (this.factories.has(key)) {
      const factory = this.factories.get(key)!;
      const instance = factory();
      this.services.set(key, instance);
      return instance;
    }
    
    // 未找到
    throw new Error(`服务 ${key} 未注册`);
  }

  /**
   * 检查服务是否已注册
   */
  has<T extends ServiceKey>(key: T): boolean {
    return this.services.has(key) || this.factories.has(key);
  }

  /**
   * 移除服务
   */
  unregister<T extends ServiceKey>(key: T): void {
    this.services.delete(key);
    this.factories.delete(key);
    HiLog.info("ServiceLocator", `服务 ${key} 已移除`);
  }

  /**
   * 清空所有服务
   */
  clear(): void {
    this.services.clear();
    this.factories.clear();
    HiLog.info("ServiceLocator", "所有服务已清空");
  }

  /**
   * 获取所有已注册服务
   */
  getAllRegistered(): ServiceKey[] {
    const keys = new Set<ServiceKey>();
    this.services.forEach((_, key) => keys.add(key));
    this.factories.forEach((_, key) => keys.add(key));
    return Array.from(keys);
  }

  /**
   * 批量注册服务
   */
  registerAll(services: Array<{ key: ServiceKey; instance: any }>): void {
    for (const { key, instance } of services) {
      this.register(key, instance);
    }
  }

  /**
   * 获取服务（带默认值）
   */
  getOrDefault<T extends ServiceKey>(key: T, defaultValue: ServiceMap[T]): ServiceMap[T] {
    try {
      return this.get(key);
    } catch (error) {
      HiLog.warn("ServiceLocator", `服务 ${key} 未找到，使用默认值`);
      return defaultValue;
    }
  }

  /**
   * 懒加载服务（首次使用时初始化）
   */
  lazyGet<T extends ServiceKey>(key: T): ServiceMap[T] {
    return this.get(key);
  }

  /**
   * 获取服务统计信息
   */
  getStats(): {
    totalServices: number;
    instantiatedServices: number;
    factoryServices: number;
  } {
    return {
      totalServices: this.getAllRegistered().length,
      instantiatedServices: this.services.size,
      factoryServices: this.factories.size,
    };
  }
}

/**
 * 便捷获取服务
 */
export function getService<T extends ServiceKey>(key: T): ServiceMap[T] {
  return ServiceLocator.getInstance().get(key);
}

/**
 * 便捷注册服务
 */
export function registerService<T extends ServiceKey>(key: T, instance: ServiceMap[T]): void {
  ServiceLocator.getInstance().register(key, instance);
}

/**
 * 便捷检查服务
 */
export function hasService<T extends ServiceKey>(key: T): boolean {
  return ServiceLocator.getInstance().has(key);
}

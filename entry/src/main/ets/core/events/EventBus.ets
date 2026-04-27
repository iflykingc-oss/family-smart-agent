/**
 * ============================================================================
 * 事件总线实现 - EventBus
 * 核心：发布/订阅模式，解耦业务逻辑
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { DomainEvent, EventHandler, IEventBus } from './DomainEvent';

/**
 * 事件总线实现
 */
export class EventBus implements IEventBus {
  private static instance: EventBus | null = null;
  
  // 事件处理器映射
  private handlers: Map<string, Array<EventHandler<any>>> = new Map();
  
  // 事件历史（用于调试）
  private eventHistory: DomainEvent[] = [];
  private readonly maxHistorySize: number = 100;

  /**
   * 获取单例实例
   */
  static getInstance(): EventBus {
    if (!EventBus.instance) {
      EventBus.instance = new EventBus();
    }
    return EventBus.instance;
  }

  private constructor() {
    HiLog.info("EventBus", "事件总线初始化");
  }

  /**
   * 发布事件
   */
  async publish<T extends DomainEvent>(event: T): Promise<void> {
    HiLog.debug("EventBus", `发布事件：${event.getType()}`);
    
    // 记录事件历史
    this.eventHistory.push(event);
    if (this.eventHistory.length > this.maxHistorySize) {
      this.eventHistory.shift();
    }
    
    // 获取事件处理器
    const eventType = event.getType();
    const eventHandlers = this.handlers.get(eventType) || [];
    
    // 异步执行所有处理器
    const promises = eventHandlers.map(handler => 
      handler.handle(event).catch(error => {
        HiLog.error("EventBus", `事件处理器执行失败：${error.message}`);
      })
    );
    
    await Promise.all(promises);
    
    HiLog.debug("EventBus", `事件处理完成：${event.getType()}`);
  }

  /**
   * 订阅事件
   */
  subscribe<T extends DomainEvent>(eventType: string, handler: EventHandler<T>): void {
    if (!this.handlers.has(eventType)) {
      this.handlers.set(eventType, []);
    }
    
    const handlers = this.handlers.get(eventType)!;
    handlers.push(handler);
    
    HiLog.info("EventBus", `订阅事件：${eventType}, 当前订阅数：${handlers.length}`);
  }

  /**
   * 取消订阅
   */
  unsubscribe<T extends DomainEvent>(eventType: string, handler: EventHandler<T>): void {
    const handlers = this.handlers.get(eventType);
    if (!handlers) return;
    
    const index = handlers.indexOf(handler);
    if (index >= 0) {
      handlers.splice(index, 1);
      HiLog.info("EventBus", `取消订阅：${eventType}, 剩余订阅数：${handlers.length}`);
    }
  }

  /**
   * 清除所有订阅
   */
  clear(): void {
    this.handlers.clear();
    this.eventHistory = [];
    HiLog.info("EventBus", "清除所有订阅");
  }

  /**
   * 获取事件历史
   */
  getEventHistory(limit?: number): DomainEvent[] {
    if (limit) {
      return this.eventHistory.slice(-limit);
    }
    return [...this.eventHistory];
  }

  /**
   * 获取订阅统计
   */
  getStats(): {
    totalEventTypes: number;
    totalHandlers: number;
    historySize: number;
  } {
    let totalHandlers = 0;
    this.handlers.forEach(handlers => {
      totalHandlers += handlers.length;
    });
    
    return {
      totalEventTypes: this.handlers.size,
      totalHandlers,
      historySize: this.eventHistory.length,
    };
  }
}

/**
 * 便捷发布函数
 */
export function publishEvent<T extends DomainEvent>(event: T): Promise<void> {
  return EventBus.getInstance().publish(event);
}

/**
 * 便捷订阅函数
 */
export function subscribeEvent<T extends DomainEvent>(
  eventType: string,
  handler: EventHandler<T>
): void {
  EventBus.getInstance().subscribe(eventType, handler);
}

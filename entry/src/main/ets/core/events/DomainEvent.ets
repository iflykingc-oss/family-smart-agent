/**
 * ============================================================================
 * 领域事件基类 - DomainEvent
 * 核心：事件驱动架构，解耦业务逻辑
 * ============================================================================
 */

/**
 * 领域事件基类
 */
export abstract class DomainEvent {
  /** 事件 ID */
  public readonly id: string;
  
  /** 事件时间戳 */
  public readonly timestamp: number;
  
  /** 事件数据 */
  public readonly data: any;

  constructor(data: any) {
    this.id = `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    this.timestamp = Date.now();
    this.data = data;
  }

  /**
   * 获取事件类型
   */
  abstract getType(): string;

  /**
   * 转换为 JSON
   */
  toJSON(): object {
    return {
      id: this.id,
      type: this.getType(),
      timestamp: this.timestamp,
      data: this.data,
    };
  }
}

/**
 * 事件处理器接口
 */
export interface EventHandler<T extends DomainEvent> {
  handle(event: T): Promise<void>;
}

/**
 * 事件总线接口
 */
export interface IEventBus {
  publish<T extends DomainEvent>(event: T): Promise<void>;
  subscribe<T extends DomainEvent>(eventType: string, handler: EventHandler<T>): void;
  unsubscribe<T extends DomainEvent>(eventType: string, handler: EventHandler<T>): void;
}

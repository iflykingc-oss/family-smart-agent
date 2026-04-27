/**
 * ============================================================================
 * 领域事件定义 - 具体事件类
 * ============================================================================
 */

import { DomainEvent } from './DomainEvent';

/**
 * 成就解锁事件
 */
export class AchievementUnlockedEvent extends DomainEvent {
  constructor(data: { userId: string; achievementId: string; achievementName: string }) {
    super(data);
  }

  getType(): string {
    return 'AchievementUnlocked';
  }

  get userId(): string {
    return this.data.userId;
  }

  get achievementId(): string {
    return this.data.achievementId;
  }

  get achievementName(): string {
    return this.data.achievementName;
  }
}

/**
 * 学习完成事件
 */
export class LearningCompletedEvent extends DomainEvent {
  constructor(data: { userId: string; skillId: string; skillName: string; duration: number }) {
    super(data);
  }

  getType(): string {
    return 'LearningCompleted';
  }

  get userId(): string {
    return this.data.userId;
  }

  get skillId(): string {
    return this.data.skillId;
  }

  get skillName(): string {
    return this.data.skillName;
  }

  get duration(): number {
    return this.data.duration;
  }
}

/**
 * 复习提醒事件
 */
export class ReviewReminderEvent extends DomainEvent {
  constructor(data: { userId: string; skillId: string; stepNumber: number; retrievability: number }) {
    super(data);
  }

  getType(): string {
    return 'ReviewReminder';
  }

  get userId(): string {
    return this.data.userId;
  }

  get skillId(): string {
    return this.data.skillId;
  }

  get stepNumber(): number {
    return this.data.stepNumber;
  }

  get retrievability(): number {
    return this.data.retrievability;
  }
}

/**
 * 用户行为追踪事件
 */
export class UserBehaviorTrackedEvent extends DomainEvent {
  constructor(data: { userId: string; eventType: string; eventData: any }) {
    super(data);
  }

  getType(): string {
    return 'UserBehaviorTracked';
  }

  get userId(): string {
    return this.data.userId;
  }

  get eventType(): string {
    return this.data.eventType;
  }

  get eventData(): any {
    return this.data.eventData;
  }
}

/**
 * 错误发生事件
 */
export class ErrorOccurredEvent extends DomainEvent {
  constructor(data: { userId?: string; errorCode: string; errorMessage: string; stack?: string }) {
    super(data);
  }

  getType(): string {
    return 'ErrorOccurred';
  }

  get userId(): string | undefined {
    return this.data.userId;
  }

  get errorCode(): string {
    return this.data.errorCode;
  }

  get errorMessage(): string {
    return this.data.errorMessage;
  }

  get stack(): string | undefined {
    return this.data.stack;
  }
}

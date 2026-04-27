/**
 * ============================================================================
 * 事件总线集成测试
 * 测试领域事件系统
 * ============================================================================
 */

import { describe, it, expect, beforeEach } from '@kit.TestKit';
import { EventBus, publishEvent, subscribeEvent } from '../../entry/src/main/ets/core/events/EventBus';
import { AchievementUnlockedEvent, LearningCompletedEvent, ReviewReminderEvent, ErrorOccurredEvent } from '../../entry/src/main/ets/core/events/DomainEvents';
import { EventHandler } from '../../entry/src/main/ets/core/events/DomainEvent';

describe('EventBusIntegration - 事件总线集成测试', () => {
  let eventBus: EventBus;

  beforeEach(() => {
    eventBus = EventBus.getInstance();
    eventBus.clear();
  });

  describe('基础事件测试', () => {
    it('应该正确发布和接收事件', async () => {
      // Arrange
      const receivedEvents: DomainEvent[] = [];
      const handler: EventHandler<AchievementUnlockedEvent> = {
        handle: async (event) => {
          receivedEvents.push(event);
        }
      };
      eventBus.subscribe('AchievementUnlocked', handler);
      
      const event = new AchievementUnlockedEvent({
        userId: 'user_001',
        achievementId: 'first_step',
        achievementName: '第一步',
      });
      
      // Act
      await eventBus.publish(event);
      
      // Assert
      expect(receivedEvents.length).toBe(1);
      expect(receivedEvents[0]).toBeInstanceOf(AchievementUnlockedEvent);
    });

    it('应该支持多个订阅者', async () => {
      // Arrange
      const received1: DomainEvent[] = [];
      const received2: DomainEvent[] = [];
      
      const handler1: EventHandler<AchievementUnlockedEvent> = {
        handle: async (event) => received1.push(event)
      };
      const handler2: EventHandler<AchievementUnlockedEvent> = {
        handle: async (event) => received2.push(event)
      };
      
      eventBus.subscribe('AchievementUnlocked', handler1);
      eventBus.subscribe('AchievementUnlocked', handler2);
      
      const event = new AchievementUnlockedEvent({
        userId: 'user_001',
        achievementId: 'first_step',
        achievementName: '第一步',
      });
      
      // Act
      await eventBus.publish(event);
      
      // Assert
      expect(received1.length).toBe(1);
      expect(received2.length).toBe(1);
    });

    it('应该正确取消订阅', async () => {
      // Arrange
      const received: DomainEvent[] = [];
      const handler: EventHandler<AchievementUnlockedEvent> = {
        handle: async (event) => received.push(event)
      };
      
      eventBus.subscribe('AchievementUnlocked', handler);
      eventBus.unsubscribe('AchievementUnlocked', handler);
      
      const event = new AchievementUnlockedEvent({
        userId: 'user_001',
        achievementId: 'first_step',
        achievementName: '第一步',
      });
      
      // Act
      await eventBus.publish(event);
      
      // Assert
      expect(received.length).toBe(0);
    });
  });

  describe('事件类型测试', () => {
    it('应该正确处理 AchievementUnlockedEvent', async () => {
      // Arrange
      const received: AchievementUnlockedEvent[] = [];
      const handler: EventHandler<AchievementUnlockedEvent> = {
        handle: async (event) => received.push(event)
      };
      eventBus.subscribe('AchievementUnlocked', handler);
      
      // Act
      await publishEvent(new AchievementUnlockedEvent({
        userId: 'user_001',
        achievementId: 'streak_7',
        achievementName: '坚持不懈',
      }));
      
      // Assert
      expect(received.length).toBe(1);
      expect(received[0].userId).toBe('user_001');
      expect(received[0].achievementId).toBe('streak_7');
      expect(received[0].achievementName).toBe('坚持不懈');
    });

    it('应该正确处理 LearningCompletedEvent', async () => {
      // Arrange
      const received: LearningCompletedEvent[] = [];
      const handler: EventHandler<LearningCompletedEvent> = {
        handle: async (event) => received.push(event)
      };
      eventBus.subscribe('LearningCompleted', handler);
      
      // Act
      await publishEvent(new LearningCompletedEvent({
        userId: 'user_001',
        skillId: 'excel_basic',
        skillName: 'Excel 基础',
        duration: 120,
      }));
      
      // Assert
      expect(received.length).toBe(1);
      expect(received[0].skillName).toBe('Excel 基础');
    });

    it('应该正确处理 ReviewReminderEvent', async () => {
      // Arrange
      const received: ReviewReminderEvent[] = [];
      const handler: EventHandler<ReviewReminderEvent> = {
        handle: async (event) => received.push(event)
      };
      eventBus.subscribe('ReviewReminder', handler);
      
      // Act
      await publishEvent(new ReviewReminderEvent({
        userId: 'user_001',
        skillId: 'excel_basic',
        stepNumber: 3,
        retrievability: 0.7,
      }));
      
      // Assert
      expect(received.length).toBe(1);
      expect(received[0].stepNumber).toBe(3);
    });

    it('应该正确处理 ErrorOccurredEvent', async () => {
      // Arrange
      const received: ErrorOccurredEvent[] = [];
      const handler: EventHandler<ErrorOccurredEvent> = {
        handle: async (event) => received.push(event)
      };
      eventBus.subscribe('ErrorOccurred', handler);
      
      // Act
      await publishEvent(new ErrorOccurredEvent({
        userId: 'user_001',
        errorCode: 'E1001',
        errorMessage: '网络错误',
        stack: 'stack trace',
      }));
      
      // Assert
      expect(received.length).toBe(1);
      expect(received[0].errorCode).toBe('E1001');
    });
  });

  describe('事件历史测试', () => {
    it('应该记录事件历史', async () => {
      // Arrange
      const event1 = new AchievementUnlockedEvent({
        userId: 'user_001',
        achievementId: 'first_step',
        achievementName: '第一步',
      });
      const event2 = new LearningCompletedEvent({
        userId: 'user_001',
        skillId: 'excel_basic',
        skillName: 'Excel 基础',
        duration: 120,
      });
      
      // Act
      await eventBus.publish(event1);
      await eventBus.publish(event2);
      const history = eventBus.getEventHistory();
      
      // Assert
      expect(history.length).toBe(2);
    });

    it('应该限制历史记录大小', async () => {
      // Arrange
      for (let i = 0; i < 150; i++) {
        await eventBus.publish(new AchievementUnlockedEvent({
          userId: 'user_001',
          achievementId: `achievement_${i}`,
          achievementName: `成就${i}`,
        }));
      }
      
      // Act
      const history = eventBus.getEventHistory();
      
      // Assert
      expect(history.length).toBeLessThanOrEqual(100);
    });

    it('应该支持获取指定数量的历史', async () => {
      // Arrange
      for (let i = 0; i < 50; i++) {
        await eventBus.publish(new AchievementUnlockedEvent({
          userId: 'user_001',
          achievementId: `achievement_${i}`,
          achievementName: `成就${i}`,
        }));
      }
      
      // Act
      const history = eventBus.getEventHistory(10);
      
      // Assert
      expect(history.length).toBe(10);
    });
  });

  describe('错误处理测试', () => {
    it('应该处理事件处理器异常', async () => {
      // Arrange
      const handler: EventHandler<AchievementUnlockedEvent> = {
        handle: async () => {
          throw new Error('处理器异常');
        }
      };
      eventBus.subscribe('AchievementUnlocked', handler);
      
      const event = new AchievementUnlockedEvent({
        userId: 'user_001',
        achievementId: 'first_step',
        achievementName: '第一步',
      });
      
      // Act & Assert
      await expect(eventBus.publish(event)).resolves.not.toThrow();
    });

    it('应该继续处理其他订阅者', async () => {
      // Arrange
      const received: DomainEvent[] = [];
      
      const errorHandler: EventHandler<AchievementUnlockedEvent> = {
        handle: async () => { throw new Error('错误'); }
      };
      const successHandler: EventHandler<AchievementUnlockedEvent> = {
        handle: async (event) => { received.push(event); }
      };
      
      eventBus.subscribe('AchievementUnlocked', errorHandler);
      eventBus.subscribe('AchievementUnlocked', successHandler);
      
      const event = new AchievementUnlockedEvent({
        userId: 'user_001',
        achievementId: 'first_step',
        achievementName: '第一步',
      });
      
      // Act
      await eventBus.publish(event);
      
      // Assert
      expect(received.length).toBe(1);
    });
  });

  describe('性能测试', () => {
    it('应该快速发布事件', async () => {
      // Arrange
      const handler: EventHandler<AchievementUnlockedEvent> = {
        handle: async () => {}
      };
      eventBus.subscribe('AchievementUnlocked', handler);
      
      const startTime = Date.now();
      
      // Act
      for (let i = 0; i < 100; i++) {
        await eventBus.publish(new AchievementUnlockedEvent({
          userId: 'user_001',
          achievementId: `achievement_${i}`,
          achievementName: `成就${i}`,
        }));
      }
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      // Assert
      expect(duration).toBeLessThan(5000); // 5 秒内完成 100 次发布
    });
  });
});

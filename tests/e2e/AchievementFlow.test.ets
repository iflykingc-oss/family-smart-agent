/**
 * ============================================================================
 * 成就系统 E2E 测试
 * 测试完整成就解锁流程
 * ============================================================================
 */

import { describe, it, expect, beforeAll } from '@kit.TestKit';
import { GrowthService } from '../../entry/src/main/ets/service/GrowthService';
import { EventBus } from '../../entry/src/main/ets/core/events/EventBus';
import { AchievementUnlockedEvent } from '../../entry/src/main/ets/core/events/DomainEvents';

describe('AchievementFlow E2E - 完整成就流程测试', () => {
  let growthService: GrowthService;
  let eventBus: EventBus;

  beforeAll(() => {
    growthService = GrowthService.getInstance();
    eventBus = EventBus.getInstance();
  });

  describe('成就解锁流程', () => {
    it('应该解锁第一步成就', async () => {
      // Arrange
      const userId = 'test_user';
      
      // TODO: 模拟用户完成第一次学习
      
      // Act
      const results = await growthService.checkAchievements(userId);
      
      // Assert
      expect(results.some(r => r.unlocked && r.achievement?.id === 'first_step')).toBeTruthy();
    });

    it('应该解锁技能完成成就', async () => {
      // Arrange
      const userId = 'test_user';
      
      // TODO: 模拟用户完成一个技能
      
      // Act
      const results = await growthService.checkAchievements(userId);
      
      // Assert
      expect(results.some(r => r.unlocked && r.achievement?.id === 'skill_complete')).toBeTruthy();
    });

    it('应该解锁连续学习成就', async () => {
      // Arrange
      const userId = 'test_user';
      
      // TODO: 模拟用户连续学习 3 天
      
      // Act
      const results = await growthService.checkAchievements(userId);
      
      // Assert
      expect(results.some(r => r.unlocked && r.achievement?.id === 'streak_3')).toBeTruthy();
    });

    it('应该解锁等级成就', async () => {
      // Arrange
      const userId = 'test_user';
      
      // TODO: 模拟用户达到 5 级
      
      // Act
      const results = await growthService.checkAchievements(userId);
      
      // Assert
      expect(results.some(r => r.unlocked && r.achievement?.id === 'level_5')).toBeTruthy();
    });
  });

  describe('成就事件流程', () => {
    it('应该发布成就解锁事件', async () => {
      // Arrange
      const receivedEvents: AchievementUnlockedEvent[] = [];
      eventBus.subscribe('AchievementUnlocked', {
        handle: async (event) => {
          receivedEvents.push(event);
        }
      });
      
      // TODO: 模拟成就解锁
      
      // Assert
      expect(receivedEvents.length).toBeGreaterThan(0);
    });
  });

  describe('成就进度流程', () => {
    it('应该正确计算成就进度', async () => {
      // Arrange
      const userId = 'test_user';
      
      // Act
      const progress = await growthService.getUserAchievementProgress(userId);
      
      // Assert
      expect(progress.total).toBeGreaterThan(0);
      expect(progress.unlocked).toBeGreaterThanOrEqual(0);
      expect(progress.progress).toBeGreaterThanOrEqual(0);
      expect(progress.progress).toBeLessThanOrEqual(100);
    });

    it('应该返回下一个成就', async () => {
      // Arrange
      const userId = 'test_user';
      
      // Act
      const progress = await growthService.getUserAchievementProgress(userId);
      
      // Assert
      expect(progress.nextAchievement).toBeDefined();
    });
  });

  describe('分享文案生成', () => {
    it('应该生成成就分享文案', () => {
      // Arrange
      const extraData = {
        achievementName: '坚持不懈',
      };
      
      // Act
      const text = growthService.generateShareContent('user_001', 'achievement', extraData);
      
      // Assert
      expect(text).toContain('坚持不懈');
    });

    it('应该生成完成分享文案', () => {
      // Arrange
      const extraData = {
        skillName: 'Excel 基础',
      };
      
      // Act
      const text = growthService.generateShareContent('user_001', 'completion', extraData);
      
      // Assert
      expect(text).toContain('Excel 基础');
    });

    it('应该生成连续学习分享文案', () => {
      // Arrange
      const extraData = {
        streak: 7,
      };
      
      // Act
      const text = growthService.generateShareContent('user_001', 'streak', extraData);
      
      // Assert
      expect(text).toContain('7');
    });
  });

  describe('成就系统性能', () => {
    it('应该快速检查成就', async () => {
      // Arrange
      const userId = 'test_user';
      const startTime = Date.now();
      
      // Act
      for (let i = 0; i < 10; i++) {
        await growthService.checkAchievements(userId);
      }
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      // Assert
      expect(duration).toBeLessThan(5000); // 5 秒内完成 10 次检查
    });
  });
});

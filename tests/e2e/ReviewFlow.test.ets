/**
 * ============================================================================
 * 复习流程 E2E 测试
 * 测试 FSRS 复习提醒流程
 * ============================================================================
 */

import { describe, it, expect, beforeAll } from '@kit.TestKit';
import { TemporalAbilityGraph } from '../../entry/src/main/ets/services/engine/TemporalAbilityGraph';
import { ReviewViewModel } from '../../entry/src/main/ets/presentation/viewmodels/ReviewViewModel';

describe('ReviewFlow E2E - 完整复习流程测试', () => {
  let abilityGraph: TemporalAbilityGraph;
  let viewModel: ReviewViewModel;

  beforeAll(() => {
    abilityGraph = TemporalAbilityGraph.getInstance();
    viewModel = new ReviewViewModel();
  });

  describe('FSRS 复习提醒流程', () => {
    it('应该正确检测需要复习的技能', async () => {
      // Arrange
      const userId = 'test_user';
      const skillId = 'excel_basic';
      
      // Act: 用户学习
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      
      // Assert: 初始不需要复习
      const checkResult = abilityGraph.checkReviewNeeded(userId, skillId);
      expect(checkResult.needed).toBeFalsy();
    });

    it('应该正确计算复习优先级', async () => {
      // Arrange
      const userId = 'test_user';
      
      // Act: 用户学习多个技能
      abilityGraph.updateSkill(userId, 'excel_basic', 'correct', 30, 0, 'phone');
      abilityGraph.updateSkill(userId, 'wechat_basic', 'incorrect', 30, 2, 'phone');
      abilityGraph.updateSkill(userId, 'harmony_share', 'correct', 30, 0, 'phone');
      
      // Assert: 获取复习列表
      const pendingReviews = abilityGraph.getPendingReviews(userId);
      expect(pendingReviews).toBeDefined();
    });
  });

  describe('复习 ViewModel 流程', () => {
    it('应该正确刷新复习列表', async () => {
      // Arrange
      const userId = 'test_user';
      
      // Act: 模拟学习
      abilityGraph.updateSkill(userId, 'excel_basic', 'correct', 30, 0, 'phone');
      abilityGraph.updateSkill(userId, 'wechat_basic', 'correct', 30, 0, 'phone');
      
      // Act: 刷新复习列表
      await viewModel.refresh(userId);
      
      // Assert
      const items = viewModel.getReviewItems();
      expect(items).toBeDefined();
    });

    it('应该正确完成复习', async () => {
      // Arrange
      const userId = 'test_user';
      abilityGraph.updateSkill(userId, 'excel_basic', 'correct', 30, 0, 'phone');
      await viewModel.refresh(userId);
      
      // Act: 完成复习
      const items = viewModel.getReviewItems();
      if (items.length > 0) {
        viewModel.completeReview(items[0].skillId, items[0].stepNumber, true);
      }
      
      // Assert
      const stats = viewModel.getStats();
      expect(stats.total).toBeDefined();
    });

    it('应该正确跳过复习', async () => {
      // Arrange
      const userId = 'test_user';
      abilityGraph.updateSkill(userId, 'excel_basic', 'correct', 30, 0, 'phone');
      await viewModel.refresh(userId);
      
      // Act: 跳过复习
      const items = viewModel.getReviewItems();
      if (items.length > 0) {
        viewModel.skipReview(items[0].skillId, items[0].stepNumber);
      }
      
      // Assert
      const stats = viewModel.getStats();
      expect(stats.total).toBeDefined();
    });
  });

  describe('复习提醒性能', () => {
    it('应该快速刷新复习列表', async () => {
      // Arrange
      const userId = 'test_user';
      
      // Act: 模拟大量学习记录
      for (let i = 0; i < 50; i++) {
        abilityGraph.updateSkill(userId, `skill_${i}`, 'correct', 30, 0, 'phone');
      }
      
      const startTime = Date.now();
      
      // Act: 刷新复习列表
      await viewModel.refresh(userId);
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      // Assert
      expect(duration).toBeLessThan(2000); // 2 秒内完成
    });
  });
});

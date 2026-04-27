/**
 * ============================================================================
 * FSRS 调度器完整单元测试
 * 测试覆盖率目标：100%
 * ============================================================================
 */

import { describe, it, expect, beforeEach } from '@kit.TestKit';
import { TemporalAbilityGraph } from '../entry/src/main/ets/services/engine/TemporalAbilityGraph';
import { getFsrsScheduler } from '../entry/src/main/ets/domain/algorithms/impl/FSRScheduler';

describe('FSRScheduler - 完整测试', () => {
  let abilityGraph: TemporalAbilityGraph;
  const userId = 'test_user_001';
  const skillId = 'excel_basic';

  beforeEach(() => {
    abilityGraph = TemporalAbilityGraph.getInstance();
  });

  describe('基础功能测试', () => {
    it('应该正确初始化用户技能', () => {
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill).not.toBeNull();
      expect(skill!.skillId).toBe(skillId);
      expect(skill!.level).toBeGreaterThan(0);
    });

    it('应该正确记录学习次数', () => {
      // Arrange
      const initialCount = 0;
      
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill!.practiceCount).toBe(initialCount + 3);
    });

    it('应该正确计算学习速度', () => {
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      abilityGraph.updateSkill(userId, skillId, 'incorrect', 30, 2, 'phone');
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill!.learningSpeed).toBeGreaterThan(0);
      expect(skill!.learningSpeed).toBeLessThan(0.2);
    });
  });

  describe('FSRS 稳定度测试', () => {
    it('答对应该提高稳定度', () => {
      // Arrange
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill1 = abilityGraph.getUserSkill(userId, skillId);
      const initialStability = skill1!.fsrsStability;
      
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill2 = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill2!.fsrsStability).toBeGreaterThan(initialStability);
    });

    it('答错应该降低稳定度', () => {
      // Arrange
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill1 = abilityGraph.getUserSkill(userId, skillId);
      const initialStability = skill1!.fsrsStability;
      
      // Act
      abilityGraph.updateSkill(userId, skillId, 'incorrect', 30, 2, 'phone');
      const skill2 = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill2!.fsrsStability).toBeLessThan(initialStability);
    });

    it('连续答对应该显著提高稳定度', () => {
      // Act
      for (let i = 0; i < 5; i++) {
        abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      }
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill!.fsrsStability).toBeGreaterThan(1.0);
      expect(skill!.fsrsStability).toBeLessThan(100.0); // 合理范围
    });
  });

  describe('FSRS 难度测试', () => {
    it('初始难度应该是 5.0', () => {
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill!.fsrsDifficulty).toBe(5.0);
    });

    it('答对应该降低难度', () => {
      // Arrange
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const initialDifficulty = 5.0;
      
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill!.fsrsDifficulty).toBeLessThanOrEqual(initialDifficulty);
    });

    it('答错应该提高难度', () => {
      // Arrange
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const initialDifficulty = 5.0;
      
      // Act
      abilityGraph.updateSkill(userId, skillId, 'incorrect', 30, 2, 'phone');
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill!.fsrsDifficulty).toBeGreaterThanOrEqual(initialDifficulty);
    });

    it('难度应该在 1-10 范围内', () => {
      // Act
      for (let i = 0; i < 20; i++) {
        abilityGraph.updateSkill(userId, skillId, i % 2 === 0 ? 'correct' : 'incorrect', 30, 0, 'phone');
      }
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill!.fsrsDifficulty).toBeGreaterThanOrEqual(1.0);
      expect(skill!.fsrsDifficulty).toBeLessThanOrEqual(10.0);
    });
  });

  describe('FSRS 间隔测试', () => {
    it('首次复习间隔应该大于 0', () => {
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill!.fsrsInterval).toBeGreaterThan(0);
    });

    it('连续答对应该增加间隔', () => {
      // Arrange
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill1 = abilityGraph.getUserSkill(userId, skillId);
      const initialInterval = skill1!.fsrsInterval;
      
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill2 = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill2!.fsrsInterval).toBeGreaterThan(initialInterval);
    });

    it('答错应该重置间隔', () => {
      // Arrange
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill1 = abilityGraph.getUserSkill(userId, skillId);
      const initialInterval = skill1!.fsrsInterval;
      
      // Act
      abilityGraph.updateSkill(userId, skillId, 'incorrect', 30, 2, 'phone');
      const skill2 = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill2!.fsrsInterval).toBeLessThan(initialInterval);
    });
  });

  describe('FSRS 可回忆性测试', () => {
    it('刚学习后可回忆性应该接近 100%', () => {
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill!.fsrsRetrievability).toBeGreaterThan(0.9);
    });

    it('复习次数越多可回忆性越高', () => {
      // Arrange
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill1 = abilityGraph.getUserSkill(userId, skillId);
      const initialRetrievability = skill1!.fsrsRetrievability;
      
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const skill2 = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill2!.fsrsRetrievability).toBeGreaterThanOrEqual(initialRetrievability);
    });
  });

  describe('复习提醒测试', () => {
    it('新学习技能不需要复习', () => {
      // Arrange
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      
      // Act
      const result = abilityGraph.checkReviewNeeded(userId, skillId);
      
      // Assert
      expect(result.needed).toBeFalsy();
    });

    it('可回忆性低于 85% 需要复习', () => {
      // TODO: 模拟时间流逝，使可回忆性降低
      // 暂时跳过
    });

    it('应该正确返回下次复习时间', () => {
      // Arrange
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      
      // Act
      const result = abilityGraph.checkReviewNeeded(userId, skillId);
      
      // Assert
      expect(result.nextReviewTime).toBeDefined();
      expect(result.nextReviewTime!.getTime()).toBeGreaterThan(Date.now());
    });
  });

  describe('时空模式分析测试', () => {
    it('应该正确分析学习时间分布', () => {
      // Arrange
      const currentHour = new Date().getHours();
      
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const analysis = abilityGraph.getTemporalPatternAnalysis(userId, skillId);
      
      // Assert
      expect(analysis.bestTimeSlot).toBeDefined();
      expect(analysis.learningSpeed).toBeDefined();
      expect(analysis.engagementLevel).toBeDefined();
    });

    it('应该正确分析设备分布', () => {
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'tablet');
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const analysis = abilityGraph.getTemporalPatternAnalysis(userId, skillId);
      
      // Assert
      expect(analysis.bestDevice).toBe('手机');
    });

    it('应该返回 FSRS 状态', () => {
      // Act
      abilityGraph.updateSkill(userId, skillId, 'correct', 30, 0, 'phone');
      const analysis = abilityGraph.getTemporalPatternAnalysis(userId, skillId);
      
      // Assert
      expect(analysis.fsrsStability).toBeDefined();
      expect(analysis.fsrsRetrievability).toBeDefined();
    });
  });

  describe('边界条件测试', () => {
    it('处理大量学习记录', () => {
      // Act
      for (let i = 0; i < 100; i++) {
        abilityGraph.updateSkill(userId, skillId, i % 2 === 0 ? 'correct' : 'incorrect', 30, 0, 'phone');
      }
      const skill = abilityGraph.getUserSkill(userId, skillId);
      
      // Assert
      expect(skill).not.toBeNull();
      expect(skill!.practiceCount).toBe(100);
    });

    it('处理多个用户', () => {
      // Arrange
      const users = ['user_001', 'user_002', 'user_003'];
      
      // Act
      users.forEach((uid, index) => {
        abilityGraph.updateSkill(uid, skillId, 'correct', 30, 0, 'phone');
      });
      
      // Assert
      users.forEach(uid => {
        const skill = abilityGraph.getUserSkill(uid, skillId);
        expect(skill).not.toBeNull();
      });
    });

    it('处理多个技能', () => {
      // Arrange
      const skills = ['excel_basic', 'wechat_basic', 'harmony_share'];
      
      // Act
      skills.forEach(sid => {
        abilityGraph.updateSkill(userId, sid, 'correct', 30, 0, 'phone');
      });
      
      // Assert
      const userSkills = abilityGraph.getUserSkills(userId);
      expect(userSkills.length).toBe(3);
    });
  });
});

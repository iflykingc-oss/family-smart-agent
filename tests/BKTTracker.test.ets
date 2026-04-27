/**
 * ============================================================================
 * BKT 知识追踪完整单元测试
 * 测试覆盖率目标：100%
 * ============================================================================
 */

import { describe, it, expect, beforeEach } from '@kit.TestKit';
import { KnowledgeTrackingEntity } from '../entry/src/main/ets/domain/entities/KnowledgeTrackingEntity';

describe('BKTTracker - 完整测试', () => {
  let entity: KnowledgeTrackingEntity;

  beforeEach(() => {
    entity = new KnowledgeTrackingEntity(
      'kt_001',
      'user_001',
      'excel_basic',
      'formula_sum'
    );
  });

  describe('初始化测试', () => {
    it('应该正确初始化掌握概率', () => {
      // Assert
      expect(entity.getMasteryProbability()).toBe(0.01); // 初始 1%
    });

    it('应该正确初始化 BKT 参数', () => {
      // Assert
      expect(entity.p_learn).toBe(0.1);
      expect(entity.p_slip).toBe(0.1);
      expect(entity.p_guess).toBe(0.3);
    });

    it('应该正确初始化学习计数', () => {
      // Assert
      expect(entity.state.learning_count).toBe(0);
      expect(entity.state.correct_count).toBe(0);
      expect(entity.state.incorrect_count).toBe(0);
    });
  });

  describe('掌握概率更新测试', () => {
    it('答对应该提高掌握概率', () => {
      // Arrange
      const initialPKnown = entity.getMasteryProbability();
      
      // Act
      entity.update(true);
      
      // Assert
      expect(entity.getMasteryProbability()).toBeGreaterThan(initialPKnown);
    });

    it('答错应该降低掌握概率', () => {
      // Arrange
      const initialPKnown = entity.getMasteryProbability();
      
      // Act
      entity.update(false);
      
      // Assert
      expect(entity.getMasteryProbability()).toBeLessThan(initialPKnown);
    });

    it('连续答对应该显著提高掌握概率', () => {
      // Act
      for (let i = 0; i < 10; i++) {
        entity.update(true);
      }
      
      // Assert
      expect(entity.getMasteryProbability()).toBeGreaterThan(0.9);
    });

    it('连续答错应该显著降低掌握概率', () => {
      // Act
      for (let i = 0; i < 10; i++) {
        entity.update(false);
      }
      
      // Assert
      expect(entity.getMasteryProbability()).toBeLessThan(0.5);
    });

    it('掌握概率应该在 0-1 范围内', () => {
      // Act
      for (let i = 0; i < 100; i++) {
        entity.update(i % 2 === 0 ? true : false);
      }
      
      // Assert
      const pKnown = entity.getMasteryProbability();
      expect(pKnown).toBeGreaterThanOrEqual(0);
      expect(pKnown).toBeLessThanOrEqual(1);
    });
  });

  describe('掌握状态测试', () => {
    it('初始状态不应该掌握', () => {
      // Assert
      expect(entity.isMastered()).toBeFalsy();
    });

    it('掌握概率达到 95% 应该标记为掌握', () => {
      // Act
      for (let i = 0; i < 20; i++) {
        entity.update(true);
      }
      
      // Assert
      expect(entity.isMastered()).toBeTruthy();
    });

    it('掌握概率低于 95% 不应该标记为掌握', () => {
      // Act
      entity.update(true);
      entity.update(true);
      
      // Assert
      expect(entity.isMastered()).toBeFalsy();
    });

    it('自定义阈值应该生效', () => {
      // Act
      entity.update(true);
      entity.update(true);
      entity.update(true);
      
      // Assert
      expect(entity.isMastered(0.5)).toBeTruthy(); // 50% 阈值
      expect(entity.isMastered(0.95)).toBeFalsy(); // 95% 阈值
    });
  });

  describe('推荐操作测试', () => {
    it('初始状态应该推荐复习', () => {
      // Assert
      expect(entity.getRecommendation()).toBe('review');
    });

    it('掌握后应该推荐完成', () => {
      // Act
      for (let i = 0; i < 20; i++) {
        entity.update(true);
      }
      
      // Assert
      expect(entity.getRecommendation()).toBe('complete');
    });

    it('部分掌握应该推荐继续', () => {
      // Act
      entity.update(true);
      entity.update(true);
      entity.update(true);
      
      // Assert
      expect(['review', 'continue']).toContain(entity.getRecommendation());
    });
  });

  describe('正确率计算测试', () => {
    it('没有记录时正确率应该为 0', () => {
      // Assert
      expect(entity.getAccuracy()).toBe(0);
    });

    it('应该正确计算正确率', () => {
      // Act
      entity.update(true);
      entity.update(true);
      entity.update(false);
      
      // Assert
      expect(entity.getAccuracy()).toBeCloseTo(0.67, 2); // 2/3
    });

    it('全部答对正确率应该为 100%', () => {
      // Act
      for (let i = 0; i < 10; i++) {
        entity.update(true);
      }
      
      // Assert
      expect(entity.getAccuracy()).toBe(1);
    });

    it('全部答错正确率应该为 0%', () => {
      // Act
      for (let i = 0; i < 10; i++) {
        entity.update(false);
      }
      
      // Assert
      expect(entity.getAccuracy()).toBe(0);
    });
  });

  describe('学习计数测试', () => {
    it('应该正确记录学习次数', () => {
      // Act
      entity.update(true);
      entity.update(false);
      entity.update(true);
      
      // Assert
      expect(entity.state.learning_count).toBe(3);
    });

    it('应该正确记录正确次数', () => {
      // Act
      entity.update(true);
      entity.update(false);
      entity.update(true);
      
      // Assert
      expect(entity.state.correct_count).toBe(2);
    });

    it('应该正确记录错误次数', () => {
      // Act
      entity.update(true);
      entity.update(false);
      entity.update(false);
      
      // Assert
      expect(entity.state.incorrect_count).toBe(2);
    });

    it('正确次数 + 错误次数应该等于学习次数', () => {
      // Act
      entity.update(true);
      entity.update(false);
      entity.update(true);
      entity.update(false);
      entity.update(true);
      
      // Assert
      expect(entity.state.correct_count + entity.state.incorrect_count)
        .toBe(entity.state.learning_count);
    });
  });

  describe('BKT 参数影响测试', () => {
    it('高 p_learn 应该提高掌握概率增长', () => {
      // Arrange
      const entityHighLearn = new KnowledgeTrackingEntity(
        'kt_002', 'user_001', 'excel_basic', 'formula_sum',
        0.5, // 高 p_learn
        0.1, 0.3
      );
      
      // Act
      entity.update(true);
      entityHighLearn.update(true);
      
      // Assert
      expect(entityHighLearn.getMasteryProbability())
        .toBeGreaterThan(entity.getMasteryProbability());
    });

    it('高 p_slip 应该降低答对时的掌握概率', () => {
      // Arrange
      const entityHighSlip = new KnowledgeTrackingEntity(
        'kt_003', 'user_001', 'excel_basic', 'formula_sum',
        0.1, 0.5, // 高 p_slip
        0.3
      );
      
      // Act
      entity.update(true);
      entityHighSlip.update(true);
      
      // Assert
      expect(entityHighSlip.getMasteryProbability())
        .toBeLessThan(entity.getMasteryProbability());
    });

    it('高 p_guess 应该降低答对时的掌握概率增长', () => {
      // Arrange
      const entityHighGuess = new KnowledgeTrackingEntity(
        'kt_004', 'user_001', 'excel_basic', 'formula_sum',
        0.1, 0.1, 0.8 // 高 p_guess
      );
      
      // Act
      entity.update(true);
      entityHighGuess.update(true);
      
      // Assert
      expect(entityHighGuess.getMasteryProbability())
        .toBeLessThan(entity.getMasteryProbability());
    });
  });

  describe('重置测试', () => {
    it('重置后应该恢复初始状态', () => {
      // Arrange
      entity.update(true);
      entity.update(true);
      entity.update(false);
      
      // Act
      entity.reset();
      
      // Assert
      expect(entity.getMasteryProbability()).toBe(0.01);
      expect(entity.state.learning_count).toBe(0);
      expect(entity.state.correct_count).toBe(0);
      expect(entity.state.incorrect_count).toBe(0);
    });
  });

  describe('边界条件测试', () => {
    it('处理大量学习记录', () => {
      // Act
      for (let i = 0; i < 1000; i++) {
        entity.update(i % 2 === 0 ? true : false);
      }
      
      // Assert
      expect(entity.state.learning_count).toBe(1000);
      expect(entity.getMasteryProbability()).toBeGreaterThanOrEqual(0);
      expect(entity.getMasteryProbability()).toBeLessThanOrEqual(1);
    });

    it('处理多个知识点', () => {
      // Arrange
      const entities = [
        new KnowledgeTrackingEntity('kt_001', 'user_001', 'excel_basic', 'formula_sum'),
        new KnowledgeTrackingEntity('kt_002', 'user_001', 'excel_basic', 'formula_avg'),
        new KnowledgeTrackingEntity('kt_003', 'user_001', 'excel_basic', 'formula_count'),
      ];
      
      // Act
      entities.forEach(e => {
        for (let i = 0; i < 10; i++) {
          e.update(true);
        }
      });
      
      // Assert
      entities.forEach(e => {
        expect(e.isMastered()).toBeTruthy();
      });
    });
  });
});

/**
 * ============================================================================
 * 学习路径推荐完整单元测试
 * 测试覆盖率目标：100%
 * ============================================================================
 */

import { describe, it, expect, beforeEach } from '@kit.TestKit';
import { RecommendLearningPathUseCase, RecommendLearningPathRequest } from '../entry/src/main/ets/domain/usecases/RecommendLearningPathUseCase';
import { SkillEntity, SkillCategory, SkillDifficulty, SkillStep } from '../entry/src/main/ets/domain/entities/SkillEntity';

describe('LearningPathRecommender - 完整测试', () => {
  const useCase = RecommendLearningPathUseCase.getInstance();

  describe('基础功能测试', () => {
    it('应该生成完整的学习路径', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.success).toBeTruthy();
      expect(result.steps).toBeDefined();
      expect(result.steps!.length).toBeGreaterThan(0);
      expect(result.totalEstimatedTime).toBeGreaterThan(0);
      expect(result.estimatedDays).toBeGreaterThan(0);
    });

    it('应该包含热身步骤', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.steps![0].type).toBe('assess');
      expect(result.steps![0].title).toContain('学习目标');
    });

    it('应该包含学习步骤', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      const learnSteps = result.steps!.filter(s => s.type === 'learn');
      expect(learnSteps.length).toBeGreaterThan(0);
    });

    it('应该包含实践项目', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      const projectSteps = result.steps!.filter(s => s.type === 'project');
      expect(projectSteps.length).toBeGreaterThan(0);
    });

    it('应该包含复习步骤', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      const reviewSteps = result.steps!.filter(s => s.type === 'review');
      expect(reviewSteps.length).toBeGreaterThan(0);
    });
  });

  describe('前置技能测试', () => {
    it('应该跳过已掌握的前置技能', async () => {
      // Arrange
      const skill = createTestSkill('excel_pivot', '数据透视表', 2, ['excel_basic']);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: ['excel_basic'],
        assessmentScores: { 'excel_basic': 90 },
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.success).toBeTruthy();
      expect(result.skippedSkills).toContain('excel_basic');
    });

    it('应该学习未掌握的前置技能', async () => {
      // Arrange
      const skill = createTestSkill('excel_pivot', '数据透视表', 2, ['excel_basic']);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: { 'excel_basic': 30 },
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.success).toBeTruthy();
      expect(result.focusAreas).toContain('excel_basic');
    });

    it('应该复习部分掌握的前置技能', async () => {
      // Arrange
      const skill = createTestSkill('excel_pivot', '数据透视表', 2, ['excel_basic']);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: { 'excel_basic': 60 },
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.success).toBeTruthy();
      expect(result.focusAreas).toContain('excel_basic');
    });

    it('应该正确处理多个前置技能', async () => {
      // Arrange
      const skill = createTestSkill('excel_chart', 'Excel 图表', 2, ['excel_basic', 'excel_formula']);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: ['excel_basic'],
        assessmentScores: { 'excel_basic': 90, 'excel_formula': 40 },
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.success).toBeTruthy();
      expect(result.skippedSkills).toContain('excel_basic');
      expect(result.focusAreas).toContain('excel_formula');
    });
  });

  describe('时间估算测试', () => {
    it('应该正确计算总预计时长', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.totalEstimatedTime).toBeGreaterThan(0);
    });

    it('应该正确计算预计天数', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      // 假设每天学习 30 分钟
      const expectedDays = Math.ceil(result.totalEstimatedTime! / 30);
      expect(result.estimatedDays).toBeCloseTo(expectedDays, 0);
    });

    it('技能越多预计时间越长', async () => {
      // Arrange
      const skill3 = createTestSkill('excel_basic', 'Excel 基础', 3);
      const skill5 = createTestSkill('excel_basic', 'Excel 基础', 5);
      
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill3,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result3 = await useCase.execute(request);
      request.targetSkill = skill5;
      const result5 = await useCase.execute(request);
      
      // Assert
      expect(result5.totalEstimatedTime).toBeGreaterThan(result3.totalEstimatedTime);
    });
  });

  describe('进度计算测试', () => {
    it('步骤顺序应该正确', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      for (let i = 1; i < result.steps!.length; i++) {
        expect(result.steps![i].order).toBeGreaterThan(result.steps![i-1].order);
      }
    });

    it('前置步骤应该正确', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.steps![0].prerequisites).toEqual([]);
      for (let i = 1; i < result.steps!.length; i++) {
        expect(result.steps![i].prerequisites).toContain(result.steps![i-1].order);
      }
    });
  });

  describe('边界条件测试', () => {
    it('处理没有步骤的技能', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 0);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.success).toBeTruthy();
      expect(result.steps).toBeDefined();
    });

    it('处理空用户 ID', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      const request: RecommendLearningPathRequest = {
        userId: '',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.success).toBeTruthy();
    });

    it('处理空评估分数', async () => {
      // Arrange
      const skill = createTestSkill('excel_basic', 'Excel 基础', 3);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: [],
        assessmentScores: {},
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.success).toBeTruthy();
    });

    it('处理大量前置技能', async () => {
      // Arrange
      const skill = createTestSkill('excel_advanced', 'Excel 高级', 5, [
        'excel_basic', 'excel_formula', 'excel_pivot', 'excel_chart', 'excel_macro'
      ]);
      const request: RecommendLearningPathRequest = {
        userId: 'user_001',
        targetSkill: skill,
        masteredSkills: ['excel_basic', 'excel_formula'],
        assessmentScores: {
          'excel_basic': 90,
          'excel_formula': 90,
          'excel_pivot': 30,
          'excel_chart': 50,
          'excel_macro': 10,
        },
      };
      
      // Act
      const result = await useCase.execute(request);
      
      // Assert
      expect(result.success).toBeTruthy();
      expect(result.skippedSkills.length).toBe(2);
      expect(result.focusAreas.length).toBe(3);
    });
  });
});

/**
 * 创建测试技能
 */
function createTestSkill(
  id: string,
  name: string,
  stepCount: number,
  prerequisites: string[] = []
): SkillEntity {
  const steps: SkillStep[] = [];
  for (let i = 1; i <= stepCount; i++) {
    steps.push({
      stepNumber: i,
      title: `步骤${i}`,
      content: `步骤${i}的内容`,
      keyPoint: `步骤${i}的关键点`,
      estimatedTime: 10,
    });
  }
  
  return new SkillEntity(
    id,
    name,
    SkillCategory.OFFICE,
    stepCount <= 2 ? SkillDifficulty.BEGINNER : SkillDifficulty.INTERMEDIATE,
    steps,
    prerequisites,
    ['实际应用场景'],
    ['标签'],
    stepCount * 10
  );
}

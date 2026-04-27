/**
 * ============================================================================
 * 学习流程 E2E 测试
 * 测试完整学习流程
 * ============================================================================
 */

import { describe, it, expect, beforeAll, afterAll } from '@kit.TestKit';
import { LearningEngine_v2 } from '../../entry/src/main/ets/services/engine/LearningEngine_v2';
import { SceneClassificationService } from '../../entry/src/main/ets/service/SceneClassificationService';
import { LLMService } from '../../entry/src/main/ets/service/LLMService';
import { GrowthService } from '../../entry/src/main/ets/service/GrowthService';

describe('LearningFlow E2E - 完整学习流程测试', () => {
  let engine: LearningEngine_v2;
  let sceneService: SceneClassificationService;
  let llmService: LLMService;
  let growthService: GrowthService;

  beforeAll(() => {
    engine = LearningEngine_v2.getInstance();
    sceneService = SceneClassificationService.getInstance();
    llmService = LLMService.getInstance();
    growthService = GrowthService.getInstance();
  });

  afterAll(() => {
    // 清理
  });

  describe('完整学习流程', () => {
    it('应该完成从场景分类到学习完成的完整流程', async () => {
      // Step 1: 用户输入学习需求
      const userInput = '教我用 Excel 做数据分析';
      
      // Step 2: 场景分类
      const sceneResult = await sceneService.classifyScene(userInput);
      expect(sceneResult.sceneType).toBeDefined();
      
      // Step 3: 生成教学内容
      const teachingContent = await llmService.generateTeachingContent(userInput);
      expect(teachingContent).toBeDefined();
      
      // Step 4: 开始学习
      const learningResult = await engine.handleLearningRequest({
        userId: 'test_user',
        text: userInput,
      });
      expect(learningResult.stage).toBe('analyzing');
      
      // Step 5: 完成学习步骤
      // TODO: 模拟完成所有步骤
      
      // Step 6: 检查成就解锁
      const achievements = await growthService.checkAchievements('test_user');
      expect(achievements).toBeDefined();
    });
  });

  describe('场景分类流程', () => {
    it('应该正确分类办公场景', async () => {
      // Arrange
      const userInput = '教我用 Excel 做报表';
      
      // Act
      const result = await sceneService.classifyScene(userInput);
      
      // Assert
      expect(result.sceneType).toBe('office_report');
      expect(result.confidence).toBeGreaterThan(0.7);
    });

    it('应该正确分类生活场景', async () => {
      // Arrange
      const userInput = '教我用微信支付';
      
      // Act
      const result = await sceneService.classifyScene(userInput);
      
      // Assert
      expect(result.sceneType).toBe('life_finance');
    });

    it('应该正确分类数字技能场景', async () => {
      // Arrange
      const userInput = '教我用鸿蒙设备协同';
      
      // Act
      const result = await sceneService.classifyScene(userInput);
      
      // Assert
      expect(result.sceneType).toBe('digital');
    });
  });

  describe('教学内容生成', () => {
    it('应该生成有效的教学内容', async () => {
      // Arrange
      const userInput = '教我用 Excel';
      
      // Act
      const content = await llmService.generateTeachingContent(userInput);
      
      // Assert
      expect(content).toBeDefined();
      expect(content.length).toBeGreaterThan(0);
    });

    it('应该处理未知技能', async () => {
      // Arrange
      const userInput = '教我一些奇怪的技能';
      
      // Act
      const content = await llmService.generateTeachingContent(userInput);
      
      // Assert
      expect(content).toBeDefined();
      // 应该返回降级内容
    });
  });

  describe('成就系统流程', () => {
    it('应该解锁第一步成就', async () => {
      // Arrange
      // TODO: 模拟用户完成第一次学习
      
      // Act
      const results = await growthService.checkAchievements('test_user');
      
      // Assert
      expect(results.some(r => r.achievement?.id === 'first_step')).toBeTruthy();
    });

    it('应该解锁连续学习成就', async () => {
      // Arrange
      // TODO: 模拟用户连续学习 3 天
      
      // Act
      const results = await growthService.checkAchievements('test_user');
      
      // Assert
      expect(results.some(r => r.achievement?.id === 'streak_3')).toBeTruthy();
    });

    it('应该生成分享文案', () => {
      // Arrange
      const extraData = {
        achievementName: '坚持不懈',
        skillName: 'Excel 基础',
        streak: 7,
      };
      
      // Act
      const achievementText = growthService.generateShareContent('user_001', 'achievement', extraData);
      const completionText = growthService.generateShareContent('user_001', 'completion', extraData);
      const streakText = growthService.generateShareContent('user_001', 'streak', extraData);
      
      // Assert
      expect(achievementText).toContain('坚持不懈');
      expect(completionText).toContain('Excel 基础');
      expect(streakText).toContain('7');
    });
  });
});

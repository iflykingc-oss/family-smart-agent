/**
 * ============================================================================
 * 学习路径推荐用例 - RecommendLearningPathUseCase
 * 单一职责：根据用户能力评估结果推荐个性化学习路径
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { SkillEntity } from '../entities/SkillEntity';

/**
 * 学习路径推荐请求
 */
export interface RecommendLearningPathRequest {
  /** 用户 ID */
  userId: string;
  
  /** 目标技能 */
  targetSkill: SkillEntity;
  
  /** 用户已掌握技能 ID 列表 */
  masteredSkills: string[];
  
  /** 用户能力评估结果 */
  assessmentScores: Record<string, number>; // skillId -> score (0-100)
}

/**
 * 学习路径步骤
 */
export interface LearningPathStep {
  order: number;
  type: 'assess' | 'learn' | 'practice' | 'review' | 'project';
  skillId: string;
  title: string;
  description: string;
  estimatedTime: number;
  prerequisites: number[]; // 前置步骤 order
}

/**
 * 学习路径推荐结果
 */
export interface RecommendLearningPathResult {
  /** 是否成功 */
  success: boolean;
  
  /** 学习路径步骤 */
  steps?: LearningPathStep[];
  
  /** 总预计时长（分钟） */
  totalEstimatedTime?: number;
  
  /** 预计天数 */
  estimatedDays?: number;
  
  /** 跳过的技能 */
  skippedSkills?: string[];
  
  /** 重点攻克技能 */
  focusAreas?: string[];
  
  /** 错误信息 */
  error?: string;
}

/**
 * 学习路径推荐用例
 */
export class RecommendLearningPathUseCase {
  private static instance: RecommendLearningPathUseCase | null = null;

  static getInstance(): RecommendLearningPathUseCase {
    if (!RecommendLearningPathUseCase.instance) {
      RecommendLearningPathUseCase.instance = new RecommendLearningPathUseCase();
    }
    return RecommendLearningPathUseCase.instance;
  }

  private constructor() {
    HiLog.info("RecommendLearningPathUseCase", "用例初始化");
  }

  /**
   * 执行用例
   */
  async execute(request: RecommendLearningPathRequest): Promise<RecommendLearningPathResult> {
    HiLog.info("RecommendLearningPathUseCase", `执行：${request.userId}/${request.targetSkill.name}`);
    
    try {
      const steps: LearningPathStep[] = [];
      const skippedSkills: string[] = [];
      const focusAreas: string[] = [];
      
      let stepOrder = 1;
      let totalTime = 0;
      
      // 1. 热身步骤
      steps.push({
        order: stepOrder++,
        type: 'assess',
        skillId: request.targetSkill.id,
        title: '学习目标确认',
        description: `明确学习目标：${request.targetSkill.name}`,
        estimatedTime: 5,
        prerequisites: [],
      });
      totalTime += 5;
      
      // 2. 检查前置技能
      for (const prereqId of request.targetSkill.prerequisites) {
        const score = request.assessmentScores[prereqId] || 0;
        
        if (score >= 80) {
          // 已掌握，跳过
          skippedSkills.push(prereqId);
        } else if (score >= 50) {
          // 部分掌握，复习
          focusAreas.push(prereqId);
          steps.push({
            order: stepOrder++,
            type: 'review',
            skillId: prereqId,
            title: `复习：${prereqId}`,
            description: '巩固薄弱环节',
            estimatedTime: 15,
            prerequisites: [stepOrder - 1],
          });
          totalTime += 15;
        } else {
          // 未掌握，学习
          focusAreas.push(prereqId);
          steps.push({
            order: stepOrder++,
            type: 'learn',
            skillId: prereqId,
            title: `学习：${prereqId}`,
            description: '系统学习前置技能',
            estimatedTime: 30,
            prerequisites: [stepOrder - 1],
          });
          totalTime += 30;
        }
      }
      
      // 3. 目标技能学习步骤
      for (const step of request.targetSkill.steps) {
        steps.push({
          order: stepOrder++,
          type: 'learn',
          skillId: request.targetSkill.id,
          title: step.title,
          description: step.content,
          estimatedTime: step.estimatedTime,
          prerequisites: [stepOrder - 1],
        });
        totalTime += step.estimatedTime;
      }
      
      // 4. 实践项目
      steps.push({
        order: stepOrder++,
        type: 'project',
        skillId: request.targetSkill.id,
        title: '综合实践项目',
        description: `运用所学技能完成：${request.targetSkill.realWorldScenes[0]}`,
        estimatedTime: 60,
        prerequisites: [stepOrder - 1],
      });
      totalTime += 60;
      
      // 5. 复习步骤
      steps.push({
        order: stepOrder++,
        type: 'review',
        skillId: request.targetSkill.id,
        title: '总结与复习',
        description: '回顾学习内容，巩固记忆',
        estimatedTime: 15,
        prerequisites: [stepOrder - 1],
      });
      totalTime += 15;
      
      // 计算预计天数（假设每天学习 30 分钟）
      const estimatedDays = Math.ceil(totalTime / 30);
      
      HiLog.info("RecommendLearningPathUseCase", 
        `路径生成成功：${steps.length}步，${totalTime}分钟，${estimatedDays}天`
      );
      
      return {
        success: true,
        steps,
        totalEstimatedTime: totalTime,
        estimatedDays,
        skippedSkills,
        focusAreas,
      };
    } catch (error: any) {
      HiLog.error("RecommendLearningPathUseCase", `路径推荐失败：${error.message}`);
      return {
        success: false,
        error: error.message,
      };
    }
  }
}

/**
 * ============================================================================
 * 学习路径规划服务 - LearningPathPlanner
 * 核心：根据评估结果，生成个性化学习路径（只学不会的）
 * 
 * 输入：场景分析 + 能力评估
 * 输出：
 *   - 个性化学习路径
 *   - 跳过已掌握的
 *   - 重点攻克薄弱点
 *   - 预计完成时间
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { ScenarioAnalysis } from './ScenarioAnalyzer';
import { AssessmentResult, SkillAssessment, LearningRecommendation } from './AbilityAssessor';

/**
 * 学习路径
 */
export interface LearningPath {
  userId: string;
  scenarioName: string;
  
  // 路径信息
  pathId: string;
  approach: 'tutorial' | 'scenario' | 'project' | 'assessment';
  
  // 学习步骤
  steps: LearningStep[];
  
  // 时间估算
  totalEstimatedTime: number; // 总时长（分钟）
  estimatedDays: number;      // 预计天数
  
  // 跳过项
  skippedSkills: SkippedSkill[];
  
  // 重点项
  focusAreas: FocusArea[];
  
  // 里程碑
  milestones: Milestone[];
  
  // 元数据
  createdAt: number;
  version: number;
}

/**
 * 学习步骤
 */
export interface LearningStep {
  order: number;
  type: 'warmup' | 'learn' | 'practice' | 'project' | 'review';
  
  // 内容
  title: string;
  description: string;
  skillId?: string;
  skillName?: string;
  
  // 时间
  estimatedTime: number; // 分钟
  
  // 前置条件
  prerequisites: string[]; // 需要先完成的步骤 order
  
  // 完成标准
  completionCriteria: string;
  
  // 资源
  resources?: LearningResource[];
}

/**
 * 学习资源
 */
export interface LearningResource {
  type: 'video' | 'article' | 'interactive' | 'quiz';
  title: string;
  url?: string;
  duration?: number;
}

/**
 * 跳过的技能
 */
export interface SkippedSkill {
  skillId: string;
  skillName: string;
  reason: string;
  score: number;
}

/**
 * 重点攻克区域
 */
export interface FocusArea {
  skillId: string;
  skillName: string;
  reason: string;
  priority: 'high' | 'medium' | 'low';
  estimatedTime: number;
  weakPoints: string[];
}

/**
 * 里程碑
 */
export interface Milestone {
  order: number;
  title: string;
  description: string;
  afterStep: number;
  reward?: string;
}

/**
 * 学习路径规划服务
 */
export class LearningPathPlanner {
  private static instance: LearningPathPlanner | null = null;

  static getInstance(): LearningPathPlanner {
    if (!LearningPathPlanner.instance) {
      LearningPathPlanner.instance = new LearningPathPlanner();
    }
    return LearningPathPlanner.instance;
  }

  private constructor() {
    HiLog.info("LearningPathPlanner", "学习路径规划服务初始化");
  }

  /**
   * 生成个性化学习路径
   * 核心方法
   */
  generatePath(
    userId: string,
    scenario: ScenarioAnalysis,
    assessment: AssessmentResult
  ): LearningPath {
    HiLog.info("LearningPathPlanner", `生成路径：${userId}/${scenario.scenarioName}`);
    
    const steps: LearningStep[] = [];
    const skippedSkills: SkippedSkill[] = [];
    const focusAreas: FocusArea[] = [];
    
    let stepOrder = 1;
    let totalTime = 0;
    
    // 1. 热身步骤（所有路径都有）
    steps.push(this.createWarmupStep(scenario, stepOrder++));
    totalTime += 5;
    
    // 2. 根据评估结果处理每个技能
    for (const skillAssessment of assessment.skillAssessments) {
      const recommendation = assessment.recommendations.find(
        r => r.skillId === skillAssessment.skillId
      );
      
      if (!recommendation) continue;
      
      // 跳过的技能
      if (recommendation.type === 'skip') {
        skippedSkills.push({
          skillId: skillAssessment.skillId,
          skillName: skillAssessment.skillName,
          reason: recommendation.reason,
          score: skillAssessment.score
        });
        continue;
      }
      
      // 重点攻克区域
      if (recommendation.type === 'learn' || recommendation.type === 'review') {
        focusAreas.push({
          skillId: skillAssessment.skillId,
          skillName: skillAssessment.skillName,
          reason: recommendation.reason,
          priority: skillAssessment.learnPriority,
          estimatedTime: recommendation.estimatedTime,
          weakPoints: this.identifyWeakPoints(skillAssessment)
        });
        
        // 生成学习步骤
        const skillSteps = this.createSkillSteps(
          skillAssessment,
          recommendation,
          stepOrder,
          steps.map(s => s.order) // 前置步骤
        );
        
        steps.push(...skillSteps);
        totalTime += recommendation.estimatedTime;
        stepOrder += skillSteps.length;
      }
    }
    
    // 3. 综合实践项目（所有路径都有）
    steps.push(this.createProjectStep(scenario, stepOrder++, steps.map(s => s.order)));
    totalTime += 60;
    
    // 4. 复习步骤
    steps.push(this.createReviewStep(stepOrder++, [steps.length - 1]));
    totalTime += 15;
    
    // 5. 生成里程碑
    const milestones = this.generateMilestones(steps, focusAreas);
    
    // 6. 计算预计天数
    const estimatedDays = this.calculateEstimatedDays(totalTime);
    
    const path: LearningPath = {
      userId,
      scenarioName: scenario.scenarioName,
      pathId: `path_${Date.now()}`,
      approach: scenario.suggestedPath.approach,
      steps,
      totalEstimatedTime: totalTime,
      estimatedDays,
      skippedSkills,
      focusAreas,
      milestones,
      createdAt: Date.now(),
      version: 1
    };
    
    HiLog.info("LearningPathPlanner", 
      `路径生成完成：${steps.length}步，${totalTime}分钟，${estimatedDays}天，跳过${skippedSkills.length}项`
    );
    
    return path;
  }

  /**
   * 创建热身步骤
   */
  private createWarmupStep(
    scenario: ScenarioAnalysis,
    order: number
  ): LearningStep {
    return {
      order,
      type: 'warmup',
      title: '学习目标确认',
      description: `明确本次学习目标：${scenario.realGoal}`,
      estimatedTime: 5,
      prerequisites: [],
      completionCriteria: '理解学习目标和预期成果',
      resources: []
    };
  }

  /**
   * 创建技能学习步骤
   */
  private createSkillSteps(
    skill: SkillAssessment,
    recommendation: LearningRecommendation,
    startOrder: number,
    previousSteps: number[]
  ): LearningStep[] {
    const steps: LearningStep[] = [];
    
    if (recommendation.type === 'learn') {
      // 系统学习：讲解→练习
      steps.push({
        order: startOrder,
        type: 'learn',
        title: `${skill.skillName}基础讲解`,
        description: `学习${skill.skillName}的核心概念和操作`,
        skillId: skill.skillId,
        skillName: skill.skillName,
        estimatedTime: Math.round(recommendation.estimatedTime * 0.6),
        prerequisites: previousSteps,
        completionCriteria: '理解核心概念，完成基础练习'
      });
      
      steps.push({
        order: startOrder + 1,
        type: 'practice',
        title: `${skill.skillName}实践练习`,
        description: `动手练习${skill.skillName}`,
        skillId: skill.skillId,
        skillName: skill.skillName,
        estimatedTime: Math.round(recommendation.estimatedTime * 0.4),
        prerequisites: [startOrder],
        completionCriteria: '独立完成练习题'
      });
    } else if (recommendation.type === 'review') {
      // 复习：只练习薄弱环节
      steps.push({
        order: startOrder,
        type: 'review',
        title: `${skill.skillName}薄弱点巩固`,
        description: `针对性复习薄弱环节`,
        skillId: skill.skillId,
        skillName: skill.skillName,
        estimatedTime: recommendation.estimatedTime,
        prerequisites: previousSteps,
        completionCriteria: '薄弱点掌握度提升至 80%'
      });
    }
    
    return steps;
  }

  /**
   * 创建实践项目步骤
   */
  private createProjectStep(
    scenario: ScenarioAnalysis,
    order: number,
    prerequisites: number[]
  ): LearningStep {
    return {
      order,
      type: 'project',
      title: '综合实践项目',
      description: `运用所学技能完成：${scenario.realGoal}`,
      estimatedTime: 60,
      prerequisites,
      completionCriteria: '完成实际项目，产出可用成果',
      resources: [
        {
          type: 'interactive',
          title: '项目指导',
          duration: 30
        }
      ]
    };
  }

  /**
   * 创建复习步骤
   */
  private createReviewStep(
    order: number,
    prerequisites: number[]
  ): LearningStep {
    return {
      order,
      type: 'review',
      title: '总结与复习',
      description: '回顾学习内容，巩固记忆',
      estimatedTime: 15,
      prerequisites,
      completionCriteria: '完成复习测试'
    };
  }

  /**
   * 识别薄弱点
   */
  private identifyWeakPoints(skill: SkillAssessment): string[] {
    const weakPoints: string[] = [];
    
    if (skill.knowledgeScore < 60) {
      weakPoints.push('理论知识薄弱');
    }
    if (skill.practiceScore < 60) {
      weakPoints.push('实践能力不足');
    }
    if (skill.score < 50) {
      weakPoints.push('整体掌握度低');
    }
    
    return weakPoints;
  }

  /**
   * 生成里程碑
   */
  private generateMilestones(
    steps: LearningStep[],
    focusAreas: FocusArea[]
  ): Milestone[] {
    const milestones: Milestone[] = [];
    
    // 第一个里程碑：完成热身
    milestones.push({
      order: 1,
      title: '起步',
      description: '完成学习目标确认',
      afterStep: 1
    });
    
    // 中间里程碑：完成每个重点技能
    let milestoneOrder = 2;
    for (const focus of focusAreas) {
      const focusSteps = steps.filter(s => s.skillId === focus.skillId);
      if (focusSteps.length > 0) {
        const lastStep = focusSteps[focusSteps.length - 1];
        milestones.push({
          order: milestoneOrder++,
          title: `掌握${focus.skillName}`,
          description: focus.reason,
          afterStep: lastStep.order,
          reward: `🎉 解锁${focus.skillName}技能`
        });
      }
    }
    
    // 最终里程碑：完成项目
    const projectStep = steps.find(s => s.type === 'project');
    if (projectStep) {
      milestones.push({
        order: milestoneOrder,
        title: '学成出师',
        description: '完成综合实践项目',
        afterStep: projectStep.order,
        reward: '🏆 获得学习证书'
      });
    }
    
    return milestones;
  }

  /**
   * 计算预计天数
   */
  private calculateEstimatedDays(totalMinutes: number): number {
    // 假设每天学习 30 分钟
    const minutesPerDay = 30;
    return Math.ceil(totalMinutes / minutesPerDay);
  }

  /**
   * 优化路径（根据用户反馈）
   */
  optimizePath(
    path: LearningPath,
    feedback: {
      stepOrder: number;
      difficulty: 'too_easy' | 'just_right' | 'too_hard';
      timeSpent: number;
    }
  ): LearningPath {
    HiLog.info("LearningPathPlanner", `优化路径：步骤${feedback.stepOrder}, 难度${feedback.difficulty}`);
    
    const step = path.steps.find(s => s.order === feedback.stepOrder);
    if (!step) return path;
    
    // 根据反馈调整后续步骤
    if (feedback.difficulty === 'too_easy') {
      // 太难了，降低难度
      step.estimatedTime = Math.round(step.estimatedTime * 1.5);
    } else if (feedback.difficulty === 'too_hard') {
      // 太简单了，加快进度
      step.estimatedTime = Math.round(step.estimatedTime * 0.7);
    }
    
    path.version++;
    
    return path;
  }
}

/**
 * ============================================================================
 * 学习引擎 v2 - LearningEngine_v2
 * 重构版：整合场景分析 + 能力评估 + 个性化路径 + 项目实践
 * 
 * 新流程：
 * 1. 场景分析 - 理解用户真实需求
 * 2. 能力评估 - 评估现有能力
 * 3. 路径规划 - 生成个性化路径（只学不会的）
 * 4. 项目实践 - 边做边学，产出成果
 * 5. 复习巩固 - FSRS 遗忘曲线
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { ScenarioAnalyzer, ScenarioAnalysis } from '../core/ScenarioAnalyzer';
import { AbilityAssessor, AssessmentResult } from '../core/AbilityAssessor';
import { LearningPathPlanner, LearningPath } from '../core/LearningPathPlanner';
import { ProjectBasedLearning, ProjectTemplate, UserProjectProgress } from '../project/ProjectBasedLearning';
import { HarmonyReminderService } from './HarmonyReminderService';

/**
 * 学习会话状态
 */
export interface LearningSession {
  sessionId: string;
  userId: string;
  
  // 当前状态
  stage: 'analyzing' | 'assessing' | 'planning' | 'learning' | 'project' | 'completed';
  
  // 各阶段结果
  scenario?: ScenarioAnalysis;
  assessment?: AssessmentResult;
  learningPath?: LearningPath;
  project?: UserProjectProgress;
  
  // 进度
  currentStepOrder?: number;
  overallProgress: number; // 0-100
  
  // 时间
  createdAt: number;
  lastUpdateTime: number;
  timeSpent: number;
  
  // 状态
  isPaused: boolean;
  completedAt?: number;
}

/**
 * 用户输入
 */
export interface UserInput {
  text: string;
  userId: string;
  context?: {
    previousSkill?: string;
    deviceType?: string;
    timeOfDay?: number;
  };
}

/**
 * 学习引擎 v2
 */
export class LearningEngine_v2 {
  private static instance: LearningEngine_v2 | null = null;
  
  // 核心服务
  private scenarioAnalyzer: ScenarioAnalyzer;
  private abilityAssessor: AbilityAssessor;
  private pathPlanner: LearningPathPlanner;
  private projectLearning: ProjectBasedLearning;
  private reminderService: HarmonyReminderService;
  
  // 学习会话
  private sessions: Map<string, LearningSession> = new Map();
  
  // 配置
  private config = {
    enableAssessment: true,      // 是否启用能力评估
    enableProject: true,         // 是否启用项目实践
    autoSaveProgress: true,      // 自动保存进度
    reminderEnabled: true        // 启用复习提醒
  };

  static getInstance(): LearningEngine_v2 {
    if (!LearningEngine_v2.instance) {
      LearningEngine_v2.instance = new LearningEngine_v2();
    }
    return LearningEngine_v2.instance;
  }

  private constructor() {
    this.scenarioAnalyzer = ScenarioAnalyzer.getInstance();
    this.abilityAssessor = AbilityAssessor.getInstance();
    this.pathPlanner = LearningPathPlanner.getInstance();
    this.projectLearning = ProjectBasedLearning.getInstance();
    this.reminderService = HarmonyReminderService.getInstance();
    
    HiLog.info("LearningEngine_v2", "学习引擎 v2 初始化（深度重构版）");
  }

  /**
   * 处理用户学习请求
   * 核心入口方法
   */
  async handleLearningRequest(input: UserInput): Promise<{
    stage: string;
    message: string;
    nextAction?: string;
    data?: any;
  }> {
    HiLog.info("LearningEngine_v2", `处理请求：${input.userId}/${input.text}`);
    
    // 1. 场景分析
    const scenario = await this.scenarioAnalyzer.analyze(input.text);
    
    const message = `📊 分析完成！

**学习场景**：${scenario.scenarioName}
**真实目标**：${scenario.realGoal}
**预计时长**：${scenario.estimatedTime}分钟
**难度**：${'⭐'.repeat(scenario.difficulty)}

接下来为你进行能力评估，只学你不会的！`;
    
    return {
      stage: 'analyzing',
      message,
      nextAction: 'assessment',
      data: { scenario }
    };
  }

  /**
   * 执行能力评估
   */
  async runAssessment(userId: string, scenario: ScenarioAnalysis): Promise<{
    message: string;
    assessment: AssessmentResult;
  }> {
    HiLog.info("LearningEngine_v2", `执行评估：${userId}`);
    
    const assessment = await this.abilityAssessor.assess(userId, scenario);
    
    const skippedCount = assessment.recommendations.filter(r => r.type === 'skip').length;
    const learnCount = assessment.recommendations.filter(r => r.type === 'learn').length;
    
    const message = `✅ 评估完成！

**准备度**：${assessment.readinessScore}%
**整体水平**：${this.getLevelName(assessment.overallLevel)}

**学习建议**：
- 跳过已掌握：${skippedCount}项
- 需要学习：${learnCount}项

为你生成个性化学习路径...`;
    
    return {
      message,
      assessment
    };
  }

  /**
   * 生成学习路径
   */
  generateLearningPath(
    userId: string,
    scenario: ScenarioAnalysis,
    assessment: AssessmentResult
  ): LearningPath {
    HiLog.info("LearningEngine_v2", `生成路径：${userId}`);
    
    const path = this.pathPlanner.generatePath(userId, scenario, assessment);
    
    const message = `🗺️ 学习路径已生成！

**学习方式**：${this.getApproachName(path.approach)}
**总步骤**：${path.steps.length}步
**预计时长**：${path.totalEstimatedTime}分钟（${path.estimatedDays}天）
**跳过技能**：${path.skippedSkills.length}项
**重点攻克**：${path.focusAreas.length}项

${path.focusAreas.length > 0 ? `\n**重点攻克**：${path.focusAreas.map(f => f.skillName).join('、')}` : ''}

准备好开始学习了吗？`;
    
    return path;
  }

  /**
   * 开始学习
   */
  async startLearning(
    userId: string,
    path: LearningPath
  ): Promise<{
    message: string;
    currentStep: any;
  }> {
    // 创建学习会话
    const session: LearningSession = {
      sessionId: `session_${Date.now()}`,
      userId,
      stage: 'learning',
      learningPath: path,
      overallProgress: 0,
      createdAt: Date.now(),
      lastUpdateTime: Date.now(),
      timeSpent: 0,
      isPaused: false
    };
    
    this.sessions.set(session.sessionId, session);
    
    const firstStep = path.steps[0];
    
    const message = `📚 开始学习！

**第一步**：${firstStep.title}
${firstStep.description}

**预计用时**：${firstStep.estimatedTime}分钟

完成后告诉我，我们继续下一步！`;
    
    return {
      message,
      currentStep: firstStep
    };
  }

  /**
   * 完成学习步骤
   */
  async completeStep(
    sessionId: string,
    stepOrder: number,
    userFeedback?: {
      difficulty?: 'too_easy' | 'just_right' | 'too_hard';
      timeSpent?: number;
    }
  ): Promise<{
    message: string;
    nextStep?: any;
    isCompleted?: boolean;
  }> {
    const session = this.sessions.get(sessionId);
    if (!session || !session.learningPath) {
      return { message: '会话不存在' };
    }
    
    // 优化路径（根据反馈）
    if (userFeedback && session.learningPath) {
      this.pathPlanner.optimizePath(session.learningPath, {
        stepOrder,
        difficulty: userFeedback.difficulty || 'just_right',
        timeSpent: userFeedback.timeSpent || 0
      });
    }
    
    // 查找下一步
    const currentStepIdx = session.learningPath.steps.findIndex(s => s.order === stepOrder);
    const nextStep = session.learningPath.steps[currentStepIdx + 1];
    
    // 更新进度
    session.currentStepOrder = nextStep ? nextStep.order : stepOrder;
    session.overallProgress = Math.round(
      ((currentStepIdx + 1) / session.learningPath.steps.length) * 100
    );
    session.lastUpdateTime = Date.now();
    
    if (!nextStep) {
      // 学习完成，进入项目实践
      session.stage = 'project';
      return {
        message: `🎉 恭喜完成所有学习步骤！

**总进度**：100%
**用时**：${session.timeSpent}分钟

接下来进入实践环节，做一个实际项目巩固所学！`,
        isCompleted: true
      };
    }
    
    const message = `✅ 步骤完成！

**当前进度**：${session.overallProgress}%

**下一步**：${nextStep.title}
${nextStep.description}

准备好了吗？`;
    
    return {
      message,
      nextStep
    };
  }

  /**
   * 开始项目实践
   */
  async startProject(
    sessionId: string,
    scenarioType: string
  ): Promise<{
    message: string;
    project?: UserProjectProgress;
  }> {
    const session = this.sessions.get(sessionId);
    if (!session) {
      return { message: '会话不存在' };
    }
    
    // 推荐项目
    const projects = this.projectLearning.recommendProject(scenarioType);
    
    if (projects.length === 0) {
      return {
        message: '暂无适合的项目，但你可以直接应用所学！'
      };
    }
    
    // 开始第一个推荐项目
    const project = this.projectLearning.startProject(session.userId, projects[0].id);
    session.project = project;
    session.stage = 'project';
    
    const firstStep = projects[0].steps[0];
    
    const message = `🛠️ 开始实践项目！

**项目**：${projects[0].name}
**描述**：${projects[0].description}
**预计时长**：${projects[0].estimatedTime}分钟

**第一步**：${firstStep.title}
${firstStep.description}

完成每一步后告诉我，我会帮你检查！`;
    
    return {
      message,
      project
    };
  }

  /**
   * 完成项目步骤
   */
  async completeProjectStep(
    projectId: string,
    stepOrder: number
  ): Promise<{
    message: string;
    isProjectCompleted?: boolean;
  }> {
    const completed = this.projectLearning.completeStep(projectId, stepOrder);
    
    if (!completed) {
      return { message: '项目不存在' };
    }
    
    const progress = this.projectLearning.getProjectProgress(projectId);
    if (!progress) {
      return { message: '获取进度失败' };
    }
    
    const template = this.projectLearning.getProjectTemplate(progress.templateId);
    
    if (progress.completedSteps.length >= (template?.steps.length || 0)) {
      // 项目完成
      const evaluation = this.projectLearning.evaluateProject(projectId);
      
      // 更新会话
      const session = Array.from(this.sessions.values()).find(s => s.project?.projectId === projectId);
      if (session) {
        session.stage = 'completed';
        session.completedAt = Date.now();
        session.overallProgress = 100;
      }
      
      return {
        message: `🏆 项目完成！

**得分**：${evaluation.score}分

${evaluation.feedback}

学习完成！已为你设置复习提醒。`,
        isProjectCompleted: true
      };
    }
    
    const nextStep = template?.steps.find(s => s.order === progress.currentStep);
    
    return {
      message: `✅ 步骤完成！进度${progress.overallProgress}%

**下一步**：${nextStep?.title || '继续'}
${nextStep?.description || ''}`
    };
  }

  /**
   * 获取会话状态
   */
  getSessionStatus(sessionId: string): LearningSession | null {
    return this.sessions.get(sessionId) || null;
  }

  /**
   * 获取用户所有会话
   */
  getUserSessions(userId: string): LearningSession[] {
    const sessions: LearningSession[] = [];
    for (const session of this.sessions.values()) {
      if (session.userId === userId) {
        sessions.push(session);
      }
    }
    return sessions;
  }

  /**
   * 暂停/恢复会话
   */
  toggleSessionPause(sessionId: string): boolean {
    const session = this.sessions.get(sessionId);
    if (!session) return false;
    
    session.isPaused = !session.isPaused;
    session.lastUpdateTime = Date.now();
    
    return true;
  }

  /**
   * 辅助方法
   */
  private getLevelName(level: string): string {
    const names: Record<string, string> = {
      'beginner': '初学者',
      'intermediate': '中级',
      'advanced': '高级'
    };
    return names[level] || level;
  }

  private getApproachName(approach: string): string {
    const names: Record<string, string> = {
      'tutorial': '系统化教程',
      'scenario': '场景驱动',
      'project': '项目实践',
      'assessment': '评估导向'
    };
    return names[approach] || approach;
  }
}

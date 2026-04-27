/**
 * ============================================================================
 * 能力评估服务 - AbilityAssessor
 * 
 * 【借鉴优化】
 * 参考：Self-Improving Agent - 3x 晋升规则
 * 优化：从"使用次数" → "掌握度评估"（知识/实践双维度）
 * 
 * 核心：评估用户现有能力，只学不会的
 * 
 * 输入：用户 + 场景分析结果
 * 输出：
 *   - 能力图谱（已掌握/未掌握）
 *   - 薄弱点诊断
 *   - 个性化学习建议（跳过已掌握的）
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { ScenarioAnalysis, SkillRequirement } from './ScenarioAnalyzer';

/**
 * 能力评估结果
 */
export interface AssessmentResult {
  userId: string;
  scenarioId: string;
  
  // 整体评估
  overallLevel: 'beginner' | 'intermediate' | 'advanced';
  readinessScore: number; // 准备度 0-100
  
  // 技能评估
  skillAssessments: SkillAssessment[];
  
  // 薄弱点
  weakPoints: WeakPoint[];
  
  // 学习建议
  recommendations: LearningRecommendation[];
  
  // 评估元数据
  assessmentTime: number; // 评估用时（秒）
  questionCount: number;  // 题目数量
  confidence: number;     // 评估置信度
}

/**
 * 单项技能评估
 */
export interface SkillAssessment {
  skillId: string;
  skillName: string;
  
  // 评估结果
  level: 'not_started' | 'learning' | 'mastered';
  score: number; // 0-100
  
  // 详细评估
  knowledgeScore: number; // 知识掌握 0-100
  practiceScore: number;  // 实践能力 0-100
  
  // 历史数据
  previousAttempts: number;
  lastAssessed: number;
  
  // 建议
  shouldLearn: boolean;
  learnPriority: 'high' | 'medium' | 'low';
  estimatedTime: number; // 预计学习时长（分钟）
}

/**
 * 薄弱点
 */
export interface WeakPoint {
  skillId: string;
  aspect: string; // 具体薄弱方面
  severity: 'critical' | 'moderate' | 'minor';
  description: string;
  improvement: string; // 改进建议
}

/**
 * 学习建议
 */
export interface LearningRecommendation {
  type: 'skip' | 'review' | 'learn' | 'practice';
  skillId: string;
  reason: string;
  action: string;
  estimatedTime: number;
}

/**
 * 评估题目
 */
export interface AssessmentQuestion {
  id: string;
  skillId: string;
  type: 'knowledge' | 'practice' | 'scenario';
  question: string;
  options?: string[];
  correctAnswer: string | boolean;
  explanation: string;
  difficulty: number; // 1-5
}

/**
 * 能力评估服务
 */
export class AbilityAssessor {
  private static instance: AbilityAssessor | null = null;
  
  // 评估题库（按技能分类）
  private questionBank: Record<string, AssessmentQuestion[]> = {};
  
  // 用户评估历史
  private assessmentHistory: Map<string, AssessmentResult[]> = new Map();

  static getInstance(): AbilityAssessor {
    if (!AbilityAssessor.instance) {
      AbilityAssessor.instance = new AbilityAssessor();
    }
    return AbilityAssessor.instance;
  }

  private constructor() {
    this.initQuestionBank();
    HiLog.info("AbilityAssessor", "能力评估服务初始化");
  }

  /**
   * 初始化题库
   */
  private initQuestionBank(): void {
    // Excel 基础题库
    this.questionBank['excel_basic'] = [
      {
        id: 'excel_q1',
        skillId: 'excel_basic',
        type: 'knowledge',
        question: 'Excel 中，单元格 A1 表示什么？',
        options: ['第 1 行 A 列', '第 A 列第 1 行', '第 1 列第 A 行'],
        correctAnswer: '第 A 列第 1 行',
        explanation: 'Excel 的单元格地址规则是：先列后行',
        difficulty: 1
      },
      {
        id: 'excel_q2',
        skillId: 'excel_basic',
        type: 'practice',
        question: '要在 Excel 中输入公式，必须以什么符号开头？',
        options: ['+', '-', '=', '#'],
        correctAnswer: '=',
        explanation: 'Excel 公式必须以等号开头，否则会被当作文本',
        difficulty: 1
      },
      {
        id: 'excel_q3',
        skillId: 'excel_basic',
        type: 'scenario',
        question: '你想计算 A1 到 A10 的总和，应该用什么公式？',
        options: ['=ADD(A1:A10)', '=SUM(A1:A10)', '=TOTAL(A1:A10)'],
        correctAnswer: '=SUM(A1:A10)',
        explanation: 'SUM 是求和函数，ADD 不是 Excel 函数',
        difficulty: 2
      }
    ];
    
    // 微信使用题库
    this.questionBank['wechat_basic'] = [
      {
        id: 'wechat_q1',
        skillId: 'wechat_basic',
        type: 'knowledge',
        question: '微信支付的入口在哪里？',
        options: ['通讯录', '发现', '我->支付', '朋友圈'],
        correctAnswer: '我->支付',
        explanation: '微信支付在"我"页面的"支付"入口',
        difficulty: 1
      },
      {
        id: 'wechat_q2',
        skillId: 'wechat_basic',
        type: 'scenario',
        question: '朋友给你发了一个收款码，你应该怎么付款？',
        options: ['直接转账', '扫一扫付款码', '发红包'],
        correctAnswer: '扫一扫付款码',
        explanation: '收款码需要用微信"扫一扫"功能扫描后付款',
        difficulty: 2
      }
    ];
    
    // 鸿蒙协同题库
    this.questionBank['harmony_share'] = [
      {
        id: 'harmony_q1',
        skillId: 'harmony_share',
        type: 'knowledge',
        question: '鸿蒙设备协同的前提条件是什么？',
        options: ['同一 WiFi', '同一华为账号', '同款设备'],
        correctAnswer: '同一华为账号',
        explanation: '鸿蒙协同需要设备登录同一个华为账号',
        difficulty: 1
      }
    ];
  }

  /**
   * 执行能力评估
   * 核心方法：评估用户现有能力
   */
  async assess(
    userId: string,
    scenario: ScenarioAnalysis,
    timeLimit?: number // 时间限制（秒）
  ): Promise<AssessmentResult> {
    HiLog.info("AbilityAssessor", `执行评估：${userId}/${scenario.scenarioName}`);
    
    const startTime = Date.now();
    const skillAssessments: SkillAssessment[] = [];
    const weakPoints: WeakPoint[] = [];
    const recommendations: LearningRecommendation[] = [];
    
    let totalScore = 0;
    let questionCount = 0;
    
    // 对每个所需技能进行评估
    for (const skillReq of scenario.requiredSkills) {
      const assessment = await this.assessSkill(userId, skillReq);
      skillAssessments.push(assessment);
      
      totalScore += assessment.score;
      questionCount += 3; // 每个技能 3 道题
      
      // 识别薄弱点
      if (assessment.score < 60) {
        weakPoints.push({
          skillId: skillReq.skillId,
          aspect: '整体掌握度低',
          severity: assessment.score < 30 ? 'critical' : 'moderate',
          description: `${skillReq.skillName}掌握度仅为${assessment.score}%`,
          improvement: `建议系统学习${skillReq.skillName}基础`
        });
      }
      
      // 生成学习建议
      recommendations.push(this.generateRecommendation(assessment));
    }
    
    // 计算整体评估
    const averageScore = totalScore / skillAssessments.length;
    const overallLevel = this.calculateOverallLevel(averageScore);
    const readinessScore = Math.round(averageScore);
    
    const result: AssessmentResult = {
      userId,
      scenarioId: scenario.scenarioName,
      overallLevel,
      readinessScore,
      skillAssessments,
      weakPoints,
      recommendations,
      assessmentTime: Math.round((Date.now() - startTime) / 1000),
      questionCount,
      confidence: 0.85
    };
    
    // 保存评估历史
    this.saveAssessmentHistory(userId, result);
    
    HiLog.info("AbilityAssessor", `评估完成：准备度${readinessScore}%, 用时${result.assessmentTime}秒`);
    
    return result;
  }

  /**
   * 评估单项技能
   */
  private async assessSkill(
    userId: string,
    skillReq: SkillRequirement
  ): Promise<SkillAssessment> {
    const questions = this.getQuestionsForSkill(skillReq.skillId, skillReq.level);
    
    let correctCount = 0;
    let knowledgeCorrect = 0;
    let practiceCorrect = 0;
    let knowledgeCount = 0;
    let practiceCount = 0;
    
    // 模拟答题（实际应该让用户答题）
    for (const q of questions) {
      const isCorrect = this.simulateAnswer(q, userId);
      
      if (isCorrect) correctCount++;
      
      if (q.type === 'knowledge') {
        knowledgeCount++;
        if (isCorrect) knowledgeCorrect++;
      } else if (q.type === 'practice') {
        practiceCount++;
        if (isCorrect) practiceCorrect++;
      }
    }
    
    // 计算得分
    const score = Math.round((correctCount / questions.length) * 100);
    const knowledgeScore = knowledgeCount > 0 ? Math.round((knowledgeCorrect / knowledgeCount) * 100) : 0;
    const practiceScore = practiceCount > 0 ? Math.round((practiceCorrect / practiceCount) * 100) : 0;
    
    // 确定水平
    let level: SkillAssessment['level'] = 'not_started';
    if (score >= 80) level = 'mastered';
    else if (score >= 40) level = 'learning';
    
    // 是否应该学习
    const shouldLearn = score < 80;
    const learnPriority = score < 30 ? 'high' : score < 60 ? 'medium' : 'low';
    
    return {
      skillId: skillReq.skillId,
      skillName: skillReq.skillName,
      level,
      score,
      knowledgeScore,
      practiceScore,
      previousAttempts: 1,
      lastAssessed: Date.now(),
      shouldLearn,
      learnPriority,
      estimatedTime: this.estimateLearningTime(score, skillReq.level)
    };
  }

  /**
   * 获取技能评估题目
   */
  private getQuestionsForSkill(
    skillId: string,
    level: string
  ): AssessmentQuestion[] {
    const questions = this.questionBank[skillId] || [];
    
    // 根据水平筛选题目
    if (level === 'basic') {
      return questions.filter(q => q.difficulty <= 2);
    } else if (level === 'intermediate') {
      return questions.filter(q => q.difficulty <= 3);
    } else {
      return questions;
    }
  }

  /**
   * 模拟答题（实际应该让用户答题）
   */
  private simulateAnswer(question: AssessmentQuestion, userId: string): boolean {
    // 简化：随机正确率 70%
    return Math.random() > 0.3;
  }

  /**
   * 计算整体水平
   */
  private calculateOverallLevel(score: number): AssessmentResult['overallLevel'] {
    if (score >= 80) return 'advanced';
    if (score >= 50) return 'intermediate';
    return 'beginner';
  }

  /**
   * 生成学习建议
   */
  private generateRecommendation(assessment: SkillAssessment): LearningRecommendation {
    if (assessment.level === 'mastered') {
      return {
        type: 'skip',
        skillId: assessment.skillId,
        reason: `已掌握${assessment.skillName}（${assessment.score}分）`,
        action: '跳过，直接进入下一项',
        estimatedTime: 0
      };
    } else if (assessment.score >= 50) {
      return {
        type: 'review',
        skillId: assessment.skillId,
        reason: `${assessment.skillName}基础尚可，需要巩固`,
        action: '复习薄弱环节',
        estimatedTime: Math.round(assessment.estimatedTime * 0.5)
      };
    } else {
      return {
        type: 'learn',
        skillId: assessment.skillId,
        reason: `${assessment.skillName}需要系统学习`,
        action: '从头开始学习',
        estimatedTime: assessment.estimatedTime
      };
    }
  }

  /**
   * 估算学习时间
   */
  private estimateLearningTime(score: number, level: string): number {
    const baseTime = level === 'basic' ? 30 : level === 'intermediate' ? 60 : 90;
    
    // 分数越低，需要时间越长
    const multiplier = score < 30 ? 2 : score < 60 ? 1.5 : 1;
    
    return Math.round(baseTime * multiplier);
  }

  /**
   * 保存评估历史
   */
  private saveAssessmentHistory(userId: string, result: AssessmentResult): void {
    if (!this.assessmentHistory.has(userId)) {
      this.assessmentHistory.set(userId, []);
    }
    this.assessmentHistory.get(userId)!.push(result);
  }

  /**
   * 获取评估历史
   */
  getAssessmentHistory(userId: string): AssessmentResult[] {
    return this.assessmentHistory.get(userId) || [];
  }

  /**
   * 获取能力报告
   */
  getAbilityReport(userId: string): {
    totalAssessments: number;
    averageScore: number;
    strongestSkill: string;
    weakestSkill: string;
    progressTrend: 'up' | 'down' | 'stable';
  } {
    const history = this.getAssessmentHistory(userId);
    
    if (history.length === 0) {
      return {
        totalAssessments: 0,
        averageScore: 0,
        strongestSkill: '',
        weakestSkill: '',
        progressTrend: 'stable'
      };
    }
    
    const totalAssessments = history.length;
    const averageScore = Math.round(
      history.reduce((sum, r) => sum + r.readinessScore, 0) / totalAssessments
    );
    
    // 找出最强/最弱技能
    const allSkills = new Map<string, number[]>();
    history.forEach(r => {
      r.skillAssessments.forEach(s => {
        if (!allSkills.has(s.skillId)) {
          allSkills.set(s.skillId, []);
        }
        allSkills.get(s.skillId)!.push(s.score);
      });
    });
    
    let strongestSkill = '';
    let weakestSkill = '';
    let strongestAvg = 0;
    let weakestAvg = 100;
    
    allSkills.forEach((scores, skillId) => {
      const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
      if (avg > strongestAvg) {
        strongestAvg = avg;
        strongestSkill = skillId;
      }
      if (avg < weakestAvg) {
        weakestAvg = avg;
        weakestSkill = skillId;
      }
    });
    
    // 计算趋势
    const recent = history.slice(-3);
    const older = history.slice(-6, -3);
    const recentAvg = recent.reduce((s, r) => s + r.readinessScore, 0) / recent.length;
    const olderAvg = older.length > 0 ? older.reduce((s, r) => s + r.readinessScore, 0) / older.length : recentAvg;
    
    let progressTrend: 'up' | 'down' | 'stable' = 'stable';
    if (recentAvg > olderAvg + 5) progressTrend = 'up';
    else if (recentAvg < olderAvg - 5) progressTrend = 'down';
    
    return {
      totalAssessments,
      averageScore,
      strongestSkill,
      weakestSkill,
      progressTrend
    };
  }
}

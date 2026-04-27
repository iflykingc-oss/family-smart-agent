/**
 * ============================================================================
 * 场景分析服务 - ScenarioAnalyzer
 * 
 * 【借鉴优化】
 * 参考：AI Persona OS - Proactive Behavior（主动行为）
 * 优化：从"等待请求" → "主动理解真实需求"
 * 
 * 核心：理解用户真实学习场景，而非表面技能
 * 
 * 输入："我想用 Excel 管理家庭开支"
 * 输出：
 *   - 场景类型：家庭财务管理
 *   - 真实目标：记录开支→分析→控制预算
 *   - 所需技能：Excel 基础 + 表格设计 + 公式
 *   - 推荐路径：场景驱动学习
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { HuaweiAIService } from '../harmony/HuaweiAIService';

/**
 * 场景类型
 */
export enum ScenarioType {
  // 办公场景
  OFFICE_REPORT = 'office_report',         // 做报表
  OFFICE_ANALYSIS = 'office_analysis',     // 数据分析
  OFFICE_PRESENTATION = 'office_presentation', // 演示汇报
  
  // 生活场景
  LIFE_FINANCE = 'life_finance',           // 家庭财务
  LIFE_HEALTH = 'life_health',             // 健康管理
  LIFE_TRAVEL = 'life_travel',             // 旅行规划
  LIFE_COOKING = 'life_cooking',           // 烹饪学习
  LIFE_SHOPPING = 'life_shopping',         // 购物决策
  
  // 学习场景
  STUDY_SKILL = 'study_skill',             // 技能学习
  STUDY_EXAM = 'study_exam',               // 考试准备
  
  // 社交场景
  SOCIAL_COMMUNICATION = 'social_comm',    // 沟通社交
  SOCIAL_NETWORKING = 'social_networking'  // 人脉建立
}

/**
 * 场景分析结果
 */
export interface ScenarioAnalysis {
  // 基础信息
  rawInput: string;
  scenarioType: ScenarioType;
  scenarioName: string;
  
  // 目标分析
  realGoal: string;           // 真实目标（不是表面技能）
  subGoals: string[];         // 子目标拆解
  successCriteria: string;    // 成功标准（学完能做什么）
  
  // 技能需求
  requiredSkills: SkillRequirement[];
  prerequisiteSkills: string[]; // 前置技能
  
  // 学习路径建议
  suggestedPath: LearningPathSuggestion;
  
  // 场景元数据
  estimatedTime: number;      // 预计学习时长（分钟）
  difficulty: number;         // 难度 1-5
  priority: 'high' | 'medium' | 'low'; // 优先级
  
  // AI 生成标记
  isAIGenerated: boolean;
  confidence: number;         // 置信度 0-1
}

/**
 * 技能需求
 */
export interface SkillRequirement {
  skillId: string;
  skillName: string;
  level: 'basic' | 'intermediate' | 'advanced';
  reason: string; // 为什么需要这个技能
}

/**
 * 学习路径建议
 */
export interface LearningPathSuggestion {
  approach: 'tutorial' | 'scenario' | 'project' | 'assessment';
  reason: string;
  steps: {
    order: number;
    type: 'assess' | 'learn' | 'practice' | 'project';
    title: string;
    description: string;
    estimatedTime: number;
  }[];
}

/**
 * 场景库（内置场景定义）
 */
const SCENARIO_LIBRARY: Record<string, {
  type: ScenarioType;
  keywords: string[];
  goal: string;
  subGoals: string[];
  skills: SkillRequirement[];
  estimatedTime: number;
  difficulty: number;
}> = {
  // 办公场景
  'office_report': {
    type: ScenarioType.OFFICE_REPORT,
    keywords: ['报表', '报告', '汇总', '统计'],
    goal: '能够独立完成数据报表制作',
    subGoals: ['数据整理', '表格设计', '公式计算', '格式美化'],
    skills: [
      { skillId: 'excel_basic', skillName: 'Excel 基础', level: 'basic', reason: '数据录入和基础操作' },
      { skillId: 'excel_formula', skillName: 'Excel 公式', level: 'intermediate', reason: '数据计算' },
      { skillId: 'excel_chart', skillName: 'Excel 图表', level: 'basic', reason: '数据可视化' }
    ],
    estimatedTime: 120,
    difficulty: 3
  },
  
  // 生活场景 - 家庭财务
  'life_finance': {
    type: ScenarioType.LIFE_FINANCE,
    keywords: ['家庭开支', '记账', '理财', '预算', '花钱', '收入'],
    goal: '能够用工具管理家庭财务，控制预算',
    subGoals: ['记录每日开支', '分类统计', '预算设置', '超支预警'],
    skills: [
      { skillId: 'excel_basic', skillName: 'Excel 基础', level: 'basic', reason: '制作记账表格' },
      { skillId: 'excel_formula', skillName: 'Excel 公式', level: 'intermediate', reason: '自动计算收支' },
      { skillId: 'excel_chart', skillName: 'Excel 图表', level: 'basic', reason: '开支可视化' }
    ],
    estimatedTime: 180,
    difficulty: 3
  },
  
  // 生活场景 - 健康管理
  'life_health': {
    type: ScenarioType.LIFE_HEALTH,
    keywords: ['健康', '运动', '减肥', '健身', '饮食', '体检'],
    goal: '能够科学管理个人健康',
    subGoals: ['记录健康数据', '制定运动计划', '饮食管理', '进度追踪'],
    skills: [
      { skillId: 'health_tracking', skillName: '健康数据记录', level: 'basic', reason: '基础记录' },
      { skillId: 'excel_basic', skillName: 'Excel 基础', level: 'basic', reason: '数据整理' }
    ],
    estimatedTime: 90,
    difficulty: 2
  },
  
  // 生活场景 - 烹饪学习
  'life_cooking': {
    type: ScenarioType.LIFE_COOKING,
    keywords: ['做菜', '做饭', '烹饪', '菜谱', '红烧肉', '炒菜'],
    goal: '能够独立完成指定菜品制作',
    subGoals: ['食材准备', '处理技巧', '烹饪步骤', '调味掌握'],
    skills: [
      { skillId: 'cooking_basic', skillName: '烹饪基础', level: 'basic', reason: '刀工/火候' },
      { skillId: 'cooking_recipe', skillName: '菜谱理解', level: 'basic', reason: '步骤跟随' }
    ],
    estimatedTime: 60,
    difficulty: 2
  },
  
  // 学习场景 - 技能学习
  'study_skill': {
    type: ScenarioType.STUDY_SKILL,
    keywords: ['学习', '学会', '教程', '怎么学', '入门'],
    goal: '掌握指定技能的基础应用',
    subGoals: ['理解概念', '基础操作', '简单应用'],
    skills: [
      { skillId: 'learning_method', skillName: '学习方法', level: 'basic', reason: '高效学习' }
    ],
    estimatedTime: 240,
    difficulty: 3
  }
};

/**
 * 场景分析服务
 */
export class ScenarioAnalyzer {
  private static instance: ScenarioAnalyzer | null = null;
  
  private aiService: HuaweiAIService;

  static getInstance(): ScenarioAnalyzer {
    if (!ScenarioAnalyzer.instance) {
      ScenarioAnalyzer.instance = new ScenarioAnalyzer();
    }
    return ScenarioAnalyzer.instance;
  }

  private constructor() {
    this.aiService = HuaweiAIService.getInstance();
    HiLog.info("ScenarioAnalyzer", "场景分析服务初始化");
  }

  /**
   * 分析用户场景
   * 核心方法：理解用户真实学习需求
   */
  async analyze(userInput: string): Promise<ScenarioAnalysis> {
    HiLog.info("ScenarioAnalyzer", `分析场景：${userInput}`);
    
    // 1. 关键词匹配（快速路径）
    const matchedScenario = this.matchByKeywords(userInput);
    
    if (matchedScenario) {
      HiLog.info("ScenarioAnalyzer", `匹配到内置场景：${matchedScenario.goal}`);
      return this.buildAnalysis(userInput, matchedScenario, false);
    }
    
    // 2. AI 深度分析（兜底路径）
    HiLog.info("ScenarioAnalyzer", "关键词未匹配，使用 AI 分析");
    return this.analyzeWithAI(userInput);
  }

  /**
   * 关键词匹配
   */
  private matchByKeywords(input: string): {
    type: ScenarioType;
    goal: string;
    subGoals: string[];
    skills: SkillRequirement[];
    estimatedTime: number;
    difficulty: number;
  } | null {
    const lowerInput = input.toLowerCase();
    
    for (const [key, scenario] of Object.entries(SCENARIO_LIBRARY)) {
      for (const keyword of scenario.keywords) {
        if (lowerInput.includes(keyword)) {
          return {
            type: scenario.type,
            goal: scenario.goal,
            subGoals: scenario.subGoals,
            skills: scenario.skills,
            estimatedTime: scenario.estimatedTime,
            difficulty: scenario.difficulty
          };
        }
      }
    }
    
    return null;
  }

  /**
   * AI 深度分析
   */
  private async analyzeWithAI(userInput: string): Promise<ScenarioAnalysis> {
    const prompt = `分析用户的学习需求，提取以下信息：
    
用户输入：${userInput}

请分析：
1. 场景类型（办公/生活/学习/社交）
2. 真实目标（用户想解决什么问题，不是表面技能）
3. 子目标拆解（3-5 个）
4. 所需技能列表
5. 预计学习时长（分钟）
6. 难度评估（1-5）

返回 JSON 格式`;

    try {
      const response = await this.aiService.generateTeachingContent(prompt);
      
      if (response.success && response.content) {
        const aiResult = JSON.parse(response.content);
        
        return {
          rawInput: userInput,
          scenarioType: this.parseScenarioType(aiResult.scenarioType),
          scenarioName: aiResult.scenarioName || '自定义场景',
          realGoal: aiResult.realGoal,
          subGoals: aiResult.subGoals || [],
          successCriteria: aiResult.successCriteria || '',
          requiredSkills: aiResult.requiredSkills || [],
          prerequisiteSkills: aiResult.prerequisiteSkills || [],
          suggestedPath: this.generatePathSuggestion(aiResult),
          estimatedTime: aiResult.estimatedTime || 120,
          difficulty: aiResult.difficulty || 3,
          priority: this.calculatePriority(aiResult),
          isAIGenerated: true,
          confidence: 0.7
        };
      }
    } catch (error) {
      HiLog.error("ScenarioAnalyzer", `AI 分析失败：${error}`);
    }
    
    // AI 失败，返回通用分析
    return this.buildGenericAnalysis(userInput);
  }

  /**
   * 构建分析结果
   */
  private buildAnalysis(
    userInput: string,
    scenario: any,
    isAIGenerated: boolean
  ): ScenarioAnalysis {
    return {
      rawInput: userInput,
      scenarioType: scenario.type,
      scenarioName: this.getScenarioName(scenario.type),
      realGoal: scenario.goal,
      subGoals: scenario.subGoals,
      successCriteria: `学完后能够${scenario.goal}`,
      requiredSkills: scenario.skills,
      prerequisiteSkills: this.extractPrerequisites(scenario.skills),
      suggestedPath: this.generatePathSuggestion(scenario),
      estimatedTime: scenario.estimatedTime,
      difficulty: scenario.difficulty,
      priority: this.calculatePriority(scenario),
      isAIGenerated,
      confidence: isAIGenerated ? 0.7 : 0.9
    };
  }

  /**
   * 生成通用分析（兜底）
   */
  private buildGenericAnalysis(userInput: string): ScenarioAnalysis {
    return {
      rawInput: userInput,
      scenarioType: ScenarioType.STUDY_SKILL,
      scenarioName: '通用技能学习',
      realGoal: '掌握用户指定的技能',
      subGoals: ['理解基础概念', '学习核心操作', '实践应用'],
      successCriteria: '能够独立完成相关任务',
      requiredSkills: [
        { skillId: 'generic_skill', skillName: '通用技能', level: 'basic', reason: '基础学习' }
      ],
      prerequisiteSkills: [],
      suggestedPath: {
        approach: 'tutorial',
        reason: '通用学习路径',
        steps: [
          { order: 1, type: 'assess', title: '能力评估', description: '了解当前水平', estimatedTime: 5 },
          { order: 2, type: 'learn', title: '基础学习', description: '学习核心概念', estimatedTime: 30 },
          { order: 3, type: 'practice', title: '实践练习', description: '动手操作', estimatedTime: 30 },
          { order: 4, type: 'project', title: '小项目', description: '综合应用', estimatedTime: 60 }
        ]
      },
      estimatedTime: 125,
      difficulty: 3,
      priority: 'medium',
      isAIGenerated: false,
      confidence: 0.5
    };
  }

  /**
   * 生成路径建议
   */
  private generatePathSuggestion(scenario: any): LearningPathSuggestion {
    // 根据场景类型推荐学习方式
    const approach = this.recommendApproach(scenario.type);
    
    return {
      approach,
      reason: this.getApproachReason(approach),
      steps: scenario.subGoals.map((goal: string, idx: number) => ({
        order: idx + 1,
        type: this.getStepType(idx, scenario.subGoals.length),
        title: goal,
        description: `学习：${goal}`,
        estimatedTime: Math.round(scenario.estimatedTime / scenario.subGoals.length)
      }))
    };
  }

  /**
   * 推荐学习方式
   */
  private recommendApproach(type: ScenarioType): 'tutorial' | 'scenario' | 'project' | 'assessment' {
    switch (type) {
      case ScenarioType.OFFICE_REPORT:
      case ScenarioType.OFFICE_ANALYSIS:
        return 'project'; // 办公场景用项目驱动
      case ScenarioType.LIFE_FINANCE:
      case ScenarioType.LIFE_HEALTH:
        return 'scenario'; // 生活场景用场景驱动
      case ScenarioType.STUDY_SKILL:
        return 'assessment'; // 技能学习先评估
      default:
        return 'tutorial';
    }
  }

  /**
   * 获取方式说明
   */
  private getApproachReason(approach: string): string {
    const reasons: Record<string, string> = {
      'tutorial': '系统化学习，适合零基础',
      'scenario': '场景驱动，学完就能用',
      'project': '项目驱动，有实际成果',
      'assessment': '先评估再学习，只学不会的'
    };
    return reasons[approach] || '';
  }

  /**
   * 获取步骤类型
   */
  private getStepType(idx: number, total: number): 'assess' | 'learn' | 'practice' | 'project' {
    if (idx === 0) return 'assess';
    if (idx < total - 1) return 'learn';
    return 'project';
  }

  /**
   * 计算优先级
   */
  private calculatePriority(scenario: any): 'high' | 'medium' | 'low' {
    // 生活场景优先级高
    if ([ScenarioType.LIFE_FINANCE, ScenarioType.LIFE_HEALTH].includes(scenario.type)) {
      return 'high';
    }
    // 办公场景优先级中
    if ([ScenarioType.OFFICE_REPORT, ScenarioType.OFFICE_ANALYSIS].includes(scenario.type)) {
      return 'medium';
    }
    return 'low';
  }

  /**
   * 提取前置技能
   */
  private extractPrerequisites(skills: SkillRequirement[]): string[] {
    return skills
      .filter(s => s.level === 'basic')
      .map(s => s.skillId);
  }

  /**
   * 解析场景类型
   */
  private parseScenarioType(typeStr: string): ScenarioType {
    return ScenarioType[typeStr as keyof typeof ScenarioType] || ScenarioType.STUDY_SKILL;
  }

  /**
   * 获取场景名称
   */
  private getScenarioName(type: ScenarioType): string {
    const names: Record<ScenarioType, string> = {
      [ScenarioType.OFFICE_REPORT]: '办公报表',
      [ScenarioType.OFFICE_ANALYSIS]: '数据分析',
      [ScenarioType.OFFICE_PRESENTATION]: '演示汇报',
      [ScenarioType.LIFE_FINANCE]: '家庭财务',
      [ScenarioType.LIFE_HEALTH]: '健康管理',
      [ScenarioType.LIFE_TRAVEL]: '旅行规划',
      [ScenarioType.LIFE_COOKING]: '烹饪学习',
      [ScenarioType.LIFE_SHOPPING]: '购物决策',
      [ScenarioType.STUDY_SKILL]: '技能学习',
      [ScenarioType.STUDY_EXAM]: '考试准备',
      [ScenarioType.SOCIAL_COMMUNICATION]: '沟通社交',
      [ScenarioType.SOCIAL_NETWORKING]: '人脉建立'
    };
    return names[type] || '通用学习';
  }
}

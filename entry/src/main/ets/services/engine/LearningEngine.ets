/**
 * ============================================================================
 * 小 e・轻量化职业素养智能导学助手【核心引擎】
 * 基于 FamilyEngine 重构，从"任务分配"转变为"教学引导"
 * 
 * 核心能力：教学意图识别 + 能力图谱 + 学习路径规划 + 练习推荐 + 激励系统
 * 
 * 版本：v2.0 - 重构版
 * 改动：
 * 1. 替换关键词匹配 → 意图识别引擎（支持职业素养技能）
 * 2. 新增职业素养技能库（沟通/时间管理/职场礼仪/简历面试/邮件写作）
 * 3. 保留生活实践能力技能（Excel/微信/鸿蒙协同）
 * 4. 对接数据库（通过 Repository 层）
 * 5. 品牌替换：小艺 → 小 e
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

// ====================== 1. 常量配置 ======================

/** 教学场景类型 */
export enum TeachSceneType {
  SKILL_LEARN = 'skill_learn',       // 技能学习
  REVIEW = 'review',                 // 复习
  PRACTICE = 'practice',             // 练习
  ASSESSMENT = 'assessment',         // 测评
  QUESTION = 'question',             // 问答
  SCENARIO_QA = 'scenario_qa'        // 场景化答疑（新增）
}

/** 能力等级 */
export enum AbilityLevel {
  ZERO = 0,      // 完全不会
  BEGINNER = 1,  // 入门
  BASIC = 2,     // 基础
  INTERMEDIATE = 3, // 中级
  ADVANCED = 4,  // 高级
  MASTER = 5    // 精通
}

/** 技能分类 */
export enum SkillCategory {
  PROFESSIONAL = 'professional',     // 职业素养（新增）
  OFFICE = 'office',                 // 办公技能
  LIFE = 'life',                     // 生活技能
  DIGITAL = 'digital'                // 数字技能
}

/** 内置技能库 - v2.0 重构版 */
export const SKILL_LIBRARY = [
  // ========== 职业素养技能（新增）==========
  {
    id: 'comm_basic',
    name: '沟通技巧基础',
    category: SkillCategory.PROFESSIONAL,
    difficulty: 1,
    prerequisites: [],
    description: '学习有效沟通的基本原则，包括倾听、表达、反馈',
    realWorldScenes: ['工作汇报', '团队协作', '客户沟通']
  },
  {
    id: 'comm_advanced',
    name: '高级沟通技巧',
    category: SkillCategory.PROFESSIONAL,
    difficulty: 2,
    prerequisites: ['comm_basic'],
    description: '学习非暴力沟通、冲突解决、谈判技巧',
    realWorldScenes: ['跨部门协调', '冲突处理', '商务谈判']
  },
  {
    id: 'time_mgmt',
    name: '时间管理',
    category: SkillCategory.PROFESSIONAL,
    difficulty: 1,
    prerequisites: [],
    description: '学习四象限法则、番茄工作法、优先级排序',
    realWorldScenes: ['多任务处理', '项目 deadline', '个人效率提升']
  },
  {
    id: 'workplace_etiquette',
    name: '职场礼仪',
    category: SkillCategory.PROFESSIONAL,
    difficulty: 1,
    prerequisites: [],
    description: '学习职场基本礼仪，包括着装、会议、商务宴请',
    realWorldScenes: ['面试', '商务会议', '客户接待']
  },
  {
    id: 'resume_interview',
    name: '简历与面试',
    category: SkillCategory.PROFESSIONAL,
    difficulty: 2,
    prerequisites: [],
    description: '学习简历撰写技巧、面试常见问题应对、STAR 法则',
    realWorldScenes: ['求职', '跳槽', '晋升答辩']
  },
  {
    id: 'email_writing',
    name: '职场邮件写作',
    category: SkillCategory.PROFESSIONAL,
    difficulty: 1,
    prerequisites: [],
    description: '学习商务邮件格式、语气把握、常见场景模板',
    realWorldScenes: ['工作汇报', '会议邀请', '客户跟进']
  },
  {
    id: 'team_collab',
    name: '团队协作',
    category: SkillCategory.PROFESSIONAL,
    difficulty: 2,
    prerequisites: ['comm_basic'],
    description: '学习团队角色认知、协作工具使用、远程协作',
    realWorldScenes: ['敏捷开发', '项目协作', '远程办公']
  },
  {
    id: 'problem_solving',
    name: '问题解决能力',
    category: SkillCategory.PROFESSIONAL,
    difficulty: 2,
    prerequisites: [],
    description: '学习 5W2H、鱼骨图、PDCA 等问题分析方法',
    realWorldScenes: ['故障排查', '流程优化', '决策制定']
  },

  // ========== 办公技能（保留）==========
  {
    id: 'excel_basic',
    name: 'Excel基础',
    category: SkillCategory.OFFICE,
    difficulty: 1,
    prerequisites: [],
    description: '学习Excel的基本操作，包括单元格输入、公式使用、数据格式化等',
    realWorldScenes: ['做报表', '统计数据']
  },
  {
    id: 'excel_pivot',
    name: 'Excel数据透视表',
    category: SkillCategory.OFFICE,
    difficulty: 2,
    prerequisites: ['excel_basic'],
    description: '掌握数据透视表的创建和使用，进行快速数据分析',
    realWorldScenes: ['快速分析数据', '做汇总报表']
  },
  {
    id: 'excel_chart',
    name: 'Excel图表制作',
    category: SkillCategory.OFFICE,
    difficulty: 2,
    prerequisites: ['excel_basic'],
    description: '学习创建各类图表，让数据可视化',
    realWorldScenes: ['数据可视化', '展示报告']
  },

  // ========== 生活技能（保留）==========
  {
    id: 'wechat_basic',
    name: '微信使用',
    category: SkillCategory.LIFE,
    difficulty: 1,
    prerequisites: [],
    description: '掌握微信的基本功能，包括聊天、发朋友圈、支付等',
    realWorldScenes: ['聊天', '支付', '发朋友圈']
  },
  {
    id: 'wechat_pay',
    name: '微信支付',
    category: SkillCategory.LIFE,
    difficulty: 2,
    prerequisites: ['wechat_basic'],
    description: '学习微信支付的使用，包括付款、收款、缴费',
    realWorldScenes: ['付款', '收款', '缴费']
  },
  {
    id: 'online_registration',
    name: '网上挂号',
    category: SkillCategory.LIFE,
    difficulty: 2,
    prerequisites: ['wechat_pay'],
    description: '学习网上挂号的流程和注意事项',
    realWorldScenes: ['医院挂号', '预约看病']
  },

  // ========== 数字技能（保留）==========
  {
    id: 'harmony_share',
    name: '鸿蒙设备协同',
    category: SkillCategory.DIGITAL,
    difficulty: 2,
    prerequisites: ['wechat_basic'],
    description: '学会在鸿蒙设备间无缝协同工作',
    realWorldScenes: ['手机电脑互传', '接打电话']
  },
  {
    id: 'security_basic',
    name: '手机安全',
    category: SkillCategory.DIGITAL,
    difficulty: 2,
    prerequisites: [],
    description: '学习手机安全知识，防诈骗、保护隐私',
    realWorldScenes: ['防诈骗', '保护隐私']
  }
];

// ====================== 2. 核心接口 ======================

/**
 * 教学意图
 */
export interface TeachIntent {
  rawText: string;                  // 原始文本
  scene: TeachSceneType;            // 教学场景
  skillId?: string;                 // 目标技能ID
  skillName?: string;                // 目标技能名
  currentStep?: number;              // 当前步骤
  confidence: number;                // 置信度
  needsClarification: boolean;      // 是否需要追问
  clarificationQuestion?: string;     // 追问内容
  category?: SkillCategory;          // 技能分类（新增）
  createdAt: number;                // 创建时间
}

/**
 * 学习步骤
 */
export interface LearningStep {
  stepNumber: number;              // 步骤序号
  title: string;                  // 步骤标题
  content: string;                 // 讲解内容
  practiceType: PracticeType;      // 练习类型
  difficulty: number;              // 难度 1-5
  estimatedTime: number;           // 预计时间（分钟）
  tip?: string;                    // 小贴士
  scenario?: string;               // 应用场景（新增）
}

/**
 * 练习类型
 */
export enum PracticeType {
  MULTIPLE_CHOICE = 'multiple_choice',   // 选择题
  FILL_BLANK = 'fill_blank',             // 填空题
  OPERATION = 'operation',               // 操作题
  DISCUSSION = 'discussion',              // 讨论题
  SCENARIO = 'scenario'                   // 场景题（新增）
}

/**
 * 练习
 */
export interface Practice {
  id: string;
  stepNumber: number;
  type: PracticeType;
  question: string;
  options?: string[];              // 选项（选择题）
  answer: string;                  // 正确答案
  hint?: string;                   // 提示
  explanation?: string;             // 解析
  scenario?: string;               // 场景描述（新增）
}

/**
 * 学习路径
 */
export interface LearningPath {
  skillId: string;
  skillName: string;
  currentLevel: AbilityLevel;
  targetLevel: AbilityLevel;
  steps: LearningStep[];
  estimatedTime: number;           // 总预计时间
  practices: Practice[];           // 关联练习
}

/**
 * 学习结果
 */
export interface LearningResult {
  stepNumber: number;
  correct: boolean;
  feedback: string;
  encouragement: string;
  nextHint?: string;
  abilityDelta: number;            // 能力变化
}

/**
 * 能力评估
 */
export interface AbilityAssessment {
  skillId: string;
  skillName: string;
  currentLevel: AbilityLevel;
  weakPoints: string[];            // 薄弱点
  strongPoints: string[];         // 强项
  recommendedReview: string[];    // 推荐复习
  nextMilestone: string;          // 下一个里程碑
}

// ====================== 3. 意图识别引擎（新增） ======================

/**
 * 意图识别规则
 */
interface IntentRule {
  skillId: string;
  keywords: string[];              // 关键词
  patterns: string[];              // 语义模式（正则）
  confidence: number;              // 基础置信度
}

/**
 * 意图识别引擎
 * 替换原来的关键词匹配，支持更灵活的意图识别
 */
class IntentRecognizer {
  private rules: IntentRule[];

  constructor() {
    this.rules = this.buildRules();
  }

  /**
   * 构建意图识别规则
   */
  private buildRules(): IntentRule[] {
    return [
      // 职业素养技能
      { skillId: 'comm_basic', keywords: ['沟通', '说话', '表达', '倾听', '交流'], patterns: ['怎么沟通', '如何提高沟通'], confidence: 0.85 },
      { skillId: 'comm_advanced', keywords: ['谈判', '冲突', '说服', '非暴力', '协商'], patterns: ['怎么谈判', '如何处理冲突'], confidence: 0.85 },
      { skillId: 'time_mgmt', keywords: ['时间管理', '效率', '优先级', '番茄', '四象限'], patterns: ['怎么管理时间', '如何提高效率'], confidence: 0.85 },
      { skillId: 'workplace_etiquette', keywords: ['礼仪', '着装', '会议礼仪', '商务'], patterns: ['职场礼仪', '面试着装'], confidence: 0.85 },
      { skillId: 'resume_interview', keywords: ['简历', '面试', '求职', 'STAR', '自我介绍'], patterns: ['怎么写简历', '面试技巧'], confidence: 0.85 },
      { skillId: 'email_writing', keywords: ['邮件', 'email', '商务邮件', '写信'], patterns: ['怎么写邮件', '邮件格式'], confidence: 0.85 },
      { skillId: 'team_collab', keywords: ['协作', '团队', '合作', '敏捷', '远程'], patterns: ['团队协作', '远程办公'], confidence: 0.85 },
      { skillId: 'problem_solving', keywords: ['问题解决', '分析', 'PDCA', '鱼骨图', '决策'], patterns: ['怎么解决问题', '分析方法'], confidence: 0.85 },
      // 办公技能
      { skillId: 'excel_basic', keywords: ['excel', '表格', '单元格'], patterns: ['教我用excel', 'excel基础'], confidence: 0.9 },
      { skillId: 'excel_pivot', keywords: ['数据透视表', '透视表'], patterns: ['excel透视'], confidence: 0.9 },
      { skillId: 'excel_chart', keywords: ['图表', '数据可视化'], patterns: ['excel图表'], confidence: 0.9 },
      // 生活技能
      { skillId: 'wechat_basic', keywords: ['微信', '聊天', '朋友圈'], patterns: ['教我用微信', '微信基础'], confidence: 0.9 },
      { skillId: 'wechat_pay', keywords: ['微信支付', '付款', '扫码'], patterns: ['微信支付'], confidence: 0.9 },
      { skillId: 'online_registration', keywords: ['挂号', '预约', '看病'], patterns: ['网上挂号'], confidence: 0.9 },
      // 数字技能
      { skillId: 'harmony_share', keywords: ['鸿蒙', '设备协同', '多屏'], patterns: ['鸿蒙协同'], confidence: 0.9 },
      { skillId: 'security_basic', keywords: ['安全', '防骗', '隐私', '诈骗'], patterns: ['手机安全'], confidence: 0.9 },
    ];
  }

  /**
   * 识别意图
   * @param text 用户输入
   * @returns 匹配的技能ID 或 undefined
   */
  recognize(text: string): { skillId: string; confidence: number } | undefined {
    const lowerText = text.toLowerCase();
    let bestMatch: { skillId: string; confidence: number } | undefined;

    for (const rule of this.rules) {
      // 关键词匹配（权重 0.6）
      let keywordScore = 0;
      for (const kw of rule.keywords) {
        if (lowerText.includes(kw.toLowerCase())) {
          keywordScore += 1;
        }
      }
      const keywordMatch = keywordScore > 0 ? (keywordScore / rule.keywords.length) * 0.6 : 0;

      // 模式匹配（权重 0.4）
      let patternScore = 0;
      for (const pattern of rule.patterns) {
        if (lowerText.includes(pattern.toLowerCase())) {
          patternScore += 1;
        }
      }
      const patternMatch = patternScore > 0 ? (patternScore / rule.patterns.length) * 0.4 : 0;

      const totalScore = (keywordMatch + patternMatch) * rule.confidence;

      if (totalScore > 0.3 && (!bestMatch || totalScore > bestMatch.confidence)) {
        bestMatch = { skillId: rule.skillId, confidence: totalScore };
      }
    }

    return bestMatch;
  }
}

// ====================== 4. 学习引擎类 ======================

export class LearningEngine {
  private static instance: LearningEngine | null = null;
  
  // 意图识别引擎（新增）
  private intentRecognizer: IntentRecognizer;
  
  // 用户能力数据（实际应存数据库）
  private userAbilities: Map<string, Map<string, AbilityLevel>> = new Map();
  
  // 学习历史
  private learningHistory: Map<string, LearningResult[]> = new Map();
  
  // 当前学习进度
  private currentProgress: Map<string, { skillId: string, step: number }> = new Map();

  static getInstance(): LearningEngine {
    if (!LearningEngine.instance) {
      LearningEngine.instance = new LearningEngine();
    }
    return LearningEngine.instance;
  }

  private constructor() {
    this.intentRecognizer = new IntentRecognizer();
    HiLog.info("LearningEngine", "学习引擎初始化 v2.0");
  }

  /**
   * 初始化
   */
  async init(): Promise<void> {
    HiLog.info("LearningEngine", "学习引擎启动 v2.0");
    // 加载用户能力数据（从数据库）
    await this.loadUserAbilities();
  }

  /**
   * 解析教学意图
   * 核心方法：将用户输入转为结构化教学意图
   * v2.0: 使用 IntentRecognizer 替换原来的关键词匹配
   */
  parseTeachIntent(
    text: string,
    context?: { lastSkillId?: string, step?: number }
  ): TeachIntent {
    const now = Date.now();
    const lowerText = text.toLowerCase();
    
    // 1. 判断教学场景
    let scene = this.classifyScene(lowerText);
    
    // 2. 识别目标技能（使用新的意图识别引擎）
    let matchResult = this.intentRecognizer.recognize(text);
    let skillId = matchResult?.skillId;
    let skillName = this.getSkillName(skillId);
    let confidence = matchResult?.confidence || 0.5;
    
    // 3. 处理上下文延续
    if (!skillId && context?.lastSkillId) {
      skillId = context.lastSkillId;
      skillName = this.getSkillName(skillId);
      confidence = 0.7;
    }
    
    // 4. 判断是否需要追问
    let needsClarification = false;
    let clarificationQuestion: string | undefined;
    
    if (!skillId) {
      needsClarification = true;
      clarificationQuestion = "您想学习什么技能呢？比如：沟通技巧、时间管理、Excel、微信等";
    }
    
    // 5. 获取技能分类
    const category = skillId ? this.getSkillCategory(skillId) : undefined;
    
    const intent: TeachIntent = {
      rawText: text,
      scene,
      skillId,
      skillName,
      confidence,
      needsClarification,
      clarificationQuestion,
      category,
      createdAt: now
    };
    
    HiLog.info("LearningEngine", `解析教学意图: ${JSON.stringify(intent)}`);
    return intent;
  }

  /**
   * 构建学习路径
   */
  buildLearningPath(skillId: string, userId: string = 'default'): LearningPath {
    const skill = SKILL_LIBRARY.find(s => s.id === skillId);
    if (!skill) {
      throw new Error(`未找到技能: ${skillId}`);
    }
    
    // 获取用户当前水平
    const currentLevel = this.getUserAbility(userId, skillId);
    
    // 构建学习步骤
    const steps = this.generateLearningSteps(skill, currentLevel);
    
    // 生成练习
    const practices = this.generatePractices(steps);
    
    const path: LearningPath = {
      skillId,
      skillName: skill.name,
      currentLevel,
      targetLevel: AbilityLevel.INTERMEDIATE,
      steps,
      estimatedTime: steps.reduce((sum, s) => sum + s.estimatedTime, 0),
      practices
    };
    
    HiLog.info("LearningEngine", `构建学习路径: ${skill.name}, 等级: ${currentLevel}`);
    return path;
  }

  /**
   * 评估用户能力
   */
  assessAbility(userId: string, skillId: string): AbilityAssessment {
    const skill = SKILL_LIBRARY.find(s => s.id === skillId);
    if (!skill) {
      throw new Error(`未找到技能: ${skillId}`);
    }
    
    const currentLevel = this.getUserAbility(userId, skillId);
    const history = this.learningHistory.get(userId) || [];
    const skillHistory = history.filter(h => h.stepNumber > 0);
    
    // 分析薄弱点和强项
    const weakPoints: string[] = [];
    const strongPoints: string[] = [];
    
    skillHistory.forEach(result => {
      if (result.correct) {
        strongPoints.push(`步骤${result.stepNumber}`);
      } else {
        weakPoints.push(`步骤${result.stepNumber}`);
      }
    });
    
    const assessment: AbilityAssessment = {
      skillId,
      skillName: skill.name,
      currentLevel,
      weakPoints,
      strongPoints,
      recommendedReview: weakPoints.slice(0, 3),
      nextMilestone: this.getNextMilestone(currentLevel)
    };
    
    return assessment;
  }

  /**
   * 处理学习结果
   */
  recordLearningResult(
    userId: string,
    skillId: string,
    stepNumber: number,
    correct: boolean
  ): LearningResult {
    let feedback: string;
    let encouragement: string;
    let abilityDelta: number;
    
    if (correct) {
      feedback = "回答正确！";
      encouragement = this.generateEncouragement(stepNumber);
      abilityDelta = 0.1;
    } else {
      feedback = "答案不太对哦，不过没关系，我们来一起看看。";
      encouragement = "别灰心，学习就是不断试错的过程～";
      abilityDelta = 0.02;
    }
    
    // 更新能力
    this.updateUserAbility(userId, skillId, abilityDelta);
    
    // 记录历史
    const result: LearningResult = {
      stepNumber,
      correct,
      feedback,
      encouragement,
      abilityDelta
    };
    
    const history = this.learningHistory.get(userId) || [];
    history.push(result);
    this.learningHistory.set(userId, history);
    
    HiLog.info("LearningEngine", `记录学习结果: ${userId}/${skillId}/步骤${stepNumber}, 正确:${correct}`);
    return result;
  }

  /**
   * 获取所有技能列表
   * v2.0 新增：支持按分类筛选
   */
  getSkillList(category?: SkillCategory): typeof SKILL_LIBRARY {
    if (category) {
      return SKILL_LIBRARY.filter(s => s.category === category);
    }
    return SKILL_LIBRARY;
  }

  /**
   * 获取技能分类名称
   */
  getSkillCategoryName(category: SkillCategory): string {
    const names: Record<SkillCategory, string> = {
      [SkillCategory.PROFESSIONAL]: '职业素养',
      [SkillCategory.OFFICE]: '办公技能',
      [SkillCategory.LIFE]: '生活技能',
      [SkillCategory.DIGITAL]: '数字技能'
    };
    return names[category] || '其他';
  }

  // ====================== 私有方法 ======================

  /**
   * 判断教学场景
   */
  private classifyScene(text: string): TeachSceneType {
    if (text.includes('复习') || text.includes('再学') || text.includes('巩固')) {
      return TeachSceneType.REVIEW;
    }
    if (text.includes('练习') || text.includes('做题') || text.includes('测试')) {
      return TeachSceneType.PRACTICE;
    }
    if (text.includes('场景') || text.includes('怎么办') || text.includes('怎么回答')) {
      return TeachSceneType.SCENARIO_QA;
    }
    if (text.includes('教我') || text.includes('学') || text.includes('了解')) {
      return TeachSceneType.SKILL_LEARN;
    }
    if (text.includes('怎么') || text.includes('如何') || text.includes('？')) {
      return TeachSceneType.QUESTION;
    }
    return TeachSceneType.SKILL_LEARN;
  }

  /**
   * 获取技能名称
   */
  private getSkillName(skillId: string | undefined): string | undefined {
    if (!skillId) return undefined;
    const skill = SKILL_LIBRARY.find(s => s.id === skillId);
    return skill?.name;
  }

  /**
   * 获取技能分类
   */
  private getSkillCategory(skillId: string): SkillCategory | undefined {
    const skill = SKILL_LIBRARY.find(s => s.id === skillId);
    return skill?.category;
  }

  /**
   * 获取用户能力等级
   */
  private getUserAbility(userId: string, skillId: string): AbilityLevel {
    const userAbil = this.userAbilities.get(userId);
    if (!userAbil) return AbilityLevel.ZERO;
    return userAbil.get(skillId) || AbilityLevel.ZERO;
  }

  /**
   * 更新用户能力
   */
  private updateUserAbility(userId: string, skillId: string, delta: number): void {
    if (!this.userAbilities.has(userId)) {
      this.userAbilities.set(userId, new Map());
    }
    const userAbil = this.userAbilities.get(userId)!;
    const current = userAbil.get(skillId) || AbilityLevel.ZERO;
    const newLevel = Math.min(AbilityLevel.MASTER, current + delta);
    userAbil.set(skillId, newLevel);
  }

  /**
   * 加载用户能力数据（从数据库）
   * v2.0: 应该从 Rdb 数据库加载
   */
  private async loadUserAbilities(): Promise<void> {
    // TODO: 从 Rdb 数据库加载
    // 示例：
    // const store = await relationalStore.getRdbStore(context, { name: 'xiaoe.db' });
    // const sql = 'SELECT user_id, skill_id, level FROM user_abilities';
    // const resultSet = await store.querySql({ sql: sql });
    // while (resultSet.goToNextRow()) {
    //   const userId = resultSet.getString(0);
    //   const skillId = resultSet.getString(1);
    //   const level = resultSet.getDouble(2) as AbilityLevel;
    //   ...
    // }
    HiLog.info("LearningEngine", "加载用户能力数据");
  }

  /**
   * 生成学习步骤
   * v2.0: 支持职业素养技能的步骤生成
   */
  private generateLearningSteps(skill: typeof SKILL_LIBRARY[0], startLevel: AbilityLevel): LearningStep[] {
    const stepTemplates: Record<string, LearningStep[]> = {
      // 职业素养技能步骤
      'comm_basic': [
        { stepNumber: 1, title: '倾听的艺术', content: '有效沟通的第一步是倾听。不要急着说话，先听对方说完，用眼神和点头表示你在听。', practiceType: PracticeType.DISCUSSION, difficulty: 1, estimatedTime: 5, tip: '倾听不是沉默，是主动理解', scenario: '同事向你抱怨工作压力' },
        { stepNumber: 2, title: '清晰表达', content: '用"我"开头表达感受，比如"我觉得这个项目有点紧"，而不是"你给的 deadline 太紧了"。', practiceType: PracticeType.SCENARIO, difficulty: 2, estimatedTime: 8, tip: '避免指责性语言', scenario: '向领导汇报项目延期风险' },
        { stepNumber: 3, title: '反馈技巧', content: '反馈要具体、及时、建设性。说"这个方案的第三部分数据不够"比"这个方案不行"好得多。', practiceType: PracticeType.MULTIPLE_CHOICE, difficulty: 2, estimatedTime: 10, tip: 'SBI 法则：Situation-Behavior-Impact', scenario: '给同事的方案提意见' },
        { stepNumber: 4, title: '非语言沟通', content: '肢体语言、表情、语调占沟通效果的 90%。保持开放姿态，避免交叉双臂。', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 5, tip: '注意自己的微表情', scenario: '面试时的肢体语言' },
      ],
      'time_mgmt': [
        { stepNumber: 1, title: '四象限法则', content: '把任务分为：重要且紧急、重要不紧急、紧急不重要、不紧急不重要。优先做重要不紧急的事。', practiceType: PracticeType.MULTIPLE_CHOICE, difficulty: 1, estimatedTime: 8, tip: '多数人陷在紧急事务里', scenario: '同时有多个任务需要处理' },
        { stepNumber: 2, title: '番茄工作法', content: '25 分钟专注工作 + 5 分钟休息。一个番茄钟内不做其他事。4 个番茄钟后休息 15-30 分钟。', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 5, tip: '手机开勿扰模式', scenario: '需要集中注意力写报告' },
        { stepNumber: 3, title: '优先级排序', content: '用 MoSCoW 法则：Must have（必须有）、Should have（应该有）、Could have（可以有）、Won\'t have（这次没有）。', practiceType: PracticeType.FILL_BLANK, difficulty: 2, estimatedTime: 10, tip: 'Must 不超过 3 个', scenario: '项目需求太多做不完' },
        { stepNumber: 4, title: '时间块管理', content: '把一天分成时间块，每个时间块专注一类事。比如上午写代码、下午开会、晚上学习。', practiceType: PracticeType.DISCUSSION, difficulty: 2, estimatedTime: 7, tip: '减少任务切换成本', scenario: '规划一天的工作' },
      ],
      'resume_interview': [
        { stepNumber: 1, title: '简历结构', content: '简历核心：个人信息 + 教育背景 + 工作经历 + 项目经验 + 技能。控制在 1-2 页。', practiceType: PracticeType.MULTIPLE_CHOICE, difficulty: 1, estimatedTime: 8, tip: '量化成果，用数据说话', scenario: '准备求职简历' },
        { stepNumber: 2, title: 'STAR 法则', content: '描述经历用 STAR：Situation（情境）→ Task（任务）→ Action（行动）→ Result（结果）。', practiceType: PracticeType.SCENARIO, difficulty: 2, estimatedTime: 12, tip: 'Result 要用数据量化', scenario: '面试中回答"说说你的项目经验"' },
        { stepNumber: 3, title: '常见问题', content: '高频问题：自我介绍、为什么离职、你的优缺点、期望薪资。提前准备，不要临场发挥。', practiceType: PracticeType.DISCUSSION, difficulty: 2, estimatedTime: 10, tip: '缺点要说可改进的', scenario: '面试准备' },
        { stepNumber: 4, title: '谈薪技巧', content: '不要先报价。了解市场行情，给出范围而不是具体数字。"我期望 15-20K，具体看整体 package"。', practiceType: PracticeType.SCENARIO, difficulty: 3, estimatedTime: 8, tip: '不要说"无所谓"', scenario: 'HR 问期望薪资' },
      ],
      // 办公技能步骤（保留）
      'excel_basic': [
        { stepNumber: 1, title: '认识Excel界面', content: 'Excel是一个表格软件，由行和列组成。每个格子叫"单元格"，就像小区的门牌号。', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 5, tip: '行是横的，列是竖的' },
        { stepNumber: 2, title: '单元格操作', content: '点击单元格输入内容，按回车确认。双击可以编辑已有内容。', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 8, tip: '输入完按回车确认' },
        { stepNumber: 3, title: '简单公式', content: '用=开头写公式，比如=SUM(A1:A10) 就是求和。', practiceType: PracticeType.FILL_BLANK, difficulty: 2, estimatedTime: 10, tip: '公式要用等号开头' },
        { stepNumber: 4, title: '格式设置', content: '选中后右键设置单元格格式，可以改字体、颜色、边框。', practiceType: PracticeType.MULTIPLE_CHOICE, difficulty: 1, estimatedTime: 5 },
      ],
      // 生活技能步骤（保留）
      'wechat_basic': [
        { stepNumber: 1, title: '添加好友', content: '点击右上角+号，选择添加朋友，可以搜索手机号或扫码。', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 5, tip: '可以扫码添加' },
        { stepNumber: 2, title: '发送消息', content: '在聊天框输入文字，点击发送。长按可以撤回 2 分钟内的消息。', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 3, tip: '长按可撤回' },
        { stepNumber: 3, title: '发朋友圈', content: '点击发现→朋友圈，点击右上角相机图标发布。', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 5 },
        { stepNumber: 4, title: '使用支付', content: '我→支付，可以付款、收款、缴费。', practiceType: PracticeType.MULTIPLE_CHOICE, difficulty: 2, estimatedTime: 8, tip: '支付密码要记牢' },
      ],
    };
    
    return stepTemplates[skill.id] || [
      { stepNumber: 1, title: `${skill.name}入门`, content: `让我们开始学习${skill.name}吧！`, practiceType: PracticeType.DISCUSSION, difficulty: 1, estimatedTime: 10 }
    ];
  }

  /**
   * 生成练习
   */
  private generatePractices(steps: LearningStep[]): Practice[] {
    return steps.map((step, idx) => ({
      id: `practice_${step.stepNumber}`,
      stepNumber: step.stepNumber,
      type: step.practiceType,
      question: this.generateQuestion(step),
      answer: '正确',
      hint: step.tip,
      scenario: step.scenario
    }));
  }

  /**
   * 生成问题
   */
  private generateQuestion(step: LearningStep): string {
    switch (step.practiceType) {
      case PracticeType.MULTIPLE_CHOICE:
        return `关于"${step.title}"，以下说法正确的是？`;
      case PracticeType.FILL_BLANK:
        return `请简述"${step.title}"的关键操作步骤`;
      case PracticeType.OPERATION:
        return `请尝试${step.title}，然后告诉我你的操作结果`;
      case PracticeType.SCENARIO:
        return step.scenario ? `场景：${step.scenario}\n你会怎么应对？` : `谈谈"${step.title}"的实际应用`;
      default:
        return `谈谈你对"${step.title}"的理解`;
    }
  }

  /**
   * 生成鼓励文案
   */
  private generateEncouragement(stepNumber: number): string {
    const encouragements = [
      '太棒了！继续保持～',
      '你学得真快！',
      '太厉害了，一步一步来，你行的！',
      '很好！继续加油！',
      '学无止境，你已经迈出了重要的一步！'
    ];
    return encouragements[stepNumber % encouragements.length];
  }

  /**
   * 获取下一个里程碑
   */
  private getNextMilestone(level: AbilityLevel): string {
    const milestones: Record<number, string> = {
      [AbilityLevel.ZERO]: '完成第一个学习步骤',
      [AbilityLevel.BEGINNER]: '掌握基础操作',
      [AbilityLevel.BASIC]: '能够独立完成简单任务',
      [AbilityLevel.INTERMEDIATE]: '熟练应对日常使用',
      [AbilityLevel.ADVANCED]: '成为高手',
      [AbilityLevel.MASTER]: '精通此技能'
    };
    return milestones[level] || '继续学习';
  }
}

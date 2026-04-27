/**
 * ============================================================================
 * 小艺・全场景生活实践能力教学智能体【核心引擎】
 * 基于 FamilyEngine 重构，从"任务分配"转变为"教学引导"
 * 
 * 核心能力：教学意图识别 + 能力图谱 + 学习路径规划 + 练习推荐 + 激励系统
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

// ====================== 1. 常量配置 ======================

/** 教学场景类型 */
enum TeachSceneType {
  SKILL_LEARN = 'skill_learn',       // 技能学习
  REVIEW = 'review',                 // 复习
  PRACTICE = 'practice',             // 练习
  ASSESSMENT = 'assessment',         // 测评
  QUESTION = 'question'              // 问答
}

/** 能力等级 */
enum AbilityLevel {
  ZERO = 0,      // 完全不会
  BEGINNER = 1,  // 入门
  BASIC = 2,     // 基础
  INTERMEDIATE = 3, // 中级
  ADVANCED = 4,  // 高级
  MASTER = 5    // 精通
}

/** 内置技能库 */
const SKILL_LIBRARY = [
  {
    id: 'excel_basic',
    name: 'Excel基础',
    category: 'office',
    difficulty: 1,
    prerequisites: [],
    description: '学习Excel的基本操作，包括单元格输入、公式使用、数据格式化等'
  },
  {
    id: 'excel_pivot',
    name: 'Excel数据透视表',
    category: 'office',
    difficulty: 2,
    prerequisites: ['excel_basic'],
    description: '掌握数据透视表的创建和使用，进行快速数据分析'
  },
  {
    id: 'excel_chart',
    name: 'Excel图表制作',
    category: 'office',
    difficulty: 2,
    prerequisites: ['excel_basic'],
    description: '学习创建各类图表，让数据可视化'
  },
  {
    id: 'wechat_basic',
    name: '微信使用',
    category: 'life',
    difficulty: 1,
    prerequisites: [],
    description: '掌握微信的基本功能，包括聊天、发朋友圈、支付等'
  },
  {
    id: 'harmony_share',
    name: '鸿蒙设备协同',
    category: 'digital',
    difficulty: 2,
    prerequisites: ['wechat_basic'],
    description: '学会在鸿蒙设备间无缝协同工作'
  }
];

// ====================== 2. 核心接口 ======================

/**
 * 教学意图
 */
interface TeachIntent {
  rawText: string;                  // 原始文本
  scene: TeachSceneType;            // 教学场景
  skillId?: string;                 // 目标技能ID
  skillName?: string;                // 目标技能名
  currentStep?: number;              // 当前步骤
  confidence: number;                // 置信度
  needsClarification: boolean;      // 是否需要追问
  clarificationQuestion?: string;     // 追问内容
  createdAt: number;                // 创建时间
}

/**
 * 学习步骤
 */
interface LearningStep {
  stepNumber: number;              // 步骤序号
  title: string;                  // 步骤标题
  content: string;                 // 讲解内容
  practiceType: PracticeType;      // 练习类型
  difficulty: number;              // 难度 1-5
  estimatedTime: number;           // 预计时间（分钟）
  tip?: string;                    // 小贴士
}

/**
 * 练习类型
 */
enum PracticeType {
  MULTIPLE_CHOICE = 'multiple_choice',   // 选择题
  FILL_BLANK = 'fill_blank',             // 填空题
  OPERATION = 'operation',               // 操作题
  DISCUSSION = 'discussion'               // 讨论题
}

/**
 * 练习
 */
interface Practice {
  id: string;
  stepNumber: number;
  type: PracticeType;
  question: string;
  options?: string[];              // 选项（选择题）
  answer: string;                  // 正确答案
  hint?: string;                   // 提示
  explanation?: string;             // 解析
}

/**
 * 学习路径
 */
interface LearningPath {
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
interface LearningResult {
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
interface AbilityAssessment {
  skillId: string;
  skillName: string;
  currentLevel: AbilityLevel;
  weakPoints: string[];            // 薄弱点
  strongPoints: string[];         // 强项
  recommendedReview: string[];    // 推荐复习
  nextMilestone: string;          // 下一个里程碑
}

// ====================== 3. 学习引擎类 ======================

export class LearningEngine {
  private static instance: LearningEngine | null = null;
  
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
    HiLog.info("LearningEngine", "学习引擎初始化");
  }

  /**
   * 初始化
   */
  async init(): Promise<void> {
    HiLog.info("LearningEngine", "学习引擎启动");
    // 加载用户能力数据
    await this.loadUserAbilities();
  }

  /**
   * 解析教学意图
   * 核心方法：将用户输入转为结构化教学意图
   */
  parseTeachIntent(
    text: string,
    context?: { lastSkillId?: string, step?: number }
  ): TeachIntent {
    const now = Date.now();
    const lowerText = text.toLowerCase();
    
    // 1. 判断教学场景
    let scene = this.classifyScene(lowerText);
    
    // 2. 识别目标技能
    let skillId = this.identifySkill(lowerText);
    let skillName = this.getSkillName(skillId);
    
    // 3. 处理上下文延续
    if (!skillId && context?.lastSkillId) {
      skillId = context.lastSkillId;
      skillName = this.getSkillName(skillId);
    }
    
    // 4. 判断是否需要追问
    let needsClarification = false;
    let clarificationQuestion: string | undefined;
    
    if (!skillId) {
      needsClarification = true;
      clarificationQuestion = "您想学习什么技能呢？比如：Excel、微信、鸿蒙协同等";
    }
    
    const intent: TeachIntent = {
      rawText: text,
      scene,
      skillId,
      skillName,
      confidence: skillId ? 0.85 : 0.5,
      needsClarification,
      clarificationQuestion,
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
      abilityDelta = correct ? 0.1 : 0.02;
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
    if (text.includes('教我') || text.includes('学') || text.includes('了解')) {
      return TeachSceneType.SKILL_LEARN;
    }
    if (text.includes('怎么') || text.includes('如何') || text.includes('？')) {
      return TeachSceneType.QUESTION;
    }
    return TeachSceneType.SKILL_LEARN;
  }

  /**
   * 识别技能
   */
  private identifySkill(text: string): string | undefined {
    const skillMap: Record<string, string[]> = {
      'excel_basic': ['excel基础', 'excel基本', 'excel'],
      'excel_pivot': ['数据透视表', '透视表', 'excel透视'],
      'excel_chart': ['图表', 'excel图表', '数据可视化'],
      'wechat_basic': ['微信', '微信使用', '微信基础'],
      'harmony_share': ['鸿蒙协同', '设备协同', '鸿蒙']
    };
    
    for (const [skillId, keywords] of Object.entries(skillMap)) {
      if (keywords.some(kw => text.includes(kw))) {
        return skillId;
      }
    }
    return undefined;
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
   * 加载用户能力数据（实际应从数据库加载）
   */
  private async loadUserAbilities(): Promise<void> {
    // TODO: 从分布式数据库加载
    HiLog.info("LearningEngine", "加载用户能力数据");
  }

  /**
   * 生成学习步骤
   */
  private generateLearningSteps(skill: any, startLevel: AbilityLevel): LearningStep[] {
    // 根据技能生成对应步骤
    const stepTemplates: Record<string, LearningStep[]> = {
      'excel_basic': [
        { stepNumber: 1, title: '认识Excel界面', content: 'Excel是一个表格软件，由行和列组成...', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 5, tip: '行是横的，列是竖的' },
        { stepNumber: 2, title: '单元格操作', content: '点击单元格就能输入内容...', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 8, tip: '输入完按回车确认' },
        { stepNumber: 3, title: '简单公式', content: '用=开头写公式，比如=SUM(A1:A10)...', practiceType: PracticeType.FILL_BLANK, difficulty: 2, estimatedTime: 10, tip: '公式要用等号开头' },
        { stepNumber: 4, title: '格式设置', content: '可以设置字体、颜色、边框等...', practiceType: PracticeType.MULTIPLE_CHOICE, difficulty: 1, estimatedTime: 5 }
      ],
      'wechat_basic': [
        { stepNumber: 1, title: '添加好友', content: '点击右上角+号，选择添加朋友...', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 5, tip: '可以扫码添加' },
        { stepNumber: 2, title: '发送消息', content: '在聊天框输入文字，点击发送...', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 3, tip: '长按可撤回' },
        { stepNumber: 3, title: '发朋友圈', content: '点击朋友圈入口，点击右上角相机...', practiceType: PracticeType.OPERATION, difficulty: 1, estimatedTime: 5 },
        { stepNumber: 4, title: '使用支付', content: '我->支付，可以付款、收款...', practiceType: PracticeType.MULTIPLE_CHOICE, difficulty: 2, estimatedTime: 8, tip: '支付密码要记牢' }
      ]
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
      answer: '正确',  // 简化版
      hint: step.tip
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

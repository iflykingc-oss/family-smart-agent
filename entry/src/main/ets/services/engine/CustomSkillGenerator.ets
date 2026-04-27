/**
 * ============================================================================
 * 用户自定义技能生成服务 - CustomSkillGenerator
 * 核心差异化：用户自定义技能生成模块
 * 
 * 功能：
 * - 用户通过自然语言提交学习需求
 * - 系统实时生成标准化教学内容
 * - 适配双角色互动、随堂问答、跨端流转
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 技能难度
 */
export enum SkillDifficulty {
  BEGINNER = 1,    // 入门
  INTERMEDIKE = 2, // 进阶
  ADVANCED = 3     // 高级
}

/**
 * 教学步骤
 */
export interface TeachingStep {
  stepNumber: number;
  title: string;          // 步骤标题
  content: string;        // 讲解内容（≤30字）
  keyPoint: string;        // 易错点提示（≤30字）
  safetyTip?: string;     // 安全规范提示
  giphyUrl?: string;      // 动漫素材URL
  duration: number;       // 预计时长（秒）
}

/**
 * 自定义技能请求
 */
export interface CustomSkillRequest {
  userId: string;
  rawRequest: string;     // 用户原始需求
  targetDevice?: 'phone' | 'watch' | 'smartScreen' | 'car';
  preferSpeed?: 'slow' | 'normal' | 'fast';
  preferMode?: 'normal' | 'elder' | 'child' | 'newbie';
}

/**
 * 自定义技能
 */
export interface CustomSkill {
  id: string;
  name: string;
  category: string;
  difficulty: SkillDifficulty;
  steps: TeachingStep[];
  totalDuration: number;   // 总时长（秒）
  quizQuestion: QuizQuestion;
  compliance: boolean;
  createdAt: number;
}

/**
 * 随堂巩固题
 */
export interface QuizQuestion {
  question: string;        // 题目（≤50字）
  correctAnswer: boolean;    // 判断题答案
  correctFeedback: string;  // 正确点评（≤2句话）
  incorrectFeedback: string; // 错误点评（≤2句话）
}

/**
 * 合规检查结果
 */
export interface ComplianceResult {
  passed: boolean;
  blockReason?: string;
  suggestion?: string;
}

/**
 * 内容模式
 */
export interface AdaptMode {
  mode: 'normal' | 'elder' | 'child' | 'newbie';
  speechRate: number;       // 语速倍率
  stepDetailLevel: number;   // 步骤拆分粒度（1-5）
  extraSafetyTip: boolean;
  fontSize?: number;         // 字体大小倍率
  emojiLevel: 'none' | 'some' | 'many';
}

/**
 * 内容生成器
 */
export class ContentGenerator {
  // 内置技能库
  private static SKILL_TEMPLATES: Record<string, {
    category: string;
    steps: string[];
    keywords: string[];
    safetyTips: string[];
  }> = {
    'excel': {
      category: '办公',
      steps: ['打开Excel', '新建工作簿', '输入数据', '简单公式', '保存文件'],
      keywords: ['excel', '表格', '电子表格', '数据处理'],
      safetyTips: ['注意保存文件', '小心误删数据', '重要文件多备份']
    },
    'wechat': {
      category: '社交',
      steps: ['打开微信', '添加好友', '发送消息', '发朋友圈', '使用支付'],
      keywords: ['微信', 'wechat', '朋友圈', '微信支付'],
      safetyTips: ['不要轻易转账陌生人', '保护隐私']
    },
    'cooking': {
      category: '生活',
      steps: ['准备食材', '处理食材', '烹饪步骤', '调味', '出锅装盘'],
      keywords: ['做菜', '做饭', '烹饪', '红烧肉', '炒菜', '家常菜'],
      safetyTips: ['注意用火安全', '刀具小心使用', '热的锅不要直接用手碰']
    },
    'health': {
      category: '健康',
      steps: ['识别症状', '查找原因', '处理方法', '注意事项', '何时就医'],
      keywords: ['急救', '健康', '保健', '养生', '锻炼'],
      safetyTips: ['情况严重要及时就医', '仅供参考，不作为医疗建议']
    }
  };

  /**
   * 校验用户请求的合规性
   */
  static checkCompliance(request: string): ComplianceResult {
    const lower = request.toLowerCase();
    
    // 合规红线检查
    const blocked = ['医疗', '治病', '开药', 'K12', '补课', '学科', '考试', '作文', '作业帮', '金融投资', '股票', '法律咨询', '律师'];
    
    for (const keyword of blocked) {
      if (lower.includes(keyword)) {
        return {
          passed: false,
          blockReason: `暂不支持${keyword}类内容`,
          suggestion: '请问换个其他生活技能学习需求？比如"教我做红烧肉"、"教我用微信支付"等'
        };
      }
    }
    
    return { passed: true };
  }

  /**
   * 识别用户意图
   */
  static identifyIntent(request: string): { type: 'preset' | 'custom'; matchedTemplate?: string; newSkillName?: string } {
    const lower = request.toLowerCase();
    
    // 尝试匹配内置模板
    for (const [key, template] of Object.entries(this.SKILL_TEMPLATES)) {
      for (const kw of template.keywords) {
        if (lower.includes(kw)) {
          return { type: 'preset', matchedTemplate: key };
        }
      }
    }
    
    // 自定义技能
    return { type: 'custom', newSkillName: request };
  }

  /**
   * 生成自定义技能
   */
  static generateCustomSkill(request: CustomSkillRequest): CustomSkill {
    const compliance = this.checkCompliance(request.rawRequest);
    if (!compliance.passed) {
      throw new Error(compliance.blockReason);
    }
    
    const intent = this.identifyIntent(request.rawRequest);
    const mode = this.getAdaptMode(request.preferMode || 'normal');
    
    if (intent.type === 'preset' && intent.matchedTemplate) {
      return this.generateFromTemplate(intent.matchedTemplate, request);
    }
    
    return this.generateFromScratch(intent.newSkillName || request.rawRequest, mode);
  }

  /**
   * 获取适配模式
   */
  private static getAdaptMode(mode: 'normal' | 'elder' | 'child' | 'newbie'): AdaptMode {
    const modes: Record<string, AdaptMode> = {
      normal: { mode: 'normal', speechRate: 1.0, stepDetailLevel: 3, extraSafetyTip: false, emojiLevel: 'some' },
      elder: { mode: 'elder', speechRate: 0.5, stepDetailLevel: 5, extraSafetyTip: true, fontSize: 1.5, emojiLevel: 'many' },
      child: { mode: 'child', speechRate: 1.0, stepDetailLevel: 4, extraSafetyTip: true, emojiLevel: 'many' },
      newbie: { mode: 'newbie', speechRate: 0.8, stepDetailLevel: 5, extraSafetyTip: true, emojiLevel: 'some' }
    };
    return modes[mode] || modes.normal;
  }

  /**
   * 从模板生成技能
   */
  private static generateFromTemplate(templateKey: string, request: CustomSkillRequest): CustomSkill {
    const template = this.SKILL_TEMPLATES[templateKey];
    const mode = this.getAdaptMode(request.preferMode || 'normal');
    
    const steps: TeachingStep[] = template.steps.map((title, idx) => ({
      stepNumber: idx + 1,
      title: this.adaptText(title, mode),
      content: this.adaptText(`学习${title}`, mode),
      keyPoint: template.safetyTips[idx % template.safetyTips.length],
      duration: this.getStepDuration(mode)
    }));
    
    const quiz = this.generateQuiz(template.steps[0]);
    
    return {
      id: `skill_${Date.now()}`,
      name: template.category,
      category: template.category,
      difficulty: SkillDifficulty.BEGINNER,
      steps,
      totalDuration: steps.length * 30,
      quizQuestion: quiz,
      compliance: true,
      createdAt: Date.now()
    };
  }

  /**
   * 从零生成自定义技能
   */
  private static generateFromScratch(skillName: string, mode: AdaptMode): CustomSkill {
    // 通用步骤生成
    const genericSteps = ['准备', '操作', '检查', '收尾'];
    const steps: TeachingStep[] = genericSteps.map((title, idx) => ({
      stepNumber: idx + 1,
      title: this.adaptText(title, mode),
      content: this.adaptText(`学习${title}`, mode),
      keyPoint: '注意安全，仔细操作',
      duration: this.getStepDuration(mode)
    }));
    
    return {
      id: `custom_${Date.now()}`,
      name: skillName,
      category: '自定义',
      difficulty: SkillDifficulty.BEGINNER,
      steps,
      totalDuration: steps.length * 30,
      quizQuestion: this.generateQuiz(skillName),
      compliance: true,
      createdAt: Date.now()
    };
  }

  /**
   * 文本适配
   */
  private static adaptText(text: string, mode: AdaptMode): string {
    let adapted = text;
    
    if (mode.speechRate <= 0.6) {
      // 老年模式：文字简化
      adapted = `[慢速讲解] ${text}`;
    }
    
    if (mode.stepDetailLevel >= 5) {
      // 详细模式：增加引导词
      adapted = `别着急，我们来学习：${text}`;
    }
    
    return adapted;
  }

  /**
   * 获取步骤时长
   */
  private static getStepDuration(mode: AdaptMode): number {
    const base = 30;
    return Math.round(base * mode.speechRate * 2);
  }

  /**
   * 生成随堂题
   */
  private static generateQuiz(skillName: string): QuizQuestion {
    return {
      question: `以上${skillName}的步骤，你学会了吗？`,
      correctAnswer: true,
      correctFeedback: '太棒了！继续保持',
      incorrectFeedback: '没关系，再看一遍步骤吧'
    };
  }
}

/**
 * 用户自定义技能服务
 */
export class CustomSkillService {
  private static instance: CustomSkillService | null = null;
  
  private customSkills: Map<string, CustomSkill[]> = new Map();

  static getInstance(): CustomSkillService {
    if (!CustomSkillService.instance) {
      CustomSkillService.instance = new CustomSkillService();
    }
    return CustomSkillService.instance;
  }

  private constructor() {
    HiLog.info("CustomSkillService", "用户自定义技能服务初始化");
  }

  /**
   * 处理用户自定义技能请求
   */
  handleUserRequest(request: CustomSkillRequest): CustomSkill | ComplianceResult {
    HiLog.info("CustomSkillService", `处理请求: ${request.rawRequest}`);
    
    try {
      const skill = ContentGenerator.generateCustomSkill(request);
      this.saveSkill(request.userId, skill);
      return skill;
    } catch (error: any) {
      HiLog.warn("CustomSkillService", `合规拦截: ${error.message}`);
      return {
        passed: false,
        blockReason: error.message,
        suggestion: '请换个生活技能学习需求'
      };
    }
  }

  /**
   * 保存用户自定义技能
   */
  private saveSkill(userId: string, skill: CustomSkill): void {
    const userSkills = this.customSkills.get(userId) || [];
    userSkills.push(skill);
    this.customSkills.set(userId, userSkills);
    HiLog.info("CustomSkillService", `保存技能: ${skill.name}`);
  }

  /**
   * 获取用户历史技能
   */
  getUserSkills(userId: string): CustomSkill[] {
    return this.customSkills.get(userId) || [];
  }
}

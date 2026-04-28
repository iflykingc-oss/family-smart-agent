/**
 * ============================================================================
 * 微课程引擎 - MicroLessonEngine
 * 借鉴多邻国（Duolingo）微课程设计
 * 
 * 核心设计：
 * 1. 5 分钟微课程 - 碎片化学习
 * 2. 即时反馈 - 对/错 + 解析
 * 3. 渐进式难度 - 简单→中等→困难
 * 4. 错误重复 - 错题反复出现
 * 5. 情感化文案 - 鼓励、安慰、调侃
 * 
 * 借鉴多邻国：
 * - 短平快学习（5 分钟一课）
 * - 即时反馈（对/错 + 音效 + 动画）
 * - 渐进式难度（简单→中等→困难）
 * - 情感化文案（鼓励、安慰、调侃）
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

const TAG = 'MicroLessonEngine';

/**
 * 微课程
 */
export interface MicroLesson {
  /** 课程 ID */
  id: string;
  
  /** 课程标题 */
  title: string;
  
  /** 课程描述 */
  description: string;
  
  /** 预计时长（分钟） */
  duration: number;
  
  /** 难度等级 */
  difficulty: 'easy' | 'medium' | 'hard';
  
  /** 课程步骤 */
  steps: LessonStep[];
  
  /** 当前步骤 */
  currentStep: number;
  
  /** 是否正确 */
  isCorrect: boolean;
  
  /** 获得经验值 */
  xpReward: number;
}

/**
 * 课程步骤
 */
export interface LessonStep {
  /** 步骤序号 */
  stepNumber: number;
  
  /** 步骤类型 */
  type: LessonStepType;
  
  /** 问题/内容 */
  content: string;
  
  /** 选项（选择题） */
  options?: string[];
  
  /** 正确答案 */
  answer: string;
  
  /** 用户答案 */
  userAnswer?: string;
  
  /** 是否正确 */
  isCorrect?: boolean;
  
  /** 解析 */
  explanation: string;
  
  /** 提示 */
  hint?: string;
}

/**
 * 步骤类型
 */
export enum LessonStepType {
  /** 选择题 */
  MULTIPLE_CHOICE = 'multiple_choice',
  
  /** 判断题 */
  TRUE_FALSE = 'true_false',
  
  /** 填空题 */
  FILL_BLANK = 'fill_blank',
  
  /** 排序题 */
  SORT = 'sort',
  
  /** 匹配题 */
  MATCH = 'match',
  
  /** 操作题 */
  OPERATION = 'operation',
  
  /** 讲解 */
  LECTURE = 'lecture',
}

/**
 * 学习结果
 */
export interface LessonResult {
  /** 课程 ID */
  lessonId: string;
  
  /** 总步骤数 */
  totalSteps: number;
  
  /** 正确步骤数 */
  correctSteps: number;
  
  /** 正确率 */
  accuracy: number;
  
  /** 获得经验值 */
  xpGained: number;
  
  /** 获得金币 */
  coinsGained: number;
  
  /** 评级 */
  rating: 'S' | 'A' | 'B' | 'C' | 'D';
  
  /** 学习时长（秒） */
  studyTime: number;
}

/**
 * 微课程引擎
 */
export class MicroLessonEngine {
  private static instance: MicroLessonEngine | null = null;
  
  // 课程库
  private lessons: Map<string, MicroLesson>;
  
  // 当前课程
  private currentLesson: MicroLesson | null;
  
  // 错题本
  private wrongAnswers: Map<string, LessonStep[]>;
  
  // 学习记录
  private studyHistory: LessonResult[];

  static getInstance(): MicroLessonEngine {
    if (!MicroLessonEngine.instance) {
      MicroLessonEngine.instance = new MicroLessonEngine();
    }
    return MicroLessonEngine.instance;
  }

  private constructor() {
    this.lessons = new Map();
    this.currentLesson = null;
    this.wrongAnswers = new Map();
    this.studyHistory = [];
    this.initLessons();
    HiLog.info(TAG, '微课程引擎初始化（借鉴多邻国）');
  }

  /**
   * 初始化课程库
   */
  private initLessons(): void {
    // 沟通技巧基础课
    this.lessons.set('comm_basic_1', {
      id: 'comm_basic_1',
      title: '倾听的艺术',
      description: '学习有效沟通的第一步：倾听',
      duration: 5,
      difficulty: 'easy',
      currentStep: 0,
      isCorrect: false,
      xpReward: 20,
      steps: [
        {
          stepNumber: 1,
          type: LessonStepType.LECTURE,
          content: '有效沟通的第一步是倾听。不要急着说话，先听对方说完，用眼神和点头表示你在听。',
          answer: '',
          explanation: '倾听比表达更重要。研究表明，人们在沟通中 40% 的时间在倾听。'
        },
        {
          stepNumber: 2,
          type: LessonStepType.MULTIPLE_CHOICE,
          content: '以下哪项是有效倾听的表现？',
          options: ['A. 打断对方说话', 'B. 用眼神和点头表示在听', 'C. 想着怎么反驳', 'D. 看手机'],
          answer: 'B',
          explanation: '有效倾听需要用眼神和点头表示你在听，不要打断对方。'
        },
        {
          stepNumber: 3,
          type: LessonStepType.TRUE_FALSE,
          content: '倾听就是保持沉默，不需要任何反应。（判断对错）',
          answer: '错',
          explanation: '倾听不是沉默，是主动理解。需要用眼神、点头、简短回应表示你在听。'
        },
        {
          stepNumber: 4,
          type: LessonStepType.MULTIPLE_CHOICE,
          content: '当同事向你抱怨工作压力时，你应该？',
          options: ['A. 立即给建议', 'B. 先倾听，理解他的感受', 'C. 转移话题', 'D. 说自己更累'],
          answer: 'B',
          explanation: '先倾听，理解对方的感受，再给建议。不要急于解决问题。'
        },
        {
          stepNumber: 5,
          type: LessonStepType.LECTURE,
          content: '记住：倾听的核心是"先理解别人，再被理解"。',
          answer: '',
          explanation: '这是史蒂芬·柯维在《高效能人士的七个习惯》中提出的原则。'
        }
      ]
    });

    // 时间管理基础课
    this.lessons.set('time_mgmt_1', {
      id: 'time_mgmt_1',
      title: '四象限法则',
      description: '学习时间管理的核心方法：四象限法则',
      duration: 5,
      difficulty: 'easy',
      currentStep: 0,
      isCorrect: false,
      xpReward: 25,
      steps: [
        {
          stepNumber: 1,
          type: LessonStepType.LECTURE,
          content: '四象限法则是时间管理的核心方法。把任务分为：重要且紧急、重要不紧急、紧急不重要、不紧急不重要。',
          answer: '',
          explanation: '四象限法则由史蒂芬·柯维提出，核心是优先做"重要不紧急"的事。'
        },
        {
          stepNumber: 2,
          type: LessonStepType.MULTIPLE_CHOICE,
          content: '以下哪项属于"重要不紧急"的任务？',
          options: ['A. 明天要交的报表', 'B. 学习新技能', 'C. 回复紧急邮件', 'D. 刷社交媒体'],
          answer: 'B',
          explanation: '学习新技能是重要不紧急的任务，应该优先安排时间。'
        },
        {
          stepNumber: 3,
          type: LessonStepType.SORT,
          content: '请将以下任务按优先级排序：',
          options: ['重要且紧急', '重要不紧急', '紧急不重要', '不紧急不重要'],
          answer: '重要且紧急 > 重要不紧急 > 紧急不重要 > 不紧急不重要',
          explanation: '优先级：重要且紧急 > 重要不紧急 > 紧急不重要 > 不紧急不重要'
        },
        {
          stepNumber: 4,
          type: LessonStepType.TRUE_FALSE,
          content: '应该优先做"紧急不重要"的任务。（判断对错）',
          answer: '错',
          explanation: '应该优先做"重要不紧急"的任务，而不是"紧急不重要"的任务。'
        },
        {
          stepNumber: 5,
          type: LessonStepType.LECTURE,
          content: '记住：把时间花在"重要不紧急"的事上，才能避免变成"重要且紧急"的危机。',
          answer: '',
          explanation: '这是时间管理的核心原则。预防胜于治疗。'
        }
      ]
    });

    // 面试技巧课
    this.lessons.set('interview_1', {
      id: 'interview_1',
      title: 'STAR 法则',
      description: '学习面试核心技巧：STAR 法则',
      duration: 5,
      difficulty: 'medium',
      currentStep: 0,
      isCorrect: false,
      xpReward: 30,
      steps: [
        {
          stepNumber: 1,
          type: LessonStepType.LECTURE,
          content: 'STAR 法是面试核心技巧：Situation（情境）→ Task（任务）→ Action（行动）→ Result（结果）。',
          answer: '',
          explanation: 'STAR 法则帮助结构化回答面试问题，让回答更有说服力。'
        },
        {
          stepNumber: 2,
          type: LessonStepType.MULTIPLE_CHOICE,
          content: 'STAR 法则中的"A"代表什么？',
          options: ['A. Analysis（分析）', 'B. Action（行动）', 'C. Achievement（成就）', 'D. Answer（回答）'],
          answer: 'B',
          explanation: 'A 代表 Action（行动），即你采取了什么具体行动。'
        },
        {
          stepNumber: 3,
          type: LessonStepType.MULTIPLE_CHOICE,
          content: '使用 STAR 法则回答"说说你的项目经验"，第一步应该说什么？',
          options: ['A. 结果（Result）', 'B. 行动（Action）', 'C. 情境（Situation）', 'D. 任务（Task）'],
          answer: 'C',
          explanation: '第一步是 Situation（情境），描述项目背景。'
        },
        {
          stepNumber: 4,
          type: LessonStepType.TRUE_FALSE,
          content: 'STAR 法则中的 Result 可以用模糊描述，不需要数据。（判断对错）',
          answer: '错',
          explanation: 'Result 必须用数据量化，比如"用户增长 50%"，而不是"用户增长了很多"。'
        },
        {
          stepNumber: 5,
          type: LessonStepType.LECTURE,
          content: '记住：STAR 法则的核心是"用数据说话"，让面试官看到你的价值。',
          answer: '',
          explanation: '数据化的结果比模糊的描述更有说服力。'
        }
      ]
    });
  }

  /**
   * 开始微课程
   */
  startLesson(lessonId: string): MicroLesson | null {
    const lesson = this.lessons.get(lessonId);
    if (!lesson) {
      HiLog.error(TAG, `课程不存在: ${lessonId}`);
      return null;
    }
    
    // 重置课程状态
    lesson.currentStep = 0;
    lesson.steps.forEach(step => {
      step.userAnswer = undefined;
      step.isCorrect = undefined;
    });
    
    this.currentLesson = lesson;
    
    HiLog.info(TAG, `开始微课程: ${lesson.title}`);
    return lesson;
  }

  /**
   * 获取当前步骤
   */
  getCurrentStep(): LessonStep | null {
    if (!this.currentLesson) return null;
    
    const stepIndex = this.currentLesson.currentStep;
    if (stepIndex >= this.currentLesson.steps.length) {
      return null;
    }
    
    return this.currentLesson.steps[stepIndex];
  }

  /**
   * 提交答案
   */
  submitAnswer(answer: string): {
    isCorrect: boolean;
    explanation: string;
    isLastStep: boolean;
  } {
    if (!this.currentLesson) {
      return { isCorrect: false, explanation: '课程未开始', isLastStep: true };
    }
    
    const step = this.getCurrentStep();
    if (!step) {
      return { isCorrect: false, explanation: '没有更多步骤', isLastStep: true };
    }
    
    // 记录答案
    step.userAnswer = answer;
    
    // 判断对错
    const isCorrect = this.checkAnswer(step, answer);
    step.isCorrect = isCorrect;
    
    // 记录错题
    if (!isCorrect) {
      this.addWrongAnswer(this.currentLesson.id, step);
    }
    
    // 进入下一步
    this.currentLesson.currentStep++;
    
    const isLastStep = this.currentLesson.currentStep >= this.currentLesson.steps.length;
    
    HiLog.info(TAG, `提交答案: 步骤${step.stepNumber}, ${isCorrect ? '正确' : '错误'}`);
    
    return {
      isCorrect,
      explanation: step.explanation,
      isLastStep
    };
  }

  /**
   * 检查答案
   */
  private checkAnswer(step: LessonStep, answer: string): boolean {
    switch (step.type) {
      case LessonStepType.MULTIPLE_CHOICE:
        return answer.trim().toUpperCase() === step.answer.trim().toUpperCase();
      case LessonStepType.TRUE_FALSE:
        return answer.trim() === step.answer.trim();
      case LessonStepType.FILL_BLANK:
        return answer.trim().toLowerCase().includes(step.answer.trim().toLowerCase());
      default:
        return true; // 讲解步骤默认正确
    }
  }

  /**
   * 添加错题
   */
  private addWrongAnswer(lessonId: string, step: LessonStep): void {
    if (!this.wrongAnswers.has(lessonId)) {
      this.wrongAnswers.set(lessonId, []);
    }
    this.wrongAnswers.get(lessonId)!.push(step);
  }

  /**
   * 完成课程
   */
  completeLesson(): LessonResult | null {
    if (!this.currentLesson) return null;
    
    const steps = this.currentLesson.steps;
    const correctSteps = steps.filter(s => s.isCorrect !== false).length;
    const totalSteps = steps.length;
    const accuracy = totalSteps > 0 ? correctSteps / totalSteps : 0;
    
    // 计算经验值
    const xpGained = Math.floor(this.currentLesson.xpReward * accuracy);
    const coinsGained = Math.floor(xpGained / 10);
    
    // 评级
    let rating: 'S' | 'A' | 'B' | 'C' | 'D';
    if (accuracy >= 0.95) rating = 'S';
    else if (accuracy >= 0.85) rating = 'A';
    else if (accuracy >= 0.75) rating = 'B';
    else if (accuracy >= 0.6) rating = 'C';
    else rating = 'D';
    
    const result: LessonResult = {
      lessonId: this.currentLesson.id,
      totalSteps,
      correctSteps,
      accuracy,
      xpGained,
      coinsGained,
      rating,
      studyTime: this.currentLesson.duration * 60,
    };
    
    // 记录学习历史
    this.studyHistory.push(result);
    
    HiLog.info(TAG, `课程完成: ${this.currentLesson.title}, 评级: ${rating}, +${xpGained}XP`);
    
    // 重置当前课程
    this.currentLesson = null;
    
    return result;
  }

  /**
   * 获取错题本
   */
  getWrongAnswers(lessonId?: string): LessonStep[] {
    if (lessonId) {
      return this.wrongAnswers.get(lessonId) || [];
    }
    
    // 返回所有错题
    const allWrong: LessonStep[] = [];
    this.wrongAnswers.forEach(steps => {
      allWrong.push(...steps);
    });
    return allWrong;
  }

  /**
   * 获取推荐课程（基于错题和水平）
   */
  getRecommendedLessons(userId: string): MicroLesson[] {
    // 优先推荐错题相关的课程
    const wrongLessonIds = Array.from(this.wrongAnswers.keys());
    
    if (wrongLessonIds.length > 0) {
      return wrongLessonIds
        .map(id => this.lessons.get(id))
        .filter((l): l is MicroLesson => l !== undefined);
    }
    
    // 否则推荐新课程
    return Array.from(this.lessons.values())
      .filter(l => l.difficulty === 'easy')
      .slice(0, 3);
  }

  /**
   * 获取所有课程
   */
  getAllLessons(): MicroLesson[] {
    return Array.from(this.lessons.values());
  }

  /**
   * 按难度获取课程
   */
  getLessonsByDifficulty(difficulty: 'easy' | 'medium' | 'hard'): MicroLesson[] {
    return Array.from(this.lessons.values()).filter(l => l.difficulty === difficulty);
  }

  /**
   * 获取学习统计
   */
  getStudyStats(): {
    totalLessons: number;
    completedLessons: number;
    averageAccuracy: number;
    totalXP: number;
  } {
    const totalLessons = this.lessons.size;
    const completedLessons = this.studyHistory.length;
    const averageAccuracy = this.studyHistory.length > 0
      ? this.studyHistory.reduce((sum, r) => sum + r.accuracy, 0) / this.studyHistory.length
      : 0;
    const totalXP = this.studyHistory.reduce((sum, r) => sum + r.xpGained, 0);
    
    return {
      totalLessons,
      completedLessons,
      averageAccuracy,
      totalXP,
    };
  }
}

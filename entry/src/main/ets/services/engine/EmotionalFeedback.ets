/**
 * ============================================================================
 * 情感化反馈系统 - EmotionalFeedback
 * 借鉴多邻国（Duolingo）情感化文案设计
 * 
 * 核心设计：
 * 1. 鼓励文案 - 答对时的正向反馈
 * 2. 安慰文案 - 答错时的温暖安慰
 * 3. 调侃文案 - 连续答对/答错的幽默反馈
 * 4. 里程碑文案 - 达成成就时的庆祝
 * 5. 提醒文案 - 学习提醒的温情文案
 * 
 * 借鉴多邻国：
 * - 拟人化语气（像朋友一样说话）
 * - 情感化文案（鼓励、安慰、调侃）
 * - 场景化反馈（根据学习场景调整语气）
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

const TAG = 'EmotionalFeedback';

/**
 * 反馈类型
 */
export enum FeedbackType {
  /** 答对 */
  CORRECT = 'correct',
  
  /** 答错 */
  INCORRECT = 'incorrect',
  
  /** 连续答对 */
  CORRECT_STREAK = 'correct_streak',
  
  /** 连续答错 */
  INCORRECT_STREAK = 'incorrect_streak',
  
  /** 达成成就 */
  ACHIEVEMENT = 'achievement',
  
  /** 学习提醒 */
  REMINDER = 'reminder',
  
  /** 复习提醒 */
  REVIEW_REMINDER = 'review_reminder',
  
  /** 连胜提醒 */
  STREAK_REMINDER = 'streak_reminder',
  
  /** 鼓励继续 */
  ENCOURAGE = 'encourage',
}

/**
 * 情感化反馈系统
 */
export class EmotionalFeedback {
  private static instance: EmotionalFeedback | null = null;
  
  // 连续答对次数
  private correctStreaks: Map<string, number>;
  
  // 连续答错次数
  private incorrectStreaks: Map<string, number>;

  static getInstance(): EmotionalFeedback {
    if (!EmotionalFeedback.instance) {
      EmotionalFeedback.instance = new EmotionalFeedback();
    }
    return EmotionalFeedback.instance;
  }

  private constructor() {
    this.correctStreaks = new Map();
    this.incorrectStreaks = new Map();
    HiLog.info(TAG, '情感化反馈系统初始化（借鉴多邻国）');
  }

  /**
   * 获取反馈文案
   */
  getFeedback(type: FeedbackType, params?: Record<string, any>): string {
    switch (type) {
      case FeedbackType.CORRECT:
        return this.getCorrectFeedback(params);
      case FeedbackType.INCORRECT:
        return this.getIncorrectFeedback(params);
      case FeedbackType.CORRECT_STREAK:
        return this.getCorrectStreakFeedback(params);
      case FeedbackType.INCORRECT_STREAK:
        return this.getIncorrectStreakFeedback(params);
      case FeedbackType.ACHIEVEMENT:
        return this.getAchievementFeedback(params);
      case FeedbackType.REMINDER:
        return this.getReminderFeedback(params);
      case FeedbackType.REVIEW_REMINDER:
        return this.getReviewReminderFeedback(params);
      case FeedbackType.STREAK_REMINDER:
        return this.getStreakReminderFeedback(params);
      case FeedbackType.ENCOURAGE:
        return this.getEncourageFeedback(params);
      default:
        return '加油！';
    }
  }

  /**
   * 答对反馈（借鉴多邻国）
   */
  private getCorrectFeedback(params?: Record<string, any>): string {
    const correctMessages = [
      '太棒了！🎉',
      '完全正确！👏',
      '你学得真快！🌟',
      '回答正确！💯',
      '很好！继续保持～✨',
      '厉害！你真是个学习天才！🧠',
      '完美！💪',
      '答对了！你太聪明了！🎯',
      '正确！你的理解力很强！👍',
      '棒极了！🎊',
    ];
    
    return this.randomPick(correctMessages);
  }

  /**
   * 答错反馈（借鉴多邻国）
   */
  private getIncorrectFeedback(params?: Record<string, any>): string {
    const incorrectMessages = [
      '不太对哦～没关系，我们再来一次！💪',
      '答案不太对，但学习就是不断试错的过程～🌱',
      '差一点点！让我再解释一下～📚',
      '没关系，错误是学习的一部分！🌈',
      '别灰心！我们一起来看看正确答案～👀',
      '这次不对，但你已经进步了！📈',
      '没关系，记住这个知识点，下次就不会错了！📝',
      '答错了也没关系，重要的是学到了！🎓',
    ];
    
    return this.randomPick(incorrectMessages);
  }

  /**
   * 连续答对反馈（借鉴多邻国）
   */
  private getCorrectStreakFeedback(params?: Record<string, any>): string {
    const streak = params?.streak || 0;
    
    if (streak >= 10) {
      return '🔥🔥🔥 你已经连续答对 10 题了！你是天才吗？！🎉🎉🎉';
    }
    if (streak >= 7) {
      return '🔥🔥 连续答对 7 题！你的状态太好了！💪';
    }
    if (streak >= 5) {
      return '🔥 连续答对 5 题！你进入状态了！🌟';
    }
    if (streak >= 3) {
      return '连续答对 3 题！继续保持！✨';
    }
    
    return '连续答对！你太棒了！🎯';
  }

  /**
   * 连续答错反馈（借鉴多邻国）
   */
  private getIncorrectStreakFeedback(params?: Record<string, any>): string {
    const streak = params?.streak || 0;
    
    if (streak >= 5) {
      return '😢 连续答错 5 题了，要不我们先复习一下前面的内容？没关系，学习就是这样的～';
    }
    if (streak >= 3) {
      return '😅 连续答错 3 题了，这个知识点确实有点难。让我换个方式解释～';
    }
    
    return '没关系，这个知识点确实有点难。我们慢慢来～🌱';
  }

  /**
   * 成就达成反馈（借鉴多邻国）
   */
  private getAchievementFeedback(params?: Record<string, any>): string {
    const achievementName = params?.name || '成就';
    
    const messages = [
      `🎉 恭喜解锁成就"${achievementName}"！你太厉害了！`,
      `🏆 达成成就"${achievementName}"！你的努力得到了回报！`,
      `🌟 解锁新成就"${achievementName}"！继续加油！`,
      `💎 获得成就"${achievementName}"！你是学习达人！`,
    ];
    
    return this.randomPick(messages);
  }

  /**
   * 学习提醒反馈（借鉴多邻国）
   */
  private getReminderFeedback(params?: Record<string, any>): string {
    const userName = params?.name || '同学';
    const timeSinceLastStudy = params?.timeSinceLastStudy || 0;
    
    if (timeSinceLastStudy >= 7) {
      return `${userName}，你已经 7 天没学习了！想你了～今天学 5 分钟好吗？📚`;
    }
    if (timeSinceLastStudy >= 3) {
      return `${userName}，今天学习了吗？5 分钟也行哦～💪`;
    }
    
    return `${userName}，学习时间到啦！今天学点什么？🌟`;
  }

  /**
   * 复习提醒反馈（借鉴多邻国）
   */
  private getReviewReminderFeedback(params?: Record<string, any>): string {
    const skillName = params?.skillName || '这个技能';
    const daysSinceLastStudy = params?.daysSinceLastStudy || 0;
    
    if (daysSinceLastStudy >= 7) {
      return `📚 ${skillName} 已经 7 天没复习了，遗忘曲线提醒：该复习啦！温故知新哦～`;
    }
    if (daysSinceLastStudy >= 3) {
      return `📖 ${skillName} 该复习了！快速回顾一下，巩固记忆～`;
    }
    
    return `🔄 ${skillName} 的复习时间到了！来，快速过一遍～`;
  }

  /**
   * 连胜提醒反馈（借鉴多邻国）
   */
  private getStreakReminderFeedback(params?: Record<string, any>): string {
    const streak = params?.streak || 0;
    
    if (streak >= 30) {
      return `🏆 连续学习 30 天！你是真正的学习达人！继续保持！`;
    }
    if (streak >= 7) {
      return `🔥 连续学习 7 天！你的坚持让人佩服！`;
    }
    if (streak >= 3) {
      return `✨ 连续学习 3 天！好习惯正在养成！`;
    }
    
    return `💪 今天也要坚持学习哦！`;
  }

  /**
   * 鼓励继续反馈（借鉴多邻国）
   */
  private getEncourageFeedback(params?: Record<string, any>): string {
    const messages = [
      '加油！你离目标很近了！🎯',
      '坚持住！胜利就在前方！💪',
      '你已经很棒了！继续加油！🌟',
      '不要放弃！每一步都是进步！📈',
      '相信自己！你能行！🌈',
      '学习是一场马拉松，坚持就是胜利！🏃',
    ];
    
    return this.randomPick(messages);
  }

  /**
   * 随机选择
   */
  private randomPick(messages: string[]): string {
    return messages[Math.floor(Math.random() * messages.length)];
  }

  /**
   * 记录连续答对
   */
  recordCorrectStreak(userId: string): number {
    const streak = (this.correctStreaks.get(userId) || 0) + 1;
    this.correctStreaks.set(userId, streak);
    this.incorrectStreaks.set(userId, 0);
    return streak;
  }

  /**
   * 记录连续答错
   */
  recordIncorrectStreak(userId: string): number {
    const streak = (this.incorrectStreaks.get(userId) || 0) + 1;
    this.incorrectStreaks.set(userId, streak);
    this.correctStreaks.set(userId, 0);
    return streak;
  }

  /**
   * 获取连续答对次数
   */
  getCorrectStreak(userId: string): number {
    return this.correctStreaks.get(userId) || 0;
  }

  /**
   * 获取连续答错次数
   */
  getIncorrectStreak(userId: string): number {
    return this.incorrectStreaks.get(userId) || 0;
  }

  /**
   * 重置连续次数
   */
  resetStreaks(userId: string): void {
    this.correctStreaks.set(userId, 0);
    this.incorrectStreaks.set(userId, 0);
  }
}

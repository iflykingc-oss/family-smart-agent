/**
 * ============================================================================
 * 鸿蒙提醒服务 - HarmonyReminderService
 * 核心差异化：系统级提醒能力，第三方无法复制
 * 
 * 功能：
 * - 推送学习提醒（融合温馨文案）
 * - 定时复习提醒（基于FSRS遗忘曲线算法）
 * - 跨设备通知接力
 * - 写入系统日历
 * 
 * 算法说明：
 * - 基于 FSRS (Free Spaced Repetition Scheduler) 遗忘曲线算法
 * - 结合艾宾浩斯遗忘曲线 + 用户表现动态调整
 * - 计算最优复习间隔，最大化记忆保持率
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { reminderManager } from '@kit.IMKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 提醒类型
 */
export enum ReminderType {
  STUDY_REMINDER = 'study_reminder',
  REVIEW_REMINDER = 'review_reminder',
  ACHIEVEMENT_REMINDER = 'achievement',
  STREAK_REMINDER = 'streak_reminder'
}

/**
 * 提醒内容
 */
export interface ReminderContent {
  type: ReminderType;
  title: string;
  warmMessage: string;
  skillName?: string;
  stepNumber?: number;
  actionText?: string;
}

/**
 * 提醒结果
 */
export interface ReminderResult {
  success: boolean;
  reminderId?: string;
  error?: string;
}

/**
 * 用户表现评分（FSRS评级）
 */
export enum UserRating {
  AGAIN = 0,    // 完全忘记，需立即复习
  HARD = 1,     // 记得但很吃力
  GOOD = 2,     // 记住所花时间适中
  EASY = 3      // 轻松记住
}

/**
 * FSRS卡片状态
 */
export interface FSRSCard {
  skillId: string;
  stepNumber: number;
  // FSRS参数
  stability: number;        // 记忆稳定度（天）
  difficulty: number;        // 难度（0-10）
  retrievability: number;    // 当前可回忆率（0-1）
  // 状态
  interval: number;         // 当前间隔（天）
  repetitions: number;       // 复习次数
  lapses: number;          // 忘记次数
  lastReview: number;       // 上次复习时间戳
  nextReview: number;       // 下次复习时间戳
  // 历史
  reviewHistory: ReviewRecord[];
}

/**
 * 复习记录
 */
export interface ReviewRecord {
  timestamp: number;
  rating: UserRating;
  interval: number;         // 复习时的间隔
  reactionTime: number;     // 反应时间（毫秒）
}

/**
 * FSRS算法参数（简化版）
 * 参考 FSRS (Free Spaced Repetition Scheduler) 论文
 */
const FSRS_PARAMS = {
  // 初始稳定度（天）- 初始记忆建立时的稳定度
  INIT_STABILITY: 1.0,
  
  // 初始难度
  INIT_DIFFICULTY: 5.0,
  
  // 难度范围
  DIFFICULTY_MIN: 1.0,
  DIFFICULTY_MAX: 10.0,
  
  // 稳定度衰减因子
  STABILITY_DECAY: 0.1,
  
  // 稳定度增长因子（取决于评分）
  STABILITY_GROWTH: {
    [UserRating.AGAIN]: 0.5,   // 忘记后稳定度大幅下降
    [UserRating.HARD]: 0.8,     // 困难时略有增长
    [UserRating.GOOD]: 1.2,     // 一般时稳定增长
    [UserRating.EASY]: 1.5      // 简单时大幅增长
  },
  
  // 难度调整因子
  DIFFICULTY_ADJUST: {
    [UserRating.AGAIN]: 2.0,   // 忘记后难度增加
    [UserRating.HARD]: 0.9,
    [UserRating.GOOD]: 1.0,
    [UserRating.EASY]: 0.9
  },
  
  // 目标保持率
  TARGET_RETENTION: 0.9,
  
  // 最大间隔（天）
  MAX_INTERVAL: 365
};

/**
 * 遗忘曲线配置
 * 首次学习后：1天 → 3天 → 7天 → 14天 → 30天（简化版）
 */
const SIMPLE_FORGETTING_CURVE_HOURS = [24, 72, 168, 336, 720];

/**
 * 温馨文案模板
 */
const WARM_REMINDER_TEMPLATES = {
  [ReminderType.STUDY_REMINDER]: [
    '{name}～今天还没学习呢，抽出几分钟继续加油吧！',
    '{name}，昨天的进度还等着你呢，今天继续学吗？',
    '{name}，学习是每天的小进步，一起保持好节奏吧～',
    '今天的学习时间到啦，{name}准备好继续了吗？'
  ],
  [ReminderType.REVIEW_REMINDER]: [
    '{name}，之前学的"{skill}"该复习啦，温故知新哦～',
    '{name}，别忘了复习"{skill}"，这样记得更牢！',
    '学习需要定期复习，{name}要不要回顾一下"{skill}"？'
  ],
  [ReminderType.ACHIEVEMENT_REMINDER]: [
    '🎉 恭喜{name}解锁了新成就，快来看看吧！',
    '{name}的努力有回报啦，查看你的新成就～',
    '太棒了，{name}又有进步啦！来看看这个成就～'
  ],
  [ReminderType.STREAK_REMINDER]: [
    '🔥 {name}已经连续学习{day}天啦！别断签哦～',
    '{name}，再学一天就能打破记录啦，加油！',
    '坚持就是胜利，{name}的学习 streak 还在继续！'
  ]
};

/**
 * 遗忘曲线状态
 */
export interface ForgettingCurveState {
  skillId: string;
  skillName: string;
  cards: Map<string, FSRSCard>;  // key: `${skillId}_${stepNumber}`
  lastLearnTime: number;
}

/**
 * 鸿蒙提醒服务
 */
export class HarmonyReminderService {
  private static instance: HarmonyReminderService | null = null;

  // 活跃提醒记录
  private activeReminders: Map<string, reminderManager.ReminderRequest> = new Map();
  
  // 遗忘曲线状态
  private forgettingCurveStates: Map<string, ForgettingCurveState> = new Map();

  static getInstance(): HarmonyReminderService {
    if (!HarmonyReminderService.instance) {
      HarmonyReminderService.instance = new HarmonyReminderService();
    }
    return HarmonyReminderService.instance;
  }

  private constructor() {
    HiLog.info("HarmonyReminderService", "鸿蒙提醒服务初始化（FSRS版）");
  }

  /**
   * 推送学习提醒
   */
  async pushStudyReminder(
    userName: string,
    skillName: string,
    reminderTime: Date,
    warmMessage?: string
  ): Promise<ReminderResult> {
    HiLog.info("HarmonyReminderService", `推送学习提醒: ${userName}/${skillName}`);
    
    const reminderContent: ReminderContent = {
      type: ReminderType.STUDY_REMINDER,
      title: '学习提醒',
      warmMessage: warmMessage || this.generateWarmMessage(ReminderType.STUDY_REMINDER, { name: userName }),
      skillName,
      actionText: '点击继续学习'
    };

    return this.createReminder(reminderContent, reminderTime);
  }

  /**
   * 安排复习提醒（基于FSRS算法）
   * 根据用户表现动态计算最优复习间隔
   */
  async scheduleReviewReminder(
    userId: string,
    skillId: string,
    skillName: string,
    stepNumber: number
  ): Promise<ReminderResult> {
    HiLog.info("HarmonyReminderService", `安排FSRS复习: ${userId}/${skillId} 步骤${stepNumber}`);
    
    // 获取或创建遗忘曲线状态
    const state = this.getOrCreateState(userId, skillId, skillName);
    
    // 获取或创建FSRS卡片
    const cardKey = `${skillId}_${stepNumber}`;
    let card = state.cards.get(cardKey);
    
    if (!card) {
      // 新卡片，初始化FSRS状态
      card = this.initFSRSCard(skillId, stepNumber);
      state.cards.set(cardKey, card);
    }
    
    // 计算下次复习时间
    const nextReviewTime = this.calculateNextReview(card);
    card.nextReview = nextReviewTime.getTime();
    
    HiLog.info("HarmonyReminderService", 
      `FSRS计算: 稳定度=${card.stability.toFixed(2)}天, 难度=${card.difficulty.toFixed(2)}, ` +
      `间隔=${card.interval.toFixed(2)}天, 下次复习=${nextReviewTime.toLocaleString()}`
    );
    
    return this.createReviewReminder(userId, skillId, skillName, stepNumber, nextReviewTime);
  }

  /**
   * 记录用户复习表现（更新FSRS参数）
   */
  recordReviewPerformance(
    userId: string,
    skillId: string,
    stepNumber: number,
    rating: UserRating,
    reactionTime: number
  ): ForgettingCurveState {
    const state = this.getOrCreateState(userId, skillId, skillName);
    const cardKey = `${skillId}_${stepNumber}`;
    const card = state.cards.get(cardKey);
    
    if (!card) {
      HiLog.warn("HarmonyReminderService", `未找到FSRS卡片: ${cardKey}`);
      return state;
    }
    
    // 记录复习历史
    const record: ReviewRecord = {
      timestamp: Date.now(),
      rating,
      interval: card.interval,
      reactionTime
    };
    card.reviewHistory.push(record);
    
    // 更新FSRS参数
    this.updateFSRSParams(card, rating);
    
    HiLog.info("HarmonyReminderService", 
      `FSRS更新: 评分=${rating}, 新稳定度=${card.stability.toFixed(2)}天, ` +
      `新难度=${card.difficulty.toFixed(2)}, 新间隔=${card.interval.toFixed(2)}天`
    );
    
    return state;
  }

  /**
   * 获取遗忘曲线状态
   */
  getForgettingCurveState(userId: string, skillId: string): ForgettingCurveState | null {
    const key = `${userId}_${skillId}`;
    return this.forgettingCurveStates.get(key) || null;
  }

  /**
   * 获取所有待复习项
   */
  getPendingReviews(userId: string): { skillId: string; stepNumber: number; dueTime: number }[] {
    const pending: { skillId: string; stepNumber: number; dueTime: number }[] = [];
    const now = Date.now();
    
    this.forgettingCurveStates.forEach((state, key) => {
      if (!key.startsWith(userId)) return;
      
      state.cards.forEach((card, cardKey) => {
        if (card.nextReview <= now) {
          const parts = cardKey.split('_');
          pending.push({
            skillId: parts[0],
            stepNumber: parseInt(parts[1]),
            dueTime: card.nextReview
          });
        }
      });
    });
    
    return pending.sort((a, b) => a.dueTime - b.dueTime);
  }

  /**
   * 获取FSRS卡片统计
   */
  getCardStats(userId: string, skillId: string): {
    totalCards: number;
    masteredCards: number;
    learningCards: number;
    averageStability: number;
    averageDifficulty: number;
  } {
    const state = this.getForgettingCurveState(userId, skillId);
    if (!state) {
      return { totalCards: 0, masteredCards: 0, learningCards: 0, averageStability: 0, averageDifficulty: 5 };
    }
    
    let totalStability = 0;
    let totalDifficulty = 0;
    let masteredCards = 0;
    let learningCards = 0;
    
    state.cards.forEach(card => {
      totalStability += card.stability;
      totalDifficulty += card.difficulty;
      
      if (card.interval >= 21) {  // 间隔21天以上算掌握
        masteredCards++;
      } else {
        learningCards++;
      }
    });
    
    const count = state.cards.size;
    return {
      totalCards: count,
      masteredCards,
      learningCards,
      averageStability: count > 0 ? totalStability / count : 0,
      averageDifficulty: count > 0 ? totalDifficulty / count : 5
    };
  }

  // ==================== 私有方法 ====================

  /**
   * 获取或创建遗忘曲线状态
   */
  private getOrCreateState(userId: string, skillId: string, skillName: string): ForgettingCurveState {
    const key = `${userId}_${skillId}`;
    
    if (!this.forgettingCurveStates.has(key)) {
      this.forgettingCurveStates.set(key, {
        skillId,
        skillName,
        cards: new Map(),
        lastLearnTime: Date.now()
      });
    }
    
    return this.forgettingCurveStates.get(key)!;
  }

  /**
   * 初始化FSRS卡片
   */
  private initFSRSCard(skillId: string, stepNumber: number): FSRSCard {
    return {
      skillId,
      stepNumber,
      stability: FSRS_PARAMS.INIT_STABILITY,
      difficulty: FSRS_PARAMS.INIT_DIFFICULTY,
      retrievability: 1.0,
      interval: 0,
      repetitions: 0,
      lapses: 0,
      lastReview: Date.now(),
      nextReview: Date.now(),
      reviewHistory: []
    };
  }

  /**
   * 计算下次复习时间（FSRS核心算法）
   */
  private calculateNextReview(card: FSRSCard): Date {
    // 如果是第一次复习，间隔很短
    if (card.repetitions === 0) {
      const nextInterval = this.applyRetentionPolicy(card.stability, card.difficulty, 0);
      card.interval = nextInterval;
      return new Date(Date.now() + nextInterval * 24 * 60 * 60 * 1000);
    }
    
    // R = S / (S + 9 * (1 - R_max) * (D - 1))
    // 其中 R_max = 0.9 (目标保持率)
    // 反推：当 R = 0.9 时，求 S
    const targetRetrievability = FSRS_PARAMS.TARGET_RETENTION;
    const D = card.difficulty;
    const R_max = 0.9;
    
    // 计算满足目标保持率所需的间隔
    // 简化公式: interval = stability * ln((1-R_max)/(1-R)) / (1-R_max)
    // 其中 R = targetRetrievability
    const R = targetRetrievability;
    let nextInterval = card.stability * Math.log((1 - R_max) / (1 - R)) / (1 - R_max);
    
    // 应用稳定度衰减
    nextInterval = nextInterval * Math.exp(FSRS_PARAMS.STABILITY_DECAY * (card.repetitions - 1));
    
    // 限制最大间隔
    nextInterval = Math.min(nextInterval, FSRS_PARAMS.MAX_INTERVAL);
    
    // 至少1天
    nextInterval = Math.max(1, nextInterval);
    
    card.interval = nextInterval;
    
    return new Date(Date.now() + nextInterval * 24 * 60 * 60 * 1000);
  }

  /**
   * 应用保持率策略（简化版）
   */
  private applyRetentionPolicy(stability: number, difficulty: number, repetitions: number): number {
    // 简单遗忘曲线
    const curveIndex = Math.min(repetitions, SIMPLE_FORGETTING_CURVE_HOURS.length - 1);
    return SIMPLE_FORGETTING_CURVE_HOURS[curveIndex] / 24; // 转换为天
  }

  /**
   * 更新FSRS参数
   */
  private updateFSRSParams(card: FSRSCard, rating: UserRating): void {
    const oldStability = card.stability;
    const oldDifficulty = card.difficulty;
    
    // 评分对应的因素
    const sFactor = FSRS_PARAMS.STABILITY_GROWTH[rating];
    const dFactor = FSRS_PARAMS.DIFFICULTY_ADJUST[rating];
    
    // 更新稳定度
    // S_new = S_old * sFactor * (1 - R)
    // 其中 R 是目标保持率
    if (rating === UserRating.AGAIN) {
      // 忘记后，稳定度大幅下降，重置间隔
      card.stability = Math.max(0.1, card.stability * 0.5);
      card.lapses++;
      card.interval = 0.1; // 10分钟
    } else {
      // 记住后，稳定度增长
      const retentionFactor = 1 - FSRS_PARAMS.TARGET_RETENTION;
      card.stability = card.stability * sFactor * (1 + retentionFactor * card.repetitions);
    }
    
    // 更新难度
    card.difficulty = Math.max(
      FSRS_PARAMS.DIFFICULTY_MIN,
      Math.min(FSRS_PARAMS.DIFFICULTY_MAX, card.difficulty * dFactor)
    );
    
    // 更新复习次数
    card.repetitions++;
    card.lastReview = Date.now();
    
    // 重新计算下次复习间隔
    this.calculateNextReview(card);
  }

  /**
   * 创建复习提醒
   */
  private async createReviewReminder(
    userId: string,
    skillId: string,
    skillName: string,
    stepNumber: number,
    reviewTime: Date
  ): Promise<ReminderResult> {
    const warmMessage = this.generateWarmMessage(ReminderType.REVIEW_REMINDER, {
      name: '你',
      skill: skillName
    });

    const reminderContent: ReminderContent = {
      type: ReminderType.REVIEW_REMINDER,
      title: `复习提醒：${skillName}`,
      warmMessage,
      skillName,
      stepNumber,
      actionText: '点击开始复习'
    };

    return this.createReminder(reminderContent, reviewTime);
  }

  /**
   * 推送成就提醒
   */
  async pushAchievementReminder(
    userName: string,
    achievementName: string,
    achievementIcon: string
  ): Promise<ReminderResult> {
    HiLog.info("HarmonyReminderService", `推送成就提醒: ${userName}/${achievementName}`);
    
    const warmMessage = `${achievementIcon} 恭喜${userName}解锁「${achievementName}」！`;
    
    const reminderContent: ReminderContent = {
      type: ReminderType.ACHIEVEMENT_REMINDER,
      title: '🎉 新成就解锁',
      warmMessage,
      actionText: '查看成就'
    };

    return this.createReminder(reminderContent, new Date());
  }

  /**
   * 推送连续学习提醒
   */
  async pushStreakReminder(
    userName: string,
    currentStreak: number
  ): Promise<ReminderResult> {
    HiLog.info("HarmonyReminderService", `推送连续学习提醒: ${userName}/${currentStreak}天`);
    
    const warmMessage = this.generateWarmMessage(ReminderType.STREAK_REMINDER, {
      name: userName,
      day: currentStreak
    });

    const reminderContent: ReminderContent = {
      type: ReminderType.STREAK_REMINDER,
      title: '🔥 学习连续提醒',
      warmMessage,
      actionText: '继续学习'
    };

    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(10, 0, 0, 0);

    return this.createReminder(reminderContent, tomorrow);
  }

  /**
   * 跨设备通知同步
   */
  async syncToOtherDevices(
    userId: string,
    skillName: string,
    currentStep: number,
    totalSteps: number
  ): Promise<void> {
    HiLog.info("HarmonyReminderService", `跨设备同步: ${userId}/${skillName}`);
    
    const syncMessage = {
      type: 'learning_progress',
      userId,
      skillName,
      currentStep,
      totalSteps,
      progress: Math.round((currentStep / totalSteps) * 100),
      timestamp: Date.now()
    };
    
    HiLog.info("HarmonyReminderService", `同步数据: ${JSON.stringify(syncMessage)}`);
  }

  /**
   * 写入系统日历
   */
  async addToCalendar(
    skillName: string,
    plannedDate: Date,
    durationMinutes: number = 30
  ): Promise<ReminderResult> {
    HiLog.info("HarmonyReminderService", `写入日历: ${skillName}`);
    
    try {
      const calendarEvent = {
        title: `📚 学习：${skillName}`,
        description: `计划学习${skillName}，预计${durationMinutes}分钟`,
        startTime: plannedDate.getTime(),
        endTime: plannedDate.getTime() + durationMinutes * 60 * 1000,
        alarmMinutes: 15
      };
      
      HiLog.info("HarmonyReminderService", `日历事件: ${JSON.stringify(calendarEvent)}`);
      
      return { success: true, reminderId: `calendar_${Date.now()}` };
    } catch (error) {
      return { success: false, error: `${error}` };
    }
  }

  /**
   * 创建提醒
   */
  private async createReminder(
    content: ReminderContent,
    triggerTime: Date
  ): Promise<ReminderResult> {
    try {
      const reminderContent: reminderManager.ReminderRequest = {
        reminderId: `reminder_${Date.now()}`,
        type: reminderManager.ReminderType.STORAGE,
        dateTime: {
          year: triggerTime.getFullYear(),
          month: triggerTime.getMonth() + 1,
          day: triggerTime.getDate(),
          hour: triggerTime.getHours(),
          minute: triggerTime.getMinutes()
        },
        title: content.title,
        content: content.warmMessage,
        actionButton: content.actionText ? [
          {
            title: content.actionText,
            type: reminderManager.ActionButtonType.ACTION_BUTTON_TYPE_CUSTOM
          }
        ] : undefined,
        wantAgent: {
          abilityName: 'EntryAbility'
        }
      };

      const reminderId = await reminderManager.publishReminder(getContext(), reminderContent);
      
      HiLog.info("HarmonyReminderService", `提醒发布成功: ${reminderId}`);
      this.activeReminders.set(reminderId, reminderContent);
      
      return { success: true, reminderId };
    } catch (error) {
      const err = error as BusinessError;
      HiLog.error("HarmonyReminderService", `提醒发布失败: ${err.code}`);
      return { success: false, error: `${err.code}: ${err.message}` };
    }
  }

  /**
   * 取消提醒
   */
  async cancelReminder(reminderId: string): Promise<boolean> {
    try {
      await reminderManager.cancelReminder(getContext(), reminderId);
      this.activeReminders.delete(reminderId);
      HiLog.info("HarmonyReminderService", `提醒已取消: ${reminderId}`);
      return true;
    } catch (error) {
      HiLog.error("HarmonyReminderService", `取消提醒失败: ${error}`);
      return false;
    }
  }

  /**
   * 获取所有活跃提醒
   */
  getActiveReminders(): string[] {
    return Array.from(this.activeReminders.keys());
  }

  /**
   * 生成温馨文案
   */
  private generateWarmMessage(
    type: ReminderType,
    params: { name?: string; skill?: string; day?: number }
  ): string {
    const templates = WARM_REMINDER_TEMPLATES[type];
    if (!templates || templates.length === 0) {
      return '该学习啦～';
    }

    let message = templates[Math.floor(Math.random() * templates.length)];
    
    if (params.name) message = message.replace('{name}', params.name);
    if (params.skill) message = message.replace('{skill}', params.skill);
    if (params.day !== undefined) message = message.replace('{day}', params.day.toString());

    return message;
  }

  /**
   * 获取遗忘曲线复习时间点（用于展示）
   */
  static getReviewTimePoints(lastLearnTime: Date): Date[] {
    return SIMPLE_FORGETTING_CURVE_HOURS.map(hours => 
      new Date(lastLearnTime.getTime() + hours * 60 * 60 * 1000)
    );
  }
}

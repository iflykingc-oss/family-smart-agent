/**
 * ============================================================================
 * 激励服务 - MotivationService
 * 
 * 【借鉴优化】
 * 参考：Self-Improving Agent - HOT/WARM/COLD 分层
 * 优化：从'被动存储分层' → '主动游戏化激励'
 * 
 * 核心差异化：游戏化激励系统
 * 
 * 功能：
 * - XP/等级系统（基于指数增长曲线）
 * - 连续学习激励
 * - 成就徽章系统
 * - 排行榜
 * 
 * 算法说明：
 * - XP需求公式：XP_needed = 50 * (level^2)
 * - Level 1: 50 XP, Level 2: 200 XP, Level 3: 450 XP, Level 4: 800 XP...
 * - 指数增长让升级越往后越难，增加游戏性和挑战感
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 成就
 */
export interface Achievement {
  id: string;
  name: string;
  description: string;
  icon: string;
  xpReward: number;
  unlocked: boolean;
  unlockedAt?: number;
}

/**
 * 奖励结果
 */
export interface RewardResult {
  achievement?: Achievement;
  xpGained: number;
  coins: number;
  levelUp?: {
    newLevel: number;
    xpToNextLevel: number;
    progress: number;
  };
  message: string;
}

/**
 * 用户等级信息
 */
export interface LevelInfo {
  currentLevel: number;
  currentXP: number;
  xpForNextLevel: number;
  progress: number;  // 0-100
  totalEarnedXP: number;
}

/**
 * 连续学习信息
 */
export interface StreakInfo {
  currentStreak: number;
  longestStreak: number;
  lastLearningDate: string;
  todayCompleted: boolean;
  streakMultiplier: number;  // 连续奖励倍率
}

/**
 * 激励上下文
 */
export interface MotivationContext {
  userName?: string;
  skillName?: string;
  stepNumber?: number;
  completed?: boolean;
  correct?: boolean;
  perfectScore?: boolean;
}

/**
 * 激励服务
 */
export class MotivationService {
  private static instance: MotivationService | null = null;

  // 用户数据
  private userXP: Map<string, number> = new Map();          // 总XP
  private userLevel: Map<string, number> = new Map();        // 当前等级
  private userStreaks: Map<string, StreakInfo> = new Map();
  private userAchievements: Map<string, Achievement[]> = new Map();
  private userCoins: Map<string, number> = new Map();
  private userLevelHistory: Map<string, number> = new Map(); // 曾达等级（用于统计）

  // XP配置
  private readonly XP_CONFIG = {
    // 等级公式：XP_needed = 50 * (level^2)
    BASE_XP: 50,
    LEVEL_FORMULA: (level: number) => 50 * Math.pow(level, 2),
    
    // 基础奖励
    BASE_XP: {
      CORRECT_ANSWER: 10,       // 答对
      COMPLETE_STEP: 15,        // 完成步骤
      COMPLETE_SKILL: 100,      // 完成技能
      STREAK_BONUS_MULTI: 0.1  // 连续奖励每多1天加0.1倍
    },
    
    // 连续奖励倍率
    STREAK_MULTIPLIERS: {
      1: 1.0,   // 1天：1.0倍
      3: 1.2,   // 3天：1.2倍
      7: 1.5,   // 7天：1.5倍
      14: 1.8,  // 14天：1.8倍
      30: 2.0   // 30天：2.0倍（封顶）
    },
    
    // 金币兑换比例（1 XP = 0.1 金币）
    COIN_EXCHANGE_RATE: 0.1,
    
    // 最大连续奖励倍率
    MAX_STREAK_MULTIPLIER: 2.0
  };

  static getInstance(): MotivationService {
    if (!MotivationService.instance) {
      MotivationService.instance = new MotivationService();
    }
    return MotivationService.instance;
  }

  private constructor() {
    HiLog.info("MotivationService", "激励服务初始化（游戏化版）");
  }

  /**
   * 奖励用户
   */
  reward(userId: string, context: MotivationContext): RewardResult {
    HiLog.info("MotivationService", `奖励用户: ${userId}, 技能: ${context.skillName}`);
    
    let baseXP = 0;
    let baseCoins = 0;
    let message = '';

    // 计算基础XP
    if (context.correct) {
      baseXP += this.XP_CONFIG.BASE_XP.CORRECT_ANSWER;
    }
    if (context.completed) {
      baseXP += this.XP_CONFIG.BASE_XP.COMPLETE_SKILL;
    }
    if (context.perfectScore) {
      baseXP += 20; // 满分额外奖励
    }

    // 获取连续学习信息
    const streakInfo = this.checkStreak(userId);
    const multiplier = streakInfo.streakMultiplier;

    // 应用连续奖励倍率
    const finalXP = Math.round(baseXP * multiplier);
    
    // 计算金币（XP * 0.1）
    baseCoins = Math.round(finalXP * this.XP_CONFIG.COIN_EXCHANGE_RATE);

    // 添加XP
    const previousLevel = this.getLevel(userId);
    this.addXP(userId, finalXP);
    const newLevel = this.getLevel(userId);

    // 检查升级
    let levelUp = undefined;
    if (newLevel > previousLevel) {
      const levelInfo = this.getLevelInfo(userId);
      levelUp = {
        newLevel,
        xpToNextLevel: levelInfo.xpForNextLevel,
        progress: levelInfo.progress
      };
      this.userLevelHistory.set(userId, newLevel);
      HiLog.info("MotivationService", `升级: ${userId} -> Level ${newLevel}`);
    }

    // 检查成就解锁
    const achievement = this.checkAndUnlockAchievement(userId, context);

    // 生成消息
    message = this.generateRewardMessage(finalXP, multiplier, achievement?.name, levelUp);

    return {
      achievement,
      xpGained: finalXP,
      coins: baseCoins,
      levelUp,
      message
    };
  }

  /**
   * 添加XP
   */
  private addXP(userId: string, amount: number): void {
    const current = this.userXP.get(userId) || 0;
    this.userXP.set(userId, current + amount);
  }

  /**
   * 获取当前等级
   */
  getLevel(userId: string): number {
    if (this.userLevel.has(userId)) {
      return this.userLevel.get(userId)!;
    }
    
    // 根据XP计算等级
    const xp = this.userXP.get(userId) || 0;
    let level = 1;
    while (this.getXPForLevel(level + 1) <= xp) {
      level++;
    }
    this.userLevel.set(userId, level);
    return level;
  }

  /**
   * 计算指定等级需要的XP
   */
  private getXPForLevel(level: number): number {
    let totalXP = 0;
    for (let i = 1; i < level; i++) {
      totalXP += this.XP_CONFIG.LEVEL_FORMULA(i);
    }
    return totalXP;
  }

  /**
   * 获取等级信息
   */
  getLevelInfo(userId: string): LevelInfo {
    const xp = this.userXP.get(userId) || 0;
    const level = this.getLevel(userId);
    const currentLevelXP = this.getXPForLevel(level);
    const nextLevelXP = this.XP_CONFIG.LEVEL_FORMULA(level);
    const xpInCurrentLevel = xp - currentLevelXP;
    const progress = Math.round((xpInCurrentLevel / nextLevelXP) * 100);

    return {
      currentLevel: level,
      currentXP: xpInCurrentLevel,
      xpForNextLevel: nextLevelXP,
      progress,
      totalEarnedXP: xp
    };
  }

  /**
   * 检查并更新连续学习
   */
  checkStreak(userId: string): StreakInfo {
    const today = this.getTodayString();
    let streak = this.userStreaks.get(userId);
    
    if (!streak) {
      streak = {
        currentStreak: 0,
        longestStreak: 0,
        lastLearningDate: '',
        todayCompleted: false,
        streakMultiplier: 1.0
      };
      this.userStreaks.set(userId, streak);
    }

    // 计算连续奖励倍率
    streak.streakMultiplier = this.calculateStreakMultiplier(streak.currentStreak);

    if (streak.lastLearningDate === today) {
      streak.todayCompleted = true;
    } else if (streak.lastLearningDate === this.getYesterdayString()) {
      streak.currentStreak++;
      streak.todayCompleted = true;
      if (streak.currentStreak > streak.longestStreak) {
        streak.longestStreak = streak.currentStreak;
      }
      streak.streakMultiplier = this.calculateStreakMultiplier(streak.currentStreak);
    } else if (streak.lastLearningDate !== today) {
      streak.currentStreak = 1;
      streak.todayCompleted = true;
      streak.streakMultiplier = 1.0;
    }

    streak.lastLearningDate = today;

    HiLog.info("MotivationService", `连续学习: ${userId}, ${streak.currentStreak}天, ${streak.streakMultiplier}倍`);
    return streak;
  }

  /**
   * 计算连续奖励倍率
   */
  private calculateStreakMultiplier(streak: number): number {
    if (streak >= 30) return 2.0;
    if (streak >= 14) return 1.8;
    if (streak >= 7) return 1.5;
    if (streak >= 3) return 1.2;
    return 1.0;
  }

  /**
   * 生成奖励消息
   */
  private generateRewardMessage(
    xp: number, 
    multiplier: number, 
    achievementName?: string,
    levelUp?: { newLevel: number; xpToNextLevel: number; progress: number }
  ): string {
    let parts: string[] = [];

    if (xp > 0) {
      if (multiplier > 1.0) {
        parts.push(`+${xp} XP 🔥`);
      } else {
        parts.push(`+${xp} XP`);
      }
    }

    if (levelUp) {
      parts.push(`🎉 升级到 Lv.${levelUp.newLevel}！`);
    }

    if (achievementName) {
      parts.push(`🏅 解锁成就：${achievementName}`);
    }

    return parts.join('，') || '继续加油！';
  }

  /**
   * 检查并解锁成就
   */
  private checkAndUnlockAchievement(userId: string, context: MotivationContext): Achievement | undefined {
    const achievements = this.getOrCreateAchievements(userId);
    
    // 检查各类成就条件
    const checks: Array<{ condition: boolean; achievementId: string }> = [
      // 首次完成
      { condition: context.completed === true, achievementId: 'first_skill_complete' },
      // 满分
      { condition: context.perfectScore === true, achievementId: 'perfect_score' },
      // 连续7天
      { condition: this.userStreaks.get(userId)?.currentStreak === 7, achievementId: 'streak_7' },
      // 连续30天
      { condition: this.userStreaks.get(userId)?.currentStreak === 30, achievementId: 'streak_30' },
      // 等级达到5
      { condition: this.getLevel(userId) === 5, achievementId: 'level_5' },
      // 等级达到10
      { condition: this.getLevel(userId) === 10, achievementId: 'level_10' },
    ];

    for (const check of checks) {
      if (check.condition) {
        const achievement = achievements.find(a => a.id === check.achievementId);
        if (achievement && !achievement.unlocked) {
          achievement.unlocked = true;
          achievement.unlockedAt = Date.now();
          HiLog.info("MotivationService", `解锁成就: ${userId}, ${achievement.name}`);
          return achievement;
        }
      }
    }

    return undefined;
  }

  /**
   * 获取或创建成就列表
   */
  private getOrCreateAchievements(userId: string): Achievement[] {
    if (!this.userAchievements.has(userId)) {
      this.userAchievements.set(userId, this.getDefaultAchievements());
    }
    return this.userAchievements.get(userId)!;
  }

  /**
   * 默认成就列表
   */
  private getDefaultAchievements(): Achievement[] {
    return [
      { id: 'first_step', name: '第一步', description: '完成第一次学习', icon: '🌱', xpReward: 10, unlocked: false },
      { id: 'first_skill_complete', name: '技能完成', description: '完成一个技能的学习', icon: '🎯', xpReward: 50, unlocked: false },
      { id: 'perfect_score', name: '一击即中', description: '满分完成练习', icon: '💯', xpReward: 30, unlocked: false },
      { id: 'streak_3', name: '初露锋芒', description: '连续学习3天', icon: '🔥', xpReward: 30, unlocked: false },
      { id: 'streak_7', name: '坚持不懈', description: '连续学习7天', icon: '💪', xpReward: 70, unlocked: false },
      { id: 'streak_30', name: '学习达人', description: '连续学习30天', icon: '🏆', xpReward: 300, unlocked: false },
      { id: 'level_5', name: 'Lv.5', description: '达到5级', icon: '⭐', xpReward: 100, unlocked: false },
      { id: 'level_10', name: 'Lv.10', description: '达到10级', icon: '🌟', xpReward: 200, unlocked: false },
      { id: 'five_skills', name: '五项全能', description: '完成5个技能', icon: '🏅', xpReward: 200, unlocked: false },
      { id: 'ten_skills', name: '十项全能', description: '完成10个技能', icon: '🎖️', xpReward: 500, unlocked: false },
    ];
  }

  /**
   * 获取用户所有成就
   */
  getAchievements(userId: string): Achievement[] {
    return this.checkAchievements(userId);
  }

  /**
   * 检查成就（只返回已解锁的）
   */
  checkAchievements(userId: string): Achievement[] {
    const achievements = this.getOrCreateAchievements(userId);
    return achievements.filter(a => a.unlocked);
  }

  /**
   * 获取用户金币
   */
  getCoins(userId: string): number {
    return this.userCoins.get(userId) || 0;
  }

  /**
   * 获取用户统计
   */
  getUserStats(userId: string): {
    levelInfo: LevelInfo;
    streakInfo: StreakInfo;
    coins: number;
    achievementsCount: number;
    totalAchievements: number;
  } {
    return {
      levelInfo: this.getLevelInfo(userId),
      streakInfo: this.checkStreak(userId),
      coins: this.getCoins(userId),
      achievementsCount: this.checkAchievements(userId).length,
      totalAchievements: this.getDefaultAchievements().length
    };
  }

  /**
   * 获取等级排行榜（简化版）
   */
  getLeaderboard(topN: number = 10): Array<{ userId: string; level: number; xp: number }> {
    const allUsers: Array<{ userId: string; level: number; xp: number }> = [];
    
    this.userXP.forEach((xp, uid) => {
      allUsers.push({
        userId: uid,
        level: this.getLevel(uid),
        xp
      });
    });
    
    return allUsers
      .sort((a, b) => b.xp - a.xp)
      .slice(0, topN);
  }

  /**
   * 获取今日字符串
   */
  private getTodayString(): string {
    return new Date().toISOString().split('T')[0];
  }

  /**
   * 获取昨日字符串
   */
  private getYesterdayString(): string {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return yesterday.toISOString().split('T')[0];
  }
}


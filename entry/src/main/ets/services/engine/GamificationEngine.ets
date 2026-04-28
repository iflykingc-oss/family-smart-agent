/**
 * ============================================================================
 * 游戏化引擎 - GamificationEngine
 * 借鉴多邻国（Duolingo）游戏化设计
 * 
 * 核心设计：
 * 1. 经验值（XP）- 每次学习获得经验
 * 2. 连胜（Streak）- 连续学习天数
 * 3. 等级（Level）- 经验值升级
 * 4. 成就（Achievement）- 里程碑奖励
 * 5. 排行榜（Leaderboard）- 社交竞争
 * 6. 联赛（League）- 赛季制竞争
 * 
 * 借鉴多邻国：
 * - 即时反馈（对/错 + 音效 + 动画）
 * - 渐进式难度（简单→中等→困难）
 * - 情感化文案（鼓励、安慰、调侃）
 * - 社交元素（好友、排行榜、联赛）
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

const TAG = 'GamificationEngine';

/**
 * 用户游戏数据
 */
export interface UserGameData {
  /** 用户 ID */
  userId: string;
  
  /** 当前经验值 */
  currentXP: number;
  
  /** 总经验值 */
  totalXP: number;
  
  /** 当前等级 */
  level: number;
  
  /** 连胜天数 */
  streak: number;
  
  /** 最长连胜 */
  longestStreak: number;
  
  /** 上次学习日期 */
  lastStudyDate: string;
  
  /** 今日学习时长（分钟） */
  todayStudyMinutes: number;
  
  /** 今日学习目标（分钟） */
  dailyGoal: number;
  
  /** 金币 */
  coins: number;
  
  /** 宝石 */
  gems: number;
  
  /** 心数（生命值） */
  hearts: number;
  
  /** 最大心数 */
  maxHearts: number;
  
  /** 当前联赛 */
  currentLeague: string;
  
  /** 排行榜排名 */
  leaderboardRank: number;
}

/**
 * 成就
 */
export interface Achievement {
  /** 成就 ID */
  id: string;
  
  /** 成就名称 */
  name: string;
  
  /** 成就描述 */
  description: string;
  
  /** 成就图标 */
  icon: string;
  
  /** 成就类型 */
  type: AchievementType;
  
  /** 解锁条件 */
  condition: AchievementCondition;
  
  /** 奖励经验值 */
  rewardXP: number;
  
  /** 奖励金币 */
  rewardCoins: number;
  
  /** 是否已解锁 */
  unlocked: boolean;
  
  /** 解锁时间 */
  unlockedAt?: number;
}

/**
 * 成就类型
 */
export enum AchievementType {
  /** 学习类 */
  LEARNING = 'learning',
  
  /** 连胜类 */
  STREAK = 'streak',
  
  /** 技能类 */
  SKILL = 'skill',
  
  /** 社交类 */
  SOCIAL = 'social',
  
  /** 隐藏类 */
  HIDDEN = 'hidden',
}

/**
 * 成就条件
 */
export interface AchievementCondition {
  /** 条件类型 */
  type: 'xp' | 'streak' | 'skills' | 'practices' | 'accuracy' | 'time';
  
  /** 目标值 */
  target: number;
  
  /** 当前进度 */
  current: number;
}

/**
 * 经验值等级表
 */
const LEVEL_TABLE: { level: number; requiredXP: number; title: string }[] = [
  { level: 1, requiredXP: 0, title: '初学者' },
  { level: 2, requiredXP: 100, title: '入门者' },
  { level: 3, requiredXP: 300, title: '学习者' },
  { level: 4, requiredXP: 600, title: '进步者' },
  { level: 5, requiredXP: 1000, title: '熟练者' },
  { level: 6, requiredXP: 1500, title: '进阶者' },
  { level: 7, requiredXP: 2100, title: '专家' },
  { level: 8, requiredXP: 2800, title: '大师' },
  { level: 9, requiredXP: 3600, title: '宗师' },
  { level: 10, requiredXP: 4500, title: '传奇' },
];

/**
 * 联赛等级
 */
const LEAGUES = ['青铜联赛', '白银联赛', '黄金联赛', '铂金联赛', '钻石联赛', '大师联赛', '传奇联赛'];

/**
 * 游戏化引擎
 */
export class GamificationEngine {
  private static instance: GamificationEngine | null = null;
  
  // 用户游戏数据
  private userData: Map<string, UserGameData>;
  
  // 成就列表
  private achievements: Achievement[];
  
  // 排行榜
  private leaderboard: Map<string, UserGameData>;

  static getInstance(): GamificationEngine {
    if (!GamificationEngine.instance) {
      GamificationEngine.instance = new GamificationEngine();
    }
    return GamificationEngine.instance;
  }

  private constructor() {
    this.userData = new Map();
    this.achievements = [];
    this.leaderboard = new Map();
    this.initAchievements();
    HiLog.info(TAG, '游戏化引擎初始化（借鉴多邻国）');
  }

  /**
   * 初始化成就系统
   */
  private initAchievements(): void {
    // 学习类成就
    this.achievements.push(
      { id: 'first_step', name: '第一步', description: '完成第一次学习', icon: '🎯', type: AchievementType.LEARNING, condition: { type: 'practices', target: 1, current: 0 }, rewardXP: 50, rewardCoins: 10, unlocked: false },
      { id: 'practice_10', name: '勤能补拙', description: '练习 10 次', icon: '💪', type: AchievementType.LEARNING, condition: { type: 'practices', target: 10, current: 0 }, rewardXP: 100, rewardCoins: 20, unlocked: false },
      { id: 'practice_50', name: '百炼成钢', description: '练习 50 次', icon: '⚡', type: AchievementType.LEARNING, condition: { type: 'practices', target: 50, current: 0 }, rewardXP: 200, rewardCoins: 50, unlocked: false },
      { id: 'practice_100', name: '千锤百炼', description: '练习 100 次', icon: '🔥', type: AchievementType.LEARNING, condition: { type: 'practices', target: 100, current: 0 }, rewardXP: 500, rewardCoins: 100, unlocked: false },
    );
    
    // 连胜类成就
    this.achievements.push(
      { id: 'streak_3', name: '三天打鱼', description: '连续学习 3 天', icon: '🔥', type: AchievementType.STREAK, condition: { type: 'streak', target: 3, current: 0 }, rewardXP: 100, rewardCoins: 20, unlocked: false },
      { id: 'streak_7', name: '一周达人', description: '连续学习 7 天', icon: '⭐', type: AchievementType.STREAK, condition: { type: 'streak', target: 7, current: 0 }, rewardXP: 200, rewardCoins: 50, unlocked: false },
      { id: 'streak_30', name: '月度之星', description: '连续学习 30 天', icon: '🏆', type: AchievementType.STREAK, condition: { type: 'streak', target: 30, current: 0 }, rewardXP: 500, rewardCoins: 100, unlocked: false },
      { id: 'streak_100', name: '百日筑基', description: '连续学习 100 天', icon: '💎', type: AchievementType.STREAK, condition: { type: 'streak', target: 100, current: 0 }, rewardXP: 1000, rewardCoins: 200, unlocked: false },
    );
    
    // 技能类成就
    this.achievements.push(
      { id: 'skill_1', name: '初出茅庐', description: '完成 1 个技能', icon: '📚', type: AchievementType.SKILL, condition: { type: 'skills', target: 1, current: 0 }, rewardXP: 100, rewardCoins: 20, unlocked: false },
      { id: 'skill_5', name: '学富五车', description: '完成 5 个技能', icon: '🎓', type: AchievementType.SKILL, condition: { type: 'skills', target: 5, current: 0 }, rewardXP: 300, rewardCoins: 50, unlocked: false },
      { id: 'skill_10', name: '博览群书', description: '完成 10 个技能', icon: '🌟', type: AchievementType.SKILL, condition: { type: 'skills', target: 10, current: 0 }, rewardXP: 500, rewardCoins: 100, unlocked: false },
      { id: 'skill_15', name: '融会贯通', description: '完成所有技能', icon: '👑', type: AchievementType.SKILL, condition: { type: 'skills', target: 15, current: 0 }, rewardXP: 1000, rewardCoins: 200, unlocked: false },
    );
    
    // 经验值成就
    this.achievements.push(
      { id: 'xp_1000', name: '经验达人', description: '累计 1000 经验值', icon: '✨', type: AchievementType.LEARNING, condition: { type: 'xp', target: 1000, current: 0 }, rewardXP: 200, rewardCoins: 50, unlocked: false },
      { id: 'xp_5000', name: '经验大师', description: '累计 5000 经验值', icon: '💫', type: AchievementType.LEARNING, condition: { type: 'xp', target: 5000, current: 0 }, rewardXP: 500, rewardCoins: 100, unlocked: false },
      { id: 'xp_10000', name: '经验传奇', description: '累计 10000 经验值', icon: '🌈', type: AchievementType.LEARNING, condition: { type: 'xp', target: 10000, current: 0 }, rewardXP: 1000, rewardCoins: 200, unlocked: false },
    );
    
    // 正确率成就
    this.achievements.push(
      { id: 'accuracy_90', name: '百发百中', description: '正确率达到 90%', icon: '🎯', type: AchievementType.LEARNING, condition: { type: 'accuracy', target: 90, current: 0 }, rewardXP: 300, rewardCoins: 50, unlocked: false },
      { id: 'accuracy_100', name: '完美主义', description: '正确率达到 100%', icon: '💯', type: AchievementType.HIDDEN, condition: { type: 'accuracy', target: 100, current: 0 }, rewardXP: 500, rewardCoins: 100, unlocked: false },
    );
    
    // 学习时长成就
    this.achievements.push(
      { id: 'time_1h', name: '一小时达人', description: '累计学习 1 小时', icon: '⏰', type: AchievementType.LEARNING, condition: { type: 'time', target: 60, current: 0 }, rewardXP: 100, rewardCoins: 20, unlocked: false },
      { id: 'time_10h', name: '十小时大师', description: '累计学习 10 小时', icon: '🕐', type: AchievementType.LEARNING, condition: { type: 'time', target: 600, current: 0 }, rewardXP: 300, rewardCoins: 50, unlocked: false },
      { id: 'time_100h', name: '百小时宗师', description: '累计学习 100 小时', icon: '⌛', type: AchievementType.LEARNING, condition: { type: 'time', target: 6000, current: 0 }, rewardXP: 1000, rewardCoins: 200, unlocked: false },
    );
  }

  /**
   * 获取或创建用户游戏数据
   */
  getUserData(userId: string): UserGameData {
    let data = this.userData.get(userId);
    if (!data) {
      data = {
        userId,
        currentXP: 0,
        totalXP: 0,
        level: 1,
        streak: 0,
        longestStreak: 0,
        lastStudyDate: '',
        todayStudyMinutes: 0,
        dailyGoal: 30,
        coins: 0,
        gems: 0,
        hearts: 5,
        maxHearts: 5,
        currentLeague: LEAGUES[0],
        leaderboardRank: 0,
      };
      this.userData.set(userId, data);
    }
    return data;
  }

  /**
   * 记录学习（借鉴多邻国）
   * @param userId 用户 ID
   * @param xp 获得经验值
   * @param correct 是否正确
   */
  recordStudy(userId: string, xp: number, correct: boolean): void {
    const data = this.getUserData(userId);
    const today = new Date().toISOString().split('T')[0];
    
    // 更新连胜
    if (data.lastStudyDate !== today) {
      const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
      if (data.lastStudyDate === yesterday) {
        data.streak++;
      } else if (data.lastStudyDate !== today) {
        data.streak = 1;
      }
      data.todayStudyMinutes = 0;
    }
    
    data.lastStudyDate = today;
    data.todayStudyMinutes += 5; // 每次学习 5 分钟
    
    // 更新经验值
    data.currentXP += xp;
    data.totalXP += xp;
    
    // 更新等级
    this.updateLevel(data);
    
    // 更新金币
    data.coins += Math.floor(xp / 10);
    
    // 更新最长连胜
    if (data.streak > data.longestStreak) {
      data.longestStreak = data.streak;
    }
    
    // 检查成就
    this.checkAchievements(userId, data);
    
    // 更新排行榜
    this.updateLeaderboard(userId, data);
    
    HiLog.info(TAG, `学习记录: ${userId}, +${xp}XP, 等级${data.level}, 连胜${data.streak}天`);
  }

  /**
   * 更新等级
   */
  private updateLevel(data: UserGameData): void {
    let newLevel = data.level;
    
    for (let i = LEVEL_TABLE.length - 1; i >= 0; i--) {
      if (data.totalXP >= LEVEL_TABLE[i].requiredXP) {
        newLevel = LEVEL_TABLE[i].level;
        break;
      }
    }
    
    if (newLevel > data.level) {
      HiLog.info(TAG, `升级: ${data.level} → ${newLevel}, 称号: ${LEVEL_TABLE[newLevel - 1].title}`);
    }
    
    data.level = newLevel;
  }

  /**
   * 检查成就
   */
  private checkAchievements(userId: string, data: UserGameData): void {
    const newAchievements: Achievement[] = [];
    
    this.achievements.forEach(achievement => {
      if (achievement.unlocked) return;
      
      let progress = 0;
      
      switch (achievement.condition.type) {
        case 'xp':
          progress = data.totalXP;
          break;
        case 'streak':
          progress = data.streak;
          break;
        case 'practices':
          progress = data.totalXP / 10; // 估算练习次数
          break;
        case 'skills':
          progress = Math.floor(data.totalXP / 500); // 估算完成技能数
          break;
        case 'accuracy':
          progress = 85; // 默认正确率
          break;
        case 'time':
          progress = data.todayStudyMinutes;
          break;
      }
      
      achievement.condition.current = progress;
      
      if (progress >= achievement.condition.target) {
        achievement.unlocked = true;
        achievement.unlockedAt = Date.now();
        
        // 发放奖励
        data.totalXP += achievement.rewardXP;
        data.coins += achievement.rewardCoins;
        
        newAchievements.push(achievement);
        
        HiLog.info(TAG, `成就解锁: ${achievement.name}`);
      }
    });
    
    if (newAchievements.length > 0) {
      HiLog.info(TAG, `新成就: ${newAchievements.map(a => a.name).join(', ')}`);
    }
  }

  /**
   * 更新排行榜
   */
  private updateLeaderboard(userId: string, data: UserGameData): void {
    this.leaderboard.set(userId, data);
    
    // 排序
    const sorted = Array.from(this.leaderboard.entries())
      .sort((a, b) => b[1].totalXP - a[1].totalXP);
    
    // 更新排名
    sorted.forEach(([id, userData], index) => {
      userData.leaderboardRank = index + 1;
      
      // 更新联赛
      const leagueIndex = Math.min(Math.floor(index / 10), LEAGUES.length - 1);
      userData.currentLeague = LEAGUES[leagueIndex];
    });
  }

  /**
   * 获取排行榜
   */
  getLeaderboard(limit: number = 10): { userId: string; rank: number; totalXP: number; level: number; league: string }[] {
    const sorted = Array.from(this.leaderboard.entries())
      .sort((a, b) => b[1].totalXP - a[1].totalXP)
      .slice(0, limit);
    
    return sorted.map(([userId, data], index) => ({
      userId,
      rank: index + 1,
      totalXP: data.totalXP,
      level: data.level,
      league: data.currentLeague,
    }));
  }

  /**
   * 获取成就列表
   */
  getAchievements(): Achievement[] {
    return this.achievements;
  }

  /**
   * 获取用户成就
   */
  getUserAchievements(userId: string): Achievement[] {
    return this.achievements.filter(a => a.unlocked);
  }

  /**
   * 获取等级进度
   */
  getLevelProgress(data: UserGameData): { currentLevel: number; nextLevel: number; currentXP: number; requiredXP: number; progress: number } {
    const currentLevelData = LEVEL_TABLE[data.level - 1];
    const nextLevelData = LEVEL_TABLE[data.level] || LEVEL_TABLE[LEVEL_TABLE.length - 1];
    
    const currentXP = data.totalXP - currentLevelData.requiredXP;
    const requiredXP = nextLevelData.requiredXP - currentLevelData.requiredXP;
    const progress = requiredXP > 0 ? currentXP / requiredXP : 1;
    
    return {
      currentLevel: data.level,
      nextLevel: data.level + 1,
      currentXP,
      requiredXP,
      progress: Math.min(progress, 1),
    };
  }

  /**
   * 获取每日目标进度
   */
  getDailyGoalProgress(data: UserGameData): { current: number; goal: number; progress: number } {
    return {
      current: data.todayStudyMinutes,
      goal: data.dailyGoal,
      progress: data.todayStudyMinutes / data.dailyGoal,
    };
  }

  /**
   * 消耗心数（生命值）
   */
  useHeart(userId: string): boolean {
    const data = this.getUserData(userId);
    
    if (data.hearts <= 0) {
      HiLog.warn(TAG, '心数不足，无法继续学习');
      return false;
    }
    
    data.hearts--;
    HiLog.info(TAG, `消耗心数: ${data.hearts}/${data.maxHearts}`);
    return true;
  }

  /**
   * 恢复心数
   */
  restoreHearts(userId: string): void {
    const data = this.getUserData(userId);
    data.hearts = data.maxHearts;
    HiLog.info(TAG, '心数已恢复');
  }

  /**
   * 获取用户游戏状态
   */
  getUserStatus(userId: string): {
    level: number;
    levelTitle: string;
    streak: number;
    hearts: number;
    coins: number;
    gems: number;
    league: string;
    rank: number;
  } {
    const data = this.getUserData(userId);
    const levelData = LEVEL_TABLE[data.level - 1] || LEVEL_TABLE[LEVEL_TABLE.length - 1];
    
    return {
      level: data.level,
      levelTitle: levelData.title,
      streak: data.streak,
      hearts: data.hearts,
      coins: data.coins,
      gems: data.gems,
      league: data.currentLeague,
      rank: data.leaderboardRank,
    };
  }
}

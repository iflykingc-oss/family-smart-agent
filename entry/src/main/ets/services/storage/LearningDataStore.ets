/**
 * ============================================================================
 * 学习数据持久化服务 - LearningDataStore
 * 核心：HarmonyOS分布式数据管理
 * 
 * 功能：
 * - 用户学习进度持久化
 * - 跨设备数据同步
 * - 遗忘曲线数据存储
 * - 用户画像持久化
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { relationalStore, ValuesBucket } from '@kit.ArkData';

/**
 * 用户学习数据
 */
export interface UserLearningData {
  userId: string;
  skillId: string;
  currentStep: number;
  totalSteps: number;
  completed: boolean;
  lastLearnTime: number;
  totalTimeSpent: number;
  correctCount: number;
  incorrectCount: number;
  streak: number;
  xp: number;
  level: number;
}

/**
 * 用户画像数据
 */
export interface UserProfileData {
  userId: string;
  name: string;
  preferMode: 'normal' | 'elder' | 'child' | 'newbie';
  preferDialect: string;
  totalSkillsCompleted: number;
  totalLearningMinutes: number;
  longestStreak: number;
  achievements: string[];
  createdAt: number;
  updatedAt: number;
}

/**
 * 遗忘曲线数据
 */
export interface ForgettingCurveData {
  userId: string;
  skillId: string;
  stepNumber: number;
  stability: number;      // 记忆稳定度
  difficulty: number;     // 难度
  interval: number;       // 当前间隔
  repetitions: number;     // 复习次数
  nextReview: number;     // 下次复习时间
  lastReview: number;     // 上次复习时间
}

/**
 * 数据库表定义
 */
const TABLES = {
  USER_LEARNING: 'user_learning',
  USER_PROFILE: 'user_profile',
  FORGETTING_CURVE: 'forgetting_curve',
  CUSTOM_SKILLS: 'custom_skills'
};

/**
 * 数据库配置
 */
const DB_CONFIG = {
  name: 'learning_assistant.db',
  version: 1
};

/**
 * 学习数据存储服务
 */
export class LearningDataStore {
  private static instance: LearningDataStore | null = null;
  
  private store: relationalStore.RdbStore | null = null;
  private initialized: boolean = false;

  static getInstance(): LearningDataStore {
    if (!LearningDataStore.instance) {
      LearningDataStore.instance = new LearningDataStore();
    }
    return LearningDataStore.instance;
  }

  private constructor() {
    HiLog.info("LearningDataStore", "学习数据存储服务初始化");
  }

  /**
   * 初始化数据库
   */
  async init(context: any): Promise<void> {
    if (this.initialized) return;
    
    try {
      HiLog.info("LearningDataStore", "初始化数据库...");
      
      // 创建数据库
      const context_ = getContext();
      this.store = await relationalStore.getRdbStore(context_, DB_CONFIG);
      
      // 创建表
      await this.createTables();
      
      this.initialized = true;
      HiLog.info("LearningDataStore", "数据库初始化完成");
    } catch (error) {
      HiLog.error("LearningDataStore", `数据库初始化失败: ${error}`);
      throw error;
    }
  }

  /**
   * 创建数据表
   */
  private async createTables(): Promise<void> {
    if (!this.store) return;
    
    // 用户学习进度表
    await this.store.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLES.USER_LEARNING} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        skill_id TEXT NOT NULL,
        current_step INTEGER DEFAULT 0,
        total_steps INTEGER DEFAULT 0,
        completed INTEGER DEFAULT 0,
        last_learn_time INTEGER DEFAULT 0,
        total_time_spent INTEGER DEFAULT 0,
        correct_count INTEGER DEFAULT 0,
        incorrect_count INTEGER DEFAULT 0,
        streak INTEGER DEFAULT 0,
        xp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now')),
        UNIQUE(user_id, skill_id)
      )
    `);
    
    // 用户画像表
    await this.store.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLES.USER_PROFILE} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT UNIQUE NOT NULL,
        name TEXT DEFAULT '',
        prefer_mode TEXT DEFAULT 'normal',
        prefer_dialect TEXT DEFAULT '',
        total_skills_completed INTEGER DEFAULT 0,
        total_learning_minutes INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        achievements TEXT DEFAULT '[]',
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        updated_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    `);
    
    // 遗忘曲线数据表
    await this.store.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLES.FORGETTING_CURVE} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        skill_id TEXT NOT NULL,
        step_number INTEGER NOT NULL,
        stability REAL DEFAULT 1.0,
        difficulty REAL DEFAULT 5.0,
        interval REAL DEFAULT 0,
        repetitions INTEGER DEFAULT 0,
        next_review INTEGER DEFAULT 0,
        last_review INTEGER DEFAULT 0,
        UNIQUE(user_id, skill_id, step_number)
      )
    `);
    
    // 自定义技能表
    await this.store.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLES.CUSTOM_SKILLS} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        skill_name TEXT NOT NULL,
        category TEXT DEFAULT '自定义',
        difficulty INTEGER DEFAULT 1,
        steps TEXT DEFAULT '[]',
        total_duration INTEGER DEFAULT 0,
        compliance INTEGER DEFAULT 1,
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    `);
    
    HiLog.info("LearningDataStore", "数据表创建完成");
  }

  // ==================== 用户学习进度 ====================

  /**
   * 保存学习进度
   */
  async saveLearningProgress(data: UserLearningData): Promise<void> {
    if (!this.store) {
      HiLog.warn("LearningDataStore", "数据库未初始化");
      return;
    }
    
    try {
      const bucket: ValuesBucket = {
        'user_id': data.userId,
        'skill_id': data.skillId,
        'current_step': data.currentStep,
        'total_steps': data.totalSteps,
        'completed': data.completed ? 1 : 0,
        'last_learn_time': data.lastLearnTime,
        'total_time_spent': data.totalTimeSpent,
        'correct_count': data.correctCount,
        'incorrect_count': data.incorrectCount,
        'streak': data.streak,
        'xp': data.xp,
        'level': data.level,
        'updated_at': Date.now()
      };
      
      await this.store.insert(TABLES.USER_LEARNING, bucket);
      HiLog.info("LearningDataStore", `保存进度: ${data.userId}/${data.skillId}`);
    } catch (error) {
      HiLog.error("LearningDataStore", `保存进度失败: ${error}`);
    }
  }

  /**
   * 获取用户所有学习进度
   */
  async getUserLearningProgress(userId: string): Promise<UserLearningData[]> {
    if (!this.store) return [];
    
    try {
      const predicates = new relationalStore.RdbPredicates(TABLES.USER_LEARNING);
      predicates.equalTo('user_id', userId);
      
      const result = await this.store.query(predicates);
      const data: UserLearningData[] = [];
      
      while (result.goToNextRow()) {
        data.push({
          userId: result.getString(result.getColumnIndex('user_id')),
          skillId: result.getString(result.getColumnIndex('skill_id')),
          currentStep: result.getLong(result.getColumnIndex('current_step')),
          totalSteps: result.getLong(result.getColumnIndex('total_steps')),
          completed: result.getLong(result.getColumnIndex('completed')) === 1,
          lastLearnTime: result.getLong(result.getColumnIndex('last_learn_time')),
          totalTimeSpent: result.getLong(result.getColumnIndex('total_time_spent')),
          correctCount: result.getLong(result.getColumnIndex('correct_count')),
          incorrectCount: result.getLong(result.getColumnIndex('incorrect_count')),
          streak: result.getLong(result.getColumnIndex('streak')),
          xp: result.getLong(result.getColumnIndex('xp')),
          level: result.getLong(result.getColumnIndex('level'))
        });
      }
      
      result.close();
      return data;
    } catch (error) {
      HiLog.error("LearningDataStore", `查询进度失败: ${error}`);
      return [];
    }
  }

  // ==================== 用户画像 ====================

  /**
   * 保存用户画像
   */
  async saveUserProfile(data: UserProfileData): Promise<void> {
    if (!this.store) return;
    
    try {
      const bucket: ValuesBucket = {
        'user_id': data.userId,
        'name': data.name,
        'prefer_mode': data.preferMode,
        'prefer_dialect': data.preferDialect,
        'total_skills_completed': data.totalSkillsCompleted,
        'total_learning_minutes': data.totalLearningMinutes,
        'longest_streak': data.longestStreak,
        'achievements': JSON.stringify(data.achievements),
        'updated_at': Date.now()
      };
      
      await this.store.insert(TABLES.USER_PROFILE, bucket);
      HiLog.info("LearningDataStore", `保存画像: ${data.userId}`);
    } catch (error) {
      HiLog.error("LearningDataStore", `保存画像失败: ${error}`);
    }
  }

  /**
   * 获取用户画像
   */
  async getUserProfile(userId: string): Promise<UserProfileData | null> {
    if (!this.store) return null;
    
    try {
      const predicates = new relationalStore.RdbPredicates(TABLES.USER_PROFILE);
      predicates.equalTo('user_id', userId);
      
      const result = await this.store.query(predicates);
      
      if (result.goToFirstRow()) {
        const profile: UserProfileData = {
          userId: result.getString(result.getColumnIndex('user_id')),
          name: result.getString(result.getColumnIndex('name')),
          preferMode: result.getString(result.getColumnIndex('prefer_mode')) as any,
          preferDialect: result.getString(result.getColumnIndex('prefer_dialect')),
          totalSkillsCompleted: result.getLong(result.getColumnIndex('total_skills_completed')),
          totalLearningMinutes: result.getLong(result.getColumnIndex('total_learning_minutes')),
          longestStreak: result.getLong(result.getColumnIndex('longest_streak')),
          achievements: JSON.parse(result.getString(result.getColumnIndex('achievements')) || '[]'),
          createdAt: result.getLong(result.getColumnIndex('created_at')),
          updatedAt: result.getLong(result.getColumnIndex('updated_at'))
        };
        result.close();
        return profile;
      }
      
      result.close();
      return null;
    } catch (error) {
      HiLog.error("LearningDataStore", `查询画像失败: ${error}`);
      return null;
    }
  }

  // ==================== 遗忘曲线 ====================

  /**
   * 保存遗忘曲线数据
   */
  async saveForgettingCurve(data: ForgettingCurveData): Promise<void> {
    if (!this.store) return;
    
    try {
      const bucket: ValuesBucket = {
        'user_id': data.userId,
        'skill_id': data.skillId,
        'step_number': data.stepNumber,
        'stability': data.stability,
        'difficulty': data.difficulty,
        'interval': data.interval,
        'repetitions': data.repetitions,
        'next_review': data.nextReview,
        'last_review': data.lastReview
      };
      
      await this.store.insert(TABLES.FORGETTING_CURVE, bucket);
      HiLog.info("LearningDataStore", `保存遗忘曲线: ${data.userId}/${data.skillId}`);
    } catch (error) {
      HiLog.error("LearningDataStore", `保存遗忘曲线失败: ${error}`);
    }
  }

  /**
   * 获取遗忘曲线待复习项
   */
  async getPendingReviews(userId: string): Promise<ForgettingCurveData[]> {
    if (!this.store) return [];
    
    try {
      const predicates = new relationalStore.RdbPredicates(TABLES.FORGETTING_CURVE);
      predicates.equalTo('user_id', userId);
      predicates.lessThanOrEqualTo('next_review', Date.now());
      
      const result = await this.store.query(predicates);
      const pending: ForgettingCurveData[] = [];
      
      while (result.goToNextRow()) {
        pending.push({
          userId: result.getString(result.getColumnIndex('user_id')),
          skillId: result.getString(result.getColumnIndex('skill_id')),
          stepNumber: result.getLong(result.getColumnIndex('step_number')),
          stability: result.getDouble(result.getColumnIndex('stability')),
          difficulty: result.getDouble(result.getColumnIndex('difficulty')),
          interval: result.getDouble(result.getColumnIndex('interval')),
          repetitions: result.getLong(result.getColumnIndex('repetitions')),
          nextReview: result.getLong(result.getColumnIndex('next_review')),
          lastReview: result.getLong(result.getColumnIndex('last_review'))
        });
      }
      
      result.close();
      return pending;
    } catch (error) {
      HiLog.error("LearningDataStore", `查询待复习失败: ${error}`);
      return [];
    }
  }

  // ==================== 跨设备同步 ====================

  /**
   * 导出用户数据（用于跨设备同步）
   */
  async exportUserData(userId: string): Promise<string> {
    const progress = await this.getUserLearningProgress(userId);
    const profile = await this.getUserProfile(userId);
    const reviews = await this.getPendingReviews(userId);
    
    return JSON.stringify({
      progress,
      profile,
      reviews,
      exportedAt: Date.now()
    });
  }

  /**
   * 导入用户数据（用于跨设备同步）
   */
  async importUserData(userId: string, dataStr: string): Promise<void> {
    try {
      const data = JSON.parse(dataStr);
      
      // 导入学习进度
      if (data.progress) {
        for (const p of data.progress) {
          await this.saveLearningProgress({ ...p, userId });
        }
      }
      
      // 导入用户画像
      if (data.profile) {
        await this.saveUserProfile({ ...data.profile, userId });
      }
      
      // 导入遗忘曲线
      if (data.reviews) {
        for (const r of data.reviews) {
          await this.saveForgettingCurve({ ...r, userId });
        }
      }
      
      HiLog.info("LearningDataStore", `导入数据完成: ${userId}`);
    } catch (error) {
      HiLog.error("LearningDataStore", `导入数据失败: ${error}`);
    }
  }
}

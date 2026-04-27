/**
 * ============================================================================
 * 应用数据库 - AppDatabase
 * 核心：鸿蒙 RDB 关系型数据库，持久化存储
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { relationalStore, RdbStore, RdbPredicates, ValuesBucket } from '@kit.ArkData';

/**
 * 数据库配置
 */
const DB_CONFIG = {
  name: 'learning_assistant.db',
  version: 1,
};

/**
 * 表定义
 */
export const TABLES = {
  USER: 'user',
  SKILL: 'skill',
  LEARNING_RECORD: 'learning_record',
  KNOWLEDGE_TRACKING: 'knowledge_tracking',
  ACHIEVEMENT: 'achievement',
  REVIEW_QUEUE: 'review_queue',
} as const;

/**
 * 创建表 SQL
 */
const CREATE_TABLE_SQLS = {
  [TABLES.USER]: `
    CREATE TABLE IF NOT EXISTS ${TABLES.USER} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      total_learning_minutes INTEGER DEFAULT 0,
      completed_skills_count INTEGER DEFAULT 0,
      current_streak INTEGER DEFAULT 0,
      longest_streak INTEGER DEFAULT 0,
      total_xp INTEGER DEFAULT 0,
      current_level INTEGER DEFAULT 1,
      achievement_ids TEXT DEFAULT '[]',
      current_skill_id TEXT,
      current_step INTEGER DEFAULT 0,
      preferences TEXT DEFAULT '{}'
    )
  `,
  
  [TABLES.SKILL]: `
    CREATE TABLE IF NOT EXISTS ${TABLES.SKILL} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      difficulty INTEGER NOT NULL,
      steps TEXT NOT NULL,
      prerequisites TEXT DEFAULT '[]',
      real_world_scenes TEXT DEFAULT '[]',
      tags TEXT DEFAULT '[]',
      estimated_time INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL
    )
  `,
  
  [TABLES.LEARNING_RECORD]: `
    CREATE TABLE IF NOT EXISTS ${TABLES.LEARNING_RECORD} (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      skill_id TEXT NOT NULL,
      step_number INTEGER NOT NULL,
      practice_id TEXT NOT NULL,
      result TEXT NOT NULL,
      time_spent INTEGER NOT NULL,
      hints_used INTEGER DEFAULT 0,
      time_of_day INTEGER NOT NULL,
      device_type TEXT NOT NULL,
      date TEXT NOT NULL,
      day_of_week INTEGER NOT NULL,
      timestamp INTEGER NOT NULL,
      INDEX idx_user_id (user_id),
      INDEX idx_skill_id (skill_id),
      INDEX idx_date (date)
    )
  `,
  
  [TABLES.KNOWLEDGE_TRACKING]: `
    CREATE TABLE IF NOT EXISTS ${TABLES.KNOWLEDGE_TRACKING} (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      skill_id TEXT NOT NULL,
      knowledge_point_id TEXT NOT NULL,
      p_known REAL DEFAULT 0.01,
      learning_count INTEGER DEFAULT 0,
      correct_count INTEGER DEFAULT 0,
      incorrect_count INTEGER DEFAULT 0,
      p_learn REAL DEFAULT 0.1,
      p_slip REAL DEFAULT 0.1,
      p_guess REAL DEFAULT 0.3,
      last_updated INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      INDEX idx_user_skill (user_id, skill_id)
    )
  `,
  
  [TABLES.ACHIEVEMENT]: `
    CREATE TABLE IF NOT EXISTS ${TABLES.ACHIEVEMENT} (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      achievement_id TEXT NOT NULL,
      unlocked_at INTEGER NOT NULL,
      INDEX idx_user (user_id)
    )
  `,
  
  [TABLES.REVIEW_QUEUE]: `
    CREATE TABLE IF NOT EXISTS ${TABLES.REVIEW_QUEUE} (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      skill_id TEXT NOT NULL,
      step_number INTEGER NOT NULL,
      stability REAL DEFAULT 0,
      difficulty REAL DEFAULT 5,
      interval_days REAL DEFAULT 0,
      retrievability REAL DEFAULT 1,
      due_time INTEGER NOT NULL,
      priority TEXT DEFAULT 'medium',
      INDEX idx_user_due (user_id, due_time)
    )
  `,
};

/**
 * 应用数据库
 */
export class AppDatabase {
  private static instance: AppDatabase | null = null;
  
  private rdbStore: RdbStore | null = null;
  private initialized: boolean = false;

  /**
   * 获取单例实例
   */
  static getInstance(): AppDatabase {
    if (!AppDatabase.instance) {
      AppDatabase.instance = new AppDatabase();
    }
    return AppDatabase.instance;
  }

  private constructor() {
    HiLog.info("AppDatabase", "数据库初始化");
  }

  /**
   * 初始化数据库
   */
  async init(): Promise<void> {
    if (this.initialized) return;
    
    try {
      const context = getContext();
      this.rdbStore = await relationalStore.getRdbStore(context, DB_CONFIG);
      
      // 创建表
      await this.createTables();
      
      this.initialized = true;
      HiLog.info("AppDatabase", "数据库初始化成功");
    } catch (error: any) {
      HiLog.error("AppDatabase", `数据库初始化失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 创建表
   */
  private async createTables(): Promise<void> {
    if (!this.rdbStore) return;
    
    for (const sql of Object.values(CREATE_TABLE_SQLS)) {
      await this.rdbStore.executeSql(sql);
    }
    
    HiLog.info("AppDatabase", `创建${Object.keys(TABLES).length}个表`);
  }

  /**
   * 获取数据库实例
   */
  getStore(): RdbStore {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    return this.rdbStore;
  }

  /**
   * 检查是否已初始化
   */
  isInitialized(): boolean {
    return this.initialized;
  }

  /**
   * 关闭数据库
   */
  async close(): Promise<void> {
    if (this.rdbStore) {
      await this.rdbStore.close();
      this.rdbStore = null;
      this.initialized = false;
      HiLog.info("AppDatabase", "数据库已关闭");
    }
  }

  /**
   * 清空所有数据（调试用）
   */
  async clearAll(): Promise<void> {
    if (!this.rdbStore) return;
    
    for (const tableName of Object.values(TABLES)) {
      await this.rdbStore.executeSql(`DELETE FROM ${tableName}`);
    }
    
    HiLog.info("AppDatabase", "清空所有数据");
  }
}

/**
 * 便捷获取数据库实例
 */
export function getDatabase(): AppDatabase {
  return AppDatabase.getInstance();
}

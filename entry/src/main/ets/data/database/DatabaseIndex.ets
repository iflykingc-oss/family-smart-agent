/**
 * ============================================================================
 * 数据库索引优化
 * 创建额外索引提升查询性能
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { AppDatabase } from './AppDatabase';

/**
 * 索引定义
 */
const INDEX_SQLS = {
  // 学习记录索引
  'idx_learning_record_user_date': `
    CREATE INDEX IF NOT EXISTS idx_learning_record_user_date 
    ON learning_record(user_id, date DESC)
  `,
  'idx_learning_record_skill_date': `
    CREATE INDEX IF NOT EXISTS idx_learning_record_skill_date 
    ON learning_record(skill_id, date DESC)
  `,
  
  // 知识追踪索引
  'idx_knowledge_tracking_user': `
    CREATE INDEX IF NOT EXISTS idx_knowledge_tracking_user 
    ON knowledge_tracking(user_id)
  `,
  'idx_knowledge_tracking_skill': `
    CREATE INDEX IF NOT EXISTS idx_knowledge_tracking_skill 
    ON knowledge_tracking(skill_id)
  `,
  
  // 复习队列索引
  'idx_review_queue_user_due': `
    CREATE INDEX IF NOT EXISTS idx_review_queue_user_due 
    ON review_queue(user_id, due_time ASC)
  `,
  'idx_review_queue_priority': `
    CREATE INDEX IF NOT EXISTS idx_review_queue_priority 
    ON review_queue(priority, due_time ASC)
  `,
  
  // 成就索引
  'idx_achievement_user': `
    CREATE INDEX IF NOT EXISTS idx_achievement_user 
    ON achievement(user_id)
  `,
};

/**
 * 数据库索引管理器
 */
export class DatabaseIndexManager {
  private static instance: DatabaseIndexManager | null = null;
  
  private database: AppDatabase;

  /**
   * 获取单例实例
   */
  static getInstance(): DatabaseIndexManager {
    if (!DatabaseIndexManager.instance) {
      DatabaseIndexManager.instance = new DatabaseIndexManager();
    }
    return DatabaseIndexManager.instance;
  }

  private constructor() {
    this.database = AppDatabase.getInstance();
    HiLog.info("DatabaseIndexManager", "初始化");
  }

  /**
   * 创建所有索引
   */
  async createAllIndexes(): Promise<void> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      HiLog.info("DatabaseIndexManager", `开始创建${Object.keys(INDEX_SQLS).length}个索引`);
      
      for (const [name, sql] of Object.entries(INDEX_SQLS)) {
        try {
          await store.executeSql(sql);
          HiLog.info("DatabaseIndexManager", `创建索引成功：${name}`);
        } catch (error: any) {
          HiLog.warn("DatabaseIndexManager", `创建索引失败 ${name}: ${error.message}`);
        }
      }
      
      HiLog.info("DatabaseIndexManager", "索引创建完成");
    } catch (error: any) {
      HiLog.error("DatabaseIndexManager", `创建索引失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 分析索引使用情况
   */
  async analyzeIndexUsage(): Promise<{
    totalIndexes: number;
    usedIndexes: number;
    unusedIndexes: string[];
  }> {
    // TODO: 查询 SQLite 统计信息
    return {
      totalIndexes: Object.keys(INDEX_SQLS).length,
      usedIndexes: 0,
      unusedIndexes: [],
    };
  }

  /**
   * 删除未使用的索引
   */
  async dropUnusedIndexes(): Promise<void> {
    const analysis = await this.analyzeIndexUsage();
    
    for (const indexName of analysis.unusedIndexes) {
      try {
        await this.database.getStore().executeSql(`DROP INDEX IF EXISTS ${indexName}`);
        HiLog.info("DatabaseIndexManager", `删除未使用索引：${indexName}`);
      } catch (error: any) {
        HiLog.warn("DatabaseIndexManager", `删除索引失败 ${indexName}: ${error.message}`);
      }
    }
  }
}

/**
 * 便捷函数
 */
export async function createDatabaseIndexes(): Promise<void> {
  await DatabaseIndexManager.getInstance().createAllIndexes();
}

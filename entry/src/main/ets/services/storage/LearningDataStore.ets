/**
 * ============================================================================
 * 学习数据存储层 - LearningDataStore
 * 基于鸿蒙 6 Rdb 关系型数据库
 * 
 * 职责：
 * 1. 用户技能数据持久化
 * 2. 学习记录存储
 * 3. 复习队列管理
 * 4. 数据统计查询
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkDataKit';
import { common } from '@kit.AbilityKit';

const TAG = 'LearningDataStore';

/**
 * 用户技能记录
 */
export interface UserSkillRecord {
  userId: string;
  skillId: string;
  level: number;
  practiceCount: number;
  lastPracticed: number;
  weakPoints: string[];
  strongPoints: string[];
  confidence: number;
  
  // FSRS 状态
  fsrsStability: number;
  fsrsDifficulty: number;
  fsrsRetrievability: number;
  fsrsInterval: number;
  fsrsRepetitions: number;
  fsrsDueDate: number;
  
  createdAt: number;
  updatedAt: number;
}

/**
 * 学习记录
 */
export interface LearningRecordData {
  id: number;
  userId: string;
  skillId: string;
  stepNumber: number;
  result: 'correct' | 'incorrect' | 'partial';
  timeSpent: number;
  hintsUsed: number;
  createdAt: number;
}

/**
 * 学习统计
 */
export interface LearningStats {
  totalLearningTime: number;
  completedSkills: number;
  averageAccuracy: number;
  streak: number;
  totalPractices: number;
}

/**
 * 学习数据存储
 */
export class LearningDataStore {
  private static instance: LearningDataStore | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;

  static getInstance(): LearningDataStore {
    if (!LearningDataStore.instance) {
      LearningDataStore.instance = new LearningDataStore();
    }
    return LearningDataStore.instance;
  }

  private constructor() {}

  /**
   * 初始化数据库
   */
  async initialize(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const config: relationalStore.RdbStoreConfig = {
        name: 'xiaoe_learning.db',
        securityLevel: relationalStore.SecurityLevel.S1
      };
      
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.createTables();
      
      HiLog.info(TAG, '数据库初始化完成');
      return true;
    } catch (error) {
      HiLog.error(TAG, `数据库初始化失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 创建表
   */
  private async createTables(): Promise<void> {
    if (!this.rdbStore) return;

    const sqls = [
      // 用户技能表
      `CREATE TABLE IF NOT EXISTS user_skills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        skill_id TEXT NOT NULL,
        level REAL DEFAULT 0,
        practice_count INTEGER DEFAULT 0,
        last_practiced INTEGER,
        weak_points TEXT DEFAULT '[]',
        strong_points TEXT DEFAULT '[]',
        confidence REAL DEFAULT 0.5,
        fsrs_stability REAL DEFAULT 0,
        fsrs_difficulty REAL DEFAULT 5,
        fsrs_retrievability REAL DEFAULT 1,
        fsrs_interval INTEGER DEFAULT 0,
        fsrs_repetitions INTEGER DEFAULT 0,
        fsrs_due_date INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(user_id, skill_id)
      )`,

      // 学习记录表
      `CREATE TABLE IF NOT EXISTS learning_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        skill_id TEXT NOT NULL,
        step_number INTEGER NOT NULL,
        result TEXT NOT NULL,
        time_spent INTEGER DEFAULT 0,
        hints_used INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL
      )`,

      // 索引
      `CREATE INDEX IF NOT EXISTS idx_user_skills_user ON user_skills(user_id)`,
      `CREATE INDEX IF NOT EXISTS idx_learning_records_user ON learning_records(user_id)`,
      `CREATE INDEX IF NOT EXISTS idx_learning_records_skill ON learning_records(skill_id)`,
      `CREATE INDEX IF NOT EXISTS idx_learning_records_time ON learning_records(created_at)`,
    ];

    for (const sql of sqls) {
      await this.rdbStore.executeSql(sql);
    }

    HiLog.info(TAG, '表创建完成');
  }

  // ==================== 用户技能操作 ====================

  /**
   * 获取用户技能
   */
  async getUserSkill(userId: string, skillId: string): Promise<UserSkillRecord | null> {
    if (!this.rdbStore) return null;

    try {
      const predicates = new relationalStore.RdbPredicates('user_skills');
      predicates.equal('user_id', userId);
      predicates.equal('skill_id', skillId);

      const resultSet = await this.rdbStore.query(predicates);
      
      if (resultSet.goToNextRow()) {
        return this.parseUserSkillRecord(resultSet);
      }
      
      return null;
    } catch (error) {
      HiLog.error(TAG, `获取用户技能失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 获取用户所有技能
   */
  async getUserSkills(userId: string): Promise<UserSkillRecord[]> {
    if (!this.rdbStore) return [];

    try {
      const predicates = new relationalStore.RdbPredicates('user_skills');
      predicates.equal('user_id', userId);

      const resultSet = await this.rdbStore.query(predicates);
      const skills: UserSkillRecord[] = [];
      
      while (resultSet.goToNextRow()) {
        skills.push(this.parseUserSkillRecord(resultSet));
      }
      
      return skills;
    } catch (error) {
      HiLog.error(TAG, `获取用户技能列表失败: ${JSON.stringify(error)}`);
      return [];
    }
  }

  /**
   * 保存/更新用户技能
   */
  async saveUserSkill(record: UserSkillRecord): Promise<boolean> {
    if (!this.rdbStore) return false;

    try {
      // 先查询是否存在
      const existing = await this.getUserSkill(record.userId, record.skillId);
      
      const values: relationalStore.ValuesBucket = {
        user_id: record.userId,
        skill_id: record.skillId,
        level: record.level,
        practice_count: record.practiceCount,
        last_practiced: record.lastPracticed,
        weak_points: JSON.stringify(record.weakPoints),
        strong_points: JSON.stringify(record.strongPoints),
        confidence: record.confidence,
        fsrs_stability: record.fsrsStability,
        fsrs_difficulty: record.fsrsDifficulty,
        fsrs_retrievability: record.fsrsRetrievability,
        fsrs_interval: record.fsrsInterval,
        fsrs_repetitions: record.fsrsRepetitions,
        fsrs_due_date: record.fsrsDueDate,
        updated_at: record.updatedAt
      };

      if (existing) {
        // 更新
        const predicates = new relationalStore.RdbPredicates('user_skills');
        predicates.equal('user_id', record.userId);
        predicates.equal('skill_id', record.skillId);
        await this.rdbStore.update(values, predicates);
      } else {
        // 插入
        values.created_at = record.createdAt;
        await this.rdbStore.insert(values);
      }
      
      HiLog.info(TAG, `用户技能已保存: ${record.userId}/${record.skillId}`);
      return true;
    } catch (error) {
      HiLog.error(TAG, `保存用户技能失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  // ==================== 学习记录操作 ====================

  /**
   * 添加学习记录
   */
  async addLearningRecord(record: Omit<LearningRecordData, 'id'>): Promise<boolean> {
    if (!this.rdbStore) return false;

    try {
      const values: relationalStore.ValuesBucket = {
        user_id: record.userId,
        skill_id: record.skillId,
        step_number: record.stepNumber,
        result: record.result,
        time_spent: record.timeSpent,
        hints_used: record.hintsUsed,
        created_at: record.createdAt
      };

      await this.rdbStore.insert(values);
      return true;
    } catch (error) {
      HiLog.error(TAG, `添加学习记录失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 获取用户学习记录
   */
  async getLearningRecords(userId: string, limit: number = 100): Promise<LearningRecordData[]> {
    if (!this.rdbStore) return [];

    try {
      const predicates = new relationalStore.RdbPredicates('learning_records');
      predicates.equal('user_id', userId);
      predicates.orderByDesc('created_at');
      predicates.limitAs(limit);

      const resultSet = await this.rdbStore.query(predicates);
      const records: LearningRecordData[] = [];
      
      while (resultSet.goToNextRow()) {
        records.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          userId: resultSet.getString(resultSet.getColumnIndex('user_id')),
          skillId: resultSet.getString(resultSet.getColumnIndex('skill_id')),
          stepNumber: resultSet.getLong(resultSet.getColumnIndex('step_number')),
          result: resultSet.getString(resultSet.getColumnIndex('result')) as any,
          timeSpent: resultSet.getLong(resultSet.getColumnIndex('time_spent')),
          hintsUsed: resultSet.getLong(resultSet.getColumnIndex('hints_used')),
          createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at'))
        });
      }
      
      return records;
    } catch (error) {
      HiLog.error(TAG, `获取学习记录失败: ${JSON.stringify(error)}`);
      return [];
    }
  }

  /**
   * 获取需要复习的技能
   */
  async getDueReviewSkills(userId: string): Promise<UserSkillRecord[]> {
    if (!this.rdbStore) return [];

    try {
      const now = Date.now();
      const predicates = new relationalStore.RdbPredicates('user_skills');
      predicates.equal('user_id', userId);
      predicates.lessThan('fsrs_due_date', now);

      const resultSet = await this.rdbStore.query(predicates);
      const skills: UserSkillRecord[] = [];
      
      while (resultSet.goToNextRow()) {
        skills.push(this.parseUserSkillRecord(resultSet));
      }
      
      return skills;
    } catch (error) {
      HiLog.error(TAG, `获取复习技能失败: ${JSON.stringify(error)}`);
      return [];
    }
  }

  // ==================== 统计查询 ====================

  /**
   * 获取学习统计
   */
  async getLearningStats(userId: string): Promise<LearningStats> {
    if (!this.rdbStore) {
      return { totalLearningTime: 0, completedSkills: 0, averageAccuracy: 0, streak: 0, totalPractices: 0 };
    }

    try {
      // 总学习时间
      const timeResult = await this.rdbStore.querySql(
        { sql: 'SELECT SUM(time_spent) as total FROM learning_records WHERE user_id = ?', bindVars: [userId] }
      );
      const totalLearningTime = timeResult.goToNextRow() ? timeResult.getLong(timeResult.getColumnIndex('total')) : 0;

      // 总练习次数
      const countResult = await this.rdbStore.querySql(
        { sql: 'SELECT COUNT(*) as count FROM learning_records WHERE user_id = ?', bindVars: [userId] }
      );
      const totalPractices = countResult.goToNextRow() ? countResult.getLong(countResult.getColumnIndex('count')) : 0;

      // 正确率
      const correctResult = await this.rdbStore.querySql(
        { sql: 'SELECT COUNT(*) as count FROM learning_records WHERE user_id = ? AND result = ?', bindVars: [userId, 'correct'] }
      );
      const correctCount = correctResult.goToNextRow() ? correctResult.getLong(correctResult.getColumnIndex('count')) : 0;
      const averageAccuracy = totalPractices > 0 ? correctCount / totalPractices : 0;

      // 完成技能数（level >= 3）
      const completedResult = await this.rdbStore.querySql(
        { sql: 'SELECT COUNT(*) as count FROM user_skills WHERE user_id = ? AND level >= 3', bindVars: [userId] }
      );
      const completedSkills = completedResult.goToNextRow() ? completedResult.getLong(completedResult.getColumnIndex('count')) : 0;

      // 连续学习天数（简化实现）
      const streak = await this.calculateStreak(userId);

      return {
        totalLearningTime: totalLearningTime / 60, // 转换为分钟
        completedSkills,
        averageAccuracy,
        streak,
        totalPractices
      };
    } catch (error) {
      HiLog.error(TAG, `获取学习统计失败: ${JSON.stringify(error)}`);
      return { totalLearningTime: 0, completedSkills: 0, averageAccuracy: 0, streak: 0, totalPractices: 0 };
    }
  }

  /**
   * 计算连续学习天数
   */
  private async calculateStreak(userId: string): Promise<number> {
    if (!this.rdbStore) return 0;

    try {
      const now = Date.now();
      const oneDay = 24 * 60 * 60 * 1000;
      let streak = 0;
      let checkDate = new Date(now).toISOString().split('T')[0];

      for (let i = 0; i < 365; i++) {
        const date = new Date(now - i * oneDay).toISOString().split('T')[0];
        const result = await this.rdbStore.querySql({
          sql: 'SELECT COUNT(*) as count FROM learning_records WHERE user_id = ? AND DATE(created_at / 1000, "unixepoch") = ?',
          bindVars: [userId, date]
        });
        
        if (result.goToNextRow() && result.getLong(result.getColumnIndex('count')) > 0) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (error) {
      HiLog.error(TAG, `计算连续天数失败: ${JSON.stringify(error)}`);
      return 0;
    }
  }

  // ==================== 私有方法 ====================

  /**
   * 解析用户技能记录
   */
  private parseUserSkillRecord(resultSet: relationalStore.ResultSet): UserSkillRecord {
    return {
      userId: resultSet.getString(resultSet.getColumnIndex('user_id')),
      skillId: resultSet.getString(resultSet.getColumnIndex('skill_id')),
      level: resultSet.getDouble(resultSet.getColumnIndex('level')),
      practiceCount: resultSet.getLong(resultSet.getColumnIndex('practice_count')),
      lastPracticed: resultSet.getLong(resultSet.getColumnIndex('last_practiced')),
      weakPoints: JSON.parse(resultSet.getString(resultSet.getColumnIndex('weak_points')) || '[]'),
      strongPoints: JSON.parse(resultSet.getString(resultSet.getColumnIndex('strong_points')) || '[]'),
      confidence: resultSet.getDouble(resultSet.getColumnIndex('confidence')),
      fsrsStability: resultSet.getDouble(resultSet.getColumnIndex('fsrs_stability')),
      fsrsDifficulty: resultSet.getDouble(resultSet.getColumnIndex('fsrs_difficulty')),
      fsrsRetrievability: resultSet.getDouble(resultSet.getColumnIndex('fsrs_retrievability')),
      fsrsInterval: resultSet.getLong(resultSet.getColumnIndex('fsrs_interval')),
      fsrsRepetitions: resultSet.getLong(resultSet.getColumnIndex('fsrs_repetitions')),
      fsrsDueDate: resultSet.getLong(resultSet.getColumnIndex('fsrs_due_date')),
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
    };
  }
}

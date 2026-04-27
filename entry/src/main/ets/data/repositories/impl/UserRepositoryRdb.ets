/**
 * ============================================================================
 * 用户仓库 RDB 实现 - UserRepositoryRdb
 * 使用鸿蒙 RDB 关系型数据库
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { IUserRepository } from '../interfaces/IUserRepository';
import { UserEntity, UserDTO } from '../../../domain/entities/UserEntity';
import { AppDatabase, TABLES } from '../../database/AppDatabase';
import { RdbPredicates, ValuesBucket } from '@kit.ArkData';

/**
 * 用户仓库 RDB 实现
 */
export class UserRepositoryRdb implements IUserRepository {
  private database: AppDatabase;
  private static instance: UserRepositoryRdb | null = null;

  /**
   * 获取单例实例
   */
  static getInstance(): UserRepositoryRdb {
    if (!UserRepositoryRdb.instance) {
      UserRepositoryRdb.instance = new UserRepositoryRdb();
    }
    return UserRepositoryRdb.instance;
  }

  private constructor() {
    this.database = AppDatabase.getInstance();
    HiLog.info("UserRepositoryRdb", "初始化");
  }

  /**
   * 根据 ID 查找用户
   */
  async findById(id: string): Promise<UserEntity | null> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.USER);
      predicates.equalTo('id', id);
      
      const result = await store.query(predicates);
      
      if (result.count === 0) {
        result.close();
        return null;
      }
      
      result.goToFirstRow();
      const dto = this.rowToDTO(result);
      result.close();
      
      return UserEntity.fromDTO(dto);
    } catch (error: any) {
      HiLog.error("UserRepositoryRdb", `查找失败：${error.message}`);
      return null;
    }
  }

  /**
   * 保存用户
   */
  async save(user: UserEntity): Promise<void> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const bucket: ValuesBucket = this.entityToBucket(user);
      
      // 检查是否存在
      const existing = await this.findById(user.id);
      if (existing) {
        // 更新
        const predicates = new RdbPredicates(TABLES.USER);
        predicates.equalTo('id', user.id);
        await store.update(bucket, predicates);
        HiLog.info("UserRepositoryRdb", `更新用户：${user.id}`);
      } else {
        // 插入
        await store.insert(TABLES.USER, bucket);
        HiLog.info("UserRepositoryRdb", `保存用户：${user.id}`);
      }
    } catch (error: any) {
      HiLog.error("UserRepositoryRdb", `保存失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 更新用户
   */
  async update(user: UserEntity): Promise<void> {
    await this.save(user);
  }

  /**
   * 删除用户
   */
  async delete(id: string): Promise<void> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.USER);
      predicates.equalTo('id', id);
      
      await store.delete(predicates);
      HiLog.info("UserRepositoryRdb", `删除用户：${id}`);
    } catch (error: any) {
      HiLog.error("UserRepositoryRdb", `删除失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 查找所有用户
   */
  async findAll(): Promise<UserEntity[]> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.USER);
      const result = await store.query(predicates);
      
      const users: UserEntity[] = [];
      while (result.goToNextRow()) {
        const dto = this.rowToDTO(result);
        users.push(UserEntity.fromDTO(dto));
      }
      
      result.close();
      return users;
    } catch (error: any) {
      HiLog.error("UserRepositoryRdb", `查找所有失败：${error.message}`);
      return [];
    }
  }

  /**
   * 将行转换为 DTO
   */
  private rowToDTO(result: any): UserDTO {
    return {
      id: result.getString(result.getColumnIndex('id')),
      name: result.getString(result.getColumnIndex('name')),
      createdAt: result.getLong(result.getColumnIndex('created_at')),
      updatedAt: result.getLong(result.getColumnIndex('updated_at')),
      stats: {
        totalLearningMinutes: result.getLong(result.getColumnIndex('total_learning_minutes')),
        completedSkillsCount: result.getLong(result.getColumnIndex('completed_skills_count')),
        currentStreak: result.getLong(result.getColumnIndex('current_streak')),
        longestStreak: result.getLong(result.getColumnIndex('longest_streak')),
        totalXP: result.getLong(result.getColumnIndex('total_xp')),
        currentLevel: result.getLong(result.getColumnIndex('current_level')),
        achievementIds: JSON.parse(result.getString(result.getColumnIndex('achievement_ids')) || '[]'),
      },
      preferences: JSON.parse(result.getString(result.getColumnIndex('preferences')) || '{}'),
      currentSkillId: result.getString(result.getColumnIndex('current_skill_id')),
      currentStep: result.getLong(result.getColumnIndex('current_step')),
    };
  }

  /**
   * 将实体转换为 ValuesBucket
   */
  private entityToBucket(user: UserEntity): ValuesBucket {
    return {
      'id': user.id,
      'name': user.name,
      'created_at': user.createdAt,
      'updated_at': user.updatedAt,
      'total_learning_minutes': user.stats.totalLearningMinutes,
      'completed_skills_count': user.stats.completedSkillsCount,
      'current_streak': user.stats.currentStreak,
      'longest_streak': user.stats.longestStreak,
      'total_xp': user.stats.totalXP,
      'current_level': user.stats.currentLevel,
      'achievement_ids': JSON.stringify(user.stats.achievementIds),
      'current_skill_id': user.currentSkillId || null,
      'current_step': user.currentStep,
      'preferences': JSON.stringify(user.preferences),
    };
  }
}

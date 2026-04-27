/**
 * ============================================================================
 * 学习记录仓库 RDB 实现 - LearningRecordRepositoryRdb
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { ILearningRecordRepository, LearningRecordQuery } from '../interfaces/ILearningRecordRepository';
import { LearningRecordEntity, LearningRecordDTO, LearningResult, DeviceType } from '../../../domain/entities/LearningRecordEntity';
import { AppDatabase, TABLES } from '../../database/AppDatabase';
import { RdbPredicates, ValuesBucket } from '@kit.ArkData';

/**
 * 学习记录仓库 RDB 实现
 */
export class LearningRecordRepositoryRdb implements ILearningRecordRepository {
  private database: AppDatabase;
  private static instance: LearningRecordRepositoryRdb | null = null;

  static getInstance(): LearningRecordRepositoryRdb {
    if (!LearningRecordRepositoryRdb.instance) {
      LearningRecordRepositoryRdb.instance = new LearningRecordRepositoryRdb();
    }
    return LearningRecordRepositoryRdb.instance;
  }

  private constructor() {
    this.database = AppDatabase.getInstance();
    HiLog.info("LearningRecordRepositoryRdb", "初始化");
  }

  async findById(id: string): Promise<LearningRecordEntity | null> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.LEARNING_RECORD);
      predicates.equalTo('id', id);
      
      const result = await store.query(predicates);
      if (result.count === 0) {
        result.close();
        return null;
      }
      
      result.goToFirstRow();
      const dto = this.rowToDTO(result);
      result.close();
      
      return LearningRecordEntity.fromDTO(dto);
    } catch (error: any) {
      HiLog.error("LearningRecordRepositoryRdb", `查找失败：${error.message}`);
      return null;
    }
  }

  async save(record: LearningRecordEntity): Promise<void> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const bucket: ValuesBucket = this.entityToBucket(record);
      await store.insert(TABLES.LEARNING_RECORD, bucket);
      HiLog.info("LearningRecordRepositoryRdb", `保存记录：${record.id}`);
    } catch (error: any) {
      HiLog.error("LearningRecordRepositoryRdb", `保存失败：${error.message}`);
      throw error;
    }
  }

  async saveAll(records: LearningRecordEntity[]): Promise<void> {
    for (const record of records) {
      await this.save(record);
    }
  }

  async query(query: LearningRecordQuery): Promise<LearningRecordEntity[]> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.LEARNING_RECORD);
      
      if (query.userId) {
        predicates.equalTo('user_id', query.userId);
      }
      if (query.skillId) {
        predicates.equalTo('skill_id', query.skillId);
      }
      if (query.dateFrom) {
        predicates.greaterThanOrEqualTo('date', query.dateFrom);
      }
      if (query.dateTo) {
        predicates.lessThanOrEqualTo('date', query.dateTo);
      }
      
      // 排序
      predicates.orderByDesc('timestamp');
      
      // 分页
      const limit = query.limit || 100;
      const offset = query.offset || 0;
      
      const result = await store.query(predicates, limit, offset);
      
      const records: LearningRecordEntity[] = [];
      while (result.goToNextRow()) {
        const dto = this.rowToDTO(result);
        records.push(LearningRecordEntity.fromDTO(dto));
      }
      
      result.close();
      return records;
    } catch (error: any) {
      HiLog.error("LearningRecordRepositoryRdb", `查询失败：${error.message}`);
      return [];
    }
  }

  async count(query: LearningRecordQuery): Promise<number> {
    const records = await this.query(query);
    return records.length;
  }

  async delete(id: string): Promise<void> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.LEARNING_RECORD);
      predicates.equalTo('id', id);
      
      await store.delete(predicates);
      HiLog.info("LearningRecordRepositoryRdb", `删除记录：${id}`);
    } catch (error: any) {
      HiLog.error("LearningRecordRepositoryRdb", `删除失败：${error.message}`);
      throw error;
    }
  }

  async findByUserId(userId: string, limit: number = 100): Promise<LearningRecordEntity[]> {
    return this.query({ userId, limit });
  }

  async findBySkillId(skillId: string, limit: number = 100): Promise<LearningRecordEntity[]> {
    return this.query({ skillId, limit });
  }

  private rowToDTO(result: any): LearningRecordDTO {
    return {
      id: result.getString(result.getColumnIndex('id')),
      userId: result.getString(result.getColumnIndex('user_id')),
      skillId: result.getString(result.getColumnIndex('skill_id')),
      stepNumber: result.getLong(result.getColumnIndex('step_number')),
      practiceId: result.getString(result.getColumnIndex('practice_id')),
      result: result.getString(result.getColumnIndex('result')) as LearningResult,
      timeSpent: result.getLong(result.getColumnIndex('time_spent')),
      hintsUsed: result.getLong(result.getColumnIndex('hints_used')),
      timeOfDay: result.getLong(result.getColumnIndex('time_of_day')),
      deviceType: result.getString(result.getColumnIndex('device_type')) as DeviceType,
      date: result.getString(result.getColumnIndex('date')),
      dayOfWeek: result.getLong(result.getColumnIndex('day_of_week')),
      timestamp: result.getLong(result.getColumnIndex('timestamp')),
    };
  }

  private entityToBucket(record: LearningRecordEntity): ValuesBucket {
    return {
      'id': record.id,
      'user_id': record.userId,
      'skill_id': record.skillId,
      'step_number': record.stepNumber,
      'practice_id': record.practiceId,
      'result': record.result,
      'time_spent': record.timeSpent,
      'hints_used': record.hintsUsed,
      'time_of_day': record.timeOfDay,
      'device_type': record.deviceType,
      'date': record.date,
      'day_of_week': record.dayOfWeek,
      'timestamp': record.timestamp,
    };
  }
}

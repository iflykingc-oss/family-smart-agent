/**
 * ============================================================================
 * 学习记录仓库实现 - LearningRecordRepository
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { ILearningRecordRepository, LearningRecordQuery } from '../interfaces/ILearningRecordRepository';
import { LearningRecordEntity, LearningRecordDTO } from '../../../domain/entities/LearningRecordEntity';
import { ILocalDataSource } from '../../datasources/interfaces/ILocalDataSource';
import { PreferencesLocalDataSource } from '../../datasources/impl/PreferencesLocalDataSource';

/**
 * 学习记录仓库实现
 */
export class LearningRecordRepository implements ILearningRecordRepository {
  private static instance: LearningRecordRepository | null = null;
  
  private localDataSource: ILocalDataSource;
  private readonly keyPrefix: string = 'record_';
  private readonly indexKey: string = 'record_index';

  /**
   * 获取单例实例
   */
  static getInstance(): LearningRecordRepository {
    if (!LearningRecordRepository.instance) {
      LearningRecordRepository.instance = new LearningRecordRepository();
    }
    return LearningRecordRepository.instance;
  }

  private constructor() {
    this.localDataSource = PreferencesLocalDataSource.getInstance();
    HiLog.info("LearningRecordRepository", "初始化");
  }

  /**
   * 根据 ID 查找记录
   */
  async findById(id: string): Promise<LearningRecordEntity | null> {
    try {
      const key = `${this.keyPrefix}${id}`;
      const dto = await this.localDataSource.getObject<LearningRecordDTO>(key);
      
      if (!dto) {
        return null;
      }
      
      return LearningRecordEntity.fromDTO(dto);
    } catch (error: any) {
      HiLog.error("LearningRecordRepository", `查找失败：${error.message}`);
      return null;
    }
  }

  /**
   * 保存记录
   */
  async save(record: LearningRecordEntity): Promise<void> {
    try {
      const key = `${this.keyPrefix}${record.id}`;
      const dto = record.toDTO();
      await this.localDataSource.setObject(key, dto);
      
      // 更新索引
      await this.updateIndex(record.id);
      
      HiLog.info("LearningRecordRepository", `保存成功：${record.id}`);
    } catch (error: any) {
      HiLog.error("LearningRecordRepository", `保存失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 批量保存记录
   */
  async saveAll(records: LearningRecordEntity[]): Promise<void> {
    for (const record of records) {
      await this.save(record);
    }
  }

  /**
   * 查询记录
   */
  async query(query: LearningRecordQuery): Promise<LearningRecordEntity[]> {
    try {
      const allRecords = await this.findAll();
      
      let filtered = allRecords;
      
      // 按用户 ID 过滤
      if (query.userId) {
        filtered = filtered.filter(r => r.userId === query.userId);
      }
      
      // 按技能 ID 过滤
      if (query.skillId) {
        filtered = filtered.filter(r => r.skillId === query.skillId);
      }
      
      // 按日期范围过滤
      if (query.dateFrom) {
        filtered = filtered.filter(r => r.date >= query.dateFrom!);
      }
      if (query.dateTo) {
        filtered = filtered.filter(r => r.date <= query.dateTo!);
      }
      
      // 分页
      const offset = query.offset || 0;
      const limit = query.limit || filtered.length;
      filtered = filtered.slice(offset, offset + limit);
      
      return filtered;
    } catch (error: any) {
      HiLog.error("LearningRecordRepository", `查询失败：${error.message}`);
      return [];
    }
  }

  /**
   * 统计记录数
   */
  async count(query: LearningRecordQuery): Promise<number> {
    const records = await this.query(query);
    return records.length;
  }

  /**
   * 删除记录
   */
  async delete(id: string): Promise<void> {
    try {
      const key = `${this.keyPrefix}${id}`;
      await this.localDataSource.delete(key);
      
      // 从索引移除
      await this.removeFromIndex(id);
      
      HiLog.info("LearningRecordRepository", `删除成功：${id}`);
    } catch (error: any) {
      HiLog.error("LearningRecordRepository", `删除失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 根据用户 ID 查找记录
   */
  async findByUserId(userId: string, limit: number = 100): Promise<LearningRecordEntity[]> {
    return this.query({ userId, limit });
  }

  /**
   * 根据技能 ID 查找记录
   */
  async findBySkillId(skillId: string, limit: number = 100): Promise<LearningRecordEntity[]> {
    return this.query({ skillId, limit });
  }

  /**
   * 查找所有记录
   */
  private async findAll(): Promise<LearningRecordEntity[]> {
    try {
      const index = await this.localDataSource.getObject<string[]>(this.indexKey) || [];
      
      const records: LearningRecordEntity[] = [];
      for (const id of index) {
        const record = await this.findById(id);
        if (record) {
          records.push(record);
        }
      }
      
      return records;
    } catch (error: any) {
      HiLog.error("LearningRecordRepository", `查找所有失败：${error.message}`);
      return [];
    }
  }

  /**
   * 更新索引
   */
  private async updateIndex(recordId: string): Promise<void> {
    const index = await this.localDataSource.getObject<string[]>(this.indexKey) || [];
    if (!index.includes(recordId)) {
      index.push(recordId);
      await this.localDataSource.setObject(this.indexKey, index);
    }
  }

  /**
   * 从索引移除
   */
  private async removeFromIndex(recordId: string): Promise<void> {
    const index = await this.localDataSource.getObject<string[]>(this.indexKey) || [];
    const newIndex = index.filter(id => id !== recordId);
    await this.localDataSource.setObject(this.indexKey, newIndex);
  }
}

/**
 * ============================================================================
 * 学习记录仓库接口 - ILearningRecordRepository
 * ============================================================================
 */

import { LearningRecordEntity } from '../../../domain/entities/LearningRecordEntity';

/**
 * 查询条件
 */
export interface LearningRecordQuery {
  userId?: string;
  skillId?: string;
  dateFrom?: string;
  dateTo?: string;
  limit?: number;
  offset?: number;
}

/**
 * 学习记录仓库接口
 */
export interface ILearningRecordRepository {
  /**
   * 根据 ID 查找记录
   */
  findById(id: string): Promise<LearningRecordEntity | null>;
  
  /**
   * 保存记录
   */
  save(record: LearningRecordEntity): Promise<void>;
  
  /**
   * 批量保存记录
   */
  saveAll(records: LearningRecordEntity[]): Promise<void>;
  
  /**
   * 查询记录
   */
  query(query: LearningRecordQuery): Promise<LearningRecordEntity[]>;
  
  /**
   * 统计记录数
   */
  count(query: LearningRecordQuery): Promise<number>;
  
  /**
   * 删除记录
   */
  delete(id: string): Promise<void>;
  
  /**
   * 根据用户 ID 查找记录
   */
  findByUserId(userId: string, limit?: number): Promise<LearningRecordEntity[]>;
  
  /**
   * 根据技能 ID 查找记录
   */
  findBySkillId(skillId: string, limit?: number): Promise<LearningRecordEntity[]>;
}

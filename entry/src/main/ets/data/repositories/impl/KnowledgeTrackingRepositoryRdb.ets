/**
 * ============================================================================
 * 知识追踪仓库 RDB 实现 - KnowledgeTrackingRepositoryRdb
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { KnowledgeTrackingEntity, KnowledgeState } from '../../../domain/entities/KnowledgeTrackingEntity';
import { AppDatabase, TABLES } from '../../database/AppDatabase';
import { RdbPredicates, ValuesBucket } from '@kit.ArkData';

/**
 * 知识追踪仓库接口
 */
export interface IKnowledgeTrackingRepository {
  findById(userId: string, skillId: string, knowledgePointId: string): Promise<KnowledgeTrackingEntity | null>;
  save(entity: KnowledgeTrackingEntity): Promise<void>;
  findByUser(userId: string): Promise<KnowledgeTrackingEntity[]>;
}

/**
 * 知识追踪仓库 RDB 实现
 */
export class KnowledgeTrackingRepositoryRdb implements IKnowledgeTrackingRepository {
  private database: AppDatabase;
  private static instance: KnowledgeTrackingRepositoryRdb | null = null;

  static getInstance(): KnowledgeTrackingRepositoryRdb {
    if (!KnowledgeTrackingRepositoryRdb.instance) {
      KnowledgeTrackingRepositoryRdb.instance = new KnowledgeTrackingRepositoryRdb();
    }
    return KnowledgeTrackingRepositoryRdb.instance;
  }

  private constructor() {
    this.database = AppDatabase.getInstance();
    HiLog.info("KnowledgeTrackingRepositoryRdb", "初始化");
  }

  async findById(userId: string, skillId: string, knowledgePointId: string): Promise<KnowledgeTrackingEntity | null> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.KNOWLEDGE_TRACKING);
      predicates.equalTo('user_id', userId);
      predicates.equalTo('skill_id', skillId);
      predicates.equalTo('knowledge_point_id', knowledgePointId);
      
      const result = await store.query(predicates);
      if (result.count === 0) {
        result.close();
        return null;
      }
      
      result.goToFirstRow();
      const entity = this.rowToEntity(result);
      result.close();
      
      return entity;
    } catch (error: any) {
      HiLog.error("KnowledgeTrackingRepositoryRdb", `查找失败：${error.message}`);
      return null;
    }
  }

  async save(entity: KnowledgeTrackingEntity): Promise<void> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const bucket: ValuesBucket = this.entityToBucket(entity);
      
      const existing = await this.findById(entity.userId, entity.skillId, entity.knowledgePointId);
      if (existing) {
        const predicates = new RdbPredicates(TABLES.KNOWLEDGE_TRACKING);
        predicates.equalTo('id', entity.id);
        await store.update(bucket, predicates);
        HiLog.info("KnowledgeTrackingRepositoryRdb", `更新知识追踪：${entity.id}`);
      } else {
        await store.insert(TABLES.KNOWLEDGE_TRACKING, bucket);
        HiLog.info("KnowledgeTrackingRepositoryRdb", `保存知识追踪：${entity.id}`);
      }
    } catch (error: any) {
      HiLog.error("KnowledgeTrackingRepositoryRdb", `保存失败：${error.message}`);
      throw error;
    }
  }

  async findByUser(userId: string): Promise<KnowledgeTrackingEntity[]> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.KNOWLEDGE_TRACKING);
      predicates.equalTo('user_id', userId);
      
      const result = await store.query(predicates);
      const entities: KnowledgeTrackingEntity[] = [];
      while (result.goToNextRow()) {
        const entity = this.rowToEntity(result);
        entities.push(entity);
      }
      
      result.close();
      return entities;
    } catch (error: any) {
      HiLog.error("KnowledgeTrackingRepositoryRdb", `查找用户追踪失败：${error.message}`);
      return [];
    }
  }

  private rowToEntity(result: any): KnowledgeTrackingEntity {
    const entity = new KnowledgeTrackingEntity(
      result.getString(result.getColumnIndex('id')),
      result.getString(result.getColumnIndex('user_id')),
      result.getString(result.getColumnIndex('skill_id')),
      result.getString(result.getColumnIndex('knowledge_point_id')),
      result.getDouble(result.getColumnIndex('p_learn')),
      result.getDouble(result.getColumnIndex('p_slip')),
      result.getDouble(result.getColumnIndex('p_guess')),
      result.getLong(result.getColumnIndex('created_at'))
    );
    
    entity.state = {
      p_known: result.getDouble(result.getColumnIndex('p_known')),
      learning_count: result.getLong(result.getColumnIndex('learning_count')),
      correct_count: result.getLong(result.getColumnIndex('correct_count')),
      incorrect_count: result.getLong(result.getColumnIndex('incorrect_count')),
      last_updated: result.getLong(result.getColumnIndex('last_updated')),
    };
    
    return entity;
  }

  private entityToBucket(entity: KnowledgeTrackingEntity): ValuesBucket {
    return {
      'id': entity.id,
      'user_id': entity.userId,
      'skill_id': entity.skillId,
      'knowledge_point_id': entity.knowledgePointId,
      'p_known': entity.state.p_known,
      'learning_count': entity.state.learning_count,
      'correct_count': entity.state.correct_count,
      'incorrect_count': entity.state.incorrect_count,
      'p_learn': entity.p_learn,
      'p_slip': entity.p_slip,
      'p_guess': entity.p_guess,
      'last_updated': entity.state.last_updated,
      'created_at': entity.createdAt,
    };
  }
}

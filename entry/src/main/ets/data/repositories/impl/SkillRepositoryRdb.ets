/**
 * ============================================================================
 * 技能仓库 RDB 实现 - SkillRepositoryRdb
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { ISkillRepository } from '../interfaces/ISkillRepository';
import { SkillEntity, SkillDTO, SkillCategory } from '../../../domain/entities/SkillEntity';
import { AppDatabase, TABLES } from '../../database/AppDatabase';
import { RdbPredicates, ValuesBucket } from '@kit.ArkData';

/**
 * 技能仓库 RDB 实现
 */
export class SkillRepositoryRdb implements ISkillRepository {
  private database: AppDatabase;
  private static instance: SkillRepositoryRdb | null = null;

  static getInstance(): SkillRepositoryRdb {
    if (!SkillRepositoryRdb.instance) {
      SkillRepositoryRdb.instance = new SkillRepositoryRdb();
    }
    return SkillRepositoryRdb.instance;
  }

  private constructor() {
    this.database = AppDatabase.getInstance();
    HiLog.info("SkillRepositoryRdb", "初始化");
  }

  async findById(id: string): Promise<SkillEntity | null> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.SKILL);
      predicates.equalTo('id', id);
      
      const result = await store.query(predicates);
      if (result.count === 0) {
        result.close();
        return null;
      }
      
      result.goToFirstRow();
      const dto = this.rowToDTO(result);
      result.close();
      
      return SkillEntity.fromDTO(dto);
    } catch (error: any) {
      HiLog.error("SkillRepositoryRdb", `查找失败：${error.message}`);
      return null;
    }
  }

  async save(skill: SkillEntity): Promise<void> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const bucket: ValuesBucket = this.entityToBucket(skill);
      
      const existing = await this.findById(skill.id);
      if (existing) {
        const predicates = new RdbPredicates(TABLES.SKILL);
        predicates.equalTo('id', skill.id);
        await store.update(bucket, predicates);
        HiLog.info("SkillRepositoryRdb", `更新技能：${skill.id}`);
      } else {
        await store.insert(TABLES.SKILL, bucket);
        HiLog.info("SkillRepositoryRdb", `保存技能：${skill.id}`);
      }
    } catch (error: any) {
      HiLog.error("SkillRepositoryRdb", `保存失败：${error.message}`);
      throw error;
    }
  }

  async update(skill: SkillEntity): Promise<void> {
    await this.save(skill);
  }

  async delete(id: string): Promise<void> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.SKILL);
      predicates.equalTo('id', id);
      
      await store.delete(predicates);
      HiLog.info("SkillRepositoryRdb", `删除技能：${id}`);
    } catch (error: any) {
      HiLog.error("SkillRepositoryRdb", `删除失败：${error.message}`);
      throw error;
    }
  }

  async findAll(): Promise<SkillEntity[]> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.SKILL);
      const result = await store.query(predicates);
      
      const skills: SkillEntity[] = [];
      while (result.goToNextRow()) {
        const dto = this.rowToDTO(result);
        skills.push(SkillEntity.fromDTO(dto));
      }
      
      result.close();
      return skills;
    } catch (error: any) {
      HiLog.error("SkillRepositoryRdb", `查找所有失败：${error.message}`);
      return [];
    }
  }

  async findByCategory(category: string): Promise<SkillEntity[]> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.SKILL);
      predicates.equalTo('category', category);
      
      const result = await store.query(predicates);
      const skills: SkillEntity[] = [];
      while (result.goToNextRow()) {
        const dto = this.rowToDTO(result);
        skills.push(SkillEntity.fromDTO(dto));
      }
      
      result.close();
      return skills;
    } catch (error: any) {
      HiLog.error("SkillRepositoryRdb", `按类别查找失败：${error.message}`);
      return [];
    }
  }

  async findByDifficulty(difficulty: number): Promise<SkillEntity[]> {
    try {
      await this.database.init();
      const store = this.database.getStore();
      
      const predicates = new RdbPredicates(TABLES.SKILL);
      predicates.equalTo('difficulty', difficulty);
      
      const result = await store.query(predicates);
      const skills: SkillEntity[] = [];
      while (result.goToNextRow()) {
        const dto = this.rowToDTO(result);
        skills.push(SkillEntity.fromDTO(dto));
      }
      
      result.close();
      return skills;
    } catch (error: any) {
      HiLog.error("SkillRepositoryRdb", `按难度查找失败：${error.message}`);
      return [];
    }
  }

  async findPrerequisites(skillId: string): Promise<SkillEntity[]> {
    const skill = await this.findById(skillId);
    if (!skill) return [];
    
    const prerequisites: SkillEntity[] = [];
    for (const prereqId of skill.prerequisites) {
      const prereq = await this.findById(prereqId);
      if (prereq) {
        prerequisites.push(prereq);
      }
    }
    
    return prerequisites;
  }

  private rowToDTO(result: any): SkillDTO {
    return {
      id: result.getString(result.getColumnIndex('id')),
      name: result.getString(result.getColumnIndex('name')),
      category: result.getString(result.getColumnIndex('category')) as SkillCategory,
      difficulty: result.getLong(result.getColumnIndex('difficulty')),
      steps: JSON.parse(result.getString(result.getColumnIndex('steps'))),
      prerequisites: JSON.parse(result.getString(result.getColumnIndex('prerequisites')) || '[]'),
      realWorldScenes: JSON.parse(result.getString(result.getColumnIndex('real_world_scenes')) || '[]'),
      tags: JSON.parse(result.getString(result.getColumnIndex('tags')) || '[]'),
      estimatedTime: result.getLong(result.getColumnIndex('estimated_time')),
      createdAt: result.getLong(result.getColumnIndex('created_at')),
    };
  }

  private entityToBucket(skill: SkillEntity): ValuesBucket {
    return {
      'id': skill.id,
      'name': skill.name,
      'category': skill.category,
      'difficulty': skill.difficulty,
      'steps': JSON.stringify(skill.steps),
      'prerequisites': JSON.stringify(skill.prerequisites),
      'real_world_scenes': JSON.stringify(skill.realWorldScenes),
      'tags': JSON.stringify(skill.tags),
      'estimated_time': skill.estimatedTime,
      'created_at': skill.createdAt,
    };
  }
}

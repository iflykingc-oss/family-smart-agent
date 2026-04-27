/**
 * ============================================================================
 * 技能仓库实现 - SkillRepository
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { ISkillRepository } from '../interfaces/ISkillRepository';
import { SkillEntity, SkillDTO, SkillCategory } from '../../../domain/entities/SkillEntity';
import { ILocalDataSource } from '../../datasources/interfaces/ILocalDataSource';
import { PreferencesLocalDataSource } from '../../datasources/impl/PreferencesLocalDataSource';

/**
 * 技能仓库实现
 */
export class SkillRepository implements ISkillRepository {
  private static instance: SkillRepository | null = null;
  
  private localDataSource: ILocalDataSource;
  private readonly keyPrefix: string = 'skill_';
  private readonly indexKey: string = 'skill_index';

  /**
   * 获取单例实例
   */
  static getInstance(): SkillRepository {
    if (!SkillRepository.instance) {
      SkillRepository.instance = new SkillRepository();
    }
    return SkillRepository.instance;
  }

  private constructor() {
    this.localDataSource = PreferencesLocalDataSource.getInstance();
    HiLog.info("SkillRepository", "初始化");
  }

  /**
   * 根据 ID 查找技能
   */
  async findById(id: string): Promise<SkillEntity | null> {
    try {
      const key = `${this.keyPrefix}${id}`;
      const dto = await this.localDataSource.getObject<SkillDTO>(key);
      
      if (!dto) {
        return null;
      }
      
      return SkillEntity.fromDTO(dto);
    } catch (error: any) {
      HiLog.error("SkillRepository", `查找失败：${error.message}`);
      return null;
    }
  }

  /**
   * 保存技能
   */
  async save(skill: SkillEntity): Promise<void> {
    try {
      const key = `${this.keyPrefix}${skill.id}`;
      const dto = skill.toDTO();
      await this.localDataSource.setObject(key, dto);
      
      // 更新索引
      await this.updateIndex(skill.id);
      
      HiLog.info("SkillRepository", `保存成功：${skill.id}`);
    } catch (error: any) {
      HiLog.error("SkillRepository", `保存失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 更新技能
   */
  async update(skill: SkillEntity): Promise<void> {
    await this.save(skill);
  }

  /**
   * 删除技能
   */
  async delete(id: string): Promise<void> {
    try {
      const key = `${this.keyPrefix}${id}`;
      await this.localDataSource.delete(key);
      
      // 从索引移除
      await this.removeFromIndex(id);
      
      HiLog.info("SkillRepository", `删除成功：${id}`);
    } catch (error: any) {
      HiLog.error("SkillRepository", `删除失败：${error.message}`);
      throw error;
    }
  }

  /**
   * 查找所有技能
   */
  async findAll(): Promise<SkillEntity[]> {
    try {
      const index = await this.localDataSource.getObject<string[]>(this.indexKey) || [];
      
      const skills: SkillEntity[] = [];
      for (const id of index) {
        const skill = await this.findById(id);
        if (skill) {
          skills.push(skill);
        }
      }
      
      return skills;
    } catch (error: any) {
      HiLog.error("SkillRepository", `查找所有失败：${error.message}`);
      return [];
    }
  }

  /**
   * 根据类别查找技能
   */
  async findByCategory(category: string): Promise<SkillEntity[]> {
    const allSkills = await this.findAll();
    return allSkills.filter(s => s.category === category);
  }

  /**
   * 根据难度查找技能
   */
  async findByDifficulty(difficulty: number): Promise<SkillEntity[]> {
    const allSkills = await this.findAll();
    return allSkills.filter(s => s.difficulty === difficulty);
  }

  /**
   * 查找前置技能
   */
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

  /**
   * 更新索引
   */
  private async updateIndex(skillId: string): Promise<void> {
    const index = await this.localDataSource.getObject<string[]>(this.indexKey) || [];
    if (!index.includes(skillId)) {
      index.push(skillId);
      await this.localDataSource.setObject(this.indexKey, index);
    }
  }

  /**
   * 从索引移除
   */
  private async removeFromIndex(skillId: string): Promise<void> {
    const index = await this.localDataSource.getObject<string[]>(this.indexKey) || [];
    const newIndex = index.filter(id => id !== skillId);
    await this.localDataSource.setObject(this.indexKey, newIndex);
  }
}

/**
 * ============================================================================
 * 技能仓库接口 - ISkillRepository
 * ============================================================================
 */

import { SkillEntity } from '../../../domain/entities/SkillEntity';

/**
 * 技能仓库接口
 */
export interface ISkillRepository {
  /**
   * 根据 ID 查找技能
   */
  findById(id: string): Promise<SkillEntity | null>;
  
  /**
   * 保存技能
   */
  save(skill: SkillEntity): Promise<void>;
  
  /**
   * 更新技能
   */
  update(skill: SkillEntity): Promise<void>;
  
  /**
   * 删除技能
   */
  delete(id: string): Promise<void>;
  
  /**
   * 查找所有技能
   */
  findAll(): Promise<SkillEntity[]>;
  
  /**
   * 根据类别查找技能
   */
  findByCategory(category: string): Promise<SkillEntity[]>;
  
  /**
   * 根据难度查找技能
   */
  findByDifficulty(difficulty: number): Promise<SkillEntity[]>;
  
  /**
   * 查找前置技能
   */
  findPrerequisites(skillId: string): Promise<SkillEntity[]>;
}

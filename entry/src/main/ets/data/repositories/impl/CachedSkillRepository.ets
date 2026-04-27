/**
 * ============================================================================
 * 带缓存的技能仓库 - CachedSkillRepository
 * 装饰器模式，提升查询性能
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { ISkillRepository } from '../interfaces/ISkillRepository';
import { SkillEntity, SkillCategory } from '../../../domain/entities/SkillEntity';
import { AppCache } from '../../cache/AppCache';

/**
 * 带缓存的技能仓库
 */
export class CachedSkillRepository implements ISkillRepository {
  private delegate: ISkillRepository;
  private cache: AppCache;
  private static instance: CachedSkillRepository | null = null;

  /**
   * 获取单例实例
   */
  static getInstance(delegate: ISkillRepository): CachedSkillRepository {
    if (!CachedSkillRepository.instance) {
      CachedSkillRepository.instance = new CachedSkillRepository(delegate);
    }
    return CachedSkillRepository.instance;
  }

  private constructor(delegate: ISkillRepository) {
    this.delegate = delegate;
    this.cache = AppCache.getInstance({ maxSize: 50, defaultTTL: 600000 }); // 10 分钟
    HiLog.info("CachedSkillRepository", "初始化");
  }

  async findById(id: string): Promise<SkillEntity | null> {
    const cacheKey = `skill:${id}`;
    
    // 尝试从缓存获取
    const cached = this.cache.get<SkillEntity>(cacheKey);
    if (cached !== null) {
      HiLog.debug("CachedSkillRepository", `缓存命中：${id}`);
      return cached;
    }
    
    // 从数据库查询
    const skill = await this.delegate.findById(id);
    if (skill) {
      this.cache.set(cacheKey, skill);
    }
    
    return skill;
  }

  async save(skill: SkillEntity): Promise<void> {
    await this.delegate.save(skill);
    
    // 清除缓存
    this.cache.delete(`skill:${skill.id}`);
  }

  async update(skill: SkillEntity): Promise<void> {
    await this.delegate.update(skill);
    
    // 清除缓存
    this.cache.delete(`skill:${skill.id}`);
  }

  async delete(id: string): Promise<void> {
    await this.delegate.delete(id);
    
    // 清除缓存
    this.cache.delete(`skill:${id}`);
  }

  async findAll(): Promise<SkillEntity[]> {
    const cacheKey = 'skills:all';
    
    // 尝试从缓存获取
    const cached = this.cache.get<SkillEntity[]>(cacheKey);
    if (cached !== null) {
      return cached;
    }
    
    // 从数据库查询
    const skills = await this.delegate.findAll();
    this.cache.set(cacheKey, skills);
    
    return skills;
  }

  async findByCategory(category: string): Promise<SkillEntity[]> {
    const cacheKey = `skills:category:${category}`;
    
    // 尝试从缓存获取
    const cached = this.cache.get<SkillEntity[]>(cacheKey);
    if (cached !== null) {
      return cached;
    }
    
    // 从数据库查询
    const skills = await this.delegate.findByCategory(category);
    this.cache.set(cacheKey, skills, 300000); // 5 分钟
    
    return skills;
  }

  async findByDifficulty(difficulty: number): Promise<SkillEntity[]> {
    const cacheKey = `skills:difficulty:${difficulty}`;
    
    // 尝试从缓存获取
    const cached = this.cache.get<SkillEntity[]>(cacheKey);
    if (cached !== null) {
      return cached;
    }
    
    // 从数据库查询
    const skills = await this.delegate.findByDifficulty(difficulty);
    this.cache.set(cacheKey, skills, 300000);
    
    return skills;
  }

  async findPrerequisites(skillId: string): Promise<SkillEntity[]> {
    const cacheKey = `skills:prereqs:${skillId}`;
    
    // 尝试从缓存获取
    const cached = this.cache.get<SkillEntity[]>(cacheKey);
    if (cached !== null) {
      return cached;
    }
    
    // 从数据库查询
    const skills = await this.delegate.findPrerequisites(skillId);
    this.cache.set(cacheKey, skills, 300000);
    
    return skills;
  }

  /**
   * 清除所有缓存
   */
  clearCache(): void {
    this.cache.clear();
    HiLog.info("CachedSkillRepository", "清除所有缓存");
  }

  /**
   * 获取缓存统计
   */
  getCacheStats(): {
    size: number;
    maxSize: number;
  } {
    return this.cache.getStats();
  }
}

/**
 * ============================================================================
 * 缓存集成测试
 * 测试 LRU 缓存系统
 * ============================================================================
 */

import { describe, it, expect, beforeEach } from '@kit.TestKit';
import { AppCache } from '../../entry/src/main/ets/data/cache/AppCache';
import { CachedSkillRepository } from '../../entry/src/main/ets/data/repositories/impl/CachedSkillRepository';
import { SkillRepositoryRdb } from '../../entry/src/main/ets/data/repositories/impl/SkillRepositoryRdb';
import { SkillEntity, SkillCategory, SkillDifficulty } from '../../entry/src/main/ets/domain/entities/SkillEntity';

describe('CacheIntegration - 缓存集成测试', () => {
  let cache: AppCache;

  beforeEach(() => {
    cache = AppCache.getInstance({ maxSize: 10, defaultTTL: 1000 });
  });

  describe('基础缓存测试', () => {
    it('应该正确设置和获取缓存', () => {
      // Arrange
      cache.set('key1', 'value1');
      
      // Act
      const value = cache.get('key1');
      
      // Assert
      expect(value).toBe('value1');
    });

    it('应该返回 null 对于不存在的 key', () => {
      // Act
      const value = cache.get('nonexistent');
      
      // Assert
      expect(value).toBeNull();
    });

    it('应该正确删除缓存', () => {
      // Arrange
      cache.set('key2', 'value2');
      
      // Act
      cache.delete('key2');
      const value = cache.get('key2');
      
      // Assert
      expect(value).toBeNull();
    });

    it('应该清空所有缓存', () => {
      // Arrange
      cache.set('key3', 'value3');
      cache.set('key4', 'value4');
      
      // Act
      cache.clear();
      
      // Assert
      expect(cache.get('key3')).toBeNull();
      expect(cache.get('key4')).toBeNull();
    });
  });

  describe('TTL 过期测试', () => {
    it('应该在 TTL 过期后返回 null', async () => {
      // Arrange
      cache.set('key5', 'value5', 100); // 100ms TTL
      
      // Act
      await new Promise(resolve => setTimeout(resolve, 150));
      const value = cache.get('key5');
      
      // Assert
      expect(value).toBeNull();
    });

    it('应该在 TTL 内返回值', () => {
      // Arrange
      cache.set('key6', 'value6', 10000); // 10 秒 TTL
      
      // Act
      const value = cache.get('key6');
      
      // Assert
      expect(value).toBe('value6');
    });
  });

  describe('LRU 淘汰测试', () => {
    it('应该淘汰最旧的项', () => {
      // Arrange
      const smallCache = AppCache.getInstance({ maxSize: 3, defaultTTL: 60000 });
      smallCache.set('key1', 'value1');
      smallCache.set('key2', 'value2');
      smallCache.set('key3', 'value3');
      
      // Act
      smallCache.set('key4', 'value4'); // 应该淘汰 key1
      
      // Assert
      expect(smallCache.get('key1')).toBeNull();
      expect(smallCache.get('key4')).toBe('value4');
    });

    it('应该更新访问顺序', () => {
      // Arrange
      const smallCache = AppCache.getInstance({ maxSize: 3, defaultTTL: 60000 });
      smallCache.set('key1', 'value1');
      smallCache.set('key2', 'value2');
      smallCache.set('key3', 'value3');
      
      // Act
      smallCache.get('key1'); // 访问 key1
      smallCache.set('key4', 'value4'); // 应该淘汰 key2
      
      // Assert
      expect(smallCache.get('key1')).toBe('value1');
      expect(smallCache.get('key2')).toBeNull();
    });
  });

  describe('CachedSkillRepository 测试', () => {
    it('应该从缓存返回技能', async () => {
      // Arrange
      const mockRepo = {
        findById: jest.fn().mockResolvedValue(
          new SkillEntity('skill_001', '测试技能', SkillCategory.OFFICE, SkillDifficulty.BEGINNER, [])
        ),
        save: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
        findAll: jest.fn(),
        findByCategory: jest.fn(),
        findByDifficulty: jest.fn(),
        findPrerequisites: jest.fn(),
      };
      const cachedRepo = CachedSkillRepository.getInstance(mockRepo as any);
      
      // Act
      await cachedRepo.findById('skill_001');
      const cached = await cachedRepo.findById('skill_001');
      
      // Assert
      expect(cached).not.toBeNull();
      expect(mockRepo.findById).toHaveBeenCalledTimes(1); // 第二次应该从缓存
    });

    it('应该在保存后清除缓存', async () => {
      // Arrange
      const skill = new SkillEntity('skill_002', '测试技能 2', SkillCategory.OFFICE, SkillDifficulty.BEGINNER, []);
      const mockRepo = {
        findById: jest.fn().mockResolvedValue(skill),
        save: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
        findAll: jest.fn(),
        findByCategory: jest.fn(),
        findByDifficulty: jest.fn(),
        findPrerequisites: jest.fn(),
      };
      const cachedRepo = CachedSkillRepository.getInstance(mockRepo as any);
      
      // Act
      await cachedRepo.findById('skill_002');
      await cachedRepo.save(skill);
      await cachedRepo.findById('skill_002');
      
      // Assert
      expect(mockRepo.findById).toHaveBeenCalledTimes(2); // 保存后应该重新查询
    });
  });

  describe('缓存统计测试', () => {
    it('应该返回正确的统计信息', () => {
      // Arrange
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');
      cache.set('key3', 'value3');
      
      // Act
      const stats = cache.getStats();
      
      // Assert
      expect(stats.size).toBe(3);
      expect(stats.maxSize).toBe(10);
    });
  });
});

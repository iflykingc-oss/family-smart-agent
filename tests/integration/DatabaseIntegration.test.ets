/**
 * ============================================================================
 * 数据库集成测试
 * 测试 RDB 数据库 CRUD 操作
 * ============================================================================
 */

import { describe, it, expect, beforeAll, afterAll } from '@kit.TestKit';
import { AppDatabase, TABLES } from '../../entry/src/main/ets/data/database/AppDatabase';
import { UserRepositoryRdb } from '../../entry/src/main/ets/data/repositories/impl/UserRepositoryRdb';
import { SkillRepositoryRdb } from '../../entry/src/main/ets/data/repositories/impl/SkillRepositoryRdb';
import { LearningRecordRepositoryRdb } from '../../entry/src/main/ets/data/repositories/impl/LearningRecordRepositoryRdb';
import { UserEntity } from '../../entry/src/main/ets/domain/entities/UserEntity';
import { SkillEntity, SkillCategory, SkillDifficulty } from '../../entry/src/main/ets/domain/entities/SkillEntity';
import { LearningRecordEntity, LearningResult, DeviceType } from '../../entry/src/main/ets/domain/entities/LearningRecordEntity';

describe('DatabaseIntegration - 数据库集成测试', () => {
  let database: AppDatabase;
  let userRepository: UserRepositoryRdb;
  let skillRepository: SkillRepositoryRdb;
  let recordRepository: LearningRecordRepositoryRdb;

  beforeAll(async () => {
    database = AppDatabase.getInstance();
    await database.init();
    
    userRepository = UserRepositoryRdb.getInstance();
    skillRepository = SkillRepositoryRdb.getInstance();
    recordRepository = LearningRecordRepositoryRdb.getInstance();
  });

  afterAll(async () => {
    await database.clearAll();
    await database.close();
  });

  describe('UserRepository 测试', () => {
    it('应该正确保存和查找用户', async () => {
      // Arrange
      const user = new UserEntity('user_001', '测试用户');
      
      // Act
      await userRepository.save(user);
      const found = await userRepository.findById('user_001');
      
      // Assert
      expect(found).not.toBeNull();
      expect(found!.name).toBe('测试用户');
    });

    it('应该正确更新用户', async () => {
      // Arrange
      const user = new UserEntity('user_002', '测试用户 2');
      await userRepository.save(user);
      
      // Act
      user.name = '更新后的名字';
      await userRepository.update(user);
      const found = await userRepository.findById('user_002');
      
      // Assert
      expect(found!.name).toBe('更新后的名字');
    });

    it('应该正确删除用户', async () => {
      // Arrange
      const user = new UserEntity('user_003', '测试用户 3');
      await userRepository.save(user);
      
      // Act
      await userRepository.delete('user_003');
      const found = await userRepository.findById('user_003');
      
      // Assert
      expect(found).toBeNull();
    });

    it('应该查找所有用户', async () => {
      // Arrange
      await userRepository.save(new UserEntity('user_004', '用户 4'));
      await userRepository.save(new UserEntity('user_005', '用户 5'));
      
      // Act
      const users = await userRepository.findAll();
      
      // Assert
      expect(users.length).toBeGreaterThanOrEqual(2);
    });
  });

  describe('SkillRepository 测试', () => {
    it('应该正确保存和查找技能', async () => {
      // Arrange
      const skill = new SkillEntity(
        'skill_001',
        '测试技能',
        SkillCategory.OFFICE,
        SkillDifficulty.BEGINNER,
        [{ stepNumber: 1, title: '步骤 1', content: '内容', keyPoint: '关键点', estimatedTime: 10 }]
      );
      
      // Act
      await skillRepository.save(skill);
      const found = await skillRepository.findById('skill_001');
      
      // Assert
      expect(found).not.toBeNull();
      expect(found!.name).toBe('测试技能');
    });

    it('应该按类别查找技能', async () => {
      // Arrange
      await skillRepository.save(new SkillEntity(
        'skill_002', '办公技能', SkillCategory.OFFICE, SkillDifficulty.BEGINNER, []
      ));
      await skillRepository.save(new SkillEntity(
        'skill_003', '生活技能', SkillCategory.LIFE, SkillDifficulty.BEGINNER, []
      ));
      
      // Act
      const officeSkills = await skillRepository.findByCategory('office');
      
      // Assert
      expect(officeSkills.length).toBeGreaterThanOrEqual(1);
    });

    it('应该按难度查找技能', async () => {
      // Arrange
      await skillRepository.save(new SkillEntity(
        'skill_004', '初级技能', SkillCategory.OFFICE, SkillDifficulty.BEGINNER, []
      ));
      await skillRepository.save(new SkillEntity(
        'skill_005', '高级技能', SkillCategory.OFFICE, SkillDifficulty.ADVANCED, []
      ));
      
      // Act
      const beginnerSkills = await skillRepository.findByDifficulty(1);
      
      // Assert
      expect(beginnerSkills.length).toBeGreaterThanOrEqual(1);
    });

    it('应该查找前置技能', async () => {
      // Arrange
      await skillRepository.save(new SkillEntity(
        'skill_006', '前置技能', SkillCategory.OFFICE, SkillDifficulty.BEGINNER, []
      ));
      await skillRepository.save(new SkillEntity(
        'skill_007', '后续技能', SkillCategory.OFFICE, SkillDifficulty.INTERMEDIATE, [],
        ['skill_006']
      ));
      
      // Act
      const prereqs = await skillRepository.findPrerequisites('skill_007');
      
      // Assert
      expect(prereqs.length).toBe(1);
    });
  });

  describe('LearningRecordRepository 测试', () => {
    it('应该正确保存学习记录', async () => {
      // Arrange
      const record = new LearningRecordEntity(
        'record_001', 'user_001', 'skill_001', 1, 'practice_001',
        LearningResult.CORRECT, 30, 0, 10, DeviceType.PHONE,
        '2026-04-02', 4, Date.now()
      );
      
      // Act
      await recordRepository.save(record);
      const found = await recordRepository.findById('record_001');
      
      // Assert
      expect(found).not.toBeNull();
      expect(found!.result).toBe(LearningResult.CORRECT);
    });

    it('应该按用户 ID 查找记录', async () => {
      // Arrange
      await recordRepository.save(new LearningRecordEntity(
        'record_002', 'user_001', 'skill_001', 1, 'practice_002',
        LearningResult.CORRECT, 30, 0, 10, DeviceType.PHONE,
        '2026-04-02', 4, Date.now()
      ));
      
      // Act
      const records = await recordRepository.findByUserId('user_001');
      
      // Assert
      expect(records.length).toBeGreaterThanOrEqual(1);
    });

    it('应该按技能 ID 查找记录', async () => {
      // Arrange
      await recordRepository.save(new LearningRecordEntity(
        'record_003', 'user_002', 'skill_001', 1, 'practice_003',
        LearningResult.CORRECT, 30, 0, 10, DeviceType.PHONE,
        '2026-04-02', 4, Date.now()
      ));
      
      // Act
      const records = await recordRepository.findBySkillId('skill_001');
      
      // Assert
      expect(records.length).toBeGreaterThanOrEqual(1);
    });

    it('应该按日期范围查询记录', async () => {
      // Arrange
      await recordRepository.save(new LearningRecordEntity(
        'record_004', 'user_001', 'skill_001', 1, 'practice_004',
        LearningResult.CORRECT, 30, 0, 10, DeviceType.PHONE,
        '2026-04-01', 4, Date.now()
      ));
      await recordRepository.save(new LearningRecordEntity(
        'record_005', 'user_001', 'skill_001', 1, 'practice_005',
        LearningResult.CORRECT, 30, 0, 10, DeviceType.PHONE,
        '2026-04-02', 4, Date.now()
      ));
      
      // Act
      const records = await recordRepository.query({
        userId: 'user_001',
        dateFrom: '2026-04-02',
        dateTo: '2026-04-02',
      });
      
      // Assert
      expect(records.length).toBe(1);
    });

    it('应该正确分页查询', async () => {
      // Arrange
      for (let i = 0; i < 20; i++) {
        await recordRepository.save(new LearningRecordEntity(
          `record_${100 + i}`, 'user_001', 'skill_001', 1, `practice_${100 + i}`,
          LearningResult.CORRECT, 30, 0, 10, DeviceType.PHONE,
          '2026-04-02', 4, Date.now()
        ));
      }
      
      // Act
      const page1 = await recordRepository.query({ userId: 'user_001', limit: 10, offset: 0 });
      const page2 = await recordRepository.query({ userId: 'user_001', limit: 10, offset: 10 });
      
      // Assert
      expect(page1.length).toBe(10);
      expect(page2.length).toBe(10);
    });
  });

  describe('事务测试', () => {
    it('应该支持批量保存', async () => {
      // Arrange
      const records: LearningRecordEntity[] = [];
      for (let i = 0; i < 10; i++) {
        records.push(new LearningRecordEntity(
          `record_${200 + i}`, 'user_003', 'skill_001', 1, `practice_${200 + i}`,
          LearningResult.CORRECT, 30, 0, 10, DeviceType.PHONE,
          '2026-04-02', 4, Date.now()
        ));
      }
      
      // Act
      await recordRepository.saveAll(records);
      const found = await recordRepository.findByUserId('user_003');
      
      // Assert
      expect(found.length).toBe(10);
    });
  });

  describe('性能测试', () => {
    it('应该快速查找用户', async () => {
      // Arrange
      const startTime = Date.now();
      
      // Act
      for (let i = 0; i < 100; i++) {
        await userRepository.findById('user_001');
      }
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      // Assert
      expect(duration).toBeLessThan(5000); // 5 秒内完成 100 次查询
    });

    it('应该快速查找技能', async () => {
      // Arrange
      const startTime = Date.now();
      
      // Act
      for (let i = 0; i < 100; i++) {
        await skillRepository.findById('skill_001');
      }
      
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      // Assert
      expect(duration).toBeLessThan(5000);
    });
  });
});

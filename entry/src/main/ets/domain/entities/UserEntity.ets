/**
 * ============================================================================
 * 用户实体 - UserEntity
 * 领域层核心实体，包含业务逻辑
 * ============================================================================
 */

import { UserMode } from '../valueobjects/UserMode';
import { Dialect } from '../valueobjects/Dialect';

/**
 * 用户学习统计
 */
export interface UserLearningStats {
  /** 总学习时长（分钟） */
  totalLearningMinutes: number;
  
  /** 已完成技能数 */
  completedSkillsCount: number;
  
  /** 当前连续学习天数 */
  currentStreak: number;
  
  /** 最长连续学习天数 */
  longestStreak: number;
  
  /** 总 XP */
  totalXP: number;
  
  /** 当前等级 */
  currentLevel: number;
  
  /** 成就 ID 列表 */
  achievementIds: string[];
}

/**
 * 用户偏好设置
 */
export interface UserPreferences {
  /** 用户模式（普通/老年/儿童/新手） */
  mode: UserMode;
  
  /** 方言偏好 */
  dialect: Dialect;
  
  /** 首选学习时间 */
  preferredTimeSlot: 'morning' | 'afternoon' | 'evening' | 'night';
  
  /** 首选学习设备 */
  preferredDevice: 'phone' | 'tablet' | 'pc';
  
  /** 是否启用语音播报 */
  enableVoice: boolean;
  
  /** 是否启用动画素材 */
  enableAnimation: boolean;
}

/**
 * 用户实体
 */
export class UserEntity {
  /** 用户 ID */
  public readonly id: string;
  
  /** 用户昵称 */
  public name: string;
  
  /** 创建时间 */
  public readonly createdAt: number;
  
  /** 更新时间 */
  public updatedAt: number;
  
  /** 学习统计 */
  public stats: UserLearningStats;
  
  /** 偏好设置 */
  public preferences: UserPreferences;
  
  /** 当前正在学习的技能 ID */
  public currentSkillId?: string;
  
  /** 当前学习步骤 */
  public currentStep: number = 0;

  constructor(
    id: string,
    name: string,
    createdAt?: number
  ) {
    this.id = id;
    this.name = name;
    this.createdAt = createdAt || Date.now();
    this.updatedAt = Date.now();
    
    this.stats = {
      totalLearningMinutes: 0,
      completedSkillsCount: 0,
      currentStreak: 0,
      longestStreak: 0,
      totalXP: 0,
      currentLevel: 1,
      achievementIds: [],
    };
    
    this.preferences = {
      mode: UserMode.NORMAL,
      dialect: Dialect.MANDARIN,
      preferredTimeSlot: 'evening',
      preferredDevice: 'phone',
      enableVoice: true,
      enableAnimation: true,
    };
  }

  /**
   * 更新学习时间
   */
  addLearningTime(minutes: number): void {
    this.stats.totalLearningMinutes += minutes;
    this.updatedAt = Date.now();
  }

  /**
   * 完成技能
   */
  completeSkill(skillId: string): void {
    this.stats.completedSkillsCount++;
    this.currentSkillId = undefined;
    this.currentStep = 0;
    this.updatedAt = Date.now();
  }

  /**
   * 开始学习技能
   */
  startLearning(skillId: string): void {
    this.currentSkillId = skillId;
    this.currentStep = 1;
    this.updatedAt = Date.now();
  }

  /**
   * 更新学习步骤
   */
  updateStep(step: number): void {
    this.currentStep = step;
    this.updatedAt = Date.now();
  }

  /**
   * 添加 XP
   */
  addXP(amount: number): void {
    this.stats.totalXP += amount;
    
    // 计算等级（简化版：每 100 XP 升一级）
    const newLevel = Math.floor(this.stats.totalXP / 100) + 1;
    if (newLevel > this.stats.currentLevel) {
      this.stats.currentLevel = newLevel;
    }
    
    this.updatedAt = Date.now();
  }

  /**
   * 更新连续学习天数
   */
  updateStreak(streak: number): void {
    this.stats.currentStreak = streak;
    if (streak > this.stats.longestStreak) {
      this.stats.longestStreak = streak;
    }
    this.updatedAt = Date.now();
  }

  /**
   * 解锁成就
   */
  unlockAchievement(achievementId: string): boolean {
    if (this.stats.achievementIds.includes(achievementId)) {
      return false; // 已解锁
    }
    this.stats.achievementIds.push(achievementId);
    this.updatedAt = Date.now();
    return true;
  }

  /**
   * 更新偏好设置
   */
  updatePreferences(prefs: Partial<UserPreferences>): void {
    this.preferences = { ...this.preferences, ...prefs };
    this.updatedAt = Date.now();
  }

  /**
   * 转换为 DTO
   */
  toDTO(): UserDTO {
    return {
      id: this.id,
      name: this.name,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      stats: { ...this.stats },
      preferences: { ...this.preferences },
      currentSkillId: this.currentSkillId,
      currentStep: this.currentStep,
    };
  }

  /**
   * 从 DTO 创建实体
   */
  static fromDTO(dto: UserDTO): UserEntity {
    const user = new UserEntity(dto.id, dto.name, dto.createdAt);
    user.updatedAt = dto.updatedAt;
    user.stats = { ...dto.stats };
    user.preferences = { ...dto.preferences };
    user.currentSkillId = dto.currentSkillId;
    user.currentStep = dto.currentStep;
    return user;
  }
}

/**
 * 用户 DTO
 */
export interface UserDTO {
  id: string;
  name: string;
  createdAt: number;
  updatedAt: number;
  stats: UserLearningStats;
  preferences: UserPreferences;
  currentSkillId?: string;
  currentStep: number;
}

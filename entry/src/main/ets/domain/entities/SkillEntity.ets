/**
 * ============================================================================
 * 技能实体 - SkillEntity
 * 领域层核心实体
 * ============================================================================
 */

/**
 * 技能类别
 */
export enum SkillCategory {
  OFFICE = 'office',
  LIFE = 'life',
  DIGITAL = 'digital',
  HEALTH = 'health',
  FINANCIAL = 'financial',
  SOCIAL = 'social',
}

/**
 * 技能难度
 */
export enum SkillDifficulty {
  BEGINNER = 1,
  INTERMEDIATE = 2,
  ADVANCED = 3,
}

/**
 * 技能学习步骤
 */
export interface SkillStep {
  stepNumber: number;
  title: string;
  content: string;
  keyPoint: string;
  safetyTip?: string;
  estimatedTime: number; // 分钟
}

/**
 * 技能实体
 */
export class SkillEntity {
  /** 技能 ID */
  public readonly id: string;
  
  /** 技能名称 */
  public readonly name: string;
  
  /** 技能类别 */
  public readonly category: SkillCategory;
  
  /** 技能难度 */
  public readonly difficulty: SkillDifficulty;
  
  /** 前置技能 ID 列表 */
  public readonly prerequisites: string[];
  
  /** 学习步骤 */
  public readonly steps: SkillStep[];
  
  /** 真实应用场景 */
  public readonly realWorldScenes: string[];
  
  /** 标签 */
  public readonly tags: string[];
  
  /** 预计学习时长（分钟） */
  public readonly estimatedTime: number;
  
  /** 创建时间 */
  public readonly createdAt: number;

  constructor(
    id: string,
    name: string,
    category: SkillCategory,
    difficulty: SkillDifficulty,
    steps: SkillStep[],
    prerequisites?: string[],
    realWorldScenes?: string[],
    tags?: string[],
    estimatedTime?: number,
    createdAt?: number
  ) {
    this.id = id;
    this.name = name;
    this.category = category;
    this.difficulty = difficulty;
    this.steps = steps;
    this.prerequisites = prerequisites || [];
    this.realWorldScenes = realWorldScenes || [];
    this.tags = tags || [];
    this.estimatedTime = estimatedTime || steps.reduce((sum, step) => sum + step.estimatedTime, 0);
    this.createdAt = createdAt || Date.now();
  }

  /**
   * 获取总步骤数
   */
  getTotalSteps(): number {
    return this.steps.length;
  }

  /**
   * 获取指定步骤
   */
  getStep(stepNumber: number): SkillStep | undefined {
    return this.steps.find(s => s.stepNumber === stepNumber);
  }

  /**
   * 检查是否有前置技能
   */
  hasPrerequisites(): boolean {
    return this.prerequisites.length > 0;
  }

  /**
   * 检查技能类别是否匹配
   */
  isCategory(category: SkillCategory): boolean {
    return this.category === category;
  }

  /**
   * 检查难度是否匹配
   */
  isDifficulty(difficulty: SkillDifficulty): boolean {
    return this.difficulty === difficulty;
  }

  /**
   * 检查标签是否包含
   */
  hasTag(tag: string): boolean {
    return this.tags.includes(tag);
  }

  /**
   * 转换为 DTO
   */
  toDTO(): SkillDTO {
    return {
      id: this.id,
      name: this.name,
      category: this.category,
      difficulty: this.difficulty,
      steps: [...this.steps],
      prerequisites: [...this.prerequisites],
      realWorldScenes: [...this.realWorldScenes],
      tags: [...this.tags],
      estimatedTime: this.estimatedTime,
      createdAt: this.createdAt,
    };
  }

  /**
   * 从 DTO 创建实体
   */
  static fromDTO(dto: SkillDTO): SkillEntity {
    return new SkillEntity(
      dto.id,
      dto.name,
      dto.category,
      dto.difficulty,
      dto.steps,
      dto.prerequisites,
      dto.realWorldScenes,
      dto.tags,
      dto.estimatedTime,
      dto.createdAt
    );
  }
}

/**
 * 技能 DTO
 */
export interface SkillDTO {
  id: string;
  name: string;
  category: SkillCategory;
  difficulty: SkillDifficulty;
  steps: SkillStep[];
  prerequisites: string[];
  realWorldScenes: string[];
  tags: string[];
  estimatedTime: number;
  createdAt: number;
}

/**
 * ============================================================================
 * 知识追踪实体 - KnowledgeTrackingEntity
 * 领域层核心实体，用于 BKT 知识追踪
 * ============================================================================
 */

/**
 * 知识状态
 */
export interface KnowledgeState {
  /** 掌握概率 P(known) */
  p_known: number;
  
  /** 学习次数 */
  learning_count: number;
  
  /** 正确次数 */
  correct_count: number;
  
  /** 错误次数 */
  incorrect_count: number;
  
  /** 最后更新时间 */
  last_updated: number;
}

/**
 * 知识追踪实体
 */
export class KnowledgeTrackingEntity {
  /** 追踪 ID */
  public readonly id: string;
  
  /** 用户 ID */
  public readonly userId: string;
  
  /** 技能 ID */
  public readonly skillId: string;
  
  /** 知识点 ID */
  public readonly knowledgePointId: string;
  
  /** 知识状态 */
  public state: KnowledgeState;
  
  /** BKT 参数 */
  public readonly p_learn: number;     // 学习概率
  public readonly p_slip: number;      // 失误概率
  public readonly p_guess: number;     // 猜测概率
  
  /** 创建时间 */
  public readonly createdAt: number;

  constructor(
    id: string,
    userId: string,
    skillId: string,
    knowledgePointId: string,
    p_learn: number = 0.1,
    p_slip: number = 0.1,
    p_guess: number = 0.3,
    createdAt?: number
  ) {
    this.id = id;
    this.userId = userId;
    this.skillId = skillId;
    this.knowledgePointId = knowledgePointId;
    this.p_learn = p_learn;
    this.p_slip = p_slip;
    this.p_guess = p_guess;
    this.createdAt = createdAt || Date.now();
    
    this.state = {
      p_known: 0.01,  // 初始掌握概率 1%
      learning_count: 0,
      correct_count: 0,
      incorrect_count: 0,
      last_updated: Date.now(),
    };
  }

  /**
   * 更新知识状态（BKT 更新公式）
   */
  update(is_correct: boolean): void {
    const { p_known, p_learn, p_slip, p_guess } = this;
    
    // BKT 更新公式
    let p_known_new: number;
    
    if (is_correct) {
      // P(known|correct) = P(known) * (1 - p_slip) / [P(known) * (1 - p_slip) + (1 - P(known)) * p_guess]
      const numerator = p_known * (1 - p_slip);
      const denominator = p_known * (1 - p_slip) + (1 - p_known) * p_guess;
      p_known_new = numerator / denominator;
      
      // P(known|correct) = P(known|correct) + (1 - P(known|correct)) * p_learn
      p_known_new = p_known_new + (1 - p_known_new) * p_learn;
    } else {
      // P(known|incorrect) = P(known) * p_slip / [P(known) * p_slip + (1 - P(known)) * (1 - p_guess)]
      const numerator = p_known * p_slip;
      const denominator = p_known * p_slip + (1 - p_known) * (1 - p_guess);
      p_known_new = numerator / denominator;
      
      // P(known|incorrect) = P(known|incorrect) + (1 - P(known|incorrect)) * p_learn
      p_known_new = p_known_new + (1 - p_known_new) * p_learn;
    }
    
    // 更新状态
    this.state = {
      p_known: Math.min(1.0, Math.max(0.0, p_known_new)),
      learning_count: this.state.learning_count + 1,
      correct_count: this.state.correct_count + (is_correct ? 1 : 0),
      incorrect_count: this.state.incorrect_count + (is_correct ? 0 : 1),
      last_updated: Date.now(),
    };
  }

  /**
   * 获取掌握概率
   */
  getMasteryProbability(): number {
    return this.state.p_known;
  }

  /**
   * 检查是否已掌握
   */
  isMastered(threshold: number = 0.95): boolean {
    return this.state.p_known >= threshold;
  }

  /**
   * 获取推荐操作
   */
  getRecommendation(): 'review' | 'continue' | 'complete' {
    if (this.isMastered()) {
      return 'complete';
    }
    if (this.state.p_known < 0.5) {
      return 'review';
    }
    return 'continue';
  }

  /**
   * 获取正确率
   */
  getAccuracy(): number {
    if (this.state.learning_count === 0) {
      return 0;
    }
    return this.state.correct_count / this.state.learning_count;
  }

  /**
   * 重置状态
   */
  reset(): void {
    this.state = {
      p_known: 0.01,
      learning_count: 0,
      correct_count: 0,
      incorrect_count: 0,
      last_updated: Date.now(),
    };
  }

  /**
   * 转换为 DTO
   */
  toDTO(): KnowledgeTrackingDTO {
    return {
      id: this.id,
      userId: this.userId,
      skillId: this.skillId,
      knowledgePointId: this.knowledgePointId,
      state: { ...this.state },
      p_learn: this.p_learn,
      p_slip: this.p_slip,
      p_guess: this.p_guess,
      createdAt: this.createdAt,
    };
  }

  /**
   * 从 DTO 创建实体
   */
  static fromDTO(dto: KnowledgeTrackingDTO): KnowledgeTrackingEntity {
    const entity = new KnowledgeTrackingEntity(
      dto.id,
      dto.userId,
      dto.skillId,
      dto.knowledgePointId,
      dto.p_learn,
      dto.p_slip,
      dto.p_guess,
      dto.createdAt
    );
    entity.state = { ...dto.state };
    return entity;
  }
}

/**
 * 知识追踪 DTO
 */
export interface KnowledgeTrackingDTO {
  id: string;
  userId: string;
  skillId: string;
  knowledgePointId: string;
  state: KnowledgeState;
  p_learn: number;
  p_slip: number;
  p_guess: number;
  createdAt: number;
}

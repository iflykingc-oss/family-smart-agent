/**
 * ============================================================================
 * BKT 知识追踪接口 - IBKTTracker
 * ============================================================================
 */

/**
 * BKT 知识状态
 */
export interface BKTState {
  /** 掌握概率 P(known) */
  p_known: number;
  
  /** 学习次数 */
  learning_count: number;
  
  /** 正确次数 */
  correct_count: number;
  
  /** 错误次数 */
  incorrect_count: number;
}

/**
 * BKT 配置
 */
export interface BKTConfig {
  /** 初始掌握概率 */
  p_known_init: number;
  
  /** 学习概率 */
  p_learn: number;
  
  /** 失误概率 */
  p_slip: number;
  
  /** 猜测概率 */
  p_guess: number;
  
  /** 掌握阈值 */
  mastery_threshold: number;
}

/**
 * BKT 评估结果
 */
export interface BKTEvaluation {
  /** 当前掌握概率 */
  mastery_probability: number;
  
  /** 是否已掌握 */
  is_mastered: boolean;
  
  /** 推荐下一步 */
  recommendation: 'review' | 'continue' | 'complete';
  
  /** 薄弱点 */
  weak_points: string[];
}

/**
 * BKT 追踪器接口
 */
export interface IBKTTracker {
  /**
   * 更新知识状态
   * @param state 当前状态
   * @param is_correct 是否正确
   */
  update(state: BKTState, is_correct: boolean): BKTState;
  
  /**
   * 评估掌握程度
   * @param state 当前状态
   */
  evaluate(state: BKTState): BKTEvaluation;
  
  /**
   * 获取 BKT 配置
   */
  getConfig(): BKTConfig;
  
  /**
   * 更新 BKT 配置
   */
  setConfig(config: Partial<BKTConfig>): void;
  
  /**
   * 重置状态
   */
  reset(): BKTState;
}

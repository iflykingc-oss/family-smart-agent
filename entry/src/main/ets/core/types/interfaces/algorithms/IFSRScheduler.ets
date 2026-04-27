/**
 * ============================================================================
 * FSRS 调度器接口 - IFSRScheduler
 * ============================================================================
 */

/**
 * FSRS 卡片状态
 */
export interface FSRSCard {
  /** 下次复习时间 */
  due: Date;
  
  /** 记忆稳定度（天） */
  stability: number;
  
  /** 记忆难度（1-10） */
  difficulty: number;
  
  /** 已间隔天数 */
  elapsed_days: number;
  
  /** 计划间隔天数 */
  scheduled_days: number;
  
  /** 复习次数 */
  reps: number;
  
  /** 忘记次数 */
  lapses: number;
  
  /** 卡片状态 */
  state: CardState;
}

/**
 * 卡片状态
 */
export enum CardState {
  New = 0,
  Learning = 1,
  Review = 2,
  Relearning = 3,
}

/**
 * 评分等级
 */
export enum Rating {
  Again = 0,    // 完全忘记
  Hard = 1,     // 困难
  Good = 2,     // 良好
  Easy = 3,     // 简单
}

/**
 * FSRS 调度记录
 */
export interface SchedulingRecord {
  /** 调度后的卡片 */
  card: FSRSCard;
  
  /** 复习间隔 */
  interval: number;
  
  /** 可回忆性 */
  retrievability: number;
}

/**
 * FSRS 配置
 */
export interface FSRSConfig {
  /** 目标保持率 */
  request_retention: number;
  
  /** 最大间隔 */
  maximum_interval: number;
  
  /** 启用随机扰动 */
  enable_fuzz: boolean;
  
  /** 启用短期学习 */
  enable_short_term: boolean;
  
  /** 学习步骤 */
  learning_steps: string[];
  
  /** 重新学习步骤 */
  relearning_steps: string[];
}

/**
 * FSRS 调度器接口
 */
export interface IFSRScheduler {
  /**
   * 计算下一个复习状态
   * @param card 当前卡片
   * @param now 当前时间
   * @param rating 用户评分
   */
  next(card: FSRSCard, now: Date, rating: Rating): SchedulingRecord;
  
  /**
   * 重复学习（忘记后重新学习）
   */
  repeat(card: FSRSCard, now: Date): SchedulingRecord[];
  
  /**
   * 获取 FSRS 配置
   */
  getConfig(): FSRSConfig;
  
  /**
   * 更新 FSRS 配置
   */
  setConfig(config: Partial<FSRSConfig>): void;
}

/**
 * ============================================================================
 * 应用常量 - 提取魔法数字
 * ============================================================================
 */

/**
 * 时间常量（毫秒）
 */
export const TIME_CONSTANTS = {
  SECOND: 1000,
  MINUTE: 60 * 1000,
  HOUR: 60 * 60 * 1000,
  DAY: 24 * 60 * 60 * 1000,
  WEEK: 7 * 24 * 60 * 60 * 1000,
} as const;

/**
 * 缓存常量
 */
export const CACHE_CONSTANTS = {
  MAX_SIZE: 100,
  DEFAULT_TTL: 5 * 60 * 1000, // 5 分钟
  SKILL_TTL: 10 * 60 * 1000,  // 10 分钟
  USER_TTL: 5 * 60 * 1000,    // 5 分钟
} as const;

/**
 * 数据库常量
 */
export const DB_CONSTANTS = {
  MAX_RETRIES: 3,
  TIMEOUT: 30000,
  BATCH_SIZE: 100,
} as const;

/**
 * 性能常量
 */
export const PERFORMANCE_CONSTANTS = {
  MAX_QUERY_TIME: 50,    // 最大查询时间 50ms
  MAX_CACHE_TIME: 1,     // 最大缓存时间 1ms
  MAX_CONCURRENT: 10,    // 最大并发数
} as const;

/**
 * 学习常量
 */
export const LEARNING_CONSTANTS = {
  MINUTES_PER_DAY: 30,   // 每天学习 30 分钟
  MASTERY_THRESHOLD: 0.95, // 掌握阈值 95%
  REVIEW_THRESHOLD: 0.85,  // 复习阈值 85%
  PASSING_SCORE: 0.8,      // 及格分数 80%
} as const;

/**
 * 成就常量
 */
export const ACHIEVEMENT_CONSTANTS = {
  STREAK_3: 3,
  STREAK_7: 7,
  STREAK_30: 30,
  LEVEL_5: 5,
  LEVEL_10: 10,
} as const;

/**
 * UI 常量
 */
export const UI_CONSTANTS = {
  PAGE_SIZE: 10,
  MAX_LIST_LENGTH: 100,
  ANIMATION_DURATION: 300,
} as const;

/**
 * 错误码常量
 */
export const ERROR_CODES = {
  // 通用错误 1000-1999
  UNKNOWN: 1000,
  NETWORK_ERROR: 1001,
  TIMEOUT: 1002,
  PARSE_ERROR: 1003,
  VALIDATION_ERROR: 1004,
  
  // 算法错误 2000-2999
  ALGORITHM_ERROR: 2000,
  FSRS_ERROR: 2001,
  BKT_ERROR: 2002,
  
  // 数据错误 3000-3999
  DATA_NOT_FOUND: 3000,
  DATA_SAVE_FAILED: 3001,
  DATA_LOAD_FAILED: 3002,
  
  // AI 服务错误 4000-4999
  AI_SERVICE_ERROR: 4000,
  AI_QUOTA_EXCEEDED: 4001,
  AI_CONTENT_FILTERED: 4002,
} as const;

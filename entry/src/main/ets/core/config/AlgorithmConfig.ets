/**
 * ============================================================================
 * 算法参数配置 - AlgorithmConfig
 * 核心：FSRS/BKT等算法参数集中管理
 * ============================================================================
 */

/**
 * FSRS 算法配置
 */
export const FSRSConfig = {
  /** 目标保持率（0-1） */
  REQUEST_RETENTION: 0.9,
  
  /** 最大间隔天数 */
  MAXIMUM_INTERVAL: 36500,
  
  /** 启用随机扰动（防止所有卡片同一天复习） */
  ENABLE_FUZZ: false,
  
  /** 启用短期学习 */
  ENABLE_SHORT_TERM: true,
  
  /** 学习步骤（分钟） */
  LEARNING_STEPS: ['1m', '10m'],
  
  /** 重新学习步骤（分钟） */
  RELEARNING_STEPS: ['10m'],
  
  /** FSRS v6 权重参数（17 个） */
  WEIGHTS: [
    0.4072, 1.1829, 3.1262, 15.4722, 7.2102,
    0.5316, 1.0651, 1.8295, 0.0308, 0.2524,
    1.203, 0.899, 1.199, 0.924, 0.992,
    0.0, 0.0
  ],
} as const;

/**
 * BKT 贝叶斯知识追踪配置
 */
export const BKTConfig = {
  /** 初始掌握概率 P(known_init) */
  P_KNOWN_INIT: 0.01,
  
  /** 学习概率 P(learn) - 从不知道到知道 */
  P_LEARN: 0.1,
  
  /** 失误概率 P(slip) - 知道但做错 */
  P_SLIP: 0.1,
  
  /** 猜测概率 P(guess) - 不知道但做对 */
  P_GUESS: 0.3,
  
  /** 掌握阈值（超过此值认为已掌握） */
  MASTERY_THRESHOLD: 0.95,
} as const;

/**
 * 学习路径推荐配置
 */
export const LearningPathConfig = {
  /** 推荐算法类型 */
  RECOMMEND_ALGORITHM: 'hybrid', // 'collaborative' | 'content' | 'hybrid'
  
  /** 最大推荐路径长度 */
  MAX_PATH_LENGTH: 10,
  
  /** 最小路径难度 */
  MIN_DIFFICULTY: 1,
  
  /** 最大路径难度 */
  MAX_DIFFICULTY: 5,
  
  /** 协同过滤权重 */
  COLLABORATIVE_WEIGHT: 0.6,
  
  /** 内容推荐权重 */
  CONTENT_WEIGHT: 0.4,
  
  /** 最少相似用户数（协同过滤） */
  MIN_SIMILAR_USERS: 5,
} as const;

/**
 * 场景分类配置
 */
export const SceneClassifierConfig = {
  /** 分类算法类型 */
  CLASSIFIER_ALGORITHM: 'keyword', // 'keyword' | 'ml' | 'llm'
  
  /** 关键词匹配置信度阈值 */
  KEYWORD_CONFIDENCE_THRESHOLD: 0.7,
  
  /** 最大场景候选数 */
  MAX_SCENE_CANDIDATES: 3,
  
  /** 启用 LLM 辅助分类 */
  ENABLE_LLM_ASSIST: true,
} as const;

/**
 * 项目评估配置
 */
export const ProjectEvaluatorConfig = {
  /** 评估算法类型 */
  EVALUATOR_ALGORITHM: 'rubric', // 'rubric' | 'ai' | 'hybrid'
  
  /** 评分维度权重 */
  CRITERIA_WEIGHTS: {
    COMPLETENESS: 0.3,    // 完整性
    CORRECTNESS: 0.3,     // 正确性
    INNOVATION: 0.2,      // 创新性
    AESTHETICS: 0.2,      // 美观度
  },
  
  /** 及格分数线 */
  PASSING_SCORE: 60,
  
  /** 优秀分数线 */
  EXCELLENT_SCORE: 90,
} as const;

/**
 * 算法配置类型
 */
export interface AlgorithmConfigType {
  fsrs: typeof FSRSConfig;
  bkt: typeof BKTConfig;
  learningPath: typeof LearningPathConfig;
  sceneClassifier: typeof SceneClassifierConfig;
  projectEvaluator: typeof ProjectEvaluatorConfig;
}

/**
 * 获取算法配置
 */
export function getAlgorithmConfig<K extends keyof AlgorithmConfigType>(key: K): AlgorithmConfigType[K] {
  const config: AlgorithmConfigType = {
    fsrs: FSRSConfig,
    bkt: BKTConfig,
    learningPath: LearningPathConfig,
    sceneClassifier: SceneClassifierConfig,
    projectEvaluator: ProjectEvaluatorConfig,
  };
  return config[key];
}

/**
 * 获取 FSRS 配置
 */
export function getFSRSConfig(): typeof FSRSConfig {
  return FSRSConfig;
}

/**
 * 获取 BKT 配置
 */
export function getBKTConfig(): typeof BKTConfig {
  return BKTConfig;
}

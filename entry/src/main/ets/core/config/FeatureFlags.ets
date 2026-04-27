/**
 * ============================================================================
 * 功能开关配置 - FeatureFlags
 * 核心：比赛/运营双模式一键切换
 * ============================================================================
 */

/**
 * 功能开关配置
 */
export const FeatureFlags = {
  // ==================== 算法开关 ====================
  
  /** 启用 FSRS v6 算法（默认开启） */
  ENABLE_FSR_V6: true,
  
  /** 启用 BKT 贝叶斯知识追踪（P1，可关闭） */
  ENABLE_BKT: false,
  
  /** 启用学习路径推荐算法 */
  ENABLE_LEARNING_PATH_RECOMMEND: true,
  
  /** 启用场景分类算法 */
  ENABLE_SCENE_CLASSIFIER: true,
  
  /** 启用项目评估算法（P2，可关闭） */
  ENABLE_PROJECT_EVALUATOR: false,
  
  // ==================== AI 服务开关 ====================
  
  /** 启用 LLM 内容生成 */
  ENABLE_LLM_GENERATION: true,
  
  /** LLM 降级模式（API 失败时用模板） */
  LLM_FALLBACK_MODE: true,
  
  /** 启用 Prompt 优化 */
  ENABLE_PROMPT_OPTIMIZATION: true,
  
  // ==================== 演示模式 ====================
  
  /** 演示模式（用模拟数据，不依赖真实 API） */
  DEMO_MODE: false,
  
  /** 演示模式 - 固定用户数据 */
  DEMO_FIXED_USER_ID: 'demo_user_001',
  
  /** 演示模式 - 固定技能数据 */
  DEMO_FIXED_SKILLS: ['excel_basic', 'wechat_basic'],
  
  // ==================== 监控告警 ====================
  
  /** 启用性能监控 */
  ENABLE_PERFORMANCE_MONITOR: true,
  
  /** 启用健康检查 */
  ENABLE_HEALTH_CHECK: false,
  
  /** 启用异常告警 */
  ENABLE_ALERT_SERVICE: false,
  
  // ==================== 数据分析 ====================
  
  /** 启用用户行为埋点 */
  ENABLE_ANALYTICS: false,
  
  /** 启用转化漏斗分析 */
  ENABLE_CONVERSION_FUNNEL: false,
  
  /** 启用留存分析 */
  ENABLE_RETENTION_ANALYSIS: false,
  
  // ==================== 增长功能 ====================
  
  /** 启用成就系统 */
  ENABLE_ACHIEVEMENT_SYSTEM: true,
  
  /** 启用社交分享 */
  ENABLE_SOCIAL_SHARE: false,
  
  /** 启用推荐系统 */
  ENABLE_REFERRAL_SYSTEM: false,
  
  // ==================== A/B 测试 ====================
  
  /** 启用 A/B 测试框架 */
  ENABLE_AB_TEST: false,
  
  /** A/B 测试 - FSRS 算法版本 */
  AB_TEST_FSR_VERSION: 'v6', // 'v5' | 'v6'
  
  /** A/B 测试 - 教学流程版本 */
  AB_TEST_TEACHING_FLOW: 'A', // 'A' | 'B'
  
  // ==================== 运营功能 ====================
  
  /** 启用灰度发布 */
  ENABLE_CANARY_RELEASE: false,
  
  /** 灰度发布比例（0-100） */
  CANARY_RELEASE_PERCENTAGE: 10,
  
  /** 启用付费功能 */
  ENABLE_PREMIUM_FEATURES: false,
} as const;

/**
 * 功能开关类型
 */
export type FeatureFlagsType = typeof FeatureFlags;

/**
 * 获取功能开关值
 */
export function getFeatureFlag<K extends keyof FeatureFlagsType>(key: K): FeatureFlagsType[K] {
  return FeatureFlags[key];
}

/**
 * 设置功能开关值（运行时动态调整）
 */
export function setFeatureFlag<K extends keyof FeatureFlagsType>(
  key: K,
  value: FeatureFlagsType[K]
): void {
  (FeatureFlags as any)[key] = value;
  console.info(`[FeatureFlags] ${key} = ${value}`);
}

/**
 * 批量设置功能开关
 */
export function setFeatureFlags(flags: Partial<FeatureFlagsType>): void {
  Object.assign(FeatureFlags, flags);
  console.info(`[FeatureFlags] 批量更新：${JSON.stringify(flags)}`);
}

/**
 * 检查功能是否启用
 */
export function isFeatureEnabled<K extends keyof FeatureFlagsType>(key: K): boolean {
  return FeatureFlags[key] === true;
}

/**
 * 切换演示模式
 */
export function setDemoMode(enabled: boolean): void {
  setFeatureFlags({
    DEMO_MODE: enabled,
    ENABLE_PERFORMANCE_MONITOR: !enabled,
    ENABLE_HEALTH_CHECK: !enabled,
    ENABLE_ALERT_SERVICE: !enabled,
    ENABLE_ANALYTICS: !enabled,
  });
}

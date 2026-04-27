/**
 * ============================================================================
 * 大模型配置 - LLMConfig
 * ============================================================================
 */

/**
 * LLM 配置
 */
export const LLMConfig = {
  /** API 基础 URL */
  API_BASE_URL: 'https://api.llm.huaweicloud.com',
  
  /** 模型名称 */
  MODEL_NAME: 'hvw-llm-v1',
  
  /** API Token（从环境变量或安全存储加载） */
  API_TOKEN: '',
  
  /** 系统 Prompt */
  SYSTEM_PROMPT: '你是一个专业的教学助手，擅长将复杂技能拆解为简单易懂的学习步骤。',
  
  /** 最大 Token 数 */
  MAX_TOKENS: 2000,
  
  /** 温度（创造性） */
  TEMPERATURE: 0.7,
  
  /** 超时时间（毫秒） */
  TIMEOUT: 30000,
  
  /** 重试次数 */
  MAX_RETRIES: 3,
  
  /** 降级模式（API 失败时用模板） */
  FALLBACK_MODE: true,
} as const;

/**
 * LLM 配置类型
 */
export type LLMConfigType = typeof LLMConfig;

/**
 * 设置 API Token
 */
export function setApiToken(token: string): void {
  (LLMConfig as any).API_TOKEN = token;
}

/**
 * 获取 API Token
 */
export function getApiToken(): string {
  return LLMConfig.API_TOKEN;
}

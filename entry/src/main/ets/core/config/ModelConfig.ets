/**
 * ============================================================================
 * 模型分层配置 - ModelConfig
 * 目标：根据任务类型选择不同模型，节省 token 成本
 * ============================================================================
 */

/**
 * 模型类型
 */
export enum ModelType {
  /** 高端模型 - 复杂推理 */
  PREMIUM = 'claude-opus',
  
  /** 中端模型 - 一般任务 */
  STANDARD = 'claude-sonnet',
  
  /** 低端模型 - 简单问答 */
  ECONOMY = 'minimax-minimax-m2.5',
  
  /** 本地模型 - 极简单任务 */
  LOCAL = 'local-llama'
}

/**
 * 任务类型
 */
export enum TaskType {
  /** 复杂推理 */
  COMPLEX_REASONING = 'complex_reasoning',
  
  /** 代码生成 */
  CODE_GENERATION = 'code_generation',
  
  /** 教学对话 */
  TEACHING_CHAT = 'teaching_chat',
  
  /** 简单问答 */
  SIMPLE_QA = 'simple_qa',
  
  /** 数据查询 */
  DATA_QUERY = 'data_query',
  
  /** 文本处理 */
  TEXT_PROCESSING = 'text_processing'
}

/**
 * 模型配置
 */
export interface ModelConfig {
  taskType: TaskType;
  model: ModelType;
  maxTokens: number;
  temperature: number;
  description: string;
}

/**
 * 模型分层配置
 */
export const MODEL_LAYERS: Record<TaskType, ModelConfig> = {
  [TaskType.COMPLEX_REASONING]: {
    taskType: TaskType.COMPLEX_REASONING,
    model: ModelType.PREMIUM,
    maxTokens: 4000,
    temperature: 0.7,
    description: '复杂推理任务（架构设计/算法优化）'
  },
  
  [TaskType.CODE_GENERATION]: {
    taskType: TaskType.CODE_GENERATION,
    model: ModelType.STANDARD,
    maxTokens: 2000,
    temperature: 0.5,
    description: '代码生成任务（业务逻辑简单）'
  },
  
  [TaskType.TEACHING_CHAT]: {
    taskType: TaskType.TEACHING_CHAT,
    model: ModelType.STANDARD,
    maxTokens: 1500,
    temperature: 0.8,
    description: '教学对话（需要温度但不用太贵）'
  },
  
  [TaskType.SIMPLE_QA]: {
    taskType: TaskType.SIMPLE_QA,
    model: ModelType.ECONOMY,
    maxTokens: 500,
    temperature: 0.3,
    description: '简单问答（天气/时间/事实查询）'
  },
  
  [TaskType.DATA_QUERY]: {
    taskType: TaskType.DATA_QUERY,
    model: ModelType.ECONOMY,
    maxTokens: 1000,
    temperature: 0.2,
    description: '数据查询（数据库/文件读取）'
  },
  
  [TaskType.TEXT_PROCESSING]: {
    taskType: TaskType.TEXT_PROCESSING,
    model: ModelType.ECONOMY,
    maxTokens: 1000,
    temperature: 0.4,
    description: '文本处理（摘要/翻译/格式化）'
  }
};

/**
 * 根据任务类型选择模型
 */
export function selectModel(taskType: TaskType): ModelConfig {
  return MODEL_LAYERS[taskType] || MODEL_LAYERS[TaskType.SIMPLE_QA];
}

/**
 * 根据任务描述自动判断任务类型
 */
export function inferTaskType(description: string): TaskType {
  const lower = description.toLowerCase();
  
  // 复杂推理关键词
  if (lower.includes('架构') || lower.includes('优化') || lower.includes('设计') || lower.includes('分析')) {
    return TaskType.COMPLEX_REASONING;
  }
  
  // 代码生成关键词
  if (lower.includes('代码') || lower.includes('实现') || lower.includes('开发') || lower.includes('函数')) {
    return TaskType.CODE_GENERATION;
  }
  
  // 教学对话关键词
  if (lower.includes('教学') || lower.includes('学习') || lower.includes('教程') || lower.includes('步骤')) {
    return TaskType.TEACHING_CHAT;
  }
  
  // 简单问答关键词
  if (lower.includes('天气') || lower.includes('时间') || lower.includes('日期') || lower.includes('什么是')) {
    return TaskType.SIMPLE_QA;
  }
  
  // 数据查询关键词
  if (lower.includes('查询') || lower.includes('读取') || lower.includes('数据库') || lower.includes('文件')) {
    return TaskType.DATA_QUERY;
  }
  
  // 文本处理关键词
  if (lower.includes('摘要') || lower.includes('总结') || lower.includes('翻译') || lower.includes('格式化')) {
    return TaskType.TEXT_PROCESSING;
  }
  
  // 默认简单问答
  return TaskType.SIMPLE_QA;
}

/**
 * 获取模型成本估算（每 1000 tokens）
 */
export function getModelCost(model: ModelType): { input: number; output: number } {
  const costs: Record<ModelType, { input: number; output: number }> = {
    [ModelType.PREMIUM]: { input: 0.015, output: 0.075 },  // Opus
    [ModelType.STANDARD]: { input: 0.003, output: 0.015 },  // Sonnet
    [ModelType.ECONOMY]: { input: 0.0005, output: 0.001 },  // MiniMax
    [ModelType.LOCAL]: { input: 0, output: 0 }  // 本地免费
  };
  return costs[model];
}

/**
 * 估算任务成本
 */
export function estimateTaskCost(taskType: TaskType, inputTokens: number, outputTokens: number): number {
  const config = selectModel(taskType);
  const cost = getModelCost(config.model);
  return (inputTokens / 1000) * cost.input + (outputTokens / 1000) * cost.output;
}

/**
 * 智能选择模型（带成本优化）
 */
export function smartSelectModel(description: string, budget?: number): ModelConfig {
  const taskType = inferTaskType(description);
  const config = selectModel(taskType);
  
  // 如果有预算限制，降级模型
  if (budget !== undefined) {
    const estimatedCost = estimateTaskCost(taskType, 1000, 500); // 估算
    if (estimatedCost > budget && config.model !== ModelType.ECONOMY) {
      return selectModel(TaskType.SIMPLE_QA); // 降级
    }
  }
  
  return config;
}

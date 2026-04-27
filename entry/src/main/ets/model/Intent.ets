/**
 * 结构化意图数据模型
 * 小艺MCP解析后的意图结构
 */
export interface Intent {
  rawText: string;                 // 原始输入文本
  intentType: IntentType;          // 意图类型
  confidence: number;             // 置信度 0-1
  entities: IntentEntity[];        // 提取的实体列表
  subTasks: SubTask[];            // 拆解的子任务列表
  relatedMembers: string[];        // 涉及的成员ID列表
  sceneId?: string;                // 关联的场景ID
  needsClarification: boolean;     // 是否需要追问澄清
  clarificationQuestion?: string;  // 追问内容
  createdAt: number;               // 创建时间戳
}

/**
 * 意图类型枚举
 */
export type IntentType =
  | 'event'           // 事件安排（野餐、聚会等）
  | 'care'            // 照料任务（家务提醒等）
  | 'shopping'        // 购物清单
  | 'reminder'        // 提醒事项
  | 'health'          // 健康管理
  | 'schedule'        // 日程查询
  | 'memory'          // 记忆相关
  | 'task'            // 通用任务
  | 'unknown';        // 未知

/**
 * 意图实体
 */
export interface IntentEntity {
  type: EntityType;
  value: string;
  rawText: string;
  memberId?: string;        // 如果是成员实体，对应的成员ID
  confidence: number;
}

/**
 * 实体类型
 */
export type EntityType =
  | 'member'         // 家庭成员
  | 'time'           // 时间
  | 'location'        // 地点
  | 'item'           // 物品
  | 'action'         // 动作
  | 'task'           // 任务
  | 'device'          // 设备
  | 'constraint';    // 约束条件

/**
 * 子任务
 */
export interface SubTask {
  id: string;
  type: TaskType;
  description: string;
  assigneeId?: string;       // 分配给的成员ID
  dueTime?: number;          // 截止时间（毫秒）
  deviceIds: string[];       // 推送到哪些设备
  status: TaskStatus;
  createdAt: number;
}

/**
 * 任务类型
 */
export type TaskType =
  | 'reminder'       // 提醒任务
  | 'shopping'        // 购物任务
  | 'care'           // 照料任务
  | 'schedule'       // 日程任务
  | 'notification';   // 通知任务

/**
 * 任务状态
 */
export type TaskStatus =
  | 'pending'        // 待执行
  | 'in_progress'    // 执行中
  | 'completed'      // 已完成
  | 'cancelled';    // 已取消

/**
 * 可执行任务数据模型
 * 由任务编排引擎生成
 */
export interface Task {
  id: string;                    // 唯一标识符
  title: string;                 // 任务标题
  description: string;            // 任务描述
  type: ExecutableTaskType;       // 任务类型
  assigneeId?: string;           // 分配的成员ID
  assigneeName?: string;         // 分配的成员名称（便于展示）
  dueTime?: number;              // 截止时间（毫秒）
  reminderTime?: number;         // 提醒时间（毫秒）
  deviceIds: string[];           // 推送设备ID列表
  status: ExecutableTaskStatus;  // 任务状态
  priority: TaskPriority;        // 优先级
  relatedIntentId?: string;      // 关联的意图ID
  relatedSceneId?: string;       // 关联的场景ID
  parentTaskId?: string;          // 父任务ID（如果有子任务）
  subTaskIds: string[];          // 子任务ID列表
  completedAt?: number;          // 完成时间戳
  createdAt: number;             // 创建时间戳
  updatedAt: number;             // 更新时间戳
}

/**
 * 可执行任务类型
 */
export type ExecutableTaskType =
  | 'reminder'        // 提醒任务
  | 'shopping'         // 购物任务
  | 'care'            // 照料任务
  | 'calendar'        // 日历事件
  | 'notification'     // 通知推送
  | 'custom';         // 自定义任务

/**
 * 任务状态
 */
export type ExecutableTaskStatus =
  | 'pending'         // 待执行
  | 'scheduled'       // 已加入日程
  | 'notified'        // 已推送通知
  | 'completed'       // 已完成
  | 'failed';         // 失败

/**
 * 任务优先级
 */
export type TaskPriority =
  | 'high'    // 高
  | 'medium'  // 中
  | 'low';    // 低

/**
 * 创建立即执行的可执行任务
 */
export function createTask(
  title: string,
  type: ExecutableTaskType,
  options?: Partial<Task>
): Task {
  const now = Date.now();
  return {
    id: `task_${now}_${Math.random().toString(36).substring(2, 9)}`,
    title,
    description: '',
    type,
    deviceIds: [],
    status: 'pending',
    priority: 'medium',
    subTaskIds: [],
    createdAt: now,
    updatedAt: now,
    ...options,
  };
}

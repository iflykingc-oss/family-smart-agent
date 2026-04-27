/**
 * 记忆任务数据模型
 * 用户指令中需要被记忆的内容
 */
export interface MemoryTask {
  id: string;                    // 唯一标识符
  content: string;               // 记忆内容原文
  summary: string;               // AI提取的摘要
  sourceMemberId: string;         // 提出该记忆的成员ID
  relatedMembers: string[];       // 关联成员ID列表
  sceneId?: string;              // 关联的场景ID（可选）
  entityType: MemoryEntityType;   // 实体类型
  tags: string[];                // 标签，用于检索
  remembered: boolean;            // 是否已被记忆（图谱持久化）
  createdAt: number;              // 创建时间戳
}

/**
 * 记忆实体类型
 */
export type MemoryEntityType =
  | 'health'        // 健康信息
  | 'preference'    // 偏好
  | 'habit'         // 习惯
  | 'constraint'    // 约束/限制
  | 'relationship'  // 关系
  | 'schedule'      // 日程安排
  | 'other';        // 其他

/**
 * 创建新的记忆任务
 */
export function createMemoryTask(
  content: string,
  sourceMemberId: string,
  entityType: MemoryEntityType,
  summary?: string
): MemoryTask {
  const now = Date.now();
  return {
    id: `memtask_${now}_${Math.random().toString(36).substring(2, 9)}`,
    content,
    summary: summary ?? content,
    sourceMemberId,
    relatedMembers: [],
    entityType,
    tags: [],
    remembered: false,
    createdAt: now,
  };
}

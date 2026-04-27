/**
 * 家庭成员数据模型
 */
export interface FamilyMember {
  id: string;                    // 唯一标识符
  name: string;                 // 称呼：如"妈妈"、"老公"
  relation: string;             // 关系：如"母亲"、"配偶"
  healthNotes: string[];        // 健康备注：如["腰不好", "忌食辛辣"]
  habits: string[];              // 习惯偏好：如["早起", "晚睡"]
  constraints: string[];         // 照料约束：如["避免提重物", "需要定期运动"]
  avatar?: string;              // 头像（可选）
  lastMentioned: number;        // 上次提及时间戳（毫秒）
  createdAt: number;             // 创建时间戳
  updatedAt: number;            // 更新时间戳
}

/**
 * 家庭成员角色类型
 */
export type MemberRole = 
  | 'elder'      // 长辈
  | 'adult'       // 成年人
  | 'child'       // 孩子
  | 'other';      // 其他

/**
 * 创建新的家庭成员
 */
export function createFamilyMember(
  name: string,
  relation: string,
  role: MemberRole = 'other'
): FamilyMember {
  const now = Date.now();
  return {
    id: `member_${now}_${Math.random().toString(36).substring(2, 9)}`,
    name,
    relation,
    healthNotes: [],
    habits: [],
    constraints: [],
    avatar: undefined,
    lastMentioned: now,
    createdAt: now,
    updatedAt: now,
  };
}

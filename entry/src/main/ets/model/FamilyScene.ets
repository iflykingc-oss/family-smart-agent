/**
 * 家庭场景数据模型
 * 用于记忆常见家庭活动场景
 */
export interface FamilyScene {
  id: string;                    // 唯一标识符
  name: string;                  // 场景名称：如"野餐"、"家庭聚会"
  description?: string;         // 场景描述
  participants: string[];         // 参与成员ID列表
  defaultDevices: string[];       // 默认同步设备列表
  typicalTime?: string;           // 典型时间：如"周末"、"节假日"
  notes?: string;                // 备注
  createdAt: number;             // 创建时间戳
  updatedAt: number;             // 更新时间戳
}

/**
 * 创建新的家庭场景
 */
export function createFamilyScene(
  name: string,
  participants: string[] = [],
  description?: string
): FamilyScene {
  const now = Date.now();
  return {
    id: `scene_${now}_${Math.random().toString(36).substring(2, 9)}`,
    name,
    description,
    participants,
    defaultDevices: [],
    typicalTime: undefined,
    notes: undefined,
    createdAt: now,
    updatedAt: now,
  };
}

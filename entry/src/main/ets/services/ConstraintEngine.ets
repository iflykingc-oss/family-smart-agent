/**
 * 约束推理引擎
 * 核心职责：健康约束自动传导到任务分配
 * 
 * 能力：
 * - 判断任务是否违反成员约束
 * - 自动规避不合理分配
 * - 提供替代分配建议
 */

import { KnowledgeGraphService, Constraint, SemanticMemory } from './KnowledgeGraphService';

/**
 * 任务特征
 */
export interface TaskFeature {
  type: string;           // 'physical' | 'mental' | 'care' | 'other'
  physicalIntensity?: 'light' | 'medium' | 'heavy';
  requiresLifting?: boolean;
  requiresMovement?: boolean;
}

/**
 * 约束检查结果
 */
export interface ConstraintCheckResult {
  isAllowed: boolean;
  violatedConstraints: Constraint[];
  alternativeAssignments: AssignmentSuggestion[];
  reason: string;
}

/**
 * 分配建议
 */
export interface AssignmentSuggestion {
  memberId: string;
  memberName: string;
  reason: string;
  confidence: number;
}

/**
 * 分配决策
 */
export interface AssignmentDecision {
  memberId: string;
  memberName: string;
  isAutoAssigned: boolean;
  reason: string;
  constraintApplied?: Constraint;
}

/**
 * 约束推理引擎
 */
export class ConstraintEngine {
  private static instance: ConstraintEngine | null = null;
  private knowledgeGraph: KnowledgeGraphService;

  // 任务特征库
  private taskFeatureLibrary: Map<string, TaskFeature> = new Map();

  static getInstance(): ConstraintEngine {
    if (!ConstraintEngine.instance) {
      ConstraintEngine.instance = new ConstraintEngine();
    }
    return ConstraintEngine.instance;
  }

  private constructor() {
    this.knowledgeGraph = KnowledgeGraphService.getInstance();
    this.initTaskFeatureLibrary();
  }

  /**
   * 初始化任务特征库
   */
  private initTaskFeatureLibrary(): void {
    // 重体力任务
    this.taskFeatureLibrary.set('搬家具', { type: 'physical', physicalIntensity: 'heavy', requiresLifting: true });
    this.taskFeatureLibrary.set('搬家', { type: 'physical', physicalIntensity: 'heavy', requiresLifting: true });
    this.taskFeatureLibrary.set('搬重物', { type: 'physical', physicalIntensity: 'heavy', requiresLifting: true });
    this.taskFeatureLibrary.set('提水', { type: 'physical', physicalIntensity: 'heavy', requiresLifting: true });
    
    // 中等体力任务
    this.taskFeatureLibrary.set('扫地', { type: 'physical', physicalIntensity: 'light', requiresMovement: true });
    this.taskFeatureLibrary.set('拖地', { type: 'physical', physicalIntensity: 'medium', requiresMovement: true });
    this.taskFeatureLibrary.set('擦窗户', { type: 'physical', physicalIntensity: 'medium', requiresMovement: true });
    this.taskFeatureLibrary.set('买菜', { type: 'physical', physicalIntensity: 'medium', requiresLifting: true });
    this.taskFeatureLibrary.set('做饭', { type: 'mental', physicalIntensity: 'light' });
    
    // 照料任务
    this.taskFeatureLibrary.set('照顾老人', { type: 'care', physicalIntensity: 'medium' });
    this.taskFeatureLibrary.set('照顾孩子', { type: 'care', physicalIntensity: 'medium' });
    this.taskFeatureLibrary.set('陪老人看病', { type: 'care', physicalIntensity: 'light' });
  }

  /**
   * 检查任务分配是否违反约束
   */
  checkAssignment(params: {
    taskName: string;
    memberId: string;
    memberName: string;
  }): ConstraintCheckResult {
    const { taskName, memberId, memberName } = params;
    
    // 1. 获取任务特征
    const taskFeature = this.getTaskFeature(taskName);
    
    // 2. 获取成员约束
    const constraints = this.knowledgeGraph.getMemberConstraints(memberId);
    
    // 3. 检查是否违反约束
    const violatedConstraints: Constraint[] = [];
    
    constraints.forEach(c => {
      if (this.doesConstraintViolate(c, taskFeature)) {
        violatedConstraints.push(c);
      }
    });
    
    // 4. 生成结果
    if (violatedConstraints.length > 0) {
      const reason = this.generateViolationReason(violatedConstraints);
      return {
        isAllowed: false,
        violatedConstraints,
        alternativeAssignments: this.suggestAlternatives(memberId),
        reason,
      };
    }
    
    return {
      isAllowed: true,
      violatedConstraints: [],
      alternativeAssignments: [],
      reason: '无约束冲突',
    };
  }

  /**
   * 获取任务特征
   */
  getTaskFeature(taskName: string): TaskFeature {
    // 精确匹配
    if (this.taskFeatureLibrary.has(taskName)) {
      return this.taskFeatureLibrary.get(taskName)!;
    }
    
    // 模糊匹配
    const lowerName = taskName.toLowerCase();
    
    for (const [key, feature] of this.taskFeatureLibrary.entries()) {
      if (lowerName.includes(key.toLowerCase()) || key.toLowerCase().includes(lowerName)) {
        return feature;
      }
    }
    
    // 默认：中等体力
    return { type: 'physical', physicalIntensity: 'medium' };
  }

  /**
   * 检查约束是否与任务特征冲突
   */
  private doesConstraintViolate(constraint: Constraint, feature: TaskFeature): boolean {
    const condition = constraint.condition.toLowerCase();
    
    // 腰不好
    if (condition.includes('腰')) {
      if (feature.requiresLifting || feature.physicalIntensity === 'heavy' || feature.physicalIntensity === 'medium') {
        return true;
      }
    }
    
    // 高血压/心脏问题
    if (condition.includes('高血压') || condition.includes('心脏')) {
      if (feature.type === 'physical' && feature.physicalIntensity !== 'light') {
        return true;
      }
    }
    
    // 视力不好
    if (condition.includes('视力')) {
      if (feature.type === 'mental' && taskName.includes('精细')) {
        return true;
      }
    }
    
    return false;
  }

  /**
   * 生成违反原因
   */
  private generateViolationReason(constraints: Constraint[]): string {
    const reasons = constraints.map(c => {
      if (c.condition.includes('腰')) {
        return '该成员有腰伤，不适合体力劳动';
      }
      if (c.condition.includes('高血压') || c.condition.includes('心脏')) {
        return '该成员有心血管问题，不适合剧烈运动';
      }
      return `该成员有${c.condition}限制`;
    });
    return reasons.join('；');
  }

  /**
   * 建议替代分配
   */
  private suggestAlternatives(excludeMemberId: string): AssignmentSuggestion[] {
    // 获取所有成员
    const allMembers = this.knowledgeGraph.getSemanticsByMember(excludeMemberId);
    
    // 简化实现：假设家庭中有其他成员
    // 实际实现需要从FamilyMember获取所有成员列表
    return [
      {
        memberId: 'member_dad',
        memberName: '爸爸',
        reason: '体力较好，适合体力任务',
        confidence: 0.9,
      },
      {
        memberId: 'member_spouse',
        memberName: '老公',
        reason: '可分配轻体力任务',
        confidence: 0.7,
      },
    ];
  }

  /**
   * 智能分配任务
   * 给定任务和成员列表，自动选择合适的分配
   */
  smartAssign(params: {
    taskName: string;
    memberIds: string[];
    memberNames: string[];
  }): AssignmentDecision {
    const { taskName, memberIds, memberNames } = params;
    
    // 按优先级排序成员
    const sortedIndices = memberIds.map((id, index) => ({
      id,
      name: memberNames[index],
      priority: this.calculatePriority(id, taskName),
    })).sort((a, b) => b.priority - a.priority);
    
    // 尝试分配给优先级最高的成员
    for (const member of sortedIndices) {
      const check = this.checkAssignment({
        taskName,
        memberId: member.id,
        memberName: member.name,
      });
      
      if (check.isAllowed) {
        return {
          memberId: member.id,
          memberName: member.name,
          isAutoAssigned: member.id !== memberIds[0], // 如果不是第一个人选的，说明是自动分配的
          reason: member.id === memberIds[0] ? '用户指定' : '自动分配（规避约束）',
        };
      }
    }
    
    // 无法分配
    return {
      memberId: '',
      memberName: '',
      isAutoAssigned: true,
      reason: '无法自动分配，所有成员均有约束限制',
    };
  }

  /**
   * 计算成员对任务的优先级
   */
  private calculatePriority(memberId: string, taskName: string): number {
    let priority = 50; // 基础分
    
    // 获取成员偏好
    const semantics = this.knowledgeGraph.getSemanticsByMember(memberId);
    const taskFeature = this.getTaskFeature(taskName);
    
    // 检查是否有相关偏好
    semantics.forEach(s => {
      if (s.type === 'preference') {
        const content = s.content.toLowerCase();
        const taskLower = taskName.toLowerCase();
        
        // 如果偏好匹配任务
        if (content.includes('喜欢') && taskLower.includes('做')) {
          priority += 20;
        }
      }
      
      // 检查是否有相关约束
      if (s.type === 'health') {
        if (this.doesConstraintViolate({
          memberId,
          condition: s.summary,
          forbiddenActions: [],
        }, taskFeature)) {
          priority -= 100; // 大幅降低
        }
      }
    });
    
    return priority;
  }

  /**
   * 批量约束检查
   */
  checkBatch(tasks: Array<{
    taskName: string;
    assigneeId: string;
    assigneeName: string;
  }>): Array<{
    index: number;
    result: ConstraintCheckResult;
  }> {
    return tasks.map((task, index) => ({
      index,
      result: this.checkAssignment({
        taskName: task.taskName,
        memberId: task.assigneeId,
        memberName: task.assigneeName,
      }),
    }));
  }
}

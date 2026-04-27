/**
 * ============================================================================
 * 约束推理引擎
 * 负责：健康约束自动传导、智能任务分配
 * 
 * 核心能力：
 * - 识别成员约束条件（腰不好、高血压等）
 * - 判断任务分配是否违反约束
 * - 自动规避不合理分配
 * ============================================================================
 */

/** 约束 */
export interface Constraint {
  id: string;
  memberId: string;
  condition: string;           // "腰不好"
  forbiddenActions: string[];  // ["提重物", "搬重东西"]
  autoApply: boolean;
}

/** 分配检查结果 */
export interface AssignCheckResult {
  isAllowed: boolean;
  violatedConstraint?: Constraint;
  reason: string;
}

/** 分配决策 */
export interface AssignDecision {
  memberId: string;
  memberName: string;
  isAutoAssigned: boolean;
  reason: string;
  violatedConstraint?: Constraint;
}

/** 任务特征 */
interface TaskFeature {
  type: 'physical' | 'mental' | 'care' | 'other';
  intensity?: 'light' | 'medium' | 'heavy';
  requiresLifting?: boolean;
  requiresMotion?: boolean;
}

// ===== 约束规则库 =====
const CONSTRAINT_RULES: Record<string, TaskFeature['forbiddenActions']> = {
  '腰不好': ['提重物', '搬重东西', '弯腰', '搬家具', '提水'],
  '高血压': ['剧烈运动', '情绪激动', '爬高', '剧烈活动'],
  '心脏': ['剧烈运动', '剧烈活动', '提重物'],
  '胃寒': ['吃凉的', '吃辣', '吃冰'],
  '怕冷': ['吹冷风', '喝冰水', '少穿衣'],
  '怕热': ['暴晒', '剧烈活动', '闷热环境'],
  '视力不好': ['看小字', '精细活'],
  '腿脚不便': ['长时间走路', '爬楼', '提重物'],
};

/** 任务特征库 */
const TASK_FEATURES: Record<string, TaskFeature> = {
  '搬家具': { type: 'physical', intensity: 'heavy', requiresLifting: true },
  '搬家': { type: 'physical', intensity: 'heavy', requiresLifting: true },
  '搬重物': { type: 'physical', intensity: 'heavy', requiresLifting: true },
  '提水': { type: 'physical', intensity: 'heavy', requiresLifting: true },
  '提重物': { type: 'physical', intensity: 'heavy', requiresLifting: true },
  '扫地': { type: 'physical', intensity: 'light', requiresMotion: true },
  '拖地': { type: 'physical', intensity: 'medium', requiresMotion: true },
  '擦窗户': { type: 'physical', intensity: 'medium', requiresMotion: true },
  '买菜': { type: 'physical', intensity: 'medium', requiresLifting: true },
  '做饭': { type: 'mental', intensity: 'light' },
  '洗碗': { type: 'physical', intensity: 'light' },
  '接送孩子': { type: 'care', intensity: 'medium' },
  '照顾老人': { type: 'care', intensity: 'medium' },
  '照顾孩子': { type: 'care', intensity: 'medium' },
  '陪老人看病': { type: 'care', intensity: 'light' },
  '写作业': { type: 'mental', intensity: 'light' },
  '运动': { type: 'physical', intensity: 'medium' },
  '跑步': { type: 'physical', intensity: 'heavy' },
  '爬楼': { type: 'physical', intensity: 'heavy' },
};

// ===== 约束推理引擎 =====
export class ConstraintEngine {
  private static instance: ConstraintEngine | null = null;
  private constraints: Map<string, Constraint[]> = new Map();

  static getInstance(): ConstraintEngine {
    if (!ConstraintEngine.instance) {
      ConstraintEngine.instance = new ConstraintEngine();
    }
    return ConstraintEngine.instance;
  }

  /**
   * 添加约束
   */
  addConstraint(memberId: string, condition: string, forbiddenActions?: string[]): void {
    const actions = forbiddenActions || CONSTRAINT_RULES[condition] || [];
    const constraint: Constraint = {
      id: `c_${Date.now()}_${Math.random().toString(36).slice(2)}`,
      memberId,
      condition,
      forbiddenActions: actions,
      autoApply: true
    };

    const existing = this.constraints.get(memberId) || [];
    // 避免重复添加
    if (!existing.some(c => c.condition === condition)) {
      existing.push(constraint);
      this.constraints.set(memberId, existing);
    }
  }

  /**
   * 从文本自动提取约束
   */
  extractAndAddConstraint(memberId: string, text: string): Constraint | null {
    const lower = text.toLowerCase();

    if (lower.includes('腰不好') || lower.includes('腰疼')) {
      this.addConstraint(memberId, '腰不好');
      return this.constraints.get(memberId)?.find(c => c.condition === '腰不好') || null;
    }

    if (lower.includes('高血压')) {
      this.addConstraint(memberId, '高血压');
      return this.constraints.get(memberId)?.find(c => c.condition === '高血压') || null;
    }

    if (lower.includes('心脏')) {
      this.addConstraint(memberId, '心脏');
      return this.constraints.get(memberId)?.find(c => c.condition === '心脏') || null;
    }

    if (lower.includes('胃寒') || lower.includes('胃不好')) {
      this.addConstraint(memberId, '胃寒');
      return this.constraints.get(memberId)?.find(c => c.condition === '胃寒') || null;
    }

    if (lower.includes('怕冷')) {
      this.addConstraint(memberId, '怕冷');
      return this.constraints.get(memberId)?.find(c => c.condition === '怕冷') || null;
    }

    if (lower.includes('怕热')) {
      this.addConstraint(memberId, '怕热');
      return this.constraints.get(memberId)?.find(c => c.condition === '怕热') || null;
    }

    return null;
  }

  /**
   * 获取成员所有约束
   */
  getMemberConstraints(memberId: string): Constraint[] {
    return this.constraints.get(memberId) || [];
  }

  /**
   * 获取成员约束描述
   */
  getMemberConstraintSummary(memberId: string): string[] {
    const constraints = this.getMemberConstraints(memberId);
    return constraints.map(c => c.condition);
  }

  /**
   * 检查单个分配是否允许
   */
  checkAssignment(params: {
    taskName: string;
    memberId: string;
    memberName: string;
  }): AssignCheckResult {
    const constraints = this.getMemberConstraints(params.memberId);
    if (constraints.length === 0) {
      return { isAllowed: true, reason: '无约束' };
    }

    const taskFeature = this.getTaskFeature(params.taskName);

    for (const c of constraints) {
      if (this.isConstraintViolated(c, taskFeature, params.taskName)) {
        return {
          isAllowed: false,
          violatedConstraint: c,
          reason: this.generateViolationReason(c, params.memberName)
        };
      }
    }

    return { isAllowed: true, reason: '无约束冲突' };
  }

  /**
   * 智能分配（找到第一个允许的成员）
   */
  smartAssign(params: {
    taskName: string;
    memberIds: string[];
    memberNames: string[];
  }): AssignDecision[] {
    const decisions: AssignDecision[] = [];

    for (let i = 0; i < params.memberIds.length; i++) {
      const check = this.checkAssignment({
        taskName: params.taskName,
        memberId: params.memberIds[i],
        memberName: params.memberNames[i]
      });

      decisions.push({
        memberId: params.memberIds[i],
        memberName: params.memberNames[i],
        isAutoAssigned: i > 0,  // 如果不是第一个指定的，说明是自动分配的
        reason: check.reason,
        violatedConstraint: check.violatedConstraint
      });
    }

    return decisions;
  }

  /**
   * 获取最优分配（第一个允许的）
   */
  getBestAssignment(params: {
    taskName: string;
    memberIds: string[];
    memberNames: string[];
  }): AssignDecision | null {
    for (let i = 0; i < params.memberIds.length; i++) {
      const check = this.checkAssignment({
        taskName: params.taskName,
        memberId: params.memberIds[i],
        memberName: params.memberNames[i]
      });

      if (check.isAllowed) {
        return {
          memberId: params.memberIds[i],
          memberName: params.memberNames[i],
          isAutoAssigned: i > 0,
          reason: check.reason
        };
      }
    }
    return null;
  }

  // ===== 私有方法 =====

  private getTaskFeature(taskName: string): TaskFeature {
    // 精确匹配
    if (TASK_FEATURES[taskName]) {
      return TASK_FEATURES[taskName];
    }

    // 模糊匹配
    const lower = taskName.toLowerCase();
    for (const [key, feature] of Object.entries(TASK_FEATURES)) {
      if (lower.includes(key) || key.includes(lower)) {
        return feature;
      }
    }

    // 默认：中等体力
    return { type: 'physical', intensity: 'medium' };
  }

  private isConstraintViolated(constraint: Constraint, feature: TaskFeature, taskName: string): boolean {
    const conditionLower = constraint.condition.toLowerCase();

    // 腰不好 → 不能提重物/弯腰/剧烈
    if (conditionLower.includes('腰')) {
      if (constraint.forbiddenActions.some(a => taskName.includes(a))) return true;
      if (feature.intensity === 'heavy' || feature.requiresLifting) return true;
    }

    // 高血压/心脏 → 不能剧烈运动
    if (conditionLower.includes('高血压') || conditionLower.includes('心脏')) {
      if (feature.intensity === 'heavy') return true;
      if (taskName.includes('剧烈运动')) return true;
    }

    // 胃寒 → 不能吃凉的/辣的
    if (conditionLower.includes('胃寒')) {
      if (taskName.includes('吃凉的') || taskName.includes('吃辣')) return true;
    }

    return false;
  }

  private generateViolationReason(constraint: Constraint, memberName: string): string {
    const condition = constraint.condition;
    if (condition === '腰不好') {
      return `${memberName}腰不好，不适合体力劳动`;
    }
    if (condition === '高血压' || condition === '心脏') {
      return `${memberName}有心血管问题，不适合剧烈运动`;
    }
    if (condition === '胃寒') {
      return `${memberName}胃寒，需要注意饮食`;
    }
    return `${memberName}有${condition}限制`;
  }
}

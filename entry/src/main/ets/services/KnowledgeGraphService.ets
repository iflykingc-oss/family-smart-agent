/**
 * 家庭知识图谱服务
 * 自研三层记忆系统：Semantic（语义）| Procedural（程序）| Episodic（情景）
 * 
 * 核心能力：
 * - 存储家庭成员的事实性知识（健康、偏好、约束）
 * - 跨任务查询和应用这些知识
 * - 与华为AI协作：华为理解输入，我们管理记忆
 */

/**
 * 语义记忆类型
 */
export type SemanticType = 
  | 'health'        // 健康信息："腰不好"
  | 'preference'    // 偏好："喜欢吃甜的"
  | 'constraint'   // 约束："不能剧烈运动"
  | 'relation';     // 关系："是爸爸的妻子"

/**
 * 语义记忆
 * 事实性知识，关于家庭成员的信息
 */
export interface SemanticMemory {
  id: string;
  type: SemanticType;
  memberId: string;        // 关联成员
  content: string;         // 原始内容
  summary: string;         // AI摘要
  keywords: string[];      // 检索关键词
  confidence: number;      // 置信度 0-1
  sourceTaskId?: string;   // 来源任务
  usageCount: number;      // 被调用次数
  createdAt: number;
  updatedAt: number;
}

/**
 * 程序记忆
 * 行为模式，从历史任务中学习到的规律
 */
export interface ProceduralMemory {
  id: string;
  pattern: string;        // 模式描述："爸爸的任务安排在下午"
  trigger: string[];        // 触发词
  action: string;          // 执行动作
  confidence: number;      // 置信度
  evidence: string[];      // 来源任务ID列表
  autoApply: boolean;     // 是否自动应用
  usageCount: number;
  createdAt: number;
}

/**
 * 情景记忆
 * 历史事件，按时间线记录
 */
export interface EpisodicMemory {
  id: string;
  type: 'event' | 'task' | 'decision' | 'scene_created';
  content: string;
  summary: string;
  timestamp: number;
  relatedMemberIds: string[];
  relatedSceneId?: string;
  createdAt: number;
}

/**
 * 知识图谱查询结果
 */
export interface KnowledgeQueryResult {
  semantics: SemanticMemory[];
  procedurals: ProceduralMemory[];
  episodics: EpisodicMemory[];
  recommendations: string[];   // 主动推荐的建议
}

/**
 * 知识图谱服务
 */
export class KnowledgeGraphService {
  private static instance: KnowledgeGraphService | null = null;
  
  // 三层存储
  private semanticStore: Map<string, SemanticMemory> = new Map();
  private proceduralStore: Map<string, ProceduralMemory> = new Map();
  private episodicStore: Map<string, EpisodicMemory> = new Map();
  
  // 成员索引（memberId -> semanticIds）
  private memberIndex: Map<string, string[]> = new Map();
  
  // 关键词索引
  private keywordIndex: Map<string, string[]> = new Map();

  static getInstance(): KnowledgeGraphService {
    if (!KnowledgeGraphService.instance) {
      KnowledgeGraphService.instance = new KnowledgeGraphService();
    }
    return KnowledgeGraphService.instance;
  }

  private constructor() {
    this.initSampleData();
  }

  /**
   * 初始化示例数据
   */
  private initSampleData(): void {
    // 示例：妈妈腰不好
    this.addSemantic({
      id: 'sem_001',
      type: 'health',
      memberId: 'member_mom',
      content: '妈妈腰不好，不能提重物',
      summary: '腰不好',
      keywords: ['腰', '不好', '重物', '妈妈'],
      confidence: 0.95,
      usageCount: 0,
    });

    // 示例：爸爸喜欢下午做事
    this.addSemantic({
      id: 'sem_002',
      type: 'preference',
      memberId: 'member_dad',
      content: '爸爸喜欢下午做事',
      summary: '喜欢下午',
      keywords: ['爸爸', '下午', '喜欢'],
      confidence: 0.8,
      usageCount: 0,
    });
  }

  // ==================== 语义记忆操作 ====================

  /**
   * 添加语义记忆
   */
  addSemantic(memory: SemanticMemory): void {
    memory.createdAt = Date.now();
    memory.updatedAt = Date.now();
    memory.usageCount = 0;
    
    this.semanticStore.set(memory.id, memory);
    
    // 更新成员索引
    this.updateMemberIndex(memory.memberId, memory.id);
    
    // 更新关键词索引
    memory.keywords.forEach(kw => {
      this.updateKeywordIndex(kw.toLowerCase(), memory.id);
    });
  }

  /**
   * 查询成员的所有语义记忆
   */
  getSemanticsByMember(memberId: string): SemanticMemory[] {
    const ids = this.memberIndex.get(memberId) ?? [];
    return ids.map(id => this.semanticStore.get(id)).filter(Boolean) as SemanticMemory[];
  }

  /**
   * 关键词搜索语义记忆
   */
  searchSemantics(keywords: string[]): SemanticMemory[] {
    const resultIds = new Set<string>();
    
    keywords.forEach(kw => {
      const ids = this.keywordIndex.get(kw.toLowerCase()) ?? [];
      ids.forEach(id => resultIds.add(id));
    });
    
    return Array.from(resultIds).map(id => this.semanticStore.get(id)).filter(Boolean) as SemanticMemory[];
  }

  /**
   * 获取成员约束（用于任务分配）
   */
  getMemberConstraints(memberId: string): Constraint[] {
    const semantics = this.getSemanticsByMember(memberId);
    const constraints: Constraint[] = [];
    
    semantics.forEach(s => {
      if (s.type === 'health' || s.type === 'constraint') {
        constraints.push({
          memberId: s.memberId,
          condition: s.summary,
          forbiddenActions: this.extractForbiddenActions(s.content),
        });
      }
    });
    
    return constraints;
  }

  /**
   * 从内容中提取禁止的动作
   */
  private extractForbiddenActions(content: string): string[] {
    const actions: string[] = [];
    const lower = content.toLowerCase();
    
    if (lower.includes('腰') && (lower.includes('不好') || lower.includes('疼'))) {
      actions.push('提重物', '搬重东西', '弯腰');
    }
    if (lower.includes('高血压')) {
      actions.push('剧烈运动', '情绪激动');
    }
    if (lower.includes('心脏')) {
      actions.push('剧烈运动');
    }
    
    return actions;
  }

  // ==================== 程序记忆操作 ====================

  /**
   * 添加程序记忆（行为模式）
   */
  addProcedural(memory: ProceduralMemory): void {
    memory.createdAt = Date.now();
    memory.usageCount = 0;
    
    this.proceduralStore.set(memory.id, memory);
  }

  /**
   * 根据触发词查找程序记忆
   */
  findProcedurals(triggers: string[]): ProceduralMemory[] {
    const results: ProceduralMemory[] = [];
    
    this.proceduralStore.forEach(p => {
      const hasMatch = triggers.some(t => 
        p.trigger.includes(t) || 
        p.pattern.toLowerCase().includes(t.toLowerCase())
      );
      if (hasMatch) results.push(p);
    });
    
    // 按置信度排序
    return results.sort((a, b) => b.confidence - a.confidence);
  }

  /**
   * 观察行为，创建或更新程序记忆
   */
  observeAndLearn(taskId: string, context: {
    memberId?: string;
    timeOfDay?: string;
    taskType?: string;
    assignment?: string;
  }): void {
    // 简化实现：如果同一模式出现3次以上，创建程序记忆
    // 实际实现需要更复杂的模式识别
    
    if (context.memberId && context.timeOfDay && context.assignment) {
      // 检查是否已存在相似模式
      const existing = Array.from(this.proceduralStore.values()).find(p =>
        p.pattern.includes(context.memberId!) && 
        p.pattern.includes(context.timeOfDay!)
      );
      
      if (existing) {
        // 更新证据
        if (!existing.evidence.includes(taskId)) {
          existing.evidence.push(taskId);
          existing.usageCount = existing.evidence.length;
          // 3次以上自动应用
          if (existing.evidence.length >= 3) {
            existing.autoApply = true;
            existing.confidence = Math.min(0.95, existing.confidence + 0.1);
          }
        }
      }
    }
  }

  // ==================== 情景记忆操作 ====================

  /**
   * 添加情景记忆
   */
  addEpisodic(memory: EpisodicMemory): void {
    memory.createdAt = Date.now();
    this.episodicStore.set(memory.id, memory);
  }

  /**
   * 获取最近的情景记忆
   */
  getRecentEpisodics(limit: number = 10): EpisodicMemory[] {
    return Array.from(this.episodicStore.values())
      .sort((a, b) => b.timestamp - a.timestamp)
      .slice(0, limit);
  }

  // ==================== 综合查询 ====================

  /**
   * 综合查询
   */
  query(params: {
    memberId?: string;
    keywords?: string[];
    intentType?: string;
  }): KnowledgeQueryResult {
    let semantics: SemanticMemory[] = [];
    let procedurals: ProceduralMemory[] = [];
    const recommendations: string[] = [];

    // 1. 成员查询
    if (params.memberId) {
      semantics = this.getSemanticsByMember(params.memberId);
      
      // 查询相关程序记忆
      const member = semantics[0];
      if (member) {
        procedurals = this.findProcedurals([member.summary]);
      }
    }

    // 2. 关键词查询
    if (params.keywords && params.keywords.length > 0) {
      const keywordResults = this.searchSemantics(params.keywords);
      semantics = [...new Map([...semantics, ...keywordResults].map(s => [s.id, s])).values()];
      
      // 查询触发词匹配的程序记忆
      const proceduralResults = this.findProcedurals(params.keywords);
      procedurals = [...new Map([...procedurals, ...proceduralResults].map(p => [p.id, p])).values()];
    }

    // 3. 生成推荐
    if (params.intentType === 'task') {
      semantics.forEach(s => {
        if (s.type === 'health' && s.usageCount > 0) {
          recommendations.push(`注意：${s.memberId}有${s.summary}限制`);
        }
      });
    }

    return {
      semantics,
      procedurals,
      episodics: [],
      recommendations,
    };
  }

  // ==================== 辅助方法 ====================

  private updateMemberIndex(memberId: string, semanticId: string): void {
    const ids = this.memberIndex.get(memberId) ?? [];
    if (!ids.includes(semanticId)) {
      ids.push(semanticId);
      this.memberIndex.set(memberId, ids);
    }
  }

  private updateKeywordIndex(keyword: string, semanticId: string): void {
    const ids = this.keywordIndex.get(keyword) ?? [];
    if (!ids.includes(semanticId)) {
      ids.push(semanticId);
      this.keywordIndex.set(keyword, ids);
    }
  }

  /**
   * 获取统计数据
   */
  getStats(): {
    semanticCount: number;
    proceduralCount: number;
    episodicCount: number;
    memberCount: number;
  } {
    return {
      semanticCount: this.semanticStore.size,
      proceduralCount: this.proceduralStore.size,
      episodicCount: this.episodicStore.size,
      memberCount: this.memberIndex.size,
    };
  }
}

/**
 * 约束接口
 */
export interface Constraint {
  memberId: string;
  condition: string;
  forbiddenActions: string[];
}

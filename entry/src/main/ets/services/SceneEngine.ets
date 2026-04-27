/**
 * 场景引擎
 * Floatboat Combo 思想的家庭场景模板管理
 * 
 * 核心能力：
 * - 管理家庭场景模板（野餐、聚会、照料等）
 * - 从历史任务中自动发现和创建场景
 * - 智能推荐相关场景
 * - 场景自动补全
 */

/**
 * 场景模板
 * 对应 Floatboat 的 Combo
 */
export interface FamilyScene {
  id: string;
  name: string;              // 场景名称："野餐"
  description: string;       // 场景描述
  
  // 参与成员
  participantIds: string[];
  participantNames: string[];
  
  // 典型任务模板
  typicalTasks: TaskTemplate[];
  
  // 默认推送设备
  defaultDeviceIds: string[];
  
  // 关联资源
  resourceTemplates: ResourceTemplate[];
  
  // 使用统计
  usageCount: number;
  lastUsed: number;
  createdAt: number;
  
  // 推荐阈值
  autoRecommendThreshold: number;  // 使用N次以上自动推荐
  
  // 标签（用于检索）
  tags: string[];
}

/**
 * 任务模板
 */
export interface TaskTemplate {
  id: string;
  title: string;           // "准备食物"
  description: string;      // "准备野餐食物和饮料"
  assigneeId?: string;      // 默认分配
  assigneeName?: string;
  estimatedDuration?: number; // 分钟
  priority?: 'high' | 'medium' | 'low';
}

/**
 * 资源模板
 */
export interface ResourceTemplate {
  id: string;
  type: 'checklist' | 'template' | 'link';
  name: string;           // "野餐采购清单"
  content: string;        // JSON string
}

/**
 * 场景推荐
 */
export interface SceneRecommendation {
  scene: FamilyScene;
  matchScore: number;      // 匹配度 0-1
  matchReason: string;     // 匹配原因
  triggerKeywords: string[]; // 触发关键词
}

/**
 * 场景识别结果
 */
export interface SceneRecognitionResult {
  recognized: boolean;
  scene?: FamilyScene;
  confidence: number;
  suggestedTasks: string[];
}

/**
 * 场景引擎服务
 */
export class SceneEngine {
  private static instance: SceneEngine | null = null;
  
  // 场景存储
  private scenes: Map<string, FamilyScene> = new Map();
  
  // 名称索引
  private nameIndex: Map<string, string[]> = new Map();
  
  // 标签索引
  private tagIndex: Map<string, string[]> = new Map();

  static getInstance(): SceneEngine {
    if (!SceneEngine.instance) {
      SceneEngine.instance = new SceneEngine();
    }
    return SceneEngine.instance;
  }

  private constructor() {
    this.initSampleScenes();
  }

  /**
   * 初始化示例场景
   */
  private initSampleScenes(): void {
    // 野餐场景
    const picnicScene: FamilyScene = {
      id: 'scene_picnic',
      name: '野餐',
      description: '家庭户外野餐活动',
      participantIds: ['member_mom', 'member_dad', 'member_spouse'],
      participantNames: ['妈妈', '爸爸', '老公'],
      typicalTasks: [
        { id: 'task_1', title: '准备食物', description: '准备野餐食物和饮料', assigneeName: '妈妈' },
        { id: 'task_2', title: '准备帐篷', description: '带上帐篷和野餐垫', assigneeName: '爸爸' },
        { id: 'task_3', title: '采购清单', description: '列一份采购清单并采购', assigneeName: '老公' },
      ],
      defaultDeviceIds: ['smart_screen', 'smart_phone'],
      resourceTemplates: [
        { id: 'res_1', type: 'checklist', name: '野餐采购清单', content: '["水果","零食","饮料","湿巾","纸巾"]' },
      ],
      usageCount: 3,
      lastUsed: Date.now(),
      createdAt: Date.now() - 7 * 24 * 60 * 60 * 1000,
      autoRecommendThreshold: 3,
      tags: ['户外', '野餐', '周末', '家庭活动'],
    };
    
    this.addScene(picnicScene);
    
    // 家务场景
    const houseworkScene: FamilyScene = {
      id: 'scene_housework',
      name: '家务',
      description: '日常家务分配',
      participantIds: ['member_mom', 'member_dad', 'member_spouse'],
      participantNames: ['妈妈', '爸爸', '老公'],
      typicalTasks: [
        { id: 'task_1', title: '扫地', description: '打扫地面', assigneeName: '妈妈', priority: 'medium' },
        { id: 'task_2', title: '做饭', description: '准备晚餐', assigneeName: '老公', priority: 'high' },
      ],
      defaultDeviceIds: ['smart_phone'],
      resourceTemplates: [],
      usageCount: 10,
      lastUsed: Date.now(),
      createdAt: Date.now() - 30 * 24 * 60 * 60 * 1000,
      autoRecommendThreshold: 5,
      tags: ['家务', '日常', '分配'],
    };
    
    this.addScene(houseworkScene);
  }

  // ==================== 场景管理 ====================

  /**
   * 添加场景
   */
  addScene(scene: FamilyScene): void {
    scene.createdAt = Date.now();
    scene.lastUsed = Date.now();
    scene.usageCount = 0;
    
    this.scenes.set(scene.id, scene);
    
    // 更新名称索引
    this.updateNameIndex(scene);
    
    // 更新标签索引
    scene.tags.forEach(tag => this.updateTagIndex(tag, scene.id));
  }

  /**
   * 更新场景使用
   */
  useScene(sceneId: string): void {
    const scene = this.scenes.get(sceneId);
    if (scene) {
      scene.usageCount++;
      scene.lastUsed = Date.now();
    }
  }

  /**
   * 获取所有场景
   */
  getAllScenes(): FamilyScene[] {
    return Array.from(this.scenes.values());
  }

  /**
   * 获取常用场景
   */
  getTopScenes(limit: number = 5): FamilyScene[] {
    return Array.from(this.scenes.values())
      .sort((a, b) => b.usageCount - a.usageCount)
      .slice(0, limit);
  }

  // ==================== 场景识别 ====================

  /**
   * 从意图中识别场景
   */
  recognizeFromIntent(intent: {
    text: string;
    keywords: string[];
    entityTypes: string[];
  }): SceneRecognitionResult {
    const { text, keywords } = intent;
    const lowerText = text.toLowerCase();
    
    // 1. 名称匹配
    for (const [name, sceneIds] of this.nameIndex.entries()) {
      if (lowerText.includes(name.toLowerCase())) {
        const scene = this.scenes.get(sceneIds[0]);
        if (scene) {
          return {
            recognized: true,
            scene,
            confidence: 0.95,
            suggestedTasks: scene.typicalTasks.map(t => t.title),
          };
        }
      }
    }
    
    // 2. 标签匹配
    const matchingScenes: Array<{ scene: FamilyScene; matchCount: number }> = [];
    
    keywords.forEach(kw => {
      const sceneIds = this.tagIndex.get(kw.toLowerCase()) ?? [];
      sceneIds.forEach(id => {
        const scene = this.scenes.get(id);
        if (scene) {
          const existing = matchingScenes.find(s => s.scene.id === id);
          if (existing) {
            existing.matchCount++;
          } else {
            matchingScenes.push({ scene, matchCount: 1 });
          }
        }
      });
    });
    
    if (matchingScenes.length > 0) {
      // 按匹配度排序
      matchingScenes.sort((a, b) => b.matchCount - a.matchCount);
      const best = matchingScenes[0];
      const confidence = Math.min(0.9, best.matchCount * 0.3);
      
      return {
        recognized: true,
        scene: best.scene,
        confidence,
        suggestedTasks: best.scene.typicalTasks.map(t => t.title),
      };
    }
    
    return {
      recognized: false,
      confidence: 0,
      suggestedTasks: [],
    };
  }

  /**
   * 补全场境
   * 当识别到场景后，自动填充典型任务
   */
  completeScene(sceneId: string, customTasks?: string[]): FamilyScene | null {
    const scene = this.scenes.get(sceneId);
    if (!scene) return null;
    
    // 如果有自定义任务，合并
    if (customTasks && customTasks.length > 0) {
      // 返回带自定义任务的场景副本
      const completed = { ...scene };
      completed.typicalTasks = [
        ...scene.typicalTasks,
        ...customTasks.map((t, i) => ({
          id: `custom_task_${i}`,
          title: t,
          description: t,
        })),
      ];
      return completed;
    }
    
    return scene;
  }

  // ==================== 场景推荐 ====================

  /**
   * 智能推荐场景
   */
  recommend(context: {
    keywords?: string[];
    memberId?: string;
    timeOfDay?: string;
    dayOfWeek?: string;
  }): SceneRecommendation[] {
    const recommendations: SceneRecommendation[] = [];
    
    this.scenes.forEach(scene => {
      let matchScore = 0;
      const triggerKeywords: string[] = [];
      
      // 1. 关键词匹配
      if (context.keywords) {
        context.keywords.forEach(kw => {
          const lowerKw = kw.toLowerCase();
          
          if (scene.name.toLowerCase().includes(lowerKw)) {
            matchScore += 0.4;
            triggerKeywords.push(kw);
          }
          
          if (scene.tags.some(t => t.toLowerCase().includes(lowerKw))) {
            matchScore += 0.2;
            triggerKeywords.push(kw);
          }
        });
      }
      
      // 2. 成员匹配
      if (context.memberId && scene.participantIds.includes(context.memberId)) {
        matchScore += 0.2;
      }
      
      // 3. 使用频率加成
      if (scene.usageCount >= scene.autoRecommendThreshold) {
        matchScore += 0.1;
      }
      
      // 4. 最近使用加成
      const daysSinceLastUsed = (Date.now() - scene.lastUsed) / (24 * 60 * 60 * 1000);
      if (daysSinceLastUsed <= 7) {
        matchScore += 0.1;
      }
      
      if (matchScore > 0.1) {
        recommendations.push({
          scene,
          matchScore: Math.min(1, matchScore),
          matchReason: this.generateMatchReason(scene, context),
          triggerKeywords,
        });
      }
    });
    
    // 按匹配度排序
    return recommendations.sort((a, b) => b.matchScore - a.matchScore);
  }

  /**
   * 生成匹配原因
   */
  private generateMatchReason(scene: FamilyScene, context: {
    keywords?: string[];
    memberId?: string;
  }): string {
    const reasons: string[] = [];
    
    if (context.keywords) {
      const matched = scene.tags.filter(t => 
        context.keywords!.some(kw => t.toLowerCase().includes(kw.toLowerCase()))
      );
      if (matched.length > 0) {
        reasons.push(`相关标签：${matched.join(', ')}`);
      }
    }
    
    if (context.memberId && scene.participantIds.includes(context.memberId)) {
      const memberName = scene.participantNames[scene.participantIds.indexOf(context.memberId)];
      reasons.push(`涉及${memberName}`);
    }
    
    if (scene.usageCount > 0) {
      reasons.push(`您已使用${scene.usageCount}次`);
    }
    
    return reasons.join('；') || '推荐使用';
  }

  // ==================== 场景创建 ====================

  /**
   * 从任务历史中建议创建场景
   */
  suggestSceneFromHistory(tasks: Array<{
    title: string;
    assigneeName?: string;
    timestamp: number;
  }>): Partial<FamilyScene> | null {
    // 简化实现：如果同一批任务出现3次以上，建议创建场景
    
    if (tasks.length < 3) return null;
    
    // 提取任务标题
    const taskTitles = tasks.map(t => t.title);
    const uniqueTitles = [...new Set(taskTitles)];
    
    // 提取参与者
    const assignees = tasks.filter(t => t.assigneeName).map(t => t.assigneeName!);
    const uniqueAssignees = [...new Set(assignees)];
    
    // 如果有足够多的重复任务
    if (uniqueTitles.length <= tasks.length / 2 && uniqueAssignees.length > 0) {
      return {
        name: `场景_${Date.now()}`,
        description: `包含${uniqueTitles.length}个任务的家庭场景`,
        participantNames: uniqueAssignees,
        typicalTasks: uniqueTitles.map((t, i) => ({
          id: `auto_task_${i}`,
          title: t,
          description: t,
        })),
        tags: ['自动发现'],
      };
    }
    
    return null;
  }

  // ==================== 辅助方法 ====================

  private updateNameIndex(scene: FamilyScene): void {
    const sceneIds = this.nameIndex.get(scene.name) ?? [];
    if (!sceneIds.includes(scene.id)) {
      sceneIds.push(scene.id);
      this.nameIndex.set(scene.name, sceneIds);
    }
  }

  private updateTagIndex(tag: string, sceneId: string): void {
    const sceneIds = this.tagIndex.get(tag.toLowerCase()) ?? [];
    if (!sceneIds.includes(sceneId)) {
      sceneIds.push(sceneId);
      this.tagIndex.set(tag.toLowerCase(), sceneIds);
    }
  }

  /**
   * 获取统计数据
   */
  getStats(): {
    sceneCount: number;
    totalUsage: number;
    topScene: string | null;
  } {
    const scenes = Array.from(this.scenes.values());
    const totalUsage = scenes.reduce((sum, s) => sum + s.usageCount, 0);
    const top = scenes.sort((a, b) => b.usageCount - a.usageCount)[0];
    
    return {
      sceneCount: scenes.length,
      totalUsage,
      topScene: top?.name ?? null,
    };
  }
}

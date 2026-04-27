/**
 * 模式学习器
 * 自研行为模式学习引擎
 * 
 * 核心能力：
 * - 观察用户行为，记录任务执行历史
 * - 从历史中发现重复模式
 * - 蒸馏为可自动应用的规则
 * - Floatboat Combo 思想的实现
 */

/**
 * 行为事件
 */
export interface BehaviorEvent {
  id: string;
  timestamp: number;
  type: EventType;
  memberId?: string;
  memberName?: string;
  taskType?: string;
  timeOfDay?: string;
  dayOfWeek?: string;
  outcome?: 'accepted' | 'modified' | 'rejected';
  details: string;
}

/**
 * 事件类型
 */
export type EventType = 
  | 'task_assign'      // 任务分配
  | 'task_complete'     // 任务完成
  | 'time_preference'   // 时间偏好
  | 'member_preference' // 成员偏好
  | 'scene_create'      // 场景创建
  | 'scene_use';       // 场景使用

/**
 * 发现的模式
 */
export interface DiscoveredPattern {
  id: string;
  type: PatternType;
  description: string;
  trigger: string[];       // 触发条件
  action: string;          // 执行动作
  evidenceCount: number;   // 证据数量
  confidence: number;      // 置信度 0-1
  firstSeen: number;
  lastSeen: number;
  autoApply: boolean;     // 是否自动应用
}

/**
 * 模式类型
 */
export type PatternType = 
  | 'timing'          // 时间模式："爸爸的任务在下午"
  | 'assignment'       // 分配模式："重活分配给爸爸"
  | 'sequence'        // 顺序模式："先买菜再做饭"
  | 'scene';          // 场景模式："野餐需要准备..."

/**
 * 学习规则
 */
export interface LearnedRule {
  id: string;
  patternId: string;
  trigger: string[];
  action: string;
  confidence: number;
  usageCount: number;
  lastUsed: number;
  autoApply: boolean;
}

/**
 * 推荐的 Combo
 */
export interface ComboRecommendation {
  sceneName: string;
  description: string;
  usageCount: number;
  confidence: number;
  trigger: string[];
}

/**
 * 模式学习器服务
 */
export class PatternLearnerService {
  private static instance: PatternLearnerService | null = null;
  
  // 行为事件历史
  private eventHistory: BehaviorEvent[] = [];
  
  // 发现的模式
  private patterns: Map<string, DiscoveredPattern> = new Map();
  
  // 学习到的规则
  private learnedRules: Map<string, LearnedRule> = new Map();
  
  // 模式发现阈值
  private readonly PATTERN_THRESHOLD = 3;  // 连续3次触发才认为是模式
  private readonly CONFIDENCE_BOOST = 0.15; // 每次确认增加置信度

  static getInstance(): PatternLearnerService {
    if (!PatternLearnerService.instance) {
      PatternLearnerService.instance = new PatternLearnerService();
    }
    return PatternLearnerService.instance;
  }

  private constructor() {}

  // ==================== 行为观察 ====================

  /**
   * 记录行为事件
   */
  recordEvent(event: Omit<BehaviorEvent, 'id' | 'timestamp'>): void {
    const fullEvent: BehaviorEvent = {
      ...event,
      id: `evt_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      timestamp: Date.now(),
    };
    
    this.eventHistory.push(fullEvent);
    
    // 触发模式发现
    this.detectPattern(fullEvent);
    
    // 触发规则更新
    this.updateRules(fullEvent);
    
    // 限制历史长度
    if (this.eventHistory.length > 1000) {
      this.eventHistory = this.eventHistory.slice(-500);
    }
  }

  /**
   * 快捷方法：记录任务分配
   */
  recordTaskAssign(memberId: string, memberName: string, taskType: string): void {
    const now = new Date();
    this.recordEvent({
      type: 'task_assign',
      memberId,
      memberName,
      taskType,
      timeOfDay: this.getTimeOfDay(now),
      dayOfWeek: this.getDayOfWeek(now),
      outcome: 'accepted',
      details: `将${taskType}分配给${memberName}`,
    });
  }

  /**
   * 快捷方法：记录时间偏好
   */
  recordTimePreference(memberId: string, memberName: string, timeOfDay: string, taskType: string): void {
    this.recordEvent({
      type: 'time_preference',
      memberId,
      memberName,
      taskType,
      timeOfDay,
      details: `${memberName}在${timeOfDay}执行${taskType}`,
    });
  }

  // ==================== 模式发现 ====================

  /**
   * 从新事件中检测模式
   */
  private detectPattern(event: BehaviorEvent): void {
    // 简化实现：检查是否有重复事件
    
    if (event.type === 'task_assign' && event.memberId && event.taskType) {
      // 检查是否有时间模式
      this.detectTimingPattern(event);
      
      // 检查是否有分配模式
      this.detectAssignmentPattern(event);
    }
    
    if (event.type === 'time_preference') {
      this.detectTimingPattern(event);
    }
  }

  /**
   * 检测时间模式
   * 例如："爸爸的任务通常在下午"
   */
  private detectTimingPattern(event: BehaviorEvent): void {
    if (!event.memberId || !event.timeOfDay || !event.taskType) return;
    
    const patternKey = `timing_${event.memberId}_${event.timeOfDay}`;
    
    // 查找相似事件
    const similarEvents = this.eventHistory.filter(e =>
      e.memberId === event.memberId &&
      e.timeOfDay === event.timeOfDay &&
      e.type === event.type
    );
    
    if (similarEvents.length >= this.PATTERN_THRESHOLD) {
      // 发现模式
      const existingPattern = this.patterns.get(patternKey);
      
      if (existingPattern) {
        // 更新现有模式
        existingPattern.evidenceCount = similarEvents.length;
        existingPattern.confidence = Math.min(0.95, existingPattern.confidence + this.CONFIDENCE_BOOST);
        existingPattern.lastSeen = event.timestamp;
        
        // 3次以上自动应用
        if (similarEvents.length >= 3 && !existingPattern.autoApply) {
          existingPattern.autoApply = true;
        }
      } else {
        // 创建新模式
        const pattern: DiscoveredPattern = {
          id: patternKey,
          type: 'timing',
          description: `${event.memberName}的任务通常在${event.timeOfDay}`,
          trigger: [event.memberId!, event.timeOfDay!],
          action: `将${event.taskType}安排在${event.timeOfDay}`,
          evidenceCount: similarEvents.length,
          confidence: 0.6,
          firstSeen: event.timestamp,
          lastSeen: event.timestamp,
          autoApply: false,
        };
        
        this.patterns.set(patternKey, pattern);
      }
    }
  }

  /**
   * 检测分配模式
   * 例如："重活总是分配给爸爸"
   */
  private detectAssignmentPattern(event: BehaviorEvent): void {
    if (!event.memberId || !event.taskType) return;
    
    const patternKey = `assign_${event.taskType}_${event.memberId}`;
    
    const similarEvents = this.eventHistory.filter(e =>
      e.taskType === event.taskType &&
      e.memberId === event.memberId &&
      e.type === 'task_assign'
    );
    
    if (similarEvents.length >= this.PATTERN_THRESHOLD) {
      const existingPattern = this.patterns.get(patternKey);
      
      if (existingPattern) {
        existingPattern.evidenceCount = similarEvents.length;
        existingPattern.confidence = Math.min(0.95, existingPattern.confidence + this.CONFIDENCE_BOOST);
        existingPattern.lastSeen = event.timestamp;
      } else {
        const pattern: DiscoveredPattern = {
          id: patternKey,
          type: 'assignment',
          description: `${event.taskType}总是分配给${event.memberName}`,
          trigger: [event.taskType!],
          action: `将${event.taskType}分配给${event.memberName}`,
          evidenceCount: similarEvents.length,
          confidence: 0.6,
          firstSeen: event.timestamp,
          lastSeen: event.timestamp,
          autoApply: false,
        };
        
        this.patterns.set(patternKey, pattern);
      }
    }
  }

  // ==================== 规则管理 ====================

  /**
   * 更新规则
   */
  private updateRules(event: BehaviorEvent): void {
    // 根据模式更新规则
    this.patterns.forEach((pattern, patternId) => {
      if (pattern.autoApply && pattern.evidenceCount >= 3) {
        const ruleId = `rule_${patternId}`;
        
        if (!this.learnedRules.has(ruleId)) {
          // 创建新规则
          const rule: LearnedRule = {
            id: ruleId,
            patternId,
            trigger: pattern.trigger,
            action: pattern.action,
            confidence: pattern.confidence,
            usageCount: 0,
            lastUsed: 0,
            autoApply: true,
          };
          
          this.learnedRules.set(ruleId, rule);
        }
      }
    });
  }

  /**
   * 查找匹配的规则
   */
  findMatchingRules(context: {
    memberId?: string;
    taskType?: string;
    timeOfDay?: string;
  }): LearnedRule[] {
    const matchingRules: LearnedRule[] = [];
    
    this.learnedRules.forEach(rule => {
      const matches = rule.trigger.some(t => {
        if (context.memberId && t === context.memberId) return true;
        if (context.taskType && t === context.taskType) return true;
        if (context.timeOfDay && t === context.timeOfDay) return true;
        return false;
      });
      
      if (matches) {
        matchingRules.push(rule);
      }
    });
    
    // 按置信度排序
    return matchingRules.sort((a, b) => b.confidence - a.confidence);
  }

  /**
   * 应用规则
   */
  applyRule(ruleId: string): boolean {
    const rule = this.learnedRules.get(ruleId);
    if (rule) {
      rule.usageCount++;
      rule.lastUsed = Date.now();
      return true;
    }
    return false;
  }

  // ==================== Combo 推荐 ====================

  /**
   * 获取推荐的情景模板（Combo）
   */
  getComboRecommendations(context: {
    keywords?: string[];
    memberId?: string;
    intentType?: string;
  }): ComboRecommendation[] {
    const recommendations: ComboRecommendation[] = [];
    
    // 从模式中找出场景模式
    this.patterns.forEach(pattern => {
      if (pattern.type === 'scene' && pattern.autoApply) {
        recommendations.push({
          sceneName: pattern.description,
          description: `根据您的使用习惯推荐`,
          usageCount: pattern.evidenceCount,
          confidence: pattern.confidence,
          trigger: pattern.trigger,
        });
      }
    });
    
    // 按置信度排序
    return recommendations.sort((a, b) => b.confidence - a.confidence);
  }

  // ==================== 辅助方法 ====================

  private getTimeOfDay(date: Date): string {
    const hour = date.getHours();
    if (hour < 12) return '上午';
    if (hour < 18) return '下午';
    return '晚上';
  }

  private getDayOfWeek(date: Date): string {
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return days[date.getDay()];
  }

  /**
   * 获取所有活跃模式
   */
  getActivePatterns(): DiscoveredPattern[] {
    return Array.from(this.patterns.values())
      .filter(p => p.confidence >= 0.5)
      .sort((a, b) => b.confidence - a.confidence);
  }

  /**
   * 获取所有活跃规则
   */
  getActiveRules(): LearnedRule[] {
    return Array.from(this.learnedRules.values())
      .filter(r => r.autoApply)
      .sort((a, b) => b.confidence - a.confidence);
  }

  /**
   * 获取统计数据
   */
  getStats(): {
    eventCount: number;
    patternCount: number;
    ruleCount: number;
    autoApplyRuleCount: number;
  } {
    return {
      eventCount: this.eventHistory.length,
      patternCount: this.patterns.size,
      ruleCount: this.learnedRules.size,
      autoApplyRuleCount: Array.from(this.learnedRules.values()).filter(r => r.autoApply).length,
    };
  }
}

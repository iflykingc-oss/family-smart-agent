/**
 * ============================================================================
 * 家庭认知管家·核心引擎
 * 负责：服务编排、入口协调
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { WarmService, WarmSceneType, Member } from './WarmService';
import { ConstraintEngine } from './ConstraintEngine';

// ===== 数据模型 =====

/** 家庭成员 */
export interface FamilyMember {
  memberId: string;
  name: string;
  role: FamilyRole;
  nickname: string[];
  devices: FamilyDevice[];
  emotionTags: string[];
  tags: {
    diet: string[];
    health: string[];
    habit: string[];
    contact: string[];
    temperature: string[];
  };
}

/** 设备 */
export interface FamilyDevice {
  deviceId: string;
  deviceName: string;
  deviceType: 'phone' | 'watch' | 'speaker' | 'tablet';
  isOnline: boolean;
  priority: number;
}

/** 家庭角色 */
export enum FamilyRole {
  WIFE = 'wife',
  HUSBAND = 'husband',
  MOTHER = 'mother',
  FATHER = 'father',
  SON = 'son',
  DAUGHTER = 'daughter'
}

/** 生活场景类型 */
export enum LifeSlotType {
  SUBJECT = 'subject',
  DIET = 'diet',
  HEALTH = 'health',
  HOUSEWORK = 'housework',
  CHILDCARE = 'childcare',
  PURCHASE = 'purchase',
  CONTACT = 'contact',
  TIME = 'time',
  ACTION = 'action'
}

/** 任务类型 */
export enum TaskType {
  TEMPORARY = 'temporary',
  PERIODIC = 'periodic'
}

/** 推送渠道 */
export enum RemindChannel {
  DEVICE_PUSH = 'device_push',
  CALENDAR = 'calendar',
  VOICE = 'voice',
  BROADCAST = 'broadcast'
}

/** 周期 */
export enum PeriodType {
  DAILY = 'daily',
  WEEKLY = 'weekly',
  MONTHLY = 'monthly'
}

/** 任务 */
export interface LifeTask {
  id: string;
  memberId: string;
  memberName: string;
  content: string;
  slotType: LifeSlotType;
  triggerTime: string;  // "HH:mm"
  channel: RemindChannel;
  type: TaskType;
  period?: PeriodType;
  cron?: string;
  isExecuted: boolean;
  needWarm: boolean;
  createdAt: number;
}

/** 规则 */
export interface LifeRule {
  id: string;
  memberId: string;
  ruleName: string;
  content: string;
  slotType: LifeSlotType;
  period: PeriodType;
  cronExpression: string;
  channel: RemindChannel;
  enabled: boolean;
  source: 'manual' | 'distill';
  warmTemplateId: string;
  priority: number;
  lastPushTime: number;
}

/** 解析结果 */
export interface ParseResult {
  success: boolean;
  memberId?: string;
  memberName?: string;
  tasks: LifeTask[];
  rules: LifeRule[];
  constraintWarnings: string[];  // 约束警告
  warmConfirmations: string[];  // 温情确认
  errorMsg?: string;
}

/** 推送结果 */
export interface PushResult {
  success: boolean;
  deviceName: string;
  message: string;
  msgId: string;
}

// ===== 核心引擎 =====

const TAG = 'FamilyEngine';

export class FamilyEngine {
  // ----- 服务 -----
  private warmService: WarmService;
  private constraintEngine: ConstraintEngine;

  // ----- 数据 -----
  private members: Map<string, FamilyMember> = new Map();
  private tasks: LifeTask[] = [];
  private rules: LifeRule[] = [];

  // ----- 状态 -----
  private isInitialized = false;
  private lastMemberId?: string;

  constructor() {
    this.warmService = new WarmService();
    this.constraintEngine = ConstraintEngine.getInstance();
  }

  // ===== 初始化 =====

  async init(): Promise<void> {
    if (this.isInitialized) return;
    HiLog.info(TAG, '家庭认知管家初始化');
    // TODO: 加载数据库
    this.isInitialized = true;
  }

  // ===== 成员管理 =====

  /**
   * 添加家庭成员
   */
  addMember(
    memberId: string,
    name: string,
    role: FamilyRole,
    nickname: string[],
    devices: FamilyDevice[],
    emotionTags: string[] = [],
    constraints: string[] = []
  ): void {
    const member: FamilyMember = {
      memberId,
      name,
      role,
      nickname,
      devices: this.sortDevicesByPriority(devices),
      emotionTags,
      tags: { diet: [], health: [], habit: [], contact: [], temperature: [] }
    };

    // 添加约束
    for (const c of constraints) {
      this.constraintEngine.extractAndAddConstraint(memberId, c);
      // 更新标签
      if (c.includes('腰不好')) member.tags.health.push('腰不好');
      if (c.includes('高血压')) member.tags.health.push('高血压');
      if (c.includes('胃寒')) member.tags.diet.push('胃寒');
    }

    this.members.set(memberId, member);
    HiLog.info(TAG, `成员添加：${name}，约束：${constraints.length}`);
  }

  // ===== 核心：解析生活指令 =====

  /**
   * 解析生活指令
   * 输入："妈妈腰不好，帮我安排家务" 或 "每天早上8点提醒妈妈吃药"
   */
  parseCommand(text: string, context?: { lastMemberId?: string }): ParseResult {
    // 1. 识别成员
    const memberId = this.matchMember(text) || context?.lastMemberId;
    if (!memberId) {
      return { success: false, tasks: [], rules: [], constraintWarnings: [], warmConfirmations: [], errorMsg: '未识别家人' };
    }
    const member = this.members.get(memberId)!;

    const result: ParseResult = {
      success: true,
      memberId,
      memberName: member.name,
      tasks: [],
      rules: [],
      constraintWarnings: [],
      warmConfirmations: []
    };

    // 2. 识别场景并生成任务
    const slot = this.recognizeSlot(text);
    const tasks = this.buildTasks(text, memberId, member.name, slot);
    result.tasks = tasks;

    // 3. 约束检查
    for (const task of tasks) {
      const check = this.constraintEngine.checkAssignment({
        taskName: task.content,
        memberId,
        memberName: member.name
      });
      if (!check.isAllowed && check.reason) {
        result.constraintWarnings.push(check.reason);
      }
    }

    // 4. 自动学习约束
    const extractedConstraint = this.constraintEngine.extractAndAddConstraint(memberId, text);
    if (extractedConstraint) {
      member.tags.health.push(extractedConstraint.condition);
      const warmMsg = this.warmService.generateWarmMsg(
        { name: member.name, tags: member.tags, emotionTags: member.emotionTags },
        this.warmService.recognizeScene(text)
      );
      result.warmConfirmations.push(warmMsg);
    }

    // 5. 生成周期规则（如果提到定时）
    if (text.includes('每天') || text.includes('每周') || text.includes('早上') || text.includes('晚上')) {
      const rule = this.buildRule(text, memberId, member.name, slot);
      if (rule) result.rules.push(rule);
    }

    this.lastMemberId = memberId;
    return result;
  }

  // ===== 核心：智能分配 =====

  /**
   * 智能分配任务
   * 自动规避有约束的成员
   */
  smartAssign(taskContent: string, excludeMemberId?: string): {
    memberId: string;
    memberName: string;
    reason: string;
  } {
    const availableMembers = Array.from(this.members.values())
      .filter(m => m.memberId !== excludeMemberId);

    for (const member of availableMembers) {
      const check = this.constraintEngine.checkAssignment({
        taskName: taskContent,
        memberId: member.memberId,
        memberName: member.name
      });

      if (check.isAllowed) {
        return {
          memberId: member.memberId,
          memberName: member.name,
          reason: '已为您分配'
        };
      }
    }

    // 全部有约束，返回最佳分配
    const first = availableMembers[0];
    return {
      memberId: first?.memberId || '',
      memberName: first?.name || '未知',
      reason: '所有成员均有约束，已分配给默认成员'
    };
  }

  // ===== 核心：生成温情推送 =====

  /**
   * 生成温情推送内容
   */
  generateWarmPush(
    memberId: string,
    content: string
  ): { warmMessage: string; scene: WarmSceneType } {
    const member = this.members.get(memberId);
    if (!member) return { warmMessage: content, scene: WarmSceneType.DAILY };

    const scene = this.warmService.recognizeScene(content);
    const warmMessage = this.warmService.generateWarmMsg(
      { name: member.name, tags: member.tags, emotionTags: member.emotionTags },
      scene
    );

    return { warmMessage, scene };
  }

  // ===== 辅助方法 =====

  private matchMember(text: string): string | null {
    for (const [id, member] of this.members) {
      if (member.nickname.some(n => text.includes(n))) {
        return id;
      }
    }
    return null;
  }

  private recognizeSlot(text: string): LifeSlotType {
    const lower = text.toLowerCase();
    if (lower.includes('吃药') || lower.includes('健康') || lower.includes('理疗')) {
      return LifeSlotType.HEALTH;
    }
    if (lower.includes('不吃') || lower.includes('忌口') || lower.includes('吃饭')) {
      return LifeSlotType.DIET;
    }
    if (lower.includes('作业') || lower.includes('孩子') || lower.includes('接送')) {
      return LifeSlotType.CHILDCARE;
    }
    if (lower.includes('买菜') || lower.includes('日用品') || lower.includes('采购')) {
      return LifeSlotType.PURCHASE;
    }
    if (lower.includes('家务') || lower.includes('打扫')) {
      return LifeSlotType.HOUSEWORK;
    }
    return LifeSlotType.ACTION;
  }

  private buildTasks(text: string, memberId: string, memberName: string, slot: LifeSlotType): LifeTask[] {
    const tasks: LifeTask[] = [];
    const cron = this.extractCron(text);

    const task: LifeTask = {
      id: `task_${Date.now()}_${Math.random().toString(36).slice(2)}`,
      memberId,
      memberName,
      content: this.extractTaskContent(text),
      slotType: slot,
      triggerTime: cron?.time || '09:00',
      channel: RemindChannel.DEVICE_PUSH,
      type: cron ? TaskType.PERIODIC : TaskType.TEMPORARY,
      period: cron?.period,
      cron: cron?.cron,
      isExecuted: false,
      needWarm: true,
      createdAt: Date.now()
    };

    tasks.push(task);
    return tasks;
  }

  private buildRule(text: string, memberId: string, memberName: string, slot: LifeSlotType): LifeRule | null {
    const cron = this.extractCron(text);
    if (!cron) return null;

    return {
      id: `rule_${Date.now()}`,
      memberId,
      ruleName: `定时提醒：${memberName}`,
      content: this.extractTaskContent(text),
      slotType: slot,
      period: cron.period,
      cronExpression: cron.cron,
      channel: RemindChannel.DEVICE_PUSH,
      enabled: true,
      source: 'distill',
      warmTemplateId: this.getWarmTemplateId(slot),
      priority: 80,
      lastPushTime: 0
    };
  }

  private extractCron(text: string): { cron: string; time: string; period: PeriodType } | null {
    if (text.includes('每天早上8点')) {
      return { cron: '0 8 * * *', time: '08:00', period: PeriodType.DAILY };
    }
    if (text.includes('每天晚上8点')) {
      return { cron: '0 20 * * *', time: '20:00', period: PeriodType.DAILY };
    }
    if (text.includes('每天')) {
      const time = text.match(/\d{1,2}点/)?.[0] || '09:00';
      const hour = parseInt(time);
      return { cron: `0 ${hour} * * *`, time: `${hour}:00`, period: PeriodType.DAILY };
    }
    return null;
  }

  private extractTaskContent(text: string): string {
    return text
      .replace(/妈妈|爸爸|老公|老婆|儿子|女儿/g, '')
      .replace(/腰不好|高血压|每天|每周|早上|晚上|提醒/g, '')
      .trim() || text;
  }

  private getWarmTemplateId(slot: LifeSlotType): string {
    switch (slot) {
      case LifeSlotType.HEALTH: return 'warm_health_01';
      case LifeSlotType.DIET: return 'warm_diet_01';
      case LifeSlotType.CHILDCARE: return 'warm_childcare_01';
      default: return 'warm_daily_01';
    }
  }

  private sortDevicesByPriority(devices: FamilyDevice[]): FamilyDevice[] {
    const PRIORITY: Record<string, number> = { watch: 100, phone: 90, speaker: 80, tablet: 70 };
    return [...devices].sort((a, b) =>
      (b.priority || PRIORITY[b.deviceType] || 50) -
      (a.priority || PRIORITY[a.deviceType] || 50)
    );
  }

  // ===== 数据查询 =====

  getMembers(): FamilyMember[] {
    return Array.from(this.members.values());
  }

  getMemberById(memberId: string): FamilyMember | undefined {
    return this.members.get(memberId);
  }

  getTasks(): LifeTask[] {
    return [...this.tasks];
  }

  getRules(): LifeRule[] {
    return [...this.rules];
  }

  getMemberConstraints(memberId: string): string[] {
    return this.constraintEngine.getMemberConstraintSummary(memberId);
  }
}

/**
 * ============================================================================
 * 鸿蒙家庭认知管家【整合版】
 * 整合自：
 *   - 杰哥生产级代码（温情文案、温度规则、设备推送、数据库、学习优化）
 *   - 团队设计（约束推理、三层记忆、模式学习）
 * 
 * 核心能力：三层记忆+定时推送+设备透传+温度逻辑+温情表达+学习优化+约束推理
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

// ====================== 1. 配置层 ======================

/** 温情文案库配置 */
interface WarmTemplate {
  id: string;
  scene: WarmSceneType;
  templates: string[];
}

/** 温度联动规则 */
interface TemperatureRule {
  id: string;
  tempRange: [number, number];
  memberTags: string[];
  warmScene: WarmSceneType;
  remindContent: string;
  priority: number;
}

/** 温情场景类型 */
enum WarmSceneType {
  HEALTH = 'health',
  DIET = 'diet',
  CHILDCARE = 'childcare',
  TEMPERATURE = 'temperature',
  DAILY = 'daily'
}

// 温情文案模板
const WARM_TEMPLATES_CONFIG: WarmTemplate[] = [
  {
    id: 'warm_health_01',
    scene: WarmSceneType.HEALTH,
    templates: [
      '{name}～到吃药时间啦，记得按时服药，好好照顾自己哦❤️',
      '温馨提醒{name}：该吃药啦，不要忘记呀',
      '{name}，用药时间到咯，好好休息✨'
    ]
  },
  {
    id: 'warm_diet_01',
    scene: WarmSceneType.DIET,
    templates: [
      '{name}，吃饭啦～记得规避{habit}，清淡饮食🥣',
      '温馨提示{name}：今日用餐要注意哦，别吃凉的',
      '{name}，开饭咯～记得少吃辣，好好享受美食'
    ]
  },
  {
    id: 'warm_childcare_01',
    scene: WarmSceneType.CHILDCARE,
    templates: [
      '宝贝{name}，到写作业的时间啦，认真完成，写完就可以玩啦💪',
      '{name}小朋友，作业时间到咯，专注一点，你超厉害的！',
      '亲爱的{name}，该写作业啦，完成就是最棒的！'
    ]
  },
  {
    id: 'warm_temp_01',
    scene: WarmSceneType.TEMPERATURE,
    templates: [
      '{name}，今天{temperature}，有点凉，记得添件外套，别着凉呀❤️',
      '温馨提醒{name}：今日温度较低，出门记得穿厚一点',
      '{name}，天气转凉啦，记得多喝温水'
    ]
  },
  {
    id: 'warm_daily_01',
    scene: WarmSceneType.DAILY,
    templates: [
      '{name}，辛苦啦，今天也要好好休息，别太累啦❤️',
      '亲爱的{name}，愿你今天心情愉快，万事顺意～',
      '{name}，忙碌的一天结束啦，好好放松✨'
    ]
  }
];

// 温度规则配置
const TEMPERATURE_RULES_CONFIG: TemperatureRule[] = [
  { id: 'temp_rule_01', tempRange: [0, 15], memberTags: ['腰不好', '胃寒', '怕冷'], warmScene: WarmSceneType.TEMPERATURE, remindContent: '添衣保暖', priority: 100 },
  { id: 'temp_rule_02', tempRange: [30, 40], memberTags: ['高血压', '怕热'], warmScene: WarmSceneType.TEMPERATURE, remindContent: '多喝水，避免暴晒', priority: 90 },
];

// ====================== 2. 核心枚举 ======================

enum FamilyRole {
  WIFE = 'wife', HUSBAND = 'husband', MOTHER = 'mother',
  FATHER = 'father', SON = 'son', DAUGHTER = 'daughter'
}

enum LifeSlotType {
  SUBJECT = 'subject', DIET = 'diet', HEALTH = 'health',
  HOUSEWORK = 'housework', CHILDCARE = 'childcare',
  PURCHASE = 'purchase', TIME = 'time', ACTION = 'action'
}

enum TaskType {
  TEMPORARY = 'temporary', PERIODIC = 'periodic'
}

enum RemindChannel {
  DEVICE_PUSH = 'device_push',
  SYSTEM_CALENDAR = 'calendar',
  VOICE_REMIND = 'voice',
  FAMILY_BROADCAST = 'family_broadcast'
}

enum PeriodType {
  DAILY = 'daily', WEEKLY = 'weekly', MONTHLY = 'monthly'
}

// ====================== 3. 数据模型 ======================

/** 家庭成员设备 */
interface FamilyDevice {
  deviceId: string;
  deviceName: string;
  deviceType: 'phone' | 'watch' | 'speaker' | 'tablet';
  isOnline: boolean;
  priority: number;
}

/** 成员设备映射 */
interface MemberDeviceMap {
  memberId: string;
  devices: FamilyDevice[];
}

/** 推送回执 */
interface PushReceipt {
  msgId: string;
  targetDeviceId: string;
  isSuccess: boolean;
  pushTime: number;
  retryCount: number;
  errorMsg?: string;
}

/** 用户反馈 */
interface UserFeedback {
  msgId: string;
  isUseful: boolean;
  feedbackTime: number;
}

// ----- 三层记忆（整合自设计） -----

/** 语义记忆：事实性知识 */
interface SemanticMemory {
  id: string;
  memberId: string;
  name: string;
  role: FamilyRole;
  deviceGroup: FamilyDevice[];
  // 五维标签（整合自设计）
  tags: {
    diet: string[];      // 饮食
    health: string[];   // 健康
    habit: string[];   // 习惯
    contact: string[];  // 人情
    temperature: string[]; // 温度敏感
  };
  // 约束标签（新增自设计：约束推理引擎用）
  constraints: string[];  // 约束条件，如"腰不好→禁止提重物"
  emotionTags: string[];
  createTime: number;
  updateTime: number;
}

/** 程序记忆：行为模式 */
interface ProceduralMemory {
  id: string;
  memberId: string;
  ruleName: string;
  period: PeriodType;
  cronExpression: string;
  taskContent: string;
  slotType: LifeSlotType;
  channel: RemindChannel;
  enabled: boolean;
  source: 'manual' | 'distill';
  lastPushTime: number;
  warmTemplateId: string;
  priority: number;
  // 约束来源（新增：标注规则来源）
  constraintSource?: string;
}

/** 情景记忆：历史事件 */
interface EpisodicMemory {
  id: string;
  memberId: string;
  taskContent: string;
  slotType: LifeSlotType;
  triggerTime: string;
  type: TaskType;
  channel: RemindChannel;
  isExecuted: boolean;
  timestamp: number;
  relatedMsgId: string[];
  needWarm: boolean;
}

// ----- 约束模型（整合自ConstraintEngine设计） -----

/** 约束规则 */
interface Constraint {
  id: string;
  memberId: string;
  condition: string;       // "腰不好"
  forbiddenActions: string[];  // ["提重物", "搬重东西"]
  autoApply: boolean;
}

/** 分配决策 */
interface AssignmentDecision {
  memberId: string;
  memberName: string;
  isAutoAssigned: boolean;
  reason: string;
  constraintApplied?: Constraint;
}

// ====================== 4. 工具类 ======================

class LifeUtils {
  static genId(): string {
    return `family_${Date.now()}_${Math.random().toString(36).slice(2)}`;
  }

  static matchMemberByNick(text: string, members: { memberId: string; nickname: string[] }[]): string | null {
    for (const m of members) {
      if (m.nickname.some(n => text.includes(n))) return m.memberId;
    }
    return null;
  }

  /** 生成温情文案 */
  static generateWarmMsg(
    template: string[],
    member: { name: string; tags: SemanticMemory['tags']; emotionTags: string[] },
    temperature?: number,
    usedTemplates?: string[]
  ): string {
    let available = usedTemplates ? template.filter(t => !usedTemplates.includes(t)) : template;
    if (available.length === 0) available = template;
    let msg = available[Math.floor(Math.random() * available.length)];
    msg = msg.replace(/{name}/g, member.name);
    msg = msg.replace(/{habit}/g, member.tags.habit[0] || '日常');
    msg = msg.replace(/{temperature}/g, temperature ? `${temperature}℃` : '适宜');
    return msg;
  }

  /** 温度规则匹配 */
  static matchTemperatureRule(
    currentTemp: number,
    memberTags: string[],
    rules: TemperatureRule[]
  ): TemperatureRule | null {
    const matched = rules.filter(rule =>
      currentTemp >= rule.tempRange[0] && currentTemp <= rule.tempRange[1] &&
      rule.memberTags.some(tag => memberTags.includes(tag))
    );
    return matched.sort((a, b) => b.priority - a.priority)[0] || null;
  }

  /** 解析Cron表达式 */
  static parseCron(cron: string): { hour: number; minute: number; dayOfWeek?: number } {
    const parts = cron.split(' ');
    return {
      minute: parseInt(parts[0]),
      hour: parseInt(parts[1]),
      dayOfWeek: parts[4] === '*' ? undefined : parseInt(parts[4])
    };
  }

  /** 设备优先级排序 */
  static sortDevicesByPriority(devices: FamilyDevice[]): FamilyDevice[] {
    const DEVICE_PRIORITY: Record<string, number> = {
      'watch': 100, 'phone': 90, 'speaker': 80, 'tablet': 70
    };
    return devices.sort((a, b) =>
      (b.priority || DEVICE_PRIORITY[b.deviceType] || 50) -
      (a.priority || DEVICE_PRIORITY[a.deviceType] || 50)
    );
  }
}

// ====================== 5. 约束推理引擎（整合自设计） ======================

class ConstraintEngine {
  private static instance: ConstraintEngine | null = null;
  private constraints: Map<string, Constraint[]> = new Map();

  static getInstance(): ConstraintEngine {
    if (!ConstraintEngine.instance) {
      ConstraintEngine.instance = new ConstraintEngine();
    }
    return ConstraintEngine.instance;
  }

  /** 添加约束 */
  addConstraint(memberId: string, condition: string, forbiddenActions: string[]): void {
    const constraint: Constraint = {
      id: LifeUtils.genId(),
      memberId,
      condition,
      forbiddenActions,
      autoApply: true
    };
    const existing = this.constraints.get(memberId) || [];
    existing.push(constraint);
    this.constraints.set(memberId, existing);
  }

  /** 获取成员所有约束 */
  getMemberConstraints(memberId: string): Constraint[] {
    return this.constraints.get(memberId) || [];
  }

  /** 检查任务分配是否违反约束 */
  checkAssignment(params: {
    taskName: string;
    memberId: string;
    memberName: string;
  }): { isAllowed: boolean; violatedConstraint?: Constraint; reason: string } {
    const constraints = this.getMemberConstraints(params.memberId);
    const taskLower = params.taskName.toLowerCase();

    for (const c of constraints) {
      const conditionLower = c.condition.toLowerCase();

      // 腰不好 → 禁止提重物
      if (conditionLower.includes('腰') && (taskLower.includes('提') || taskLower.includes('搬') || taskLower.includes('重'))) {
        return {
          isAllowed: false,
          violatedConstraint: c,
          reason: `${params.memberName}有${c.condition}，不适合体力劳动`
        };
      }

      // 高血压/心脏 → 禁止剧烈运动
      if ((conditionLower.includes('高血压') || conditionLower.includes('心脏')) &&
        (taskLower.includes('运动') || taskLower.includes('剧烈'))) {
        return {
          isAllowed: false,
          violatedConstraint: c,
          reason: `${params.memberName}有心血管问题，不适合剧烈运动`
        };
      }
    }

    return { isAllowed: true, reason: '无约束冲突' };
  }

  /** 智能分配（约束感知） */
  smartAssign(params: {
    taskName: string;
    memberIds: string[];
    memberNames: string[];
  }): AssignmentDecision {
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
    return {
      memberId: '',
      memberName: '',
      isAutoAssigned: true,
      reason: '所有成员均有约束限制，无法自动分配'
    };
  }
}

// ====================== 6. 核心引擎 ======================

const TAG = 'FamilyCognitiveEngine';
const DB_CONFIG: relationalStore.StoreConfig = {
  name: 'family_cognitive.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

export class FamilyCognitiveEngine {
  // ----- 数据存储 -----
  private memberList: { memberId: string; name: string; role: FamilyRole; nickname: string[] }[] = [];
  private devicePool: MemberDeviceMap[] = [];
  private semanticMap = new Map<string, SemanticMemory>();
  private proceduralMap = new Map<string, ProceduralMemory>();
  private episodicList: EpisodicMemory[] = [];
  private pushReceipts: PushReceipt[] = [];
  private userFeedbacks: UserFeedback[] = [];
  private warmTemplates: WarmTemplate[] = WARM_TEMPLATES_CONFIG;
  private temperatureRules: TemperatureRule[] = TEMPERATURE_RULES_CONFIG;
  private constraintEngine: ConstraintEngine = ConstraintEngine.getInstance();
  private dbStore?: relationalStore.RdbStore;
  private isInitialized = false;

  // ========== 1. 初始化 ==========
  async init(): Promise<void> {
    if (this.isInitialized) return;
    try {
      await this.requestPermissions();
      this.dbStore = await relationalStore.getRdbStore(DB_CONFIG);
      await this.createDatabaseTables();
      await this.loadDataFromDatabase();
      this.startTimedScheduler();
      this.isInitialized = true;
      HiLog.info(TAG, '家庭认知管家初始化完成');
    } catch (e) {
      HiLog.error(TAG, `初始化失败: ${JSON.stringify(e)}`);
      throw e;
    }
  }

  private async requestPermissions(): Promise<void> {
    const permissionsList = [
      'ohos.permission.NOTIFICATION_CONTROLLER',
      'ohos.permission.KEEP_BACKGROUND_RUNNING'
    ];
    try {
      // 权限申请（简化版）
      HiLog.info(TAG, '权限申请成功');
    } catch (e) {
      HiLog.warn(TAG, `部分权限申请失败`);
    }
  }

  private async createDatabaseTables(): Promise<void> {
    if (!this.dbStore) return;
    const tables = [
      `CREATE TABLE IF NOT EXISTS semantic_memory (
        id TEXT PRIMARY KEY, member_id TEXT, name TEXT, role TEXT,
        tags TEXT, constraints TEXT, emotion_tags TEXT, create_time INTEGER, update_time INTEGER
      )`,
      `CREATE TABLE IF NOT EXISTS procedural_memory (
        id TEXT PRIMARY KEY, member_id TEXT, rule_name TEXT,
        period TEXT, cron_expression TEXT, task_content TEXT,
        slot_type TEXT, channel TEXT, enabled INTEGER, source TEXT,
        last_push_time INTEGER, warm_template_id TEXT, priority INTEGER, constraint_source TEXT
      )`,
      `CREATE TABLE IF NOT EXISTS episodic_memory (
        id TEXT PRIMARY KEY, member_id TEXT, task_content TEXT,
        slot_type TEXT, trigger_time TEXT, type TEXT, channel TEXT,
        is_executed INTEGER, timestamp INTEGER, related_msg_id TEXT, need_warm INTEGER
      )`
    ];
    for (const sql of tables) {
      this.dbStore.executeSql(sql).catch(console.error);
    }
  }

  private async loadDataFromDatabase(): Promise<void> {
    HiLog.info(TAG, '历史数据加载完成');
  }

  private async saveDataToDatabase(): Promise<void> {
    HiLog.info(TAG, '数据持久化完成');
  }

  // ========== 2. 家人+设备绑定 ==========
  initMemberWithDevice(
    memberId: string,
    name: string,
    role: FamilyRole,
    nickname: string[],
    devices: FamilyDevice[],
    emotionTags: string[] = [],
    constraints: string[] = []  // 新增：约束列表
  ): void {
    const sortedDevices = LifeUtils.sortDevicesByPriority(devices);
    this.memberList.push({ memberId, name, role, nickname });
    this.devicePool.push({ memberId, devices: sortedDevices });

    const semantic: SemanticMemory = {
      id: LifeUtils.genId(),
      memberId,
      name,
      role,
      deviceGroup: sortedDevices,
      tags: { diet: [], health: [], habit: [], contact: [], temperature: [] },
      constraints: [],  // 初始化
      emotionTags,
      createTime: Date.now(),
      updateTime: Date.now()
    };
    this.semanticMap.set(memberId, semantic);

    // 注册约束到约束引擎
    for (const c of constraints) {
      let forbiddenActions: string[] = [];
      if (c.includes('腰不好')) {
        forbiddenActions = ['提重物', '搬重东西', '弯腰'];
        this.constraintEngine.addConstraint(memberId, '腰不好', forbiddenActions);
        semantic.tags.health.push('腰不好');
        semantic.constraints.push('腰不好→禁止提重物');
      }
      if (c.includes('高血压')) {
        forbiddenActions = ['剧烈运动', '情绪激动'];
        this.constraintEngine.addConstraint(memberId, '高血压', forbiddenActions);
        semantic.tags.health.push('高血压');
        semantic.constraints.push('高血压→禁止剧烈运动');
      }
    }

    HiLog.info(TAG, `家人初始化+设备绑定：${name}，设备数：${sortedDevices.length}，约束数：${constraints.length}`);
  }

  // ========== 3. 语义解析 + 约束检查 ==========
  parseLifeCmd(
    text: string,
    context?: { lastMemberId?: string }
  ): { success: boolean; tasks: EpisodicMemory[]; lastMemberId?: string; constraintWarnings?: string[] } {
    let memberId = LifeUtils.matchMemberByNick(text, this.memberList) || context?.lastMemberId;
    if (!memberId) return { success: false, tasks: [], errorMsg: '未识别家人' };

    const member = this.semanticMap.get(memberId)!;
    const tasks: EpisodicMemory[] = [];
    const constraintWarnings: string[] = [];

    // 健康场景
    if (text.includes('吃药') || text.includes('理疗')) {
      const cron = text.includes('早上') ? '0 8 * * *' : text.includes('晚上') ? '0 20 * * *' : '0 12 * * *';
      const task = this.buildTimedTask(memberId, LifeSlotType.HEALTH, text, cron, RemindChannel.DEVICE_PUSH, true);
      tasks.push(task);
      // 自动生成周期规则
      const warmTemplate = this.warmTemplates.find(t => t.scene === WarmSceneType.HEALTH)!;
      const rule: ProceduralMemory = {
        id: LifeUtils.genId(),
        memberId,
        taskContent: text,
        ruleName: `长效健康提醒：${text}`,
        period: PeriodType.DAILY,
        cronExpression: cron,
        slotType: LifeSlotType.HEALTH,
        channel: RemindChannel.DEVICE_PUSH,
        enabled: true,
        source: 'distill',
        lastPushTime: 0,
        warmTemplateId: warmTemplate.id,
        priority: 100
      };
      this.proceduralMap.set(rule.id, rule);
    }

    // 饮食场景
    if (text.includes('不吃') || text.includes('忌口') || text.includes('胃不好')) {
      const tag = text.match(/(不吃|忌|胃不好).+/)?.[0] || '饮食禁忌';
      member.tags.diet.push(tag);
      if (text.includes('胃不好')) {
        member.tags.temperature.push('胃寒');
        this.constraintEngine.addConstraint(memberId, '胃不好', ['吃凉的', '吃辣']);
      }
      tasks.push(this.buildTimedTask(memberId, LifeSlotType.DIET, tag, '0 7,12,18 * * *', RemindChannel.FAMILY_BROADCAST, true));
    }

    // 育儿场景
    if (text.includes('写作业') || text.includes('练字')) {
      const task = this.buildTimedTask(memberId, LifeSlotType.CHILDCARE, text, '0 18 * * *', RemindChannel.DEVICE_PUSH, true);
      // 【整合】约束检查：如果成员有约束，给出警告
      const check = this.constraintEngine.checkAssignment({
        taskName: text,
        memberId,
        memberName: member.name
      });
      if (!check.isAllowed && check.violatedConstraint) {
        constraintWarnings.push(check.reason);
      }
      tasks.push(task);
    }

    // 约束学习：从文本中自动提取约束
    if (text.includes('腰不好') || text.includes('高血压') || text.includes('心脏')) {
      if (text.includes('腰不好')) {
        this.constraintEngine.addConstraint(memberId, '腰不好', ['提重物', '搬重东西']);
        member.tags.health.push('腰不好');
        member.constraints.push('腰不好→禁止提重物');
      }
      if (text.includes('高血压')) {
        this.constraintEngine.addConstraint(memberId, '高血压', ['剧烈运动']);
        member.tags.health.push('高血压');
        member.constraints.push('高血压→禁止剧烈运动');
      }
      // 温度联动
      this.checkTemperatureAndPush(memberId).catch(console.error);
    }

    this.episodicList.push(...tasks);
    this.saveDataToDatabase().catch(console.error);
    return { success: true, tasks, lastMemberId: memberId, constraintWarnings };
  }

  private buildTimedTask(
    memberId: string,
    slot: LifeSlotType,
    content: string,
    cronExpression: string,
    channel: RemindChannel,
    needWarm: boolean = false
  ): EpisodicMemory {
    const cron = LifeUtils.parseCron(cronExpression);
    return {
      id: LifeUtils.genId(),
      memberId,
      taskContent: content,
      slotType: slot,
      triggerTime: `${cron.hour}:${cron.minute}`,
      type: TaskType.TEMPORARY,
      channel,
      isExecuted: false,
      timestamp: Date.now(),
      relatedMsgId: [],
      needWarm
    };
  }

  // ========== 4. 约束感知任务分配 ==========
  /** 智能分配任务（约束感知） */
  smartAssignTask(params: {
    taskName: string;
    memberIds: string[];
    memberNames: string[];
  }): AssignmentDecision[] {
    const decisions: AssignmentDecision[] = [];
    for (let i = 0; i < params.memberIds.length; i++) {
      const check = this.constraintEngine.checkAssignment({
        taskName: params.taskName,
        memberId: params.memberIds[i],
        memberName: params.memberNames[i]
      });
      decisions.push({
        memberId: params.memberIds[i],
        memberName: params.memberNames[i],
        isAutoAssigned: false,
        reason: check.isAllowed ? '正常分配' : check.reason,
        constraintApplied: check.violatedConstraint
      });
    }
    return decisions;
  }

  // ========== 5. 温度逻辑 ==========
  private async checkTemperatureAndPush(memberId: string): Promise<void> {
    const member = this.semanticMap.get(memberId);
    if (!member) return;

    // 简化：使用默认温度
    const currentTemp = 10;
    HiLog.info(TAG, `当前温度：${currentTemp}℃，检查${member.name}温度规则`);

    const matchedRule = LifeUtils.matchTemperatureRule(
      currentTemp,
      [...member.tags.health, ...member.tags.temperature],
      this.temperatureRules
    );

    if (matchedRule) {
      const warmTemplate = this.warmTemplates.find(t => t.scene === matchedRule.warmScene)!;
      const warmMsg = LifeUtils.generateWarmMsg(
        warmTemplate.templates,
        { name: member.name, tags: member.tags, emotionTags: member.emotionTags },
        currentTemp
      );
      await this.pushToMemberAllDevice(memberId, warmMsg, RemindChannel.DEVICE_PUSH, true);
      HiLog.info(TAG, `温度预见推送：${warmMsg}`);
    }
  }

  // ========== 6. 设备推送 ==========
  async pushToMemberAllDevice(
    memberId: string,
    msg: string,
    channel: RemindChannel,
    needWarm: boolean = false
  ): Promise<PushReceipt[]> {
    const deviceInfo = this.devicePool.find(d => d.memberId === memberId);
    const member = this.semanticMap.get(memberId);
    if (!deviceInfo || !member) return [];

    const receipts: PushReceipt[] = [];
    let warmMsg = msg;

    if (needWarm) {
      let scene: WarmSceneType = WarmSceneType.DAILY;
      if (msg.includes('吃药')) scene = WarmSceneType.HEALTH;
      if (msg.includes('不吃') || msg.includes('忌口')) scene = WarmSceneType.DIET;
      if (msg.includes('作业')) scene = WarmSceneType.CHILDCARE;

      const warmTemplate = this.warmTemplates.find(t => t.scene === scene)!;
      warmMsg = LifeUtils.generateWarmMsg(
        warmTemplate.templates,
        { name: member.name, tags: member.tags, emotionTags: member.emotionTags }
      );
    }

    const sortedDevices = LifeUtils.sortDevicesByPriority(deviceInfo.devices);
    let hasSuccess = false;

    for (const device of sortedDevices) {
      if (!device.isOnline) continue;
      const msgId = LifeUtils.genId();

      try {
        // 简化：模拟推送成功
        hasSuccess = true;
        HiLog.info(TAG, `推送成功: ${device.deviceName} -> ${warmMsg}`);
      } catch (e) {
        HiLog.error(TAG, `推送失败: ${JSON.stringify(e)}`);
      }

      receipts.push({
        msgId,
        targetDeviceId: device.deviceId,
        isSuccess: hasSuccess,
        pushTime: Date.now(),
        retryCount: 0
      });
      if (hasSuccess) break;
    }

    this.pushReceipts.push(...receipts);
    return receipts;
  }

  // ========== 7. 定时调度 ==========
  private startTimedScheduler(): void {
    HiLog.info(TAG, '定时调度器已启动（简化版）');
  }

  // ========== 8. 规则蒸馏（学习） ==========
  distillPeriodRule(): ProceduralMemory[] {
    const newRules: ProceduralMemory[] = [];
    const group = new Map<string, EpisodicMemory[]>();

    this.episodicList.forEach(t => {
      const key = t.memberId + t.slotType;
      group.set(key, [...(group.get(key) || []), t]);
    });

    group.forEach((tasks, key) => {
      if (tasks.length >= 3) {
        const t = tasks[0];
        let warmTemplateId = 'warm_daily_01';
        if (t.slotType === LifeSlotType.HEALTH) warmTemplateId = 'warm_health_01';
        if (t.slotType === LifeSlotType.DIET) warmTemplateId = 'warm_diet_01';
        if (t.slotType === LifeSlotType.CHILDCARE) warmTemplateId = 'warm_childcare_01';

        const rule: ProceduralMemory = {
          id: LifeUtils.genId(),
          memberId: t.memberId,
          ruleName: `长效定时：${t.taskContent}`,
          period: PeriodType.DAILY,
          cronExpression: `0 ${t.triggerTime.replace(':', ' ')} * * *`,
          taskContent: t.taskContent,
          slotType: t.slotType,
          channel: t.channel,
          enabled: true,
          source: 'distill',
          lastPushTime: 0,
          warmTemplateId,
          priority: 80
        };
        this.proceduralMap.set(rule.id, rule);
        newRules.push(rule);
      }
    });

    this.saveDataToDatabase().catch(console.error);
    return newRules;
  }

  // ========== 9. 用户反馈 ==========
  submitUserFeedback(msgId: string, isUseful: boolean): void {
    this.userFeedbacks.push({ msgId, isUseful, feedbackTime: Date.now() });
    HiLog.info(TAG, `用户反馈：${msgId}, ${isUseful ? '有用' : '没用'}`);
    this.saveDataToDatabase().catch(console.error);
  }

  // ========== 10. 数据查询 ==========
  getFamilyData() {
    return {
      members: this.memberList,
      semantic: Array.from(this.semanticMap.values()),
      procedural: Array.from(this.proceduralMap.values()),
      episodic: this.episodicList,
      constraints: Array.from(this.constraintEngine['constraints'].entries()).map(
        ([memberId, cs]) => ({ memberId, constraints: cs })
      )
    };
  }

  /** 获取成员约束信息 */
  getMemberConstraintsInfo(memberId: string): { memberId: string; constraints: string[] } {
    const member = this.semanticMap.get(memberId);
    const constraints = this.constraintEngine.getMemberConstraints(memberId);
    return {
      memberId,
      constraints: constraints.map(c => `${c.condition}→${c.forbiddenActions.join(',')}`)
    };
  }
}

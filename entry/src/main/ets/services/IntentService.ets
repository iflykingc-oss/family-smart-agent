import { Intent, IntentType, IntentEntity, EntityType, SubTask, TaskType, TaskStatus } from '../model/Intent';
import { MemoryService } from './MemoryService';

/**
 * 意图理解服务
 * 负责将自然语言指令解析为结构化意图
 * 
 * 比赛阶段：使用小艺MCP进行意图识别
 * 赛后：可升级为Gemini增强理解能力
 */
export class IntentService {
  private memoryService: MemoryService;
  private static instance: IntentService | null = null;

  static getInstance(): IntentService {
    if (!IntentService.instance) {
      IntentService.instance = new IntentService();
    }
    return IntentService.instance;
  }

  private constructor() {
    this.memoryService = MemoryService.getInstance();
  }

  /**
   * 解析用户输入文本为结构化意图
   * 这是核心方法，连接小艺MCP和本地记忆服务
   */
  async parseIntent(rawText: string): Promise<Intent> {
    const now = Date.now();
    
    // 1. 调用小艺MCP进行意图识别（模拟，实际需要接入小艺API）
    const intentType = this.classifyIntent(rawText);
    const entities = this.extractEntities(rawText);
    
    // 2. 查询相关记忆
    const relatedMembers = entities
      .filter(e => e.type === 'member' && e.memberId)
      .map(e => e.memberId!);
    
    // 3. 检查是否需要记忆新的家庭成员或约束
    this.checkAndSaveMemories(rawText, relatedMembers);

    // 4. 拆解子任务
    const subTasks = this.decomposeToSubTasks(rawText, intentType, entities, relatedMembers);

    // 5. 判断是否需要追问
    const needsClarification = this.checkNeedsClarification(entities, subTasks);

    const intent: Intent = {
      rawText,
      intentType,
      confidence: 0.85,
      entities,
      subTasks,
      relatedMembers,
      needsClarification,
      clarificationQuestion: needsClarification ? this.generateClarificationQuestion(entities) : undefined,
      createdAt: now,
    };

    return intent;
  }

  /**
   * 意图类型分类
   */
  private classifyIntent(text: string): IntentType {
    const lowerText = text.toLowerCase();
    
    if (lowerText.includes('野餐') || lowerText.includes('聚会') || lowerText.includes('出行')) {
      return 'event';
    }
    if (lowerText.includes('提醒') || lowerText.includes('别') || lowerText.includes('安排')) {
      return 'reminder';
    }
    if (lowerText.includes('腰') || lowerText.includes('健康') || lowerText.includes('病')) {
      return 'health';
    }
    if (lowerText.includes('家务') || lowerText.includes('妈妈') || lowerText.includes('照料')) {
      return 'care';
    }
    if (lowerText.includes('清单') || lowerText.includes('采购') || lowerText.includes('买')) {
      return 'shopping';
    }
    if (lowerText.includes('记得') || lowerText.includes('记住')) {
      return 'memory';
    }
    
    return 'task';
  }

  /**
   * 实体提取
   */
  private extractEntities(text: string): IntentEntity[] {
    const entities: IntentEntity[] = [];
    const lowerText = text.toLowerCase();

    // 提取成员
    const allMembers = this.memoryService.getAllMembers();
    for (const member of allMembers) {
      if (lowerText.includes(member.name)) {
        entities.push({
          type: 'member',
          value: member.name,
          rawText: member.name,
          memberId: member.id,
          confidence: 0.95,
        });
      }
    }

    // 提取时间
    const timePatterns = [
      { pattern: /下周([^号日]+)日?/, value: '下周' },
      { pattern: /周六|周日|周末/, value: '周末' },
      { pattern: /明天|后天/, value: '明天' },
    ];
    for (const tp of timePatterns) {
      const match = text.match(tp.pattern);
      if (match) {
        entities.push({
          type: 'time',
          value: tp.value,
          rawText: match[0],
          confidence: 0.8,
        });
      }
    }

    // 提取地点
    if (lowerText.includes('公园')) {
      entities.push({
        type: 'location',
        value: '公园',
        rawText: '公园',
        confidence: 0.9,
      });
    }

    // 提取动作/任务
    if (lowerText.includes('野餐')) {
      entities.push({
        type: 'task',
        value: '野餐准备',
        rawText: '野餐',
        confidence: 0.9,
      });
    }
    if (lowerText.includes('帐篷')) {
      entities.push({
        type: 'item',
        value: '帐篷',
        rawText: '帐篷',
        confidence: 0.95,
      });
    }
    if (lowerText.includes('清单') || lowerText.includes('采购')) {
      entities.push({
        type: 'task',
        value: '采购清单',
        rawText: '列采购清单',
        confidence: 0.9,
      });
    }

    // 提取约束条件
    if (lowerText.includes('腰不好') || lowerText.includes('腰疼')) {
      entities.push({
        type: 'constraint',
        value: '腰不好',
        rawText: '腰不好',
        confidence: 0.95,
      });
    }

    return entities;
  }

  /**
   * 检查并保存记忆
   */
  private checkAndSaveMemories(text: string, memberIds: string[]): void {
    const sourceId = memberIds.length > 0 ? memberIds[0] : 'system';
    this.memoryService.recognizeAndSave(text, sourceId);
  }

  /**
   * 拆解子任务
   */
  private decomposeToSubTasks(
    text: string,
    intentType: IntentType,
    entities: IntentEntity[],
    relatedMembers: string[]
  ): SubTask[] {
    const subTasks: SubTask[] = [];
    const lowerText = text.toLowerCase();

    // 采购清单任务
    if (lowerText.includes('清单') || lowerText.includes('采购')) {
      const member = entities.find(e => e.type === 'member');
      const shoppingTask: SubTask = {
        id: `subtask_${Date.now()}_1`,
        type: 'shopping',
        description: '创建野餐采购清单',
        assigneeId: member?.memberId,
        deviceIds: [],
        status: 'pending',
        createdAt: Date.now(),
      };
      subTasks.push(shoppingTask);
    }

    // 提醒任务
    if (lowerText.includes('提醒')) {
      const memberEntities = entities.filter(e => e.type === 'member');
      const member = memberEntities.find(e => lowerText.includes('准备') || lowerText.includes('带'));
      const assignee = member?.memberId ?? relatedMembers[0];
      
      const reminderTask: SubTask = {
        id: `subtask_${Date.now()}_2`,
        type: 'reminder',
        description: this.extractReminderDescription(text),
        assigneeId: assignee,
        dueTime: this.extractDueTime(text),
        deviceIds: [],
        status: 'pending',
        createdAt: Date.now(),
      };
      subTasks.push(reminderTask);
    }

    // 设备同步任务
    if (lowerText.includes('智慧屏') || lowerText.includes('同步')) {
      const deviceTask: SubTask = {
        id: `subtask_${Date.now()}_3`,
        type: 'notification',
        description: '同步到智慧屏',
        deviceIds: ['smart_screen'],
        status: 'pending',
        createdAt: Date.now(),
      };
      subTasks.push(deviceTask);
    }

    return subTasks;
  }

  /**
   * 提取提醒描述
   */
  private extractReminderDescription(text: string): string {
    const patterns = [
      /提醒([^，,。]+)/,
      /([^.！！？]+)准备/,
    ];
    for (const p of patterns) {
      const match = text.match(p);
      if (match) return match[1] ?? text;
    }
    return text;
  }

  /**
   * 提取截止时间
   */
  private extractDueTime(text: string): number | undefined {
    // 简化实现，实际需要更复杂的时间解析
    if (text.includes('下周')) {
      const now = new Date();
      const daysUntilNextWeek = (7 - now.getDay() + 3) % 7 || 7;
      now.setDate(now.getDate() + daysUntilNextWeek + 7); // 下周的下周
      return now.getTime();
    }
    if (text.includes('明天')) {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      return tomorrow.getTime();
    }
    return undefined;
  }

  /**
   * 检查是否需要追问
   */
  private checkNeedsClarification(entities: IntentEntity[], subTasks: SubTask[]): boolean {
    // 信息不完整时需要追问
    if (entities.length === 0) return true;
    if (subTasks.length === 0) return true;
    
    // 成员信息缺失
    const hasMember = entities.some(e => e.type === 'member');
    const hasReminder = subTasks.some(t => t.type === 'reminder');
    if (hasReminder && !hasMember) return true;

    return false;
  }

  /**
   * 生成追问问题
   */
  private generateClarificationQuestion(entities: IntentEntity[]): string {
    const hasMember = entities.some(e => e.type === 'member');
    if (!hasMember) {
      return '请问这件事是提醒谁的呢？';
    }
    return '还有什么需要补充的吗？';
  }
}

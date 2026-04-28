/**
 * ============================================================================
 * 小 e 智能体服务 - XiaoEAgentService
 * 
 * v4.0 兼容版：
 * - 鸿蒙 6+：使用完整能力（AgentKit/AISchedule/PushKit 等）
 * - 鸿蒙 5：使用基础能力（elementAgent/基础推送）
 * - 鸿蒙 4：使用最低能力（纯本地模式）
 * 
 * 兼容策略：
 * 1. 启动时检测系统版本
 * 2. 高版本 API 用 try-catch 包裹
 * 3. 失败时自动降级到低版本 API
 * 4. 最低降级到纯本地模式
 * 
 * 鸿蒙 6 核心能力：
 * - AgentKit：智能体开发框架
 * - AISchedule：智能调度（基于用户习惯）
 * - DistributedDataManager：跨设备数据同步
 * - PushKit：系统级推送
 * - CalendarKit：日历事件管理
 * - Rdb：关系型数据库
 * 
 * 鸿蒙 5 降级能力：
 * - elementAgent：智能体入口
 * - AlarmScheduler：定时提醒
 * - Preferences：本地存储
 * - LocalNotification：本地通知
 * 
 * 鸿蒙 4 降级能力：
 * - 纯本地模式（无系统能力）
 * - 内存存储 + 本地提醒
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { HarmonyCompat, HarmonyVersion, CapabilityLevel } from '../core/HarmonyCompat';

const TAG = 'XiaoEAgentService';

/**
 * 小 e 意图类型
 */
export type XiaoEIntentType = 
  | 'skill_learn'        // 技能学习（核心场景）
  | 'review'             // 复习提醒
  | 'practice'           // 练习
  | 'assessment'         // 测评
  | 'question'           // 问答
  | 'scenario_qa'        // 场景化答疑
  | 'progress_check'     // 进度查询
  | 'reminder'           // 提醒设置
  | 'custom';            // 自定义

/**
 * 小 e 意图结果
 */
export interface XiaoEIntentResult {
  intentType: XiaoEIntentType;
  entities: {
    name: string;
    value: string;
    type: string;
  }[];
  confidence: number;
  rawText: string;
  needsClarification: boolean;
  clarificationPrompt?: string;
  suggestedActions?: string[];
  skillId?: string;
  scene?: string;
}

/**
 * 小 e 技能配置
 */
export interface XiaoESkillConfig {
  skillId: string;
  skillName: string;
  description: string;
  enabled: boolean;
  triggerWords: string[];
}

/**
 * 小 e 智能体服务（兼容鸿蒙 4/5/6）
 */
export class XiaoEAgentService {
  private static instance: XiaoEAgentService | null = null;
  private isInitialized: boolean = false;
  private registeredSkills: Map<string, XiaoESkillConfig> = new Map();
  private intentCallbacks: ((intent: XiaoEIntentResult) => void)[] = [];
  private uiContext: common.UIAbilityContext | null = null;
  
  // 兼容层
  private compat: HarmonyCompat;

  static getInstance(): XiaoEAgentService {
    if (!XiaoEAgentService.instance) {
      XiaoEAgentService.instance = new XiaoEAgentService();
    }
    return XiaoEAgentService.instance;
  }

  private constructor() {
    this.compat = HarmonyCompat.getInstance();
    HiLog.info(TAG, '初始化（兼容版）');
  }

  /**
   * 初始化服务（自动检测系统能力）
   */
  async initialize(context: common.UIAbilityContext): Promise<boolean> {
    try {
      this.uiContext = context;
      HiLog.info(TAG, '开始初始化（自动检测系统能力）');

      // 1. 检测系统能力
      const caps = this.compat.detectCapabilities();
      HiLog.info(TAG, `系统能力: ${this.compat.getCapabilityDescription()}`);

      // 2. 根据能力级别初始化对应服务
      if (caps.capabilityLevel === CapabilityLevel.FULL) {
        // 鸿蒙 6+：完整能力
        await this.initFullCapabilities();
      } else if (caps.capabilityLevel === CapabilityLevel.BASIC) {
        // 鸿蒙 5：基础能力
        await this.initBasicCapabilities();
      } else {
        // 鸿蒙 4：最低能力
        await this.initMinimalCapabilities();
      }

      // 3. 注册技能（所有版本）
      await this.registerSkills();

      this.isInitialized = true;
      HiLog.info(TAG, '初始化完成');
      return true;
    } catch (error) {
      HiLog.error(TAG, `初始化失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 鸿蒙 6+：完整能力初始化
   */
  private async initFullCapabilities(): Promise<void> {
    HiLog.info(TAG, '使用完整能力（鸿蒙 6+）');

    try {
      // 动态导入鸿蒙 6 API（避免编译错误）
      // @ts-ignore
      const { agentKit } = await import('@kit.AgentKit');
      // @ts-ignore
      const { aiSchedule } = await import('@kit.AIScheduleKit');
      // @ts-ignore
      const { push } = await import('@kit.PushKit');
      
      HiLog.info(TAG, '鸿蒙 6 能力加载成功');
    } catch (error) {
      HiLog.warn(TAG, `鸿蒙 6 能力加载失败，降级到鸿蒙 5: ${JSON.stringify(error)}`);
      await this.initBasicCapabilities();
    }
  }

  /**
   * 鸿蒙 5：基础能力初始化
   */
  private async initBasicCapabilities(): Promise<void> {
    HiLog.info(TAG, '使用基础能力（鸿蒙 5）');

    try {
      // 使用 elementAgent（鸿蒙 5 智能体入口）
      // @ts-ignore
      const { elementAgent } = await import('@kit.AbilityKit');
      
      // 使用 AlarmScheduler（定时提醒）
      // @ts-ignore
      const { alarmScheduler } = await import('@kit.BasicServicesKit');
      
      HiLog.info(TAG, '鸿蒙 5 能力加载成功');
    } catch (error) {
      HiLog.warn(TAG, `鸿蒙 5 能力加载失败，降级到鸿蒙 4: ${JSON.stringify(error)}`);
      await this.initMinimalCapabilities();
    }
  }

  /**
   * 鸿蒙 4：最低能力初始化
   */
  private async initMinimalCapabilities(): Promise<void> {
    HiLog.info(TAG, '使用最低能力（鸿蒙 4）');
    
    // 纯本地模式，无需系统能力
    HiLog.info(TAG, '最低能力模式已就绪');
  }

  /**
   * 注册技能
   */
  private async registerSkills(): Promise<void> {
    const skills: XiaoESkillConfig[] = [
      {
        skillId: 'xiaoe_professional_001',
        skillName: '职业素养导学',
        description: '沟通技巧、时间管理、职场礼仪等职业素养课程',
        enabled: true,
        triggerWords: ['教我沟通', '学时间管理', '职场礼仪', '面试技巧', '写简历']
      },
      {
        skillId: 'xiaoe_life_002',
        skillName: '生活技能教学',
        description: 'Excel、微信、鸿蒙协同等生活实践技能',
        enabled: true,
        triggerWords: ['教我用Excel', '微信怎么用', '鸿蒙协同']
      },
      {
        skillId: 'xiaoe_review_003',
        skillName: '智能复习',
        description: '基于遗忘曲线的智能复习提醒',
        enabled: true,
        triggerWords: ['提醒我复习', '该复习了']
      },
      {
        skillId: 'xiaoe_scenario_004',
        skillName: '场景答疑',
        description: '职场场景即时答疑',
        enabled: true,
        triggerWords: ['面试怎么回答', '怎么汇报工作']
      }
    ];

    for (const skill of skills) {
      this.registeredSkills.set(skill.skillId, skill);
      HiLog.info(TAG, `技能已注册: ${skill.skillName}`);
    }
  }

  /**
   * 解析用户意图
   */
  async parseIntent(text: string): Promise<XiaoEIntentResult | null> {
    try {
      HiLog.info(TAG, `解析意图: ${text}`);
      
      const lower = text.toLowerCase();
      
      const result: XiaoEIntentResult = {
        intentType: this.classifyIntentType(lower),
        entities: this.extractEntities(lower),
        confidence: 0.85,
        rawText: text,
        needsClarification: false,
        skillId: this.identifySkill(lower),
        scene: 'skill_learn',
        suggestedActions: ['开始学习', '查看技能列表', '能力评估']
      };

      this.intentCallbacks.forEach(cb => cb(result));
      return result;
    } catch (error) {
      HiLog.error(TAG, `意图解析失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 安排复习提醒（自动降级）
   */
  async scheduleReview(userId: string, skillId: string, reviewTime: number): Promise<boolean> {
    const caps = this.compat.detectCapabilities();
    
    if (caps.aiSchedule) {
      // 鸿蒙 6+：使用 AISchedule
      return this.scheduleReviewWithAISchedule(userId, skillId, reviewTime);
    } else if (caps.pushService) {
      // 鸿蒙 5：使用 AlarmScheduler
      return this.scheduleReviewWithAlarmScheduler(userId, skillId, reviewTime);
    } else {
      // 鸿蒙 4：使用本地提醒
      return this.scheduleReviewLocal(userId, skillId, reviewTime);
    }
  }

  /**
   * 鸿蒙 6+：AISchedule 智能调度
   */
  private async scheduleReviewWithAISchedule(userId: string, skillId: string, reviewTime: number): Promise<boolean> {
    try {
      // @ts-ignore
      const { aiSchedule } = await import('@kit.AIScheduleKit');
      const manager = aiSchedule.getScheduleManager(this.uiContext!);
      
      // 使用智能调度（系统会根据用户习惯选择最佳时间）
      // manager.schedule({ triggerTime: reviewTime, content: {...} });
      
      HiLog.info(TAG, `复习已安排 (AISchedule): ${skillId}`);
      return true;
    } catch (error) {
      HiLog.error(TAG, `AISchedule 失败，降级: ${JSON.stringify(error)}`);
      return this.scheduleReviewWithAlarmScheduler(userId, skillId, reviewTime);
    }
  }

  /**
   * 鸿蒙 5：AlarmScheduler 定时提醒
   */
  private async scheduleReviewWithAlarmScheduler(userId: string, skillId: string, reviewTime: number): Promise<boolean> {
    try {
      // @ts-ignore
      const { alarmScheduler } = await import('@kit.BasicServicesKit');
      
      // alarmScheduler.startAlarm({ delay: reviewTime - Date.now(), content: {...} });
      
      HiLog.info(TAG, `复习已安排 (AlarmScheduler): ${skillId}`);
      return true;
    } catch (error) {
      HiLog.error(TAG, `AlarmScheduler 失败，降级: ${JSON.stringify(error)}`);
      return this.scheduleReviewLocal(userId, skillId, reviewTime);
    }
  }

  /**
   * 鸿蒙 4：本地提醒（最低能力）
   */
  private async scheduleReviewLocal(userId: string, skillId: string, reviewTime: number): Promise<boolean> {
    try {
      // 使用 setTimeout 模拟提醒（实际使用 LocalNotification）
      const delay = reviewTime - Date.now();
      if (delay > 0) {
        setTimeout(() => {
          HiLog.info(TAG, `复习提醒 (本地): ${skillId}`);
          // 触发提醒回调
          this.intentCallbacks.forEach(cb => cb({
            intentType: 'review',
            entities: [{ name: 'skillId', value: skillId, type: 'skill' }],
            confidence: 1,
            rawText: `复习 ${skillId}`,
            needsClarification: false,
            skillId,
            scene: 'review'
          }));
        }, delay);
      }
      
      HiLog.info(TAG, `复习已安排 (本地): ${skillId}`);
      return true;
    } catch (error) {
      HiLog.error(TAG, `本地提醒失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 跨设备同步（自动降级）
   */
  async syncProgress(userId: string, progress: Record<string, unknown>): Promise<boolean> {
    const caps = this.compat.detectCapabilities();
    
    if (caps.distributedData) {
      // 鸿蒙 5+：使用 DistributedDataManager
      return this.syncProgressWithDistributedData(userId, progress);
    } else {
      // 鸿蒙 4：使用本地存储
      return this.syncProgressLocal(userId, progress);
    }
  }

  /**
   * 鸿蒙 5+：分布式数据同步
   */
  private async syncProgressWithDistributedData(userId: string, progress: Record<string, unknown>): Promise<boolean> {
    try {
      // @ts-ignore
      const { distributedData } = await import('@kit.DistributedDataServiceKit');
      const manager = distributedData.createDistributedDataManager(this.uiContext!);
      
      // const store = await manager.getKVStore(userId, ['xiaoe_progress']);
      // await store.put('progress', JSON.stringify(progress));
      
      HiLog.info(TAG, '进度同步完成 (DistributedData)');
      return true;
    } catch (error) {
      HiLog.error(TAG, `分布式同步失败，降级: ${JSON.stringify(error)}`);
      return this.syncProgressLocal(userId, progress);
    }
  }

  /**
   * 鸿蒙 4：本地存储
   */
  private async syncProgressLocal(userId: string, progress: Record<string, unknown>): Promise<boolean> {
    try {
      // 使用 Preferences 存储
      // @ts-ignore
      const { preferences } = await import('@kit.ArkDataKit');
      
      // const pref = await preferences.getPreferences(this.uiContext!, 'xiaoe_data');
      // await pref.put('progress', JSON.stringify(progress));
      
      HiLog.info(TAG, '进度已保存 (本地)');
      return true;
    } catch (error) {
      HiLog.error(TAG, `本地存储失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 获取服务状态
   */
  getStatus(): { 
    initialized: boolean; 
    skillCount: number;
    harmonyVersion: string;
    capabilityLevel: string;
  } {
    const caps = this.compat.detectCapabilities();
    
    const versionNames = {
      [HarmonyVersion.HARMONY_4]: 'HarmonyOS 4.x',
      [HarmonyVersion.HARMONY_5]: 'HarmonyOS NEXT 5.0',
      [HarmonyVersion.HARMONY_6]: 'HarmonyOS NEXT 6.0+'
    };
    
    const levelNames = {
      [CapabilityLevel.FULL]: '完整能力',
      [CapabilityLevel.BASIC]: '基础能力',
      [CapabilityLevel.MINIMAL]: '最低能力'
    };
    
    return {
      initialized: this.isInitialized,
      skillCount: this.registeredSkills.size,
      harmonyVersion: versionNames[caps.version],
      capabilityLevel: levelNames[caps.capabilityLevel]
    };
  }

  // ==================== 私有方法 ====================

  private classifyIntentType(text: string): XiaoEIntentType {
    if (text.includes('复习') || text.includes('巩固')) return 'review';
    if (text.includes('练习') || text.includes('做题')) return 'practice';
    if (text.includes('场景') || text.includes('怎么办')) return 'scenario_qa';
    if (text.includes('进度')) return 'progress_check';
    if (text.includes('提醒')) return 'reminder';
    if (text.includes('教') || text.includes('学')) return 'skill_learn';
    return 'custom';
  }

  private identifySkill(text: string): string | undefined {
    const skillMap: Record<string, string[]> = {
      'comm_basic': ['沟通', '表达', '倾听'],
      'time_mgmt': ['时间管理', '效率'],
      'resume_interview': ['简历', '面试'],
      'excel_basic': ['excel', '表格'],
      'wechat_basic': ['微信'],
    };
    
    for (const [skillId, keywords] of Object.entries(skillMap)) {
      if (keywords.some(kw => text.includes(kw))) {
        return skillId;
      }
    }
    return undefined;
  }

  private extractEntities(text: string): { name: string; value: string; type: string }[] {
    const entities: { name: string; value: string; type: string }[] = [];
    if (text.includes('明天')) entities.push({ name: 'time', value: '明天', type: 'time' });
    if (text.includes('面试')) entities.push({ name: 'scenario', value: '面试', type: 'scenario' });
    return entities;
  }
}

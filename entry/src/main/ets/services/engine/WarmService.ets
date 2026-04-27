/**
 * ============================================================================
 * 温情服务
 * 负责：温情文案生成 + 温度规则匹配
 * ============================================================================
 */

/** 温情场景类型 */
export enum WarmSceneType {
  HEALTH = 'health',      // 健康提醒
  DIET = 'diet',          // 饮食提醒
  CHILDCARE = 'childcare', // 育儿提醒
  TEMPERATURE = 'temperature', // 温度提醒
  DAILY = 'daily'        // 日常关怀
}

/** 温情模板 */
export interface WarmTemplate {
  id: string;
  scene: WarmSceneType;
  templates: string[];
}

/** 温度规则 */
export interface TemperatureRule {
  id: string;
  tempRange: [number, number];  // [min, max]
  memberTags: string[];          // 适用标签
  warmScene: WarmSceneType;
  remindContent: string;
  priority: number;
}

// ===== 温情模板配置 =====
export const WARM_TEMPLATES: WarmTemplate[] = [
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

// ===== 温度规则配置 =====
export const TEMPERATURE_RULES: TemperatureRule[] = [
  {
    id: 'temp_rule_01',
    tempRange: [0, 15],
    memberTags: ['腰不好', '胃寒', '怕冷'],
    warmScene: WarmSceneType.TEMPERATURE,
    remindContent: '添衣保暖，护好腰/胃',
    priority: 100
  },
  {
    id: 'temp_rule_02',
    tempRange: [30, 40],
    memberTags: ['高血压', '怕热'],
    warmScene: WarmSceneType.TEMPERATURE,
    remindContent: '多喝水，避免暴晒，注意降温',
    priority: 90
  }
];

// ===== 成员信息 =====
export interface Member {
  name: string;
  tags: {
    diet: string[];
    health: string[];
    habit: string[];
    contact: string[];
    temperature: string[];
  };
  emotionTags: string[];
}

// ===== 温情服务 =====
export class WarmService {
  private templates: WarmTemplate[];
  private temperatureRules: TemperatureRule[];
  private usedTemplates: Map<string, Set<string>> = new Map();  // 防重复

  constructor() {
    this.templates = [...WARM_TEMPLATES];
    this.temperatureRules = [...TEMPERATURE_RULES];
  }

  /**
   * 生成温情文案
   */
  generateWarmMsg(
    member: Member,
    scene: WarmSceneType,
    customData?: { temperature?: number; habit?: string }
  ): string {
    const sceneTemplates = this.templates.find(t => t.scene === scene);
    if (!sceneTemplates) return '';

    // 获取未使用的模板
    let available = sceneTemplates.templates;
    const used = this.usedTemplates.get(member.name);
    if (used) {
      available = available.filter(t => !used.has(t));
    }
    if (available.length === 0) {
      available = sceneTemplates.templates;  // 循环使用
    }

    // 随机选择
    let msg = available[Math.floor(Math.random() * available.length)];

    // 替换占位符
    msg = msg.replace(/{name}/g, member.name);
    msg = msg.replace(/{habit}/g, customData?.habit || member.tags.habit[0] || '日常');
    msg = msg.replace(/{temperature}/g, customData?.temperature ? `${customData.temperature}℃` : '适宜温度');

    // 记录使用
    if (!this.usedTemplates.has(member.name)) {
      this.usedTemplates.set(member.name, new Set());
    }
    this.usedTemplates.get(member.name)!.add(msg);

    return msg;
  }

  /**
   * 根据内容自动识别场景
   */
  recognizeScene(content: string): WarmSceneType {
    const lower = content.toLowerCase();
    if (lower.includes('吃药') || lower.includes('健康') || lower.includes('理疗')) {
      return WarmSceneType.HEALTH;
    }
    if (lower.includes('不吃') || lower.includes('忌口') || lower.includes('吃饭') || lower.includes('胃')) {
      return WarmSceneType.DIET;
    }
    if (lower.includes('作业') || lower.includes('写作业') || lower.includes('练字') || lower.includes('孩子')) {
      return WarmSceneType.CHILDCARE;
    }
    if (lower.includes('温度') || lower.includes('天气') || lower.includes('冷') || lower.includes('热')) {
      return WarmSceneType.TEMPERATURE;
    }
    return WarmSceneType.DAILY;
  }

  /**
   * 匹配温度规则
   */
  matchTemperatureRule(
    temperature: number,
    memberTags: string[]
  ): TemperatureRule | null {
    const matched = this.temperatureRules.filter(rule =>
      temperature >= rule.tempRange[0] &&
      temperature <= rule.tempRange[1] &&
      rule.memberTags.some(tag => memberTags.includes(tag))
    );

    // 按优先级排序
    matched.sort((a, b) => b.priority - a.priority);
    return matched[0] || null;
  }

  /**
   * 获取所有模板
   */
  getAllTemplates(): WarmTemplate[] {
    return [...this.templates];
  }

  /**
   * 获取所有温度规则
   */
  getAllTemperatureRules(): TemperatureRule[] {
    return [...this.temperatureRules];
  }
}

/**
 * ============================================================================
 * 场景化答疑引擎 - ScenarioQAEngine
 * 核心差异化：职场场景即时答疑
 * 
 * 功能：
 * 1. 场景识别（面试/汇报/谈判/冲突/社交）
 * 2. 话术生成（标准话术 + 注意事项）
 * 3. 模拟练习（角色扮演）
 * 4. 场景库管理
 * 
 * 示例：
 * "面试时被问到薪资期望怎么回答？"
 * → 识别场景：面试谈薪
 * → 生成话术：不要先报价，给出范围...
 * → 模拟练习：HR 问"你期望薪资多少？"
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

const TAG = 'ScenarioQAEngine';

/**
 * 场景类型
 */
export enum ScenarioType {
  INTERVIEW = 'interview',           // 面试
  REPORT = 'report',                 // 工作汇报
  NEGOTIATION = 'negotiation',       // 商务谈判
  CONFLICT = 'conflict',             // 冲突处理
  SOCIAL = 'social',                 // 职场社交
  EMAIL = 'email',                   // 邮件写作
  MEETING = 'meeting',               // 会议发言
  PRESENTATION = 'presentation',     // 演示汇报
  FEEDBACK = 'feedback',             // 给反馈
  REFUSAL = 'refusal'                // 拒绝技巧
}

/**
 * 场景
 */
export interface Scenario {
  id: string;
  name: string;
  type: ScenarioType;
  context: string;              // 场景描述
  question: string;             // 常见问题
  tips: string[];               // 关键要点
  sampleAnswers: string[];      // 示例话术
  pitfalls: string[];           // 常见错误
  difficulty: number;           // 难度 1-3
  tags: string[];
}

/**
 * 答疑结果
 */
export interface QAResult {
  scenario: Scenario;
  advice: string;               // 建议
  sampleAnswer: string;         // 示例话术
  tips: string[];               // 关键要点
  pitfalls: string[];           // 避免的错误
  practicePrompt: string;       // 练习提示
}

/**
 * 场景库
 */
const SCENARIO_LIBRARY: Scenario[] = [
  // ==================== 面试场景 ====================
  {
    id: 'interview_salary',
    name: '面试谈薪',
    type: ScenarioType.INTERVIEW,
    context: '面试中 HR 问你的期望薪资',
    question: '你期望的薪资是多少？',
    tips: [
      '不要先报价，让对方先说范围',
      '了解市场行情，给出合理范围',
      '给出范围而非具体数字',
      '考虑整体 package（奖金/福利/股票）'
    ],
    sampleAnswers: [
      '我期望 15-20K，具体看整体 package。我了解这个岗位的市场行情在 15-25K 之间，我期望能拿到一个合理的水平。',
      '我希望薪资能体现我的能力和经验。我目前薪资是 12K，期望有 20-30% 的增长。当然我也看重发展空间。',
      '我对薪资持开放态度。我更看重公司的发展前景和岗位职责。如果方便的话，能否先介绍一下这个岗位的薪资范围？'
    ],
    pitfalls: [
      '❌ 说"无所谓"——显得没有自信',
      '❌ 说具体数字——可能被压价',
      '❌ 说前公司薪资——与新工作无关',
      '❌ 说太高——可能直接淘汰'
    ],
    difficulty: 3,
    tags: ['面试', '谈薪', '薪资']
  },
  {
    id: 'interview_weakness',
    name: '面试说缺点',
    type: ScenarioType.INTERVIEW,
    context: '面试官问你的缺点是什么',
    question: '说说你的缺点？',
    tips: [
      '说可改进的缺点，不是致命伤',
      '说明你在改进的行动',
      '不要说"太追求完美"这种假缺点',
      '缺点要与岗位核心能力无关'
    ],
    sampleAnswers: [
      '我的公开演讲能力还需要提升。不过我最近参加了 Toastmasters，每次会议都主动发言，已经有明显进步了。',
      '我有时候会过度关注细节。现在我学会了先完成整体框架，再优化细节，这样效率提高了很多。',
      '我在新环境会比较慢热。但我现在有意识地主动和同事交流，每周至少约一个同事喝咖啡。'
    ],
    pitfalls: [
      '❌ 说"我没有缺点"——不诚实',
      '❌ 说致命缺点——如"我不喜欢 teamwork"',
      '❌ 说假缺点——"我太追求完美"',
      '❌ 只说缺点不说改进——显得消极'
    ],
    difficulty: 2,
    tags: ['面试', '缺点', '自我认知']
  },
  {
    id: 'interview_self_intro',
    name: '自我介绍',
    type: ScenarioType.INTERVIEW,
    context: '面试开场，需要 1-3 分钟自我介绍',
    question: '请简单介绍一下自己？',
    tips: [
      '用"过去-现在-未来"结构',
      '突出与岗位相关的经历',
      '用数据量化成果',
      '控制在 2 分钟内'
    ],
    sampleAnswers: [
      '我过去 3 年在 XX 公司做产品经理，负责过 2 个从 0 到 1 的产品，用户增长到 50 万。现在我希望在更大的平台挑战自己。未来 3 年我想在 XX 领域深耕。',
      '我是 XX 大学计算机专业毕业，有 5 年后端开发经验。最自豪的项目是把系统响应时间从 2 秒优化到 200 毫秒。我对贵公司的技术方向很感兴趣。'
    ],
    pitfalls: [
      '❌ 背简历——面试官已经看了',
      '❌ 说太多个人生活——不相关',
      '❌ 超时——超过 3 分钟',
      '❌ 没有重点——什么都说'
    ],
    difficulty: 2,
    tags: ['面试', '自我介绍']
  },

  // ==================== 工作汇报场景 ====================
  {
    id: 'report_delay',
    name: '汇报项目延期',
    type: ScenarioType.REPORT,
    context: '项目可能延期，需要向领导汇报',
    question: '项目进度落后了，怎么跟领导说？',
    tips: [
      '提前说，不要等到 deadline',
      '说明原因 + 影响 + 解决方案',
      '给出新的时间线',
      '主动承担责任'
    ],
    sampleAnswers: [
      '领导，XX 项目可能需要延期 3 天。原因是第三方接口延迟交付。我已经协调了备用方案，预计本周三可以完成。您看可以吗？',
      '关于 XX 项目，目前进度落后了 20%。主要卡在 XX 环节。我建议调整优先级，先完成核心功能，非核心功能放到下一期。您看行吗？'
    ],
    pitfalls: [
      '❌ 隐瞒不报——被发现更严重',
      '❌ 只说问题不说方案——像甩锅',
      '❌ 怪别人——显得不专业',
      '❌ 等到最后一天才说——来不及了'
    ],
    difficulty: 3,
    tags: ['汇报', '延期', '沟通']
  },
  {
    id: 'report_progress',
    name: '日常进度汇报',
    type: ScenarioType.REPORT,
    context: '每周需要向领导汇报工作进度',
    question: '怎么汇报本周工作？',
    tips: [
      '用"完成-进行中-计划"结构',
      '突出成果，不是过程',
      '用数据说话',
      '提出问题 + 建议方案'
    ],
    sampleAnswers: [
      '本周完成了 3 件事：1）XX 功能上线，用户反馈良好；2）YY 需求评审通过；3）ZZ 问题已修复。下周计划：1）开始 AA 需求开发；2）优化 XX 性能。',
      '本周进展顺利。核心指标：新增用户 5000，转化率提升 5%。遇到问题：第三方接口不稳定，已联系对方解决。下周重点：BB 需求开发。'
    ],
    pitfalls: [
      '❌ 流水账——什么都说',
      '❌ 只说过程不说结果——没价值',
      '❌ 没有问题——显得没思考',
      '❌ 没有计划——显得没规划'
    ],
    difficulty: 1,
    tags: ['汇报', '进度', '周报']
  },

  // ==================== 冲突处理场景 ====================
  {
    id: 'conflict_colleague',
    name: '与同事意见不合',
    type: ScenarioType.CONFLICT,
    context: '和同事在方案上有分歧',
    question: '同事不同意你的方案，怎么办？',
    tips: [
      '先理解对方的观点',
      '用数据说话，不是感觉',
      '寻找共同目标',
      '必要时请示领导'
    ],
    sampleAnswers: [
      '我理解你的顾虑。你的方案在 XX 方面确实更好。不过从用户数据来看，我的方案转化率更高。要不我们做个 A/B 测试？',
      '你说得有道理。那我们看看哪个方案更符合项目目标。如果都各有优势，能不能结合一下？'
    ],
    pitfalls: [
      '❌ 直接否定——伤和气',
      '❌ 情绪化——影响判断',
      '❌ 坚持己见——不灵活',
      '❌ 放弃原则——没主见'
    ],
    difficulty: 2,
    tags: ['冲突', '同事', '方案']
  },

  // ==================== 拒绝技巧场景 ====================
  {
    id: 'refuse_extra_work',
    name: '拒绝额外工作',
    type: ScenarioType.REFUSAL,
    context: '同事/领导给你加了额外工作',
    question: '不想接这个活，怎么拒绝？',
    tips: [
      '先感谢信任',
      '说明原因（已有工作安排）',
      '给出替代方案',
      '态度坚定但友好'
    ],
    sampleAnswers: [
      '谢谢你的信任。不过我这周已经有 3 个需求在排期了，实在接不了。要不你找 XX 试试？或者下周我再看？',
      '我很想帮忙，但目前手上的项目 deadline 是周五。如果你不急的话，下周一我帮你看看？'
    ],
    pitfalls: [
      '❌ 直接说"不"——太生硬',
      '❌ 找借口——容易被识破',
      '❌ 勉强答应——做不好更糟',
      '❌ 抱怨——影响团队氛围'
    ],
    difficulty: 2,
    tags: ['拒绝', '额外工作', '边界']
  },

  // ==================== 邮件写作场景 ====================
  {
    id: 'email_meeting_invite',
    name: '会议邀请邮件',
    type: ScenarioType.EMAIL,
    context: '需要发一封会议邀请邮件',
    question: '会议邀请邮件怎么写？',
    tips: [
      '标题明确：【会议邀请】+ 主题 + 时间',
      '说明会议目的和议程',
      '注明时间、地点、参与人',
      '提前至少 1 天发送'
    ],
    sampleAnswers: [
      '主题：【会议邀请】XX 项目需求评审 - 周三 14:00\n\n各位好，\n\n本周三 14:00-15:00 将进行 XX 项目需求评审，请准时参加。\n\n会议地点：3 楼会议室\n参会人员：产品组、开发组\n\n议程：\n1. 需求背景说明（10 分钟）\n2. 方案讨论（30 分钟）\n3. 任务分配（20 分钟）\n\n请提前阅读附件中的需求文档。',
    ],
    pitfalls: [
      '❌ 标题模糊——"开会"——容易被忽略',
      '❌ 没有时间地点——信息不全',
      '❌ 太长——没人看',
      '❌ 太短——信息不足'
    ],
    difficulty: 1,
    tags: ['邮件', '会议', '邀请']
  },
];

/**
 * 场景化答疑引擎
 */
export class ScenarioQAEngine {
  private static instance: ScenarioQAEngine | null = null;
  private scenarioLibrary: Map<string, Scenario>;

  static getInstance(): ScenarioQAEngine {
    if (!ScenarioQAEngine.instance) {
      ScenarioQAEngine.instance = new ScenarioQAEngine();
    }
    return ScenarioQAEngine.instance;
  }

  private constructor() {
    this.scenarioLibrary = new Map();
    SCENARIO_LIBRARY.forEach(s => this.scenarioLibrary.set(s.id, s));
    HiLog.info(TAG, `场景库初始化完成，共 ${SCENARIO_LIBRARY.length} 个场景`);
  }

  /**
   * 解析用户问题，匹配场景
   */
  parseQuestion(question: string): QAResult | null {
    const lower = question.toLowerCase();
    
    // 1. 场景匹配
    const matchedScenario = this.matchScenario(lower);
    if (!matchedScenario) {
      HiLog.info(TAG, `未匹配到场景: ${question}`);
      return null;
    }

    // 2. 生成答疑结果
    const result: QAResult = {
      scenario: matchedScenario,
      advice: this.generateAdvice(matchedScenario),
      sampleAnswer: matchedScenario.sampleAnswers[0],
      tips: matchedScenario.tips,
      pitfalls: matchedScenario.pitfalls,
      practicePrompt: this.generatePracticePrompt(matchedScenario)
    };

    HiLog.info(TAG, `场景匹配成功: ${matchedScenario.name}`);
    return result;
  }

  /**
   * 匹配场景
   */
  private matchScenario(text: string): Scenario | null {
    let bestMatch: Scenario | null = null;
    let bestScore = 0;

    for (const scenario of this.scenarioLibrary.values()) {
      let score = 0;

      // 关键词匹配
      for (const tag of scenario.tags) {
        if (text.includes(tag.toLowerCase())) {
          score += 2;
        }
      }

      // 场景描述匹配
      if (text.includes(scenario.context.toLowerCase())) {
        score += 3;
      }

      // 问题匹配
      if (text.includes(scenario.question.toLowerCase())) {
        score += 5;
      }

      // 场景类型匹配
      const typeKeywords: Record<ScenarioType, string[]> = {
        [ScenarioType.INTERVIEW]: ['面试', '求职', 'hr', 'offer'],
        [ScenarioType.REPORT]: ['汇报', '进度', '周报', '领导'],
        [ScenarioType.NEGOTIATION]: ['谈判', '协商', '谈'],
        [ScenarioType.CONFLICT]: ['冲突', '分歧', '不同意', '矛盾'],
        [ScenarioType.SOCIAL]: ['社交', '聚餐', '团建'],
        [ScenarioType.EMAIL]: ['邮件', 'email', '写信'],
        [ScenarioType.MEETING]: ['会议', '开会'],
        [ScenarioType.PRESENTATION]: ['演示', '汇报', '展示'],
        [ScenarioType.FEEDBACK]: ['反馈', '评价', '批评'],
        [ScenarioType.REFUSAL]: ['拒绝', '不想', '推掉']
      };

      const keywords = typeKeywords[scenario.type] || [];
      for (const kw of keywords) {
        if (text.includes(kw)) {
          score += 1;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = scenario;
      }
    }

    // 置信度阈值
    return bestScore >= 2 ? bestMatch : null;
  }

  /**
   * 生成建议
   */
  private generateAdvice(scenario: Scenario): string {
    const adviceTemplates: Record<ScenarioType, string> = {
      [ScenarioType.INTERVIEW]: '面试时保持自信，用 STAR 法则回答（情境→任务→行动→结果）。',
      [ScenarioType.REPORT]: '汇报要简洁有力，用数据说话，突出成果而非过程。',
      [ScenarioType.NEGOTIATION]: '谈判前做好功课，了解对方底线，寻找双赢方案。',
      [ScenarioType.CONFLICT]: '处理冲突先理解对方观点，用数据说话，寻找共同目标。',
      [ScenarioType.SOCIAL]: '职场社交注意分寸，保持友好但不过度亲密。',
      [ScenarioType.EMAIL]: '邮件要简洁明了，标题明确，正文结构化。',
      [ScenarioType.MEETING]: '开会前准备议程，会上控制时间，会后跟进行动项。',
      [ScenarioType.PRESENTATION]: '演示要突出重点，用图表说话，控制时间在 15 分钟内。',
      [ScenarioType.FEEDBACK]: '给反馈要具体、及时、建设性，用 SBI 法则。',
      [ScenarioType.REFUSAL]: '拒绝要坚定但友好，说明原因，给出替代方案。'
    };

    return adviceTemplates[scenario.type] || '注意沟通技巧，保持专业态度。';
  }

  /**
   * 生成练习提示
   */
  private generatePracticePrompt(scenario: Scenario): string {
    return `💬 模拟练习：\n\n假设你现在就在这个场景中：${scenario.context}\n\n对方说："${scenario.question}"\n\n你会怎么回答？试着说出来，我来帮你评估～`;
  }

  /**
   * 获取所有场景列表
   */
  getScenarioList(): Scenario[] {
    return Array.from(this.scenarioLibrary.values());
  }

  /**
   * 按类型获取场景
   */
  getScenariosByType(type: ScenarioType): Scenario[] {
    return Array.from(this.scenarioLibrary.values()).filter(s => s.type === type);
  }

  /**
   * 获取场景详情
   */
  getScenario(id: string): Scenario | null {
    return this.scenarioLibrary.get(id) || null;
  }

  /**
   * 添加自定义场景
   */
  addScenario(scenario: Scenario): void {
    this.scenarioLibrary.set(scenario.id, scenario);
    HiLog.info(TAG, `添加场景: ${scenario.name}`);
  }

  /**
   * 获取场景类型名称
   */
  getTypeName(type: ScenarioType): string {
    const names: Record<ScenarioType, string> = {
      [ScenarioType.INTERVIEW]: '面试',
      [ScenarioType.REPORT]: '工作汇报',
      [ScenarioType.NEGOTIATION]: '商务谈判',
      [ScenarioType.CONFLICT]: '冲突处理',
      [ScenarioType.SOCIAL]: '职场社交',
      [ScenarioType.EMAIL]: '邮件写作',
      [ScenarioType.MEETING]: '会议发言',
      [ScenarioType.PRESENTATION]: '演示汇报',
      [ScenarioType.FEEDBACK]: '给反馈',
      [ScenarioType.REFUSAL]: '拒绝技巧'
    };
    return names[type] || '其他';
  }
}

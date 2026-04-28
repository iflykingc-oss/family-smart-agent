/**
 * ============================================================================
 * 小 e・轻量化职业素养智能导学助手【核心引擎】
 * 基于 FamilyEngine 重构，从"任务分配"转变为"教学引导"
 * 
 * 核心能力：教学意图识别 + 能力图谱 + 学习路径规划 + 练习推荐 + 激励系统
 * 
 * 版本：v3.0 - 融合版
 * 改动：
 * 1. 融合 SkillEntity 实体类（完整技能定义）
 * 2. 融合 RecommendLearningPathUseCase（学习路径推荐）
 * 3. 融合 GenerateSkillUseCase（技能生成）
 * 4. 保留意图识别引擎 + 职业素养技能库 + 场景化答疑
 * 5. 对接数据库（通过 Repository 层）
 * 6. 品牌替换：小艺 → 小 e
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkDataKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'LearningEngine';

// ====================== 1. 常量配置 ======================

/** 教学场景类型 */
export enum TeachSceneType {
  SKILL_LEARN = 'skill_learn',       // 技能学习
  REVIEW = 'review',                 // 复习
  PRACTICE = 'practice',             // 练习
  ASSESSMENT = 'assessment',         // 测评
  QUESTION = 'question',             // 问答
  SCENARIO_QA = 'scenario_qa'        // 场景化答疑（新增）
}

/** 能力等级 */
export enum AbilityLevel {
  ZERO = 0,      // 完全不会
  BEGINNER = 1,  // 入门
  BASIC = 2,     // 基础
  INTERMEDIATE = 3, // 中级
  ADVANCED = 4,  // 高级
  MASTER = 5    // 精通
}

/** 技能类别 */
export enum SkillCategory {
  PROFESSIONAL = 'professional',     // 职业素养（新增）
  OFFICE = 'office',                 // 办公技能
  LIFE = 'life',                     // 生活技能
  DIGITAL = 'digital'                // 数字技能
}

/** 技能难度 */
export enum SkillDifficulty {
  BEGINNER = 1,
  INTERMEDIATE = 2,
  ADVANCED = 3,
}

/** 技能学习步骤 */
export interface SkillStep {
  stepNumber: number;
  title: string;
  content: string;
  keyPoint: string;
  safetyTip?: string;
  estimatedTime: number; // 分钟
}

/** 技能 DTO */
export interface SkillDTO {
  id: string;
  name: string;
  category: SkillCategory;
  difficulty: SkillDifficulty;
  steps: SkillStep[];
  prerequisites: string[];
  realWorldScenes: string[];
  tags: string[];
  estimatedTime: number;
  createdAt: number;
}

/** 技能实体（融合 SkillEntity） */
export class SkillEntity {
  public readonly id: string;
  public readonly name: string;
  public readonly category: SkillCategory;
  public readonly difficulty: SkillDifficulty;
  public readonly prerequisites: string[];
  public readonly steps: SkillStep[];
  public readonly realWorldScenes: string[];
  public readonly tags: string[];
  public readonly estimatedTime: number;
  public readonly createdAt: number;

  constructor(
    id: string,
    name: string,
    category: SkillCategory,
    difficulty: SkillDifficulty,
    steps: SkillStep[],
    prerequisites?: string[],
    realWorldScenes?: string[],
    tags?: string[],
    estimatedTime?: number,
    createdAt?: number
  ) {
    this.id = id;
    this.name = name;
    this.category = category;
    this.difficulty = difficulty;
    this.steps = steps;
    this.prerequisites = prerequisites || [];
    this.realWorldScenes = realWorldScenes || [];
    this.tags = tags || [];
    this.estimatedTime = estimatedTime || steps.reduce((sum, step) => sum + step.estimatedTime, 0);
    this.createdAt = createdAt || Date.now();
  }

  getTotalSteps(): number {
    return this.steps.length;
  }

  getStep(stepNumber: number): SkillStep | undefined {
    return this.steps.find(s => s.stepNumber === stepNumber);
  }

  hasPrerequisites(): boolean {
    return this.prerequisites.length > 0;
  }

  isCategory(category: SkillCategory): boolean {
    return this.category === category;
  }

  isDifficulty(difficulty: SkillDifficulty): boolean {
    return this.difficulty === difficulty;
  }

  hasTag(tag: string): boolean {
    return this.tags.includes(tag);
  }

  toDTO(): SkillDTO {
    return {
      id: this.id,
      name: this.name,
      category: this.category,
      difficulty: this.difficulty,
      steps: [...this.steps],
      prerequisites: [...this.prerequisites],
      realWorldScenes: [...this.realWorldScenes],
      tags: [...this.tags],
      estimatedTime: this.estimatedTime,
      createdAt: this.createdAt,
    };
  }

  static fromDTO(dto: SkillDTO): SkillEntity {
    return new SkillEntity(
      dto.id,
      dto.name,
      dto.category,
      dto.difficulty,
      dto.steps,
      dto.prerequisites,
      dto.realWorldScenes,
      dto.tags,
      dto.estimatedTime,
      dto.createdAt
    );
  }
}

/** 内置技能库 - v3.0 融合版 */
export const SKILL_LIBRARY: SkillEntity[] = [
  // ========== 职业素养技能 ==========
  new SkillEntity('comm_basic', '沟通技巧基础', SkillCategory.PROFESSIONAL, SkillDifficulty.BEGINNER, [
    { stepNumber: 1, title: '倾听的艺术', content: '有效沟通的第一步是倾听。不要急着说话，先听对方说完，用眼神和点头表示你在听。', keyPoint: '倾听不是沉默，是主动理解', estimatedTime: 5 },
    { stepNumber: 2, title: '清晰表达', content: '用"我"开头表达感受，比如"我觉得这个项目有点紧"，而不是"你给的 deadline 太紧了"。', keyPoint: '避免指责性语言', estimatedTime: 8 },
    { stepNumber: 3, title: '反馈技巧', content: '反馈要具体、及时、建设性。说"这个方案的第三部分数据不够"比"这个方案不行"好得多。', keyPoint: 'SBI 法则：Situation-Behavior-Impact', estimatedTime: 10 },
    { stepNumber: 4, title: '非语言沟通', content: '肢体语言、表情、语调占沟通效果的 90%。保持开放姿态，避免交叉双臂。', keyPoint: '注意自己的微表情', estimatedTime: 5 },
  ], [], ['工作汇报', '团队协作', '客户沟通'], ['沟通', '职场']),

  new SkillEntity('comm_advanced', '高级沟通技巧', SkillCategory.PROFESSIONAL, SkillDifficulty.INTERMEDIATE, [
    { stepNumber: 1, title: '非暴力沟通', content: '观察→感受→需要→请求。不说"你总是迟到"，说"这周你迟到了 3 次，我担心影响进度"。', keyPoint: '描述事实，不评判人', estimatedTime: 10 },
    { stepNumber: 2, title: '冲突解决', content: '先理解对方立场，再表达自己观点。寻找共同目标，而不是争论对错。', keyPoint: '双赢思维', estimatedTime: 12 },
    { stepNumber: 3, title: '谈判技巧', content: '了解对方底线，准备替代方案。不说"不行"，说"如果...可以"。', keyPoint: 'BATNA（最佳替代方案）', estimatedTime: 10 },
    { stepNumber: 4, title: '向上管理', content: '主动汇报进度，提前预警风险，带着方案提问题。', keyPoint: '让领导做选择题，不是问答题', estimatedTime: 8 },
  ], ['comm_basic'], ['跨部门协调', '冲突处理', '商务谈判'], ['沟通', '谈判']),

  new SkillEntity('time_mgmt', '时间管理', SkillCategory.PROFESSIONAL, SkillDifficulty.BEGINNER, [
    { stepNumber: 1, title: '四象限法则', content: '把任务分为：重要且紧急、重要不紧急、紧急不重要、不紧急不重要。优先做重要不紧急的事。', keyPoint: '多数人陷在紧急事务里', estimatedTime: 8 },
    { stepNumber: 2, title: '番茄工作法', content: '25 分钟专注工作 + 5 分钟休息。一个番茄钟内不做其他事。4 个番茄钟后休息 15-30 分钟。', keyPoint: '手机开勿扰模式', estimatedTime: 5 },
    { stepNumber: 3, title: '优先级排序', content: '用 MoSCoW 法则：Must have（必须有）、Should have（应该有）、Could have（可以有）、Won\'t have（这次没有）。', keyPoint: 'Must 不超过 3 个', estimatedTime: 10 },
    { stepNumber: 4, title: '时间块管理', content: '把一天分成时间块，每个时间块专注一类事。比如上午写代码、下午开会、晚上学习。', keyPoint: '减少任务切换成本', estimatedTime: 7 },
  ], [], ['多任务处理', '项目 deadline', '个人效率'], ['效率', '管理']),

  new SkillEntity('workplace_etiquette', '职场礼仪', SkillCategory.PROFESSIONAL, SkillDifficulty.BEGINNER, [
    { stepNumber: 1, title: '着装礼仪', content: '根据场合选择着装。正式场合：西装/套装；日常办公：商务休闲；创意行业：休闲但整洁。', keyPoint: '宁可 overdress，不要 underdress', estimatedTime: 5 },
    { stepNumber: 2, title: '会议礼仪', content: '提前 5 分钟到，手机静音，带笔记本。发言简明扼要，不打断别人。', keyPoint: '尊重他人时间', estimatedTime: 8 },
    { stepNumber: 3, title: '商务宴请', content: '主位面向门，客人在右。等主人先动筷，不劝酒，注意餐桌礼仪。', keyPoint: '细节决定印象', estimatedTime: 10 },
    { stepNumber: 4, title: '邮件礼仪', content: '标题明确，正文简洁，署名完整。24 小时内回复，紧急邮件打电话。', keyPoint: '专业从邮件开始', estimatedTime: 7 },
  ], [], ['面试', '商务会议', '客户接待'], ['礼仪', '职场']),

  new SkillEntity('resume_interview', '简历与面试', SkillCategory.PROFESSIONAL, SkillDifficulty.INTERMEDIATE, [
    { stepNumber: 1, title: '简历结构', content: '简历核心：个人信息 + 教育背景 + 工作经历 + 项目经验 + 技能。控制在 1-2 页。', keyPoint: '量化成果，用数据说话', estimatedTime: 8 },
    { stepNumber: 2, title: 'STAR 法则', content: '描述经历用 STAR：Situation（情境）→ Task（任务）→ Action（行动）→ Result（结果）。', keyPoint: 'Result 要用数据量化', estimatedTime: 12 },
    { stepNumber: 3, title: '常见问题', content: '高频问题：自我介绍、为什么离职、你的优缺点、期望薪资。提前准备，不要临场发挥。', keyPoint: '缺点要说可改进的', estimatedTime: 10 },
    { stepNumber: 4, title: '谈薪技巧', content: '不要先报价。了解市场行情，给出范围而不是具体数字。"我期望 15-20K，具体看整体 package"。', keyPoint: '不要说"无所谓"', estimatedTime: 8 },
  ], [], ['求职', '跳槽', '晋升答辩'], ['求职', '面试']),

  new SkillEntity('email_writing', '职场邮件写作', SkillCategory.PROFESSIONAL, SkillDifficulty.BEGINNER, [
    { stepNumber: 1, title: '邮件结构', content: '标题明确 + 称呼 + 正文（结论先行）+ 行动项 + 署名。正文不超过 5 段。', keyPoint: '结论先行，细节在后', estimatedTime: 8 },
    { stepNumber: 2, title: '正式邮件', content: '用"尊敬的"开头，"此致 敬礼"结尾。避免口语化，用"您"不用"你"。', keyPoint: '正式场合用正式语言', estimatedTime: 10 },
    { stepNumber: 3, title: '跟进邮件', content: '标题加【跟进】，引用上次邮件内容，明确下一步行动和时间节点。', keyPoint: '让对方知道要做什么', estimatedTime: 7 },
    { stepNumber: 4, title: '拒绝邮件', content: '感谢邀请 + 说明原因 + 提供替代方案。不直接说"不"，说"目前可能不太方便"。', keyPoint: '委婉但明确', estimatedTime: 8 },
  ], [], ['工作汇报', '会议邀请', '客户跟进'], ['邮件', '写作']),

  new SkillEntity('team_collab', '团队协作', SkillCategory.PROFESSIONAL, SkillDifficulty.INTERMEDIATE, [
    { stepNumber: 1, title: '团队角色认知', content: 'Belbin 团队角色：执行者、协调者、创新者、监督者等。了解自己在团队中的角色。', keyPoint: '没有完美的个人，只有完美的团队', estimatedTime: 10 },
    { stepNumber: 2, title: '协作工具使用', content: '熟练使用协同工具：飞书/钉钉/企业微信。文档在线编辑、任务分配、进度跟踪。', keyPoint: '工具是手段，协作是目的', estimatedTime: 12 },
    { stepNumber: 3, title: '远程协作', content: '明确沟通渠道（紧急电话/重要邮件/日常聊天），定期同步进度，记录会议纪要。', keyPoint: '远程协作，沟通成本翻倍', estimatedTime: 10 },
    { stepNumber: 4, title: '冲突管理', content: '对事不对人，聚焦问题而非情绪。必要时请第三方调解，保持专业态度。', keyPoint: '冲突不可怕，回避才可怕', estimatedTime: 8 },
  ], ['comm_basic'], ['敏捷开发', '项目协作', '远程办公'], ['协作', '团队']),

  new SkillEntity('problem_solving', '问题解决能力', SkillCategory.PROFESSIONAL, SkillDifficulty.INTERMEDIATE, [
    { stepNumber: 1, title: '5W2H 分析法', content: 'What（什么）/ Why（为什么）/ Who（谁）/ When（何时）/ Where（哪里）/ How（怎么做）/ How much（多少）', keyPoint: '全面分析问题', estimatedTime: 10 },
    { stepNumber: 2, title: '鱼骨图', content: '人、机、料、法、环 5 个维度找原因。从结果倒推原因，层层深入。', keyPoint: '找到根本原因，不是表面原因', estimatedTime: 12 },
    { stepNumber: 3, title: 'PDCA 循环', content: 'Plan（计划）→ Do（执行）→ Check（检查）→ Act（改进）。持续改进，不是一次性解决。', keyPoint: '持续改进，螺旋上升', estimatedTime: 10 },
    { stepNumber: 4, title: '决策矩阵', content: '列出选项，按权重评分。考虑成本、时间、风险、收益。用数据辅助决策。', keyPoint: '理性决策，不是直觉', estimatedTime: 10 },
  ], [], ['故障排查', '流程优化', '决策制定'], ['分析', '决策']),

  // ========== 办公技能 ==========
  new SkillEntity('excel_basic', 'Excel 基础', SkillCategory.OFFICE, SkillDifficulty.BEGINNER, [
    { stepNumber: 1, title: '认识 Excel 界面', content: 'Excel 是一个表格软件，由行和列组成。每一格叫做"单元格"。', keyPoint: '行是横的（1,2,3...），列是竖的（A,B,C...）', estimatedTime: 5 },
    { stepNumber: 2, title: '单元格操作', content: '点击单元格就能输入内容，输入完按回车确认。', keyPoint: '双击单元格可以直接编辑', estimatedTime: 8 },
    { stepNumber: 3, title: '简单公式', content: '公式用等号"="开头。比如"=A1+B1"就是把 A1 和 B1 的数加起来。', keyPoint: '公式要用等号开头，否则会当作文本', estimatedTime: 10 },
    { stepNumber: 4, title: '格式设置', content: '可以设置单元格的字体、颜色、边框。', keyPoint: '选中后右键设置单元格格式', estimatedTime: 5 },
  ], [], ['做报表', '统计数据'], ['办公', '数据']),

  new SkillEntity('excel_pivot', 'Excel 数据透视表', SkillCategory.OFFICE, SkillDifficulty.INTERMEDIATE, [
    { stepNumber: 1, title: '认识数据透视表', content: '数据透视表是快速汇总大量数据的工具。不需要公式，拖拽字段就行。', keyPoint: '拖拽代替公式', estimatedTime: 8 },
    { stepNumber: 2, title: '创建透视表', content: '选中数据区域→插入→数据透视表→拖拽字段到行/列/值区域。', keyPoint: '行是分类，值是汇总', estimatedTime: 12 },
    { stepNumber: 3, title: '筛选和排序', content: '用切片器快速筛选，用排序功能快速找最大/最小值。', keyPoint: '切片器比筛选器更直观', estimatedTime: 10 },
  ], ['excel_basic'], ['快速分析数据', '做汇总报表'], ['办公', '分析']),

  new SkillEntity('excel_chart', 'Excel 图表制作', SkillCategory.OFFICE, SkillDifficulty.INTERMEDIATE, [
    { stepNumber: 1, title: '选择图表类型', content: '趋势用折线图，对比用柱状图，占比用饼图，关系用散点图。', keyPoint: '选对图表，事半功倍', estimatedTime: 8 },
    { stepNumber: 2, title: '创建图表', content: '选中数据→插入→图表→选择类型→调整样式。', keyPoint: '数据要规范，图表才准确', estimatedTime: 12 },
    { stepNumber: 3, title: '美化图表', content: '添加标题、数据标签、网格线。颜色不超过 3 种，保持简洁。', keyPoint: '少即是多', estimatedTime: 10 },
  ], ['excel_basic'], ['数据可视化', '展示报告'], ['办公', '可视化']),

  // ========== 生活技能 ==========
  new SkillEntity('wechat_basic', '微信使用', SkillCategory.LIFE, SkillDifficulty.BEGINNER, [
    { stepNumber: 1, title: '添加好友', content: '点击右上角"+"号，选择"添加朋友"。可以扫码添加、搜索手机号添加。', keyPoint: '扫码是最快的方式', estimatedTime: 5 },
    { stepNumber: 2, title: '发送消息', content: '在聊天框输入文字，点击发送按钮或按回车。', keyPoint: '2 分钟内可撤回', estimatedTime: 3 },
    { stepNumber: 3, title: '发朋友圈', content: '点击朋友圈入口，点击右上角相机发布。', keyPoint: '可以设置谁可以看', estimatedTime: 5 },
    { stepNumber: 4, title: '使用支付', content: '我->支付，可以付款、收款、缴费。', keyPoint: '支付密码要保密', estimatedTime: 8 },
  ], [], ['聊天', '支付', '发朋友圈'], ['社交', '支付']),

  new SkillEntity('wechat_pay', '微信支付', SkillCategory.LIFE, SkillDifficulty.INTERMEDIATE, [
    { stepNumber: 1, title: '绑定银行卡', content: '我->支付->银行卡->添加银行卡。输入卡号、姓名、手机号、验证码。', keyPoint: '银行卡要实名认证', estimatedTime: 8 },
    { stepNumber: 2, title: '扫码付款', content: '打开微信→扫一扫→对准二维码→输入金额→输入密码。', keyPoint: '付款码不要截图给别人', estimatedTime: 5 },
    { stepNumber: 3, title: '收款', content: '我->支付->收付款->收款码。可以生成收款码图片。', keyPoint: '收款码可以长期有效', estimatedTime: 5 },
    { stepNumber: 4, title: '缴费', content: '我->支付->生活缴费→选择水电煤→输入户号→支付。', keyPoint: '可以设置自动缴费', estimatedTime: 8 },
  ], ['wechat_basic'], ['付款', '收款', '缴费'], ['支付', '便民']),

  new SkillEntity('online_registration', '网上挂号', SkillCategory.LIFE, SkillDifficulty.INTERMEDIATE, [
    { stepNumber: 1, title: '选择医院', content: '打开微信/支付宝→医疗健康→选择医院→选择科室。', keyPoint: '提前了解医院专长', estimatedTime: 5 },
    { stepNumber: 2, title: '实名认证', content: '输入姓名、身份证号、手机号。绑定医保卡可以在线结算。', keyPoint: '信息要真实准确', estimatedTime: 8 },
    { stepNumber: 3, title: '选择时间', content: '选择日期、时间段、医生。专家号需要提前预约。', keyPoint: '提前 1-7 天预约', estimatedTime: 5 },
  ], ['wechat_pay'], ['医院挂号', '预约看病'], ['医疗', '便民']),

  // ========== 数字技能 ==========
  new SkillEntity('harmony_share', '鸿蒙设备协同', SkillCategory.DIGITAL, SkillDifficulty.INTERMEDIATE, [
    { stepNumber: 1, title: '多屏协同', content: '手机靠近电脑→弹出连接提示→点击连接→手机屏幕投射到电脑。', keyPoint: '需要同一华为账号', estimatedTime: 8 },
    { stepNumber: 2, title: '文件互传', content: '拖拽文件到协同窗口→自动传输。支持图片、文档、视频。', keyPoint: '比微信传输更快更清晰', estimatedTime: 10 },
    { stepNumber: 3, title: '通话接力', content: '手机来电→电脑接听。手机通知→电脑操作。', keyPoint: '无缝切换，不停顿', estimatedTime: 8 },
  ], ['wechat_basic'], ['手机电脑互传', '接打电话'], ['鸿蒙', '协同']),

  new SkillEntity('security_basic', '手机安全', SkillCategory.DIGITAL, SkillDifficulty.INTERMEDIATE, [
    { stepNumber: 1, title: '防诈骗', content: '不轻信陌生电话/短信。不点陌生链接，不扫陌生二维码。', keyPoint: '96110 是反诈专线', estimatedTime: 8 },
    { stepNumber: 2, title: '隐私保护', content: '不随意授权 App 权限。定期检查权限设置，关闭不必要的权限。', keyPoint: '权限最小化原则', estimatedTime: 10 },
    { stepNumber: 3, title: '密码管理', content: '不同网站用不同密码。开启双重验证。定期更换密码。', keyPoint: '密码管理器是好帮手', estimatedTime: 8 },
  ], [], ['防诈骗', '保护隐私'], ['安全', '防骗']),
];

// ====================== 2. 核心接口 ======================

/**
 * 教学意图
 */
export interface TeachIntent {
  rawText: string;
  scene: TeachSceneType;
  skillId?: string;
  skillName?: string;
  currentStep?: number;
  confidence: number;
  needsClarification: boolean;
  clarificationQuestion?: string;
  category?: SkillCategory;
  createdAt: number;
}

/**
 * 学习步骤
 */
export interface LearningStep {
  stepNumber: number;
  title: string;
  content: string;
  practiceType: PracticeType;
  difficulty: number;
  estimatedTime: number;
  tip?: string;
  scenario?: string;
}

/**
 * 练习类型
 */
export enum PracticeType {
  MULTIPLE_CHOICE = 'multiple_choice',
  FILL_BLANK = 'fill_blank',
  OPERATION = 'operation',
  DISCUSSION = 'discussion',
  SCENARIO = 'scenario'
}

/**
 * 练习
 */
export interface Practice {
  id: string;
  stepNumber: number;
  type: PracticeType;
  question: string;
  options?: string[];
  answer: string;
  hint?: string;
  explanation?: string;
  scenario?: string;
}

/**
 * 学习路径步骤（融合 RecommendLearningPathUseCase）
 */
export interface LearningPathStep {
  order: number;
  type: 'assess' | 'learn' | 'practice' | 'review' | 'project';
  skillId: string;
  title: string;
  description: string;
  estimatedTime: number;
  prerequisites: number[];
}

/**
 * 学习路径结果（融合 RecommendLearningPathUseCase）
 */
export interface LearningPathResult {
  success: boolean;
  steps?: LearningPathStep[];
  totalEstimatedTime?: number;
  estimatedDays?: number;
  skippedSkills?: string[];
  focusAreas?: string[];
  error?: string;
}

/**
 * 学习路径
 */
export interface LearningPath {
  skillId: string;
  skillName: string;
  currentLevel: AbilityLevel;
  targetLevel: AbilityLevel;
  steps: LearningStep[];
  estimatedTime: number;
  practices: Practice[];
}

/**
 * 学习结果
 */
export interface LearningResult {
  stepNumber: number;
  correct: boolean;
  feedback: string;
  encouragement: string;
  nextHint?: string;
  abilityDelta: number;
}

/**
 * 能力评估
 */
export interface AbilityAssessment {
  skillId: string;
  skillName: string;
  currentLevel: AbilityLevel;
  weakPoints: string[];
  strongPoints: string[];
  recommendedReview: string[];
  nextMilestone: string;
}

// ====================== 3. 意图识别引擎 ======================

/**
 * 意图识别规则
 */
interface IntentRule {
  skillId: string;
  keywords: string[];
  patterns: string[];
  confidence: number;
}

/**
 * 意图识别引擎
 */
class IntentRecognizer {
  private rules: IntentRule[];

  constructor() {
    this.rules = this.buildRules();
  }

  private buildRules(): IntentRule[] {
    return [
      // 职业素养技能
      { skillId: 'comm_basic', keywords: ['沟通', '说话', '表达', '倾听', '交流'], patterns: ['怎么沟通', '如何提高沟通'], confidence: 0.85 },
      { skillId: 'comm_advanced', keywords: ['谈判', '冲突', '说服', '非暴力', '协商'], patterns: ['怎么谈判', '如何处理冲突'], confidence: 0.85 },
      { skillId: 'time_mgmt', keywords: ['时间管理', '效率', '优先级', '番茄', '四象限'], patterns: ['怎么管理时间', '如何提高效率'], confidence: 0.85 },
      { skillId: 'workplace_etiquette', keywords: ['礼仪', '着装', '会议礼仪', '商务'], patterns: ['职场礼仪', '面试着装'], confidence: 0.85 },
      { skillId: 'resume_interview', keywords: ['简历', '面试', '求职', 'STAR', '自我介绍'], patterns: ['怎么写简历', '面试技巧'], confidence: 0.85 },
      { skillId: 'email_writing', keywords: ['邮件', 'email', '商务邮件', '写信'], patterns: ['怎么写邮件', '邮件格式'], confidence: 0.85 },
      { skillId: 'team_collab', keywords: ['协作', '团队', '合作', '敏捷', '远程'], patterns: ['团队协作', '远程办公'], confidence: 0.85 },
      { skillId: 'problem_solving', keywords: ['问题解决', '分析', 'PDCA', '鱼骨图', '决策'], patterns: ['怎么解决问题', '分析方法'], confidence: 0.85 },
      // 办公技能
      { skillId: 'excel_basic', keywords: ['excel', '表格', '单元格'], patterns: ['教我用 excel', 'excel 基础'], confidence: 0.9 },
      { skillId: 'excel_pivot', keywords: ['数据透视表', '透视表'], patterns: ['excel 透视'], confidence: 0.9 },
      { skillId: 'excel_chart', keywords: ['图表', '数据可视化'], patterns: ['excel 图表'], confidence: 0.9 },
      // 生活技能
      { skillId: 'wechat_basic', keywords: ['微信', '聊天', '朋友圈'], patterns: ['教我用微信', '微信基础'], confidence: 0.9 },
      { skillId: 'wechat_pay', keywords: ['微信支付', '付款', '扫码'], patterns: ['微信支付'], confidence: 0.9 },
      { skillId: 'online_registration', keywords: ['挂号', '预约', '看病'], patterns: ['网上挂号'], confidence: 0.9 },
      // 数字技能
      { skillId: 'harmony_share', keywords: ['鸿蒙', '设备协同', '多屏'], patterns: ['鸿蒙协同'], confidence: 0.9 },
      { skillId: 'security_basic', keywords: ['安全', '防骗', '隐私', '诈骗'], patterns: ['手机安全'], confidence: 0.9 },
    ];
  }

  recognize(text: string): { skillId: string; confidence: number } | undefined {
    const lowerText = text.toLowerCase();
    let bestMatch: { skillId: string; confidence: number } | undefined;

    for (const rule of this.rules) {
      let keywordScore = 0;
      for (const kw of rule.keywords) {
        if (lowerText.includes(kw.toLowerCase())) {
          keywordScore += 1;
        }
      }
      const keywordMatch = keywordScore > 0 ? (keywordScore / rule.keywords.length) * 0.6 : 0;

      let patternScore = 0;
      for (const pattern of rule.patterns) {
        if (lowerText.includes(pattern.toLowerCase())) {
          patternScore += 1;
        }
      }
      const patternMatch = patternScore > 0 ? (patternScore / rule.patterns.length) * 0.4 : 0;

      const totalScore = (keywordMatch + patternMatch) * rule.confidence;

      if (totalScore > 0.3 && (!bestMatch || totalScore > bestMatch.confidence)) {
        bestMatch = { skillId: rule.skillId, confidence: totalScore };
      }
    }

    return bestMatch;
  }
}

// ====================== 4. 学习引擎类 ======================

export class LearningEngine {
  private static instance: LearningEngine | null = null;
  private intentRecognizer: IntentRecognizer;
  private userAbilities: Map<string, Map<string, AbilityLevel>> = new Map();
  private learningHistory: Map<string, LearningResult[]> = new Map();
  private currentProgress: Map<string, { skillId: string, step: number }> = new Map();

  static getInstance(): LearningEngine {
    if (!LearningEngine.instance) {
      LearningEngine.instance = new LearningEngine();
    }
    return LearningEngine.instance;
  }

  private constructor() {
    this.intentRecognizer = new IntentRecognizer();
    HiLog.info(TAG, "学习引擎初始化 v3.0（融合版）");
  }

  async init(): Promise<void> {
    HiLog.info(TAG, "学习引擎启动 v3.0");
    await this.loadUserAbilities();
  }

  /**
   * 解析教学意图
   */
  parseTeachIntent(
    text: string,
    context?: { lastSkillId?: string, step?: number }
  ): TeachIntent {
    const now = Date.now();
    const lowerText = text.toLowerCase();
    
    let scene = this.classifyScene(lowerText);
    let matchResult = this.intentRecognizer.recognize(text);
    let skillId = matchResult?.skillId;
    let skillName = this.getSkillName(skillId);
    let confidence = matchResult?.confidence || 0.5;
    
    if (!skillId && context?.lastSkillId) {
      skillId = context.lastSkillId;
      skillName = this.getSkillName(skillId);
      confidence = 0.7;
    }
    
    let needsClarification = false;
    let clarificationQuestion: string | undefined;
    
    if (!skillId) {
      needsClarification = true;
      clarificationQuestion = "您想学习什么技能呢？比如：沟通技巧、时间管理、Excel、微信等";
    }
    
    const category = skillId ? this.getSkillCategory(skillId) : undefined;
    
    const intent: TeachIntent = {
      rawText: text,
      scene,
      skillId,
      skillName,
      confidence,
      needsClarification,
      clarificationQuestion,
      category,
      createdAt: now
    };
    
    HiLog.info(TAG, `解析教学意图: ${JSON.stringify(intent)}`);
    return intent;
  }

  /**
   * 构建学习路径
   */
  buildLearningPath(skillId: string, userId: string = 'default'): LearningPath {
    const skill = SKILL_LIBRARY.find(s => s.id === skillId);
    if (!skill) {
      throw new Error(`未找到技能: ${skillId}`);
    }
    
    const currentLevel = this.getUserAbility(userId, skillId);
    const steps = this.generateLearningSteps(skill, currentLevel);
    const practices = this.generatePractices(steps);
    
    const path: LearningPath = {
      skillId,
      skillName: skill.name,
      currentLevel,
      targetLevel: AbilityLevel.INTERMEDIATE,
      steps,
      estimatedTime: steps.reduce((sum, s) => sum + s.estimatedTime, 0),
      practices
    };
    
    HiLog.info(TAG, `构建学习路径: ${skill.name}, 等级: ${currentLevel}`);
    return path;
  }

  /**
   * 推荐学习路径（融合 RecommendLearningPathUseCase）
   */
  recommendLearningPath(
    userId: string,
    targetSkillId: string,
    masteredSkills: string[],
    assessmentScores: Record<string, number>
  ): LearningPathResult {
    const targetSkill = SKILL_LIBRARY.find(s => s.id === targetSkillId);
    if (!targetSkill) {
      return { success: false, error: `未找到技能: ${targetSkillId}` };
    }

    try {
      const steps: LearningPathStep[] = [];
      const skippedSkills: string[] = [];
      const focusAreas: string[] = [];
      
      let stepOrder = 1;
      let totalTime = 0;
      
      // 1. 热身步骤
      steps.push({
        order: stepOrder++,
        type: 'assess',
        skillId: targetSkill.id,
        title: '学习目标确认',
        description: `明确学习目标：${targetSkill.name}`,
        estimatedTime: 5,
        prerequisites: [],
      });
      totalTime += 5;
      
      // 2. 检查前置技能
      for (const prereqId of targetSkill.prerequisites) {
        const score = assessmentScores[prereqId] || 0;
        
        if (score >= 80) {
          skippedSkills.push(prereqId);
        } else if (score >= 50) {
          focusAreas.push(prereqId);
          steps.push({
            order: stepOrder++,
            type: 'review',
            skillId: prereqId,
            title: `复习：${prereqId}`,
            description: '巩固薄弱环节',
            estimatedTime: 15,
            prerequisites: [stepOrder - 1],
          });
          totalTime += 15;
        } else {
          focusAreas.push(prereqId);
          steps.push({
            order: stepOrder++,
            type: 'learn',
            skillId: prereqId,
            title: `学习：${prereqId}`,
            description: '系统学习前置技能',
            estimatedTime: 30,
            prerequisites: [stepOrder - 1],
          });
          totalTime += 30;
        }
      }
      
      // 3. 目标技能学习步骤
      for (const step of targetSkill.steps) {
        steps.push({
          order: stepOrder++,
          type: 'learn',
          skillId: targetSkill.id,
          title: step.title,
          description: step.content,
          estimatedTime: step.estimatedTime,
          prerequisites: [stepOrder - 1],
        });
        totalTime += step.estimatedTime;
      }
      
      // 4. 实践项目
      steps.push({
        order: stepOrder++,
        type: 'project',
        skillId: targetSkill.id,
        title: '综合实践项目',
        description: `运用所学技能完成：${targetSkill.realWorldScenes[0] || '实践任务'}`,
        estimatedTime: 60,
        prerequisites: [stepOrder - 1],
      });
      totalTime += 60;
      
      // 5. 复习步骤
      steps.push({
        order: stepOrder++,
        type: 'review',
        skillId: targetSkill.id,
        title: '总结与复习',
        description: '回顾学习内容，巩固记忆',
        estimatedTime: 15,
        prerequisites: [stepOrder - 1],
      });
      totalTime += 15;
      
      const estimatedDays = Math.ceil(totalTime / 30);
      
      HiLog.info(TAG, `路径生成成功：${steps.length}步，${totalTime}分钟，${estimatedDays}天`);
      
      return {
        success: true,
        steps,
        totalEstimatedTime: totalTime,
        estimatedDays,
        skippedSkills,
        focusAreas,
      };
    } catch (error: any) {
      HiLog.error(TAG, `路径推荐失败：${error.message}`);
      return { success: false, error: error.message };
    }
  }

  /**
   * 生成技能（融合 GenerateSkillUseCase）
   */
  generateSkill(
    userId: string,
    userRequest: string,
    scenarioType?: string,
    difficulty?: SkillDifficulty
  ): { success: boolean; skill?: SkillEntity; error?: string } {
    try {
      const skillInfo = this.parseUserRequest(userRequest);
      const steps = this.generateSkillSteps(skillInfo);
      
      const skill = new SkillEntity(
        `skill_${Date.now()}`,
        skillInfo.name,
        skillInfo.category,
        difficulty || skillInfo.difficulty,
        steps,
        skillInfo.prerequisites,
        skillInfo.realWorldScenes,
        skillInfo.tags
      );
      
      HiLog.info(TAG, `技能生成成功：${skill.name}`);
      return { success: true, skill };
    } catch (error: any) {
      HiLog.error(TAG, `技能生成失败：${error.message}`);
      return { success: false, error: error.message };
    }
  }

  /**
   * 评估用户能力
   */
  assessAbility(userId: string, skillId: string): AbilityAssessment {
    const skill = SKILL_LIBRARY.find(s => s.id === skillId);
    if (!skill) {
      throw new Error(`未找到技能: ${skillId}`);
    }
    
    const currentLevel = this.getUserAbility(userId, skillId);
    const history = this.learningHistory.get(userId) || [];
    
    const weakPoints: string[] = [];
    const strongPoints: string[] = [];
    
    history.forEach(result => {
      if (result.correct) {
        strongPoints.push(`步骤${result.stepNumber}`);
      } else {
        weakPoints.push(`步骤${result.stepNumber}`);
      }
    });
    
    return {
      skillId,
      skillName: skill.name,
      currentLevel,
      weakPoints,
      strongPoints,
      recommendedReview: weakPoints.slice(0, 3),
      nextMilestone: this.getNextMilestone(currentLevel)
    };
  }

  /**
   * 处理学习结果
   */
  recordLearningResult(
    userId: string,
    skillId: string,
    stepNumber: number,
    correct: boolean
  ): LearningResult {
    let feedback: string;
    let encouragement: string;
    let abilityDelta: number;
    
    if (correct) {
      feedback = "回答正确！";
      encouragement = this.generateEncouragement(stepNumber);
      abilityDelta = 0.1;
    } else {
      feedback = "答案不太对哦，不过没关系，我们来一起看看。";
      encouragement = "别灰心，学习就是不断试错的过程～";
      abilityDelta = 0.02;
    }
    
    this.updateUserAbility(userId, skillId, abilityDelta);
    
    const result: LearningResult = {
      stepNumber,
      correct,
      feedback,
      encouragement,
      abilityDelta
    };
    
    const history = this.learningHistory.get(userId) || [];
    history.push(result);
    this.learningHistory.set(userId, history);
    
    HiLog.info(TAG, `记录学习结果: ${userId}/${skillId}/步骤${stepNumber}, 正确:${correct}`);
    return result;
  }

  /**
   * 获取所有技能列表
   */
  getSkillList(category?: SkillCategory): SkillEntity[] {
    if (category) {
      return SKILL_LIBRARY.filter(s => s.category === category);
    }
    return SKILL_LIBRARY;
  }

  /**
   * 获取技能分类名称
   */
  getSkillCategoryName(category: SkillCategory): string {
    const names: Record<SkillCategory, string> = {
      [SkillCategory.PROFESSIONAL]: '职业素养',
      [SkillCategory.OFFICE]: '办公技能',
      [SkillCategory.LIFE]: '生活技能',
      [SkillCategory.DIGITAL]: '数字技能'
    };
    return names[category] || '其他';
  }

  // ====================== 私有方法 ======================

  private classifyScene(text: string): TeachSceneType {
    if (text.includes('复习') || text.includes('再学') || text.includes('巩固')) {
      return TeachSceneType.REVIEW;
    }
    if (text.includes('练习') || text.includes('做题') || text.includes('测试')) {
      return TeachSceneType.PRACTICE;
    }
    if (text.includes('场景') || text.includes('怎么办') || text.includes('怎么回答')) {
      return TeachSceneType.SCENARIO_QA;
    }
    if (text.includes('教我') || text.includes('学') || text.includes('了解')) {
      return TeachSceneType.SKILL_LEARN;
    }
    if (text.includes('怎么') || text.includes('如何') || text.includes('？')) {
      return TeachSceneType.QUESTION;
    }
    return TeachSceneType.SKILL_LEARN;
  }

  private getSkillName(skillId: string | undefined): string | undefined {
    if (!skillId) return undefined;
    const skill = SKILL_LIBRARY.find(s => s.id === skillId);
    return skill?.name;
  }

  private getSkillCategory(skillId: string): SkillCategory | undefined {
    const skill = SKILL_LIBRARY.find(s => s.id === skillId);
    return skill?.category;
  }

  private getUserAbility(userId: string, skillId: string): AbilityLevel {
    const userAbil = this.userAbilities.get(userId);
    if (!userAbil) return AbilityLevel.ZERO;
    return userAbil.get(skillId) || AbilityLevel.ZERO;
  }

  private updateUserAbility(userId: string, skillId: string, delta: number): void {
    if (!this.userAbilities.has(userId)) {
      this.userAbilities.set(userId, new Map());
    }
    const userAbil = this.userAbilities.get(userId)!;
    const current = userAbil.get(skillId) || AbilityLevel.ZERO;
    const newLevel = Math.min(AbilityLevel.MASTER, current + delta);
    userAbil.set(skillId, newLevel);
  }

  private async loadUserAbilities(): Promise<void> {
    HiLog.info(TAG, "加载用户能力数据");
  }

  private generateLearningSteps(skill: SkillEntity, startLevel: AbilityLevel): LearningStep[] {
    return skill.steps.map(step => ({
      stepNumber: step.stepNumber,
      title: step.title,
      content: step.content,
      practiceType: PracticeType.OPERATION,
      difficulty: skill.difficulty,
      estimatedTime: step.estimatedTime,
      tip: step.keyPoint
    }));
  }

  private generatePractices(steps: LearningStep[]): Practice[] {
    return steps.map((step, idx) => ({
      id: `practice_${step.stepNumber}`,
      stepNumber: step.stepNumber,
      type: step.practiceType,
      question: this.generateQuestion(step),
      answer: '正确',
      hint: step.tip
    }));
  }

  private generateQuestion(step: LearningStep): string {
    switch (step.practiceType) {
      case PracticeType.MULTIPLE_CHOICE:
        return `关于"${step.title}"，以下说法正确的是？`;
      case PracticeType.FILL_BLANK:
        return `请简述"${step.title}"的关键操作步骤`;
      case PracticeType.OPERATION:
        return `请尝试${step.title}，然后告诉我你的操作结果`;
      case PracticeType.SCENARIO:
        return step.scenario ? `场景：${step.scenario}\n你会怎么应对？` : `谈谈"${step.title}"的实际应用`;
      default:
        return `谈谈你对"${step.title}"的理解`;
    }
  }

  private generateEncouragement(stepNumber: number): string {
    const encouragements = [
      '太棒了！继续保持～',
      '你学得真快！',
      '太厉害了，一步一步来，你行的！',
      '很好！继续加油！',
      '学无止境，你已经迈出了重要的一步！'
    ];
    return encouragements[stepNumber % encouragements.length];
  }

  private getNextMilestone(level: AbilityLevel): string {
    const milestones: Record<number, string> = {
      [AbilityLevel.ZERO]: '完成第一个学习步骤',
      [AbilityLevel.BEGINNER]: '掌握基础操作',
      [AbilityLevel.BASIC]: '能够独立完成简单任务',
      [AbilityLevel.INTERMEDIATE]: '熟练应对日常使用',
      [AbilityLevel.ADVANCED]: '成为高手',
      [AbilityLevel.MASTER]: '精通此技能'
    };
    return milestones[level] || '继续学习';
  }

  // ==================== 融合 GenerateSkillUseCase 的方法 ====================

  /**
   * 解析用户需求（融合 GenerateSkillUseCase）
   */
  private parseUserRequest(userRequest: string): {
    name: string;
    category: SkillCategory;
    difficulty: SkillDifficulty;
    prerequisites: string[];
    realWorldScenes: string[];
    tags: string[];
  } {
    const lowerRequest = userRequest.toLowerCase();
    
    let category = SkillCategory.LIFE;
    if (lowerRequest.includes('excel') || lowerRequest.includes('word') || lowerRequest.includes('ppt')) {
      category = SkillCategory.OFFICE;
    } else if (lowerRequest.includes('沟通') || lowerRequest.includes('时间') || lowerRequest.includes('礼仪') || lowerRequest.includes('简历') || lowerRequest.includes('邮件') || lowerRequest.includes('协作') || lowerRequest.includes('问题')) {
      category = SkillCategory.PROFESSIONAL;
    } else if (lowerRequest.includes('鸿蒙') || lowerRequest.includes('设备') || lowerRequest.includes('安全')) {
      category = SkillCategory.DIGITAL;
    }
    
    let difficulty = SkillDifficulty.BEGINNER;
    if (lowerRequest.includes('高级') || lowerRequest.includes('深入')) {
      difficulty = SkillDifficulty.ADVANCED;
    } else if (lowerRequest.includes('进阶')) {
      difficulty = SkillDifficulty.INTERMEDIATE;
    }
    
    const name = this.extractSkillName(userRequest);
    
    return {
      name,
      category,
      difficulty,
      prerequisites: [],
      realWorldScenes: [name],
      tags: [category],
    };
  }

  /**
   * 提取技能名称
   */
  private extractSkillName(request: string): string {
    if (request.includes('Excel')) return 'Excel 基础';
    if (request.includes('微信')) return '微信使用';
    if (request.includes('鸿蒙')) return '鸿蒙设备协同';
    if (request.includes('沟通')) return '沟通技巧基础';
    if (request.includes('时间管理')) return '时间管理';
    if (request.includes('简历') || request.includes('面试')) return '简历与面试';
    return '生活技能';
  }

  /**
   * 生成技能步骤
   */
  private generateSkillSteps(skillInfo: any): SkillStep[] {
    if (skillInfo.name === 'Excel 基础') {
      return [
        { stepNumber: 1, title: '认识 Excel 界面', content: 'Excel 是一个表格软件，由行和列组成。每一格叫做"单元格"。', keyPoint: '行是横的（1,2,3...），列是竖的（A,B,C...）', estimatedTime: 5 },
        { stepNumber: 2, title: '单元格操作', content: '点击单元格就能输入内容，输入完按回车确认。', keyPoint: '双击单元格可以直接编辑', estimatedTime: 8 },
        { stepNumber: 3, title: '简单公式', content: '公式用等号"="开头。比如"=A1+B1"就是把 A1 和 B1 的数加起来。', keyPoint: '公式要用等号开头，否则会当作文本', estimatedTime: 10 },
        { stepNumber: 4, title: '格式设置', content: '可以设置单元格的字体、颜色、边框。', keyPoint: '选中后右键设置单元格格式', estimatedTime: 5 },
      ];
    }
    
    if (skillInfo.name === '微信使用') {
      return [
        { stepNumber: 1, title: '添加好友', content: '点击右上角"+"号，选择"添加朋友"。可以扫码添加、搜索手机号添加。', keyPoint: '扫码是最快的方式', estimatedTime: 5 },
        { stepNumber: 2, title: '发送消息', content: '在聊天框输入文字，点击发送按钮或按回车。', keyPoint: '2 分钟内可撤回', estimatedTime: 3 },
        { stepNumber: 3, title: '发朋友圈', content: '点击朋友圈入口，点击右上角相机发布。', keyPoint: '可以设置谁可以看', estimatedTime: 5 },
        { stepNumber: 4, title: '使用支付', content: '我->支付，可以付款、收款、缴费。', keyPoint: '支付密码要保密', estimatedTime: 8 },
      ];
    }
    
    return [
      { stepNumber: 1, title: '基础概念', content: '学习基础概念和术语', keyPoint: '理解核心概念', estimatedTime: 10 },
      { stepNumber: 2, title: '基础操作', content: '学习基础操作方法', keyPoint: '动手练习', estimatedTime: 15 },
      { stepNumber: 3, title: '实践应用', content: '实际应用场景练习', keyPoint: '学以致用', estimatedTime: 20 },
    ];
  }
}

/**
 * ============================================================================
 * 双角色互动引擎 - DualRoleEngine
 * 核心差异化：自适应双角色互动引擎
 * 
 * v2.0 重构：
 * - 新增职业素养对话库（沟通/时间管理/简历面试）
 * - 新增场景化练习
 * - 对话模板化（减少硬编码）
 * 
 * 两种模式：
 * - 导师模式 (TeacherMode)：讲解概念，温柔鼓励
 * - 陪练模式 (PracticeMode)：出题练习，即时反馈
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

const TAG = 'DualRoleEngine';

/**
 * 角色模式
 */
export enum RoleMode {
  TEACHER = 'teacher',    // 导师模式
  PRACTICE = 'practice'    // 陪练模式
}

/**
 * 对话节点类型
 */
export enum DialogNodeType {
  GREETING = 'greeting',
  CONCEPT_EXPLAIN = 'concept_explain',
  EXAMPLE_SHOW = 'example_show',
  PRACTICE_INTRO = 'practice_intro',
  PRACTICE_QUESTION = 'practice_question',
  FEEDBACK_CORRECT = 'feedback_correct',
  FEEDBACK_INCORRECT = 'feedback_incorrect',
  HINT_PROVIDE = 'hint_provide',
  ENCOURAGEMENT = 'encouragement',
  TRANSITION = 'transition',
  SUMMARY = 'summary',
  SCENARIO_INTRO = 'scenario_intro',      // 场景引入（新增）
  SCENARIO_ROLEPLAY = 'scenario_roleplay'  // 场景角色扮演（新增）
}

/**
 * 对话节点
 */
export interface DialogNode {
  id: string;
  type: DialogNodeType;
  content: string;
  suggestions?: string[];
  nextAuto?: string;
  nextByUser?: Record<string, string>;
}

/**
 * 角色状态
 */
export interface RoleState {
  mode: RoleMode;
  currentStep: number;
  totalSteps: number;
  correctCount: number;
  hintCount: number;
  attempts: number;
  currentNodeId: string;
}

/**
 * 对话上下文
 */
export interface ConversationContext {
  userId: string;
  skillId: string;
  skillName: string;
  roleState: RoleState;
  conversationHistory: DialogNode[];
  lastPracticeResult?: 'correct' | 'incorrect' | 'hint_used';
}

/**
 * 温馨文案模板
 */
const WARM_TEMPLATES = {
  greeting: [
    '大家好，我是你们的学习小助手！今天我们来一起学习{name}～',
    '{name}学习时间到啦！准备好了吗？让我们开始吧！',
    '嗨！欢迎来到{name}课堂，我会一直陪着你哦～'
  ],
  concept_explain: [
    '首先，让我来给你讲解一下：{content}',
    '我们来了解一下：{content}',
    '{content}，这是今天的重点哦～'
  ],
  example_show: [
    '举个例子：{example}',
    '比如这样：{example}',
    '看这个例子：{example}'
  ],
  practice_intro: [
    '好啦，讲解完了，我们来做个小练习试试？',
    '学得怎么样？来做道题检验一下吧！',
    '来挑战一下！看看你学会了没～'
  ],
  encouragement: [
    '太棒了！你学得真快！继续保持～',
    '回答正确！你的学习能力很强！',
    '完全正确！继续保持这个节奏～'
  ],
  hint_warm: [
    '别着急，慢慢想想看～提示一下：{hint}',
    '没关系的，我们一起想想。提示：{hint}',
    '提示来啦：{hint}。相信自己！'
  ],
  transition_teacher: [
    '好，让我们继续下一部分～',
    '准备好了吗？我们继续深入学习～',
    '休息一下，接下来会更精彩哦～'
  ],
  transition_practice: [
    '好啦，练习时间到！来试试这道题～',
    '准备好了吗？这是今天的挑战哦！',
    '学以致用的时候到啦！开始吧～'
  ]
};

/**
 * 对话模板生成器（新增）
 * 减少硬编码，通过模板生成对话
 */
class DialogTemplateGenerator {
  /**
   * 生成技能对话
   */
  generateSkillDialog(skillId: string, skillName: string, steps: { title: string; content: string; tip: string }[]): DialogNode[] {
    const dialogs: DialogNode[] = [];
    const prefix = skillId;
    
    // 问候
    dialogs.push({
      id: `${prefix}_greeting`,
      type: DialogNodeType.GREETING,
      content: `欢迎来到${skillName}学习课堂！今天我们来一起学习${skillName}～`,
      nextAuto: `${prefix}_step_1`
    });
    
    // 每个步骤
    steps.forEach((step, idx) => {
      const stepNum = idx + 1;
      const stepId = `${prefix}_step_${stepNum}`;
      
      // 概念讲解
      dialogs.push({
        id: stepId,
        type: DialogNodeType.CONCEPT_EXPLAIN,
        content: step.content,
        nextAuto: `${prefix}_practice_${stepNum}`
      });
      
      // 练习引入
      dialogs.push({
        id: `${prefix}_practice_${stepNum}`,
        type: DialogNodeType.PRACTICE_INTRO,
        content: `关于"${step.title}"，来做个练习试试？`,
        nextAuto: `${prefix}_question_${stepNum}`
      });
      
      // 练习题
      dialogs.push({
        id: `${prefix}_question_${stepNum}`,
        type: DialogNodeType.PRACTICE_QUESTION,
        content: `请简述"${step.title}"的关键要点`,
        suggestions: ['明白了', '不太清楚', '需要提示'],
        nextByUser: {
          '明白了': `${prefix}_correct_${stepNum}`,
          '不太清楚': `${prefix}_incorrect_${stepNum}`,
          '需要提示': `${prefix}_hint_${stepNum}`
        }
      });
      
      // 正确反馈
      dialogs.push({
        id: `${prefix}_correct_${stepNum}`,
        type: DialogNodeType.FEEDBACK_CORRECT,
        content: `🎉 太棒了！${step.title}你掌握了！${step.tip ? '记住：' + step.tip : ''}`,
        nextAuto: stepNum < steps.length ? `${prefix}_transition_${stepNum}` : `${prefix}_summary`
      });
      
      // 错误反馈
      dialogs.push({
        id: `${prefix}_incorrect_${stepNum}`,
        type: DialogNodeType.FEEDBACK_INCORRECT,
        content: `不太对哦～让我再解释一下：${step.content}`,
        nextAuto: `${prefix}_hint_${stepNum}`
      });
      
      // 提示
      dialogs.push({
        id: `${prefix}_hint_${stepNum}`,
        type: DialogNodeType.HINT_PROVIDE,
        content: step.tip ? `提示：${step.tip}` : '想想我们刚才讲的内容～',
        nextAuto: `${prefix}_question_${stepNum}_retry`
      });
      
      // 过渡
      if (stepNum < steps.length) {
        dialogs.push({
          id: `${prefix}_transition_${stepNum}`,
          type: DialogNodeType.TRANSITION,
          content: `很好！第${stepNum}步完成啦～准备好继续了吗？`,
          nextAuto: `${prefix}_step_${stepNum + 1}`
        });
      }
    });
    
    // 总结
    dialogs.push({
      id: `${prefix}_summary`,
      type: DialogNodeType.SUMMARY,
      content: `太棒了！${skillName}的所有步骤都完成了！你学得很快，继续保持～`,
    });
    
    return dialogs;
  }

  /**
   * 生成场景对话（新增）
   */
  generateScenarioDialog(scenario: { name: string; context: string; tips: string[] }): DialogNode[] {
    const dialogs: DialogNode[] = [];
    const prefix = `scenario_${scenario.name.replace(/\s/g, '_')}`;
    
    // 场景引入
    dialogs.push({
      id: `${prefix}_intro`,
      type: DialogNodeType.SCENARIO_INTRO,
      content: `场景：${scenario.context}`,
      nextAuto: `${prefix}_roleplay`
    });
    
    // 角色扮演
    dialogs.push({
      id: `${prefix}_roleplay`,
      type: DialogNodeType.SCENARIO_ROLEPLAY,
      content: `如果是你，你会怎么说？\n\n💡 提示：${scenario.tips.join(' | ')}`,
      suggestions: ['我来试试', '先看示例', '需要帮助'],
    });
    
    return dialogs;
  }
}

/**
 * 双角色互动引擎
 */
export class DualRoleEngine {
  private static instance: DualRoleEngine | null = null;

  // 对话题库
  private dialogLibrary: Map<string, DialogNode[]> = new Map();
  
  // 当前对话状态
  private activeSessions: Map<string, ConversationContext> = new Map();
  
  // 对话模板生成器（新增）
  private templateGenerator: DialogTemplateGenerator;

  static getInstance(): DualRoleEngine {
    if (!DualRoleEngine.instance) {
      DualRoleEngine.instance = new DualRoleEngine();
    }
    return DualRoleEngine.instance;
  }

  private constructor() {
    HiLog.info(TAG, '双角色互动引擎初始化 v2.0');
    this.templateGenerator = new DialogTemplateGenerator();
    this.initDialogLibrary();
  }

  /**
   * 初始化对话库
   */
  private initDialogLibrary(): void {
    // ==================== 职业素养对话 ====================

    // 沟通技巧基础
    this.dialogLibrary.set('comm_basic', this.templateGenerator.generateSkillDialog(
      'comm_basic',
      '沟通技巧基础',
      [
        { title: '倾听的艺术', content: '有效沟通的第一步是倾听。不要急着说话，先听对方说完，用眼神和点头表示你在听。', tip: '倾听不是沉默，是主动理解' },
        { title: '清晰表达', content: '用"我"开头表达感受，比如"我觉得这个项目有点紧"，而不是"你给的 deadline 太紧了"。', tip: '避免指责性语言' },
        { title: '反馈技巧', content: '反馈要具体、及时、建设性。说"这个方案的第三部分数据不够"比"这个方案不行"好得多。', tip: 'SBI 法则：Situation-Behavior-Impact' },
        { title: '非语言沟通', content: '肢体语言、表情、语调占沟通效果的 90%。保持开放姿态，避免交叉双臂。', tip: '注意自己的微表情' },
      ]
    ));

    // 时间管理
    this.dialogLibrary.set('time_mgmt', this.templateGenerator.generateSkillDialog(
      'time_mgmt',
      '时间管理',
      [
        { title: '四象限法则', content: '把任务分为：重要且紧急、重要不紧急、紧急不重要、不紧急不重要。优先做重要不紧急的事。', tip: '多数人陷在紧急事务里' },
        { title: '番茄工作法', content: '25 分钟专注工作 + 5 分钟休息。一个番茄钟内不做其他事。4 个番茄钟后休息 15-30 分钟。', tip: '手机开勿扰模式' },
        { title: '优先级排序', content: '用 MoSCoW 法则：Must have（必须有）、Should have（应该有）、Could have（可以有）、Won\'t have（这次没有）。', tip: 'Must 不超过 3 个' },
        { title: '时间块管理', content: '把一天分成时间块，每个时间块专注一类事。比如上午写代码、下午开会、晚上学习。', tip: '减少任务切换成本' },
      ]
    ));

    // 简历与面试
    this.dialogLibrary.set('resume_interview', this.templateGenerator.generateSkillDialog(
      'resume_interview',
      '简历与面试',
      [
        { title: '简历结构', content: '简历核心：个人信息 + 教育背景 + 工作经历 + 项目经验 + 技能。控制在 1-2 页。', tip: '量化成果，用数据说话' },
        { title: 'STAR 法则', content: '描述经历用 STAR：Situation（情境）→ Task（任务）→ Action（行动）→ Result（结果）。', tip: 'Result 要用数据量化' },
        { title: '常见问题', content: '高频问题：自我介绍、为什么离职、你的优缺点、期望薪资。提前准备，不要临场发挥。', tip: '缺点要说可改进的' },
        { title: '谈薪技巧', content: '不要先报价。了解市场行情，给出范围而不是具体数字。"我期望 15-20K，具体看整体 package"。', tip: '不要说"无所谓"' },
      ]
    ));

    // ==================== 办公技能对话 ====================

    // Excel 基础
    this.dialogLibrary.set('excel_basic', this.templateGenerator.generateSkillDialog(
      'excel_basic',
      'Excel 基础',
      [
        { title: '认识 Excel 界面', content: 'Excel 是一个表格软件，就像一张大型格子纸。它由行（横的）和列（竖的）组成。每个格子叫做"单元格"。', tip: '行是横的，列是竖的' },
        { title: '单元格操作', content: '比如，"A1"表示第 A 列第 1 行，就像小区的门牌号，每个单元格都有自己的唯一地址。', tip: '先列后行' },
        { title: '简单公式', content: '用=开头写公式，比如=SUM(A1:A10) 就是求和。', tip: '公式要用等号开头' },
        { title: '格式设置', content: '选中后右键设置单元格格式，可以改字体、颜色、边框。', tip: '格式刷很方便' },
      ]
    ));

    // ==================== 生活技能对话 ====================

    // 微信基础
    this.dialogLibrary.set('wechat_basic', this.templateGenerator.generateSkillDialog(
      'wechat_basic',
      '微信使用',
      [
        { title: '添加好友', content: '点击右上角+号，选择添加朋友，可以搜索手机号或扫码。', tip: '扫码最快' },
        { title: '发送消息', content: '在聊天框输入文字，点击发送。长按可以撤回 2 分钟内的消息。', tip: '长按可撤回' },
        { title: '发朋友圈', content: '点击发现→朋友圈，点击右上角相机图标发布。', tip: '可以设置谁可以看' },
        { title: '使用支付', content: '我→支付，可以付款、收款、缴费。', tip: '支付密码要记牢' },
      ]
    ));
  }

  /**
   * 开始对话
   */
  startConversation(userId: string, skillId: string, skillName: string): ConversationContext {
    HiLog.info(TAG, `开始对话: ${userId}/${skillId}`);
    
    const roleState: RoleState = {
      mode: RoleMode.TEACHER,
      currentStep: 1,
      totalSteps: 4,
      correctCount: 0,
      hintCount: 0,
      attempts: 0,
      currentNodeId: `${skillId}_greeting`
    };

    const context: ConversationContext = {
      userId,
      skillId,
      skillName,
      roleState,
      conversationHistory: []
    };

    this.activeSessions.set(userId, context);
    return context;
  }

  /**
   * 获取当前对话内容
   */
  getCurrentDialog(userId: string): DialogNode | null {
    const context = this.activeSessions.get(userId);
    if (!context) return null;
    
    const dialogs = this.dialogLibrary.get(context.skillId);
    if (!dialogs) return null;
    
    return dialogs.find(d => d.id === context.roleState.currentNodeId) || null;
  }

  /**
   * 处理用户输入
   */
  processUserInput(userId: string, userInput: string): DialogNode | null {
    HiLog.info(TAG, `处理输入: ${userId}, ${userInput}`);
    
    const context = this.activeSessions.get(userId);
    if (!context) return null;
    
    const currentDialog = this.getCurrentDialog(userId);
    if (!currentDialog) return null;
    
    // 根据当前节点类型处理
    if (currentDialog.type === DialogNodeType.PRACTICE_QUESTION ||
        currentDialog.type === DialogNodeType.SCENARIO_ROLEPLAY) {
      const normalizedInput = userInput.trim();
      const nextNodeId = currentDialog.nextByUser?.[normalizedInput];
      
      if (nextNodeId) {
        context.roleState.currentNodeId = nextNodeId;
        context.roleState.attempts++;
        
        if (nextNodeId.includes('correct')) {
          context.roleState.correctCount++;
          context.lastPracticeResult = 'correct';
        } else if (nextNodeId.includes('hint')) {
          context.roleState.hintCount++;
          context.lastPracticeResult = 'hint_used';
        } else {
          context.lastPracticeResult = 'incorrect';
        }
        
        return this.getCurrentDialog(userId);
      }
    }
    
    // 其他情况，自动转到下一个节点
    if (currentDialog.nextAuto) {
      context.roleState.currentNodeId = currentDialog.nextAuto;
      return this.getCurrentDialog(userId);
    }
    
    return null;
  }

  /**
   * 自动推进对话
   */
  advanceDialog(userId: string): DialogNode | null {
    const context = this.activeSessions.get(userId);
    if (!context) return null;
    
    const currentDialog = this.getCurrentDialog(userId);
    if (!currentDialog) return null;
    
    if (currentDialog.nextAuto) {
      context.roleState.currentNodeId = currentDialog.nextAuto;
      return this.getCurrentDialog(userId);
    }
    
    return null;
  }

  /**
   * 切换角色模式
   */
  switchMode(userId: string, newMode: RoleMode): void {
    const context = this.activeSessions.get(userId);
    if (!context) return;
    
    HiLog.info(TAG, `切换模式: ${userId}, ${context.roleState.mode} -> ${newMode}`);
    context.roleState.mode = newMode;
    
    if (newMode === RoleMode.PRACTICE) {
      context.roleState.currentNodeId = `${context.skillId}_practice_intro_${context.roleState.currentStep}`;
    } else {
      context.roleState.currentNodeId = `${context.skillId}_step_${context.roleState.currentStep + 1}_intro`;
    }
  }

  /**
   * 获取角色状态
   */
  getRoleState(userId: string): RoleState | null {
    const context = this.activeSessions.get(userId);
    return context?.roleState || null;
  }

  /**
   * 获取学习统计
   */
  getLearningStats(userId: string): { accuracy: number; hintsUsed: number; step: number; totalSteps: number } | null {
    const context = this.activeSessions.get(userId);
    if (!context) return null;
    
    const { correctCount, hintCount, attempts, currentStep, totalSteps } = context.roleState;
    const accuracy = attempts > 0 ? Math.round((correctCount / attempts) * 100) : 0;
    
    return {
      accuracy,
      hintsUsed: hintCount,
      step: currentStep,
      totalSteps
    };
  }

  /**
   * 结束对话
   */
  endConversation(userId: string): void {
    const context = this.activeSessions.get(userId);
    if (!context) return;
    
    HiLog.info(TAG, `结束对话: ${userId}`);
    this.activeSessions.delete(userId);
  }

  /**
   * 生成温馨消息
   */
  generateWarmMessage(type: keyof typeof WARM_TEMPLATES, params: Record<string, string>): string {
    const templates = WARM_TEMPLATES[type];
    if (!templates || templates.length === 0) {
      return '加油！';
    }
    
    let message = templates[Math.floor(Math.random() * templates.length)];
    
    for (const [key, value] of Object.entries(params)) {
      message = message.replace(`{${key}}`, value);
    }
    
    return message;
  }

  /**
   * 获取建议回复
   */
  getSuggestions(userId: string): string[] {
    const currentDialog = this.getCurrentDialog(userId);
    return currentDialog?.suggestions || [];
  }

  /**
   * 判断是否进入练习模式
   */
  shouldEnterPracticeMode(userId: string): boolean {
    const context = this.activeSessions.get(userId);
    if (!context) return false;
    
    const currentDialog = this.getCurrentDialog(userId);
    if (currentDialog?.type === DialogNodeType.PRACTICE_INTRO) {
      return true;
    }
    
    return false;
  }

  /**
   * 判断是否完成学习
   */
  isLearningComplete(userId: string): boolean {
    const context = this.activeSessions.get(userId);
    if (!context) return false;
    
    return context.roleState.currentStep >= context.roleState.totalSteps;
  }
}

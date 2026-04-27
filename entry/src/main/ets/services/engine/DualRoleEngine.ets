/**
 * ============================================================================
 * 双角色互动引擎 - DualRoleEngine
 * 核心差异化：自适应双角色互动引擎
 * 
 * 两种模式：
 * - 导师模式 (TeacherMode)：讲解概念，温柔鼓励
 * - 陪练模式 (PracticeMode)：出题练习，即时反馈
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

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
  GREETING = 'greeting',           // 问候
  CONCEPT_EXPLAIN = 'concept_explain',  // 概念讲解
  EXAMPLE_SHOW = 'example_show',   // 例子展示
  PRACTICE_INTRO = 'practice_intro',  // 练习引入
  PRACTICE_QUESTION = 'practice_question',  // 练习题
  FEEDBACK_CORRECT = 'feedback_correct',  // 正确反馈
  FEEDBACK_INCORRECT = 'feedback_incorrect',  // 错误反馈
  HINT_PROVIDE = 'hint_provide',   // 给出提示
  ENCOURAGEMENT = 'encouragement', // 鼓励
  TRANSITION = 'transition',        // 过渡
  SUMMARY = 'summary'             // 总结
}

/**
 * 对话节点
 */
export interface DialogNode {
  id: string;
  type: DialogNodeType;
  content: string;
  suggestions?: string[];  // 用户可选择的回复建议
  nextAuto?: string;       // 自动下一个节点
  nextByUser?: Record<string, string>;  // 用户选择对应的下一个节点
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
 * 温馨文案服务（简化集成）
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
 * 双角色互动引擎
 */
export class DualRoleEngine {
  private static instance: DualRoleEngine | null = null;

  // 对话题库
  private dialogLibrary: Map<string, DialogNode[]> = new Map();
  
  // 当前对话状态
  private activeSessions: Map<string, ConversationContext> = new Map();

  static getInstance(): DualRoleEngine {
    if (!DualRoleEngine.instance) {
      DualRoleEngine.instance = new DualRoleEngine();
    }
    return DualRoleEngine.instance;
  }

  private constructor() {
    HiLog.info("DualRoleEngine", "双角色互动引擎初始化");
    this.initDialogLibrary();
  }

  /**
   * 初始化对话库
   * 预置常见对话模板
   */
  private initDialogLibrary(): void {
    // Excel基础对话
    const excelBasicDialogs: DialogNode[] = [
      {
        id: 'excel_greeting',
        type: DialogNodeType.GREETING,
        content: '欢迎来到Excel学习课堂！我是你的学习小助手，今天我们来学习Excel基础～',
        nextAuto: 'excel_concept_1'
      },
      {
        id: 'excel_concept_1',
        type: DialogNodeType.CONCEPT_EXPLAIN,
        content: 'Excel是一个表格软件，就像一张大型格子纸。它由行（横的）和列（竖的）组成。每个格子叫做"单元格"。',
        nextAuto: 'excel_example_1'
      },
      {
        id: 'excel_example_1',
        type: DialogNodeType.EXAMPLE_SHOW,
        content: '比如，"A1"表示第A列第1行，就像小区的门牌号，每个单元格都有自己的唯一地址。',
        nextAuto: 'excel_practice_intro_1'
      },
      {
        id: 'excel_practice_intro_1',
        type: DialogNodeType.PRACTICE_INTRO,
        content: '好啦，讲解完了，我们来做个小练习试试？',
        nextAuto: 'excel_question_1'
      },
      {
        id: 'excel_question_1',
        type: DialogNodeType.PRACTICE_QUESTION,
        content: '选择题：Excel中的A1表示什么？\nA. 第1行A列\nB. 第A列第1行\nC. 第1列第A行\nD. 不确定',
        suggestions: ['A', 'B', 'C', 'D'],
        nextByUser: {
          'B': 'excel_correct_1',
          'A': 'excel_incorrect_1',
          'C': 'excel_incorrect_1',
          'D': 'excel_incorrect_1'
        }
      },
      {
        id: 'excel_correct_1',
        type: DialogNodeType.FEEDBACK_CORRECT,
        content: '🎉 回答正确！完全正确！A1确实表示第A列第1行。你的理解力很强！',
        nextAuto: 'excel_transition_1'
      },
      {
        id: 'excel_incorrect_1',
        type: DialogNodeType.FEEDBACK_INCORRECT,
        content: '不太对哦～但没关系！让我再解释一下：Excel的规则是"先列后行"，所以A1是第A列第1行。记住这个规律就好啦！',
        nextAuto: 'excel_hint_1'
      },
      {
        id: 'excel_hint_1',
        type: DialogNodeType.HINT_PROVIDE,
        content: '提示：Excel就像坐标，先说列（A），后说行（1）。就像数学里的坐标（x,y）一样～',
        nextAuto: 'excel_question_1_retry'
      },
      {
        id: 'excel_question_1_retry',
        type: DialogNodeType.PRACTICE_QUESTION,
        content: '再来一次！A1表示什么？\nA. 第A列第1行\nB. 第1行A列',
        suggestions: ['A', 'B'],
        nextByUser: {
          'A': 'excel_correct_1_retry',
          'B': 'excel_incorrect_1_retry'
        }
      },
      {
        id: 'excel_correct_1_retry',
        type: DialogNodeType.FEEDBACK_CORRECT,
        content: '👍 这次正确了！学习就是不断尝试的过程，你做得很好！',
        nextAuto: 'excel_transition_1'
      },
      {
        id: 'excel_incorrect_1_retry',
        type: DialogNodeType.ENCOURAGEMENT,
        content: '别灰心！记住：Excel是"先列后行"。A1就是第A列第1行。这个规则会贯穿整个Excel学习哦～',
        nextAuto: 'excel_transition_1'
      },
      {
        id: 'excel_transition_1',
        type: DialogNodeType.TRANSITION,
        content: '很好！第一步完成啦～准备好继续下一节了吗？',
        nextAuto: 'excel_step_2_intro'
      }
    ];

    // 微信基础对话
    const wechatBasicDialogs: DialogNode[] = [
      {
        id: 'wechat_greeting',
        type: DialogNodeType.GREETING,
        content: '欢迎来到微信学习课堂！今天我们来一起学习微信的基本功能～',
        nextAuto: 'wechat_concept_1'
      },
      {
        id: 'wechat_concept_1',
        type: DialogNodeType.CONCEPT_EXPLAIN,
        content: '微信是目前最常用的社交软件之一。我们可以用它聊天、发朋友圈、支付等等。',
        nextAuto: 'wechat_practice_intro_1'
      },
      {
        id: 'wechat_practice_intro_1',
        type: DialogNodeType.PRACTICE_INTRO,
        content: '好啦，我们来做个小练习～',
        nextAuto: 'wechat_question_1'
      },
      {
        id: 'wechat_question_1',
        type: DialogNodeType.PRACTICE_QUESTION,
        content: '选择题：微信支付的入口在哪里？\nA. 通讯录\nB. 发现\nC. 我->支付\nD. 朋友圈',
        suggestions: ['A', 'B', 'C', 'D'],
        nextByUser: {
          'C': 'wechat_correct_1',
          'A': 'wechat_incorrect_1',
          'B': 'wechat_incorrect_1',
          'D': 'wechat_incorrect_1'
        }
      },
      {
        id: 'wechat_correct_1',
        type: DialogNodeType.FEEDBACK_CORRECT,
        content: '🎉 正确！微信支付在"我"->"支付"里面，很棒！',
        nextAuto: 'wechat_transition_1'
      },
      {
        id: 'wechat_incorrect_1',
        type: DialogNodeType.FEEDBACK_INCORRECT,
        content: '不太对哦～微信支付在"我"页面的"支付"入口里，不是"发现"也不是"通讯录"。',
        nextAuto: 'wechat_question_1_retry'
      },
      {
        id: 'wechat_question_1_retry',
        type: DialogNodeType.PRACTICE_QUESTION,
        content: '再来一次！微信支付在哪里？\nA. 我->支付\nB. 发现->朋友圈',
        suggestions: ['A', 'B'],
        nextByUser: {
          'A': 'wechat_correct_1_retry',
          'B': 'wechat_incorrect_1_retry'
        }
      },
      {
        id: 'wechat_correct_1_retry',
        type: DialogNodeType.FEEDBACK_CORRECT,
        content: '👍 这次正确了！微信支付在"我"的页面里，继续加油～',
        nextAuto: 'wechat_transition_1'
      },
      {
        id: 'wechat_incorrect_1_retry',
        type: DialogNodeType.ENCOURAGEMENT,
        content: '别灰心！记住：微信支付在"我"->"支付"。这个入口以后会经常用到的～',
        nextAuto: 'wechat_transition_1'
      },
      {
        id: 'wechat_transition_1',
        type: DialogNodeType.TRANSITION,
        content: '很好！准备好继续下一节了吗？',
        nextAuto: 'wechat_step_2_intro'
      }
    ];

    this.dialogLibrary.set('excel_basic', excelBasicDialogs);
    this.dialogLibrary.set('wechat_basic', wechatBasicDialogs);
  }

  /**
   * 开始对话
   */
  startConversation(userId: string, skillId: string, skillName: string): ConversationContext {
    HiLog.info("DualRoleEngine", `开始对话: ${userId}/${skillId}`);
    
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
    HiLog.info("DualRoleEngine", `处理输入: ${userId}, ${userInput}`);
    
    const context = this.activeSessions.get(userId);
    if (!context) return null;
    
    const currentDialog = this.getCurrentDialog(userId);
    if (!currentDialog) return null;
    
    // 根据当前节点类型处理
    if (currentDialog.type === DialogNodeType.PRACTICE_QUESTION) {
      // 用户在回答问题
      const normalizedInput = userInput.trim().toUpperCase();
      const nextNodeId = currentDialog.nextByUser?.[normalizedInput];
      
      if (nextNodeId) {
        context.roleState.currentNodeId = nextNodeId;
        context.roleState.attempts++;
        
        // 判断对错
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
    
    HiLog.info("DualRoleEngine", `切换模式: ${userId}, ${context.roleState.mode} -> ${newMode}`);
    context.roleState.mode = newMode;
    
    // 模式切换时给出过渡语
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
  getLearningStats(userId: string): { accuracy: number; hintsUsed: number; step: number } | null {
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
    
    HiLog.info("DualRoleEngine", `结束对话: ${userId}`);
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
    
    // 导师模式讲完一个概念后，自动进入练习
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

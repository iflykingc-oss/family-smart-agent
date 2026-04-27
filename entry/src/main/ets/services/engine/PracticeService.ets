/**
 * ============================================================================
 * 练习服务 - PracticeService
 * 负责生成练习、评估答案、提供提示
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

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
}

/**
 * 练习类型
 */
export enum PracticeType {
  MULTIPLE_CHOICE = 'multiple_choice',
  FILL_BLANK = 'fill_blank',
  OPERATION = 'operation',
  DISCUSSION = 'discussion'
}

/**
 * 评估结果
 */
export interface EvaluationResult {
  correct: boolean;
  score: number;
  feedback: string;
  explanation?: string;
  nextStep?: string;
}

/**
 * 练习服务
 */
export class PracticeService {
  private static instance: PracticeService | null = null;

  static getInstance(): PracticeService {
    if (!PracticeService.instance) {
      PracticeService.instance = new PracticeService();
    }
    return PracticeService.instance;
  }

  private constructor() {}

  /**
   * 生成练习
   * 根据步骤生成对应的练习题
   */
  generate(stepNumber: number, type: PracticeType, topic: string): Practice {
    HiLog.info("PracticeService", `生成练习: 步骤${stepNumber}, 类型${type}, 主题${topic}`);
    
    const practiceTemplates = this.getPracticeTemplates(topic);
    const template = practiceTemplates.find(p => p.type === type) || practiceTemplates[0];

    const practice: Practice = {
      id: `practice_${Date.now()}`,
      stepNumber,
      type,
      question: template.question,
      options: template.options,
      answer: template.answer,
      hint: template.hint,
      explanation: template.explanation
    };

    return practice;
  }

  /**
   * 评估答案
   * 判断用户回答是否正确，并给出反馈
   */
  evaluate(practice: Practice, userAnswer: string): EvaluationResult {
    HiLog.info("PracticeService", `评估答案: ${practice.id}, 用户答案: ${userAnswer}`);
    
    const normalizedAnswer = userAnswer.trim().toUpperCase();
    const normalizedCorrect = practice.answer.toUpperCase();
    
    let correct = false;
    
    // 选择题判断
    if (practice.type === PracticeType.MULTIPLE_CHOICE) {
      correct = normalizedAnswer === normalizedCorrect;
    } else if (practice.type === PracticeType.FILL_BLANK || practice.type === PracticeType.OPERATION) {
      // 填空题/操作题，模糊匹配
      correct = normalizedAnswer.includes(normalizedCorrect) || 
                normalizedCorrect.includes(normalizedAnswer);
    } else {
      // 讨论题，给出引导性反馈
      correct = userAnswer.length > 10; // 有实质内容就算对
    }

    const result: EvaluationResult = {
      correct,
      score: correct ? 100 : 0,
      feedback: correct ? this.getCorrectFeedback() : this.getIncorrectFeedback(practice.hint),
      explanation: correct ? practice.explanation : undefined
    };

    return result;
  }

  /**
   * 给出提示
   * 根据尝试次数给出不同级别的提示
   */
  hint(practice: Practice, attempts: number): string {
    HiLog.info("PracticeService", `给出提示: ${practice.id}, 尝试次数: ${attempts}`);
    
    if (!practice.hint) {
      return '再想想，你可以的！';
    }

    // 第一、二次：给部分提示
    if (attempts === 1) {
      return `提示：${practice.hint.substring(0, Math.floor(practice.hint.length / 2))}...`;
    }
    
    // 第三次：给完整提示
    if (attempts === 2) {
      return `提示：${practice.hint}`;
    }

    // 更多次：给额外引导
    return `没关系，让我们一起想想：${practice.hint}。相信自己！`;
  }

  /**
   * 举一反三
   * 生成类似但不同的练习
   */
  generateSimilar(practice: Practice): Practice {
    const similarPractice: Practice = {
      ...practice,
      id: `practice_similar_${Date.now()}`,
      question: this.rephraseQuestion(practice.question)
    };

    return similarPractice;
  }

  /**
   * 获取正确反馈
   */
  private getCorrectFeedback(): string {
    const feedbacks = [
      '太棒了！完全正确！',
      '回答正确！继续保持～',
      '太厉害了！一击即中！',
      '正确！你学得真快！',
      '完全正确，太骄傲了！'
    ];
    return feedbacks[Math.floor(Math.random() * feedbacks.length)];
  }

  /**
   * 获取错误反馈
   */
  private getIncorrectFeedback(hint?: string): string {
    if (hint) {
      return `不太对哦，没关系！提示一下：${hint}。再试试？`;
    }
    return '不太对，别灰心！再想想，我们可以一起看看解析。';
  }

  /**
   * 改写问题
   */
  private rephraseQuestion(question: string): string {
    // 简单的同义替换
    return question
      .replace('以下', '下面')
      .replace('正确', '对的')
      .replace('错误', '不对');
  }

  /**
   * 获取练习模板
   */
  private getPracticeTemplates(topic: string): Partial<Practice>[] {
    const templates: Record<string, Partial<Practice>[]> = {
      'excel_cell': [
        {
          type: PracticeType.MULTIPLE_CHOICE,
          question: 'Excel中的A1表示什么？',
          options: ['第1行A列', '第A列第1行', '第1列第A行', '不确定'],
          answer: 'B',
          hint: 'Excel中先列后行',
          explanation: 'A1表示第A列第1行。Excel的单元格地址规则是：先列后行。'
        },
        {
          type: PracticeType.OPERATION,
          question: '请在Excel中任意单元格输入"你好"，然后告诉我你输入的是哪个单元格',
          answer: '任意',
          hint: '点击任意格子，输入文字，按回车',
          explanation: '输入内容后，单元格地址会显示在左上角。'
        }
      ],
      'excel_formula': [
        {
          type: PracticeType.FILL_BLANK,
          question: 'Excel公式用什么符号开头？',
          options: undefined,
          answer: '=',
          hint: '等号',
          explanation: 'Excel公式必须以等号"="开头，否则会被当作普通文本。'
        },
        {
          type: PracticeType.MULTIPLE_CHOICE,
          question: '哪个是求和公式？',
          options: ['=AVERAGE(A1:A10)', '=SUM(A1:A10)', '=COUNT(A1:A10)', '=MAX(A1:A10)'],
          answer: 'B',
          hint: 'SUM是求和',
          explanation: 'SUM是求和，AVERAGE是平均，COUNT是计数，MAX是最大值。'
        }
      ],
      'wechat_pay': [
        {
          type: PracticeType.MULTIPLE_CHOICE,
          question: '微信支付的入口在哪里？',
          options: ['通讯录', '发现', '我->支付', '朋友圈'],
          answer: 'C',
          hint: '在"我"的页面里',
          explanation: '微信支付在"我"->"支付"里。'
        },
        {
          type: PracticeType.MULTIPLE_CHOICE,
          question: '以下哪个是安全的支付习惯？',
          options: ['把支付密码告诉朋友', '在陌生链接里输入密码', '使用微信付款码支付', '随意点击陌生短信链接'],
          answer: 'C',
          hint: '官方渠道支付',
          explanation: '使用微信官方付款码是最安全的。不要把密码告诉任何人。'
        }
      ],
      'harmony_share': [
        {
          type: PracticeType.MULTIPLE_CHOICE,
          question: '鸿蒙协同的前提条件是什么？',
          options: ['同一WiFi', '同一华为账号', '同款设备', '靠近即可'],
          answer: 'B',
          hint: '账号统一',
          explanation: '鸿蒙协同需要设备登录同一个华为账号。'
        }
      ]
    };

    // 默认模板
    return templates[topic] || [
      {
        type: PracticeType.MULTIPLE_CHOICE,
        question: `关于"${topic}"，以下说法正确的是？`,
        options: ['A. 是这样', 'B. 应该是这样', 'C. 不太确定', 'D. 以上都不对'],
        answer: 'B',
        hint: '仔细想想看',
        explanation: '需要根据具体情况判断。'
      }
    ];
  }
}

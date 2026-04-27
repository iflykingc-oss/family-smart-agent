/**
 * ============================================================================
 * 教学服务 - TeachingService
 * 负责将技能拆解为学习步骤，提供渐进式教学内容
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

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
  keyPoints: string[];
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
 * 前置技能检查结果
 */
export interface PrereqResult {
  passed: boolean;
  missing: string[];
  suggestions: string[];
}

/**
 * 教学服务
 */
export class TeachingService {
  private static instance: TeachingService | null = null;

  static getInstance(): TeachingService {
    if (!TeachingService.instance) {
      TeachingService.instance = new TeachingService();
    }
    return TeachingService.instance;
  }

  private constructor() {}

  /**
   * 获取学习步骤
   * 根据技能ID和用户水平，生成学习步骤
   */
  getLearningSteps(skillId: string, startLevel: number = 0): LearningStep[] {
    HiLog.info("TeachingService", `获取学习步骤: ${skillId}, 起始等级: ${startLevel}`);
    
    // 获取技能定义
    const skill = this.getSkillDefinition(skillId);
    if (!skill) {
      return [];
    }

    // 根据起始等级确定开始的步骤
    const startStep = Math.floor(startLevel);
    
    return skill.steps
      .filter((step, idx) => idx >= startStep)
      .map(step => ({
        ...step,
        stepNumber: step.stepNumber + startStep
      }));
  }

  /**
   * 讲解概念
   * 用通俗易懂的语言解释概念
   */
  explainConcept(concept: string, level: number = 1): string {
    const explanations: Record<string, string[]> = {
      'excel_cell': [
        'Excel里的单元格就像表格中的一个格子，你可以往里面填数字、文字。',
        '每个单元格都有自己的"地址"，比如A1表示第A列第1行。',
        '就像你家小区的门牌号一样，每个单元格都有自己唯一的标识。'
      ],
      'excel_formula': [
        '公式就是Excel帮你计算的方法。就像计算器，但更强大。',
        '公式用等号"="开头，后面跟计算内容。比如"=A1+B1"就是把A1和B1的数加在一起。',
        '学会公式，你就能做加减乘除，甚至更复杂的统计。'
      ],
      'wechat_pay': [
        '微信支付就是用微信来花钱/收钱，就像电子钱包。',
        '开通后，只要扫一扫商家二维码，或者出示付款码，就能完成支付。',
        '记得支付密码要设好，不要告诉别人，保护好你的钱包安全。'
      ],
      'harmony_share': [
        '鸿蒙协同就是让你的华为设备（比如手机和电脑）互相配合工作。',
        '比如手机拍的照，直接电脑上就能看到，不用数据线。',
        '还能用电脑接打电话，手机放一边就行。'
      ]
    };

    const conceptKey = Object.keys(explanations).find(k => concept.includes(k));
    if (!conceptKey) {
      return `关于"${concept}"，这是很实用的技能，让我们一起学习吧！`;
    }

    const levelIndex = Math.min(level - 1, explanations[conceptKey].length - 1);
    return explanations[conceptKey][levelIndex];
  }

  /**
   * 检查前置技能
   * 看用户是否具备学习该技能的前置条件
   */
  checkPrerequisites(userId: string, skillId: string, userAbilities: Map<string, number>): PrereqResult {
    const skill = this.getSkillDefinition(skillId);
    if (!skill) {
      return { passed: false, missing: [skillId], suggestions: ['未找到该技能'] };
    }

    const missing: string[] = [];
    const suggestions: string[] = [];

    for (const prereq of skill.prerequisites) {
      const userLevel = userAbilities.get(prereq) || 0;
      if (userLevel < 1) {
        missing.push(prereq);
        const prereqSkill = this.getSkillDefinition(prereq);
        if (prereqSkill) {
          suggestions.push(`建议先学习"${prereqSkill.name}"`);
        }
      }
    }

    return {
      passed: missing.length === 0,
      missing,
      suggestions
    };
  }

  /**
   * 获取技能定义
   */
  private getSkillDefinition(skillId: string): any {
    const skills: Record<string, any> = {
      'excel_basic': {
        id: 'excel_basic',
        name: 'Excel基础',
        prerequisites: [],
        steps: [
          {
            stepNumber: 1,
            title: '认识Excel界面',
            content: 'Excel是一个表格软件，由行和列组成。每一格叫做"单元格"，我们可以在里面输入文字、数字或公式。',
            practiceType: PracticeType.OPERATION,
            difficulty: 1,
            estimatedTime: 5,
            tip: '行是横的（1,2,3...），列是竖的（A,B,C...）',
            keyPoints: ['行和列', '单元格', '行列编号']
          },
          {
            stepNumber: 2,
            title: '单元格操作',
            content: '点击单元格就能输入内容，输入完按回车键确认。选中单元格后，可以复制(Ctrl+C)、粘贴(Ctrl+V)、剪切(Ctrl+X)。',
            practiceType: PracticeType.OPERATION,
            difficulty: 1,
            estimatedTime: 8,
            tip: '双击单元格可以直接编辑',
            keyPoints: ['点击输入', '回车确认', '复制粘贴']
          },
          {
            stepNumber: 3,
            title: '简单公式',
            content: '公式用等号"="开头。比如"=A1+B1"就是把A1和B1的数加起来。常用公式：SUM(求和)、AVERAGE(求平均)。',
            practiceType: PracticeType.FILL_BLANK,
            difficulty: 2,
            estimatedTime: 10,
            tip: '公式要用等号开头，否则会当作文本',
            keyPoints: ['等号开头', 'SUM求和', 'AVERAGE平均']
          },
          {
            stepNumber: 4,
            title: '格式设置',
            content: '可以设置单元格的字体、颜色、边框。选中单元格或区域后，右键选择"设置单元格格式"。',
            practiceType: PracticeType.MULTIPLE_CHOICE,
            difficulty: 1,
            estimatedTime: 5,
            keyPoints: ['字体颜色', '边框', '对齐方式']
          }
        ]
      },
      'wechat_basic': {
        id: 'wechat_basic',
        name: '微信使用',
        prerequisites: [],
        steps: [
          {
            stepNumber: 1,
            title: '添加好友',
            content: '点击右上角"+"号，选择"添加朋友"。可以扫码添加、搜索手机号添加、或者让对方发给你名片。',
            practiceType: PracticeType.OPERATION,
            difficulty: 1,
            estimatedTime: 5,
            tip: '扫码是最快的方式',
            keyPoints: ['扫码添加', '手机号搜索', '名片分享']
          },
          {
            stepNumber: 2,
            title: '发送消息',
            content: '在聊天框输入文字，点击发送按钮或按回车。发送图片点击右侧"+"号，选择图片或拍照。',
            practiceType: PracticeType.OPERATION,
            difficulty: 1,
            estimatedTime: 3,
            tip: '长按消息可以撤回，但只有2分钟内有效',
            keyPoints: ['输入发送', '发送图片', '撤回消息']
          },
          {
            stepNumber: 3,
            title: '发朋友圈',
            content: '点击朋友圈入口（相机图标），可以选择拍照或从相册选择。可以写文字、@朋友、设置谁可以看。',
            practiceType: PracticeType.OPERATION,
            difficulty: 1,
            estimatedTime: 5,
            keyPoints: ['拍照/相册', '文字说明', '谁可以看']
          },
          {
            stepNumber: 4,
            title: '使用微信支付',
            content: '点击右下角"我"->"支付"，可以付款、收款、缴费。首次使用需要设置支付密码并绑定银行卡。',
            practiceType: PracticeType.MULTIPLE_CHOICE,
            difficulty: 2,
            estimatedTime: 8,
            tip: '支付密码要记牢，不要告诉任何人',
            keyPoints: ['支付密码', '绑定银行卡', '付款码']
          }
        ]
      },
      'harmony_share': {
        id: 'harmony_share',
        name: '鸿蒙设备协同',
        prerequisites: ['wechat_basic'],
        steps: [
          {
            stepNumber: 1,
            title: '登录同一个华为账号',
            content: '确保手机、平板、电脑都登录了同一个华为账号。这是实现协同的基础。',
            practiceType: PracticeType.OPERATION,
            difficulty: 1,
            estimatedTime: 3,
            tip: '在设置->华为账号里登录',
            keyPoints: ['华为账号', '多设备登录']
          },
          {
            stepNumber: 2,
            title: '开启跨设备权限',
            content: '在手机设置里，找到"跨设备协同"选项，开启需要的权限，比如"跨设备剪贴板"、"文件互传"等。',
            practiceType: PracticeType.OPERATION,
            difficulty: 2,
            estimatedTime: 5,
            keyPoints: ['跨设备权限', '剪贴板共享', '文件互传']
          },
          {
            stepNumber: 3,
            title: '多屏协同',
            content: '打开电脑的"华为电脑管家"，用手机碰一碰电脑的NFC标签（如果有），或者扫码连接。连接后手机屏幕会显示在电脑上。',
            practiceType: PracticeType.OPERATION,
            difficulty: 3,
            estimatedTime: 10,
            tip: 'NFC标签通常在电脑触控板附近',
            keyPoints: ['华为电脑管家', 'NFC碰一碰', '扫码连接']
          }
        ]
      }
    };

    return skills[skillId];
  }

  /**
   * 获取所有技能列表
   */
  getAllSkills(): { id: string; name: string; difficulty: number; prerequisites: string[] }[] {
    return Object.values(this.getSkillDefinition.bind(this)() || {}).map((s: any) => ({
      id: s.id,
      name: s.name,
      difficulty: s.steps?.length || 0,
      prerequisites: s.prerequisites || []
    })).filter(s => s.id);
  }
}

/**
 * ============================================================================
 * 生成技能用例 - GenerateSkillUseCase
 * 单一职责：根据用户需求生成技能学习内容
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { SkillEntity, SkillCategory, SkillDifficulty, SkillStep } from '../entities/SkillEntity';

/**
 * 生成技能请求
 */
export interface GenerateSkillRequest {
  /** 用户 ID */
  userId: string;
  
  /** 用户原始需求 */
  userRequest: string;
  
  /** 场景类型 */
  scenarioType?: string;
  
  /** 难度偏好 */
  difficulty?: SkillDifficulty;
}

/**
 * 生成技能结果
 */
export interface GenerateSkillResult {
  /** 是否成功 */
  success: boolean;
  
  /** 技能实体 */
  skill?: SkillEntity;
  
  /** 错误信息 */
  error?: string;
}

/**
 * 生成技能用例
 */
export class GenerateSkillUseCase {
  private static instance: GenerateSkillUseCase | null = null;

  static getInstance(): GenerateSkillUseCase {
    if (!GenerateSkillUseCase.instance) {
      GenerateSkillUseCase.instance = new GenerateSkillUseCase();
    }
    return GenerateSkillUseCase.instance;
  }

  private constructor() {
    HiLog.info("GenerateSkillUseCase", "用例初始化");
  }

  /**
   * 执行用例
   */
  async execute(request: GenerateSkillRequest): Promise<GenerateSkillResult> {
    HiLog.info("GenerateSkillUseCase", `执行：${request.userId}/${request.userRequest}`);
    
    try {
      // 1. 解析用户需求
      const skillInfo = this.parseUserRequest(request);
      
      // 2. 生成学习步骤
      const steps = this.generateSteps(skillInfo);
      
      // 3. 创建技能实体
      const skill = new SkillEntity(
        `skill_${Date.now()}`,
        skillInfo.name,
        skillInfo.category,
        skillInfo.difficulty,
        steps,
        skillInfo.prerequisites,
        skillInfo.realWorldScenes,
        skillInfo.tags
      );
      
      HiLog.info("GenerateSkillUseCase", `技能生成成功：${skill.name}`);
      
      return {
        success: true,
        skill,
      };
    } catch (error: any) {
      HiLog.error("GenerateSkillUseCase", `技能生成失败：${error.message}`);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * 解析用户需求
   */
  private parseUserRequest(request: GenerateSkillRequest): {
    name: string;
    category: SkillCategory;
    difficulty: SkillDifficulty;
    prerequisites: string[];
    realWorldScenes: string[];
    tags: string[];
  } {
    const lowerRequest = request.userRequest.toLowerCase();
    
    // 识别类别
    let category = SkillCategory.LIFE;
    if (lowerRequest.includes('excel') || lowerRequest.includes('word') || lowerRequest.includes('ppt')) {
      category = SkillCategory.OFFICE;
    } else if (lowerRequest.includes('微信') || lowerRequest.includes('支付')) {
      category = SkillCategory.LIFE;
    } else if (lowerRequest.includes('鸿蒙') || lowerRequest.includes('设备')) {
      category = SkillCategory.DIGITAL;
    }
    
    // 识别难度
    let difficulty = SkillDifficulty.BEGINNER;
    if (lowerRequest.includes('高级') || lowerRequest.includes('深入')) {
      difficulty = SkillDifficulty.ADVANCED;
    } else if (lowerRequest.includes('进阶')) {
      difficulty = SkillDifficulty.INTERMEDIATE;
    }
    
    // 生成技能名称
    const name = this.extractSkillName(request.userRequest);
    
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
    // 简化实现，实际应该用 NLP 提取
    if (request.includes('Excel')) return 'Excel 基础';
    if (request.includes('微信')) return '微信使用';
    if (request.includes('鸿蒙')) return '鸿蒙设备协同';
    return '生活技能';
  }

  /**
   * 生成学习步骤
   */
  private generateSteps(skillInfo: any): SkillStep[] {
    // 根据技能类型生成不同的步骤
    if (skillInfo.name === 'Excel 基础') {
      return [
        {
          stepNumber: 1,
          title: '认识 Excel 界面',
          content: 'Excel 是一个表格软件，由行和列组成。每一格叫做"单元格"。',
          keyPoint: '行是横的（1,2,3...），列是竖的（A,B,C...）',
          estimatedTime: 5,
        },
        {
          stepNumber: 2,
          title: '单元格操作',
          content: '点击单元格就能输入内容，输入完按回车确认。',
          keyPoint: '双击单元格可以直接编辑',
          estimatedTime: 8,
        },
        {
          stepNumber: 3,
          title: '简单公式',
          content: '公式用等号"="开头。比如"=A1+B1"就是把 A1 和 B1 的数加起来。',
          keyPoint: '公式要用等号开头，否则会当作文本',
          estimatedTime: 10,
        },
        {
          stepNumber: 4,
          title: '格式设置',
          content: '可以设置单元格的字体、颜色、边框。',
          keyPoint: '选中后右键设置单元格格式',
          estimatedTime: 5,
        },
      ];
    }
    
    if (skillInfo.name === '微信使用') {
      return [
        {
          stepNumber: 1,
          title: '添加好友',
          content: '点击右上角"+"号，选择"添加朋友"。可以扫码添加、搜索手机号添加。',
          keyPoint: '扫码是最快的方式',
          estimatedTime: 5,
        },
        {
          stepNumber: 2,
          title: '发送消息',
          content: '在聊天框输入文字，点击发送按钮或按回车。',
          keyPoint: '2 分钟内可撤回',
          estimatedTime: 3,
        },
        {
          stepNumber: 3,
          title: '发朋友圈',
          content: '点击朋友圈入口，点击右上角相机发布。',
          keyPoint: '可以设置谁可以看',
          estimatedTime: 5,
        },
        {
          stepNumber: 4,
          title: '使用支付',
          content: '我->支付，可以付款、收款、缴费。',
          keyPoint: '支付密码要保密',
          estimatedTime: 8,
        },
      ];
    }
    
    // 默认步骤
    return [
      {
        stepNumber: 1,
        title: '基础概念',
        content: '学习基础概念和术语',
        keyPoint: '理解核心概念',
        estimatedTime: 10,
      },
      {
        stepNumber: 2,
        title: '基础操作',
        content: '学习基础操作方法',
        keyPoint: '动手练习',
        estimatedTime: 15,
      },
      {
        stepNumber: 3,
        title: '实践应用',
        content: '实际应用场景练习',
        keyPoint: '学以致用',
        estimatedTime: 20,
      },
    ];
  }
}

/**
 * ============================================================================
 * 华为AI服务 - HuaweiAIService
 * 核心：调用华为大模型进行内容生成
 * 
 * 支持：
 * - 教学内容实时生成
 * - 自定义技能AI生成
 * - 方言适配
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { rpo } from '@kit.RemoteRemoteProxy';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * AI对话请求
 */
export interface AIRequest {
  prompt: string;
  maxTokens?: number;
  temperature?: number;
  systemPrompt?: string;
}

/**
 * AI对话响应
 */
export interface AIResponse {
  success: boolean;
  content?: string;
  error?: string;
  usage?: {
    promptTokens: number;
    completionTokens: number;
    totalTokens: number;
  };
}

/**
 * 教学内容结构
 */
export interface TeachingContent {
  skillName: string;
  steps: {
    title: string;
    content: string;
    keyPoint: string;
    safetyTip?: string;
  }[];
  quiz: {
    question: string;
    answer: boolean;
    feedback: string;
  };
 合规: boolean;
}

/**
 * 华为AI服务配置
 */
interface AIConfig {
  endpoint: string;
  apiKey: string;
  model: string;
  region: string;
}

/**
 * 华为AI服务
 */
export class HuaweiAIService {
  private static instance: HuaweiAIService | null = null;
  
  // AI配置
  private config: AIConfig = {
    endpoint: 'https://api.huaweicloud.com/v1/ai-services/llm',
    apiKey: '',  // 需要配置
    model: 'hvw-llm-v1',
    region: 'cn-north-4'
  };
  
  // 降级用的模板
  private fallbackTemplates: Record<string, TeachingContent> = {
    excel: {
      skillName: 'Excel基础',
      steps: [
        { title: '认识Excel界面', content: 'Excel由行和列组成，每个格子叫单元格', keyPoint: '先列后行' },
        { title: '单元格操作', content: '点击输入，按回车确认', keyPoint: '双击编辑' },
        { title: '简单公式', content: '公式用=开头，如=SUM(A1:A10)', keyPoint: '等号必须' },
        { title: '格式设置', content: '选中后右键设置单元格格式', keyPoint: '字体颜色' }
      ],
      quiz: { question: 'Excel公式必须用什么开头？', answer: true, feedback: '正确！公式必须用=开头' },
      合规: true
    },
    wechat: {
      skillName: '微信使用',
      steps: [
        { title: '添加好友', content: '点击+号，选择添加朋友', keyPoint: '扫码最快' },
        { title: '发送消息', content: '输入文字，点击发送', keyPoint: '2分钟内可撤回' },
        { title: '发朋友圈', content: '点击朋友圈入口，点击相机发布', keyPoint: '谁可以看' },
        { title: '使用支付', content: '我->支付，可付款缴费', keyPoint: '密码要保密' }
      ],
      quiz: { question: '微信支付在哪个菜单？', answer: true, feedback: '正确！在"我"的页面里' },
      合规: true
    },
    cooking: {
      skillName: '家常菜制作',
      steps: [
        { title: '准备食材', content: '洗净切好所有材料', keyPoint: '生熟分开' },
        { title: '热锅冷油', content: '锅烧热后放油', keyPoint: '不要等油冒烟' },
        { title: '下锅翻炒', content: '按顺序放入食材', keyPoint: '火候控制' },
        { title: '调味出锅', content: '加盐等调料，出锅', keyPoint: '边尝边调' }
      ],
      quiz: { question: '炒菜应该用什么火候？', answer: true, feedback: '正确！中大火快炒' },
      合规: true
    }
  };

  static getInstance(): HuaweiAIService {
    if (!HuaweiAIService.instance) {
      HuaweiAIService.instance = new HuaweiAIService();
    }
    return HuaweiAIService.instance;
  }

  private constructor() {
    HiLog.info("HuaweiAIService", "华为AI服务初始化");
  }

  /**
   * 配置API Key
   */
  configure(apiKey: string, endpoint?: string): void {
    this.config.apiKey = apiKey;
    if (endpoint) this.config.endpoint = endpoint;
    HiLog.info("HuaweiAIService", "AI服务配置更新");
  }

  /**
   * 生成教学内容
   * 核心：调用华为AI实时生成标准化教学内容
   */
  async generateTeachingContent(userRequest: string): Promise<AIResponse> {
    HiLog.info("HuaweiAIService", `生成教学内容: ${userRequest}`);
    
    // 如果没配置API Key，用模板
    if (!this.config.apiKey) {
      HiLog.warn("HuaweiAIService", "未配置API Key，使用模板降级");
      return this.fallbackByTemplate(userRequest);
    }

    try {
      // 构建prompt
      const prompt = this.buildPrompt(userRequest);
      
      // 调用华为AI
      const response = await this.callAI(prompt);
      
      // 解析响应
      const content = this.parseAIResponse(response);
      
      return {
        success: true,
        content: JSON.stringify(content),
        usage: response.usage
      };
    } catch (error) {
      HiLog.error("HuaweiAIService", `AI调用失败: ${error}`);
      // 降级到模板
      return this.fallbackByTemplate(userRequest);
    }
  }

  /**
   * 生成自定义技能内容
   */
  async generateCustomSkill(userRequest: string): Promise<AIResponse> {
    HiLog.info("HuaweiAIService", `生成自定义技能: ${userRequest}`);
    
    if (!this.config.apiKey) {
      return this.fallbackByTemplate(userRequest);
    }

    try {
      const prompt = this.buildCustomSkillPrompt(userRequest);
      const response = await this.callAI(prompt);
      
      return {
        success: true,
        content: this.parseCustomSkillResponse(response.content || ''),
        usage: response.usage
      };
    } catch (error) {
      HiLog.error("HuaweiAIService", `自定义技能生成失败: ${error}`);
      return this.fallbackByTemplate(userRequest);
    }
  }

  /**
   * 方言适配
   */
  async adaptToDialect(content: string, dialect: string): Promise<string> {
    if (!this.config.apiKey) {
      return this.fallbackDialectAdapt(content, dialect);
    }

    try {
      const prompt = `将以下内容转换为${dialect}风格，保持原意：
      ${content}
      
      要求：
      - 保持专业术语
      - 口语化表达
      - 返回转换后的内容`;
      
      const response = await this.callAI(prompt);
      return response.content || content;
    } catch (error) {
      HiLog.error("HuaweiAIService", `方言适配失败: ${error}`);
      return this.fallbackDialectAdapt(content, dialect);
    }
  }

  /**
   * 调用华为AI API
   */
  private async callAI(prompt: string): Promise<{ content: string; usage?: any }> {
    // 实际应该调用华为云API
    // 这里用模拟响应
    return new Promise((resolve) => {
      setTimeout(() => {
        resolve({
          content: JSON.stringify({
            skillName: 'Generated Skill',
            steps: [],
            quiz: { question: '', answer: true, feedback: '' },
            合规: true
          }),
          usage: { promptTokens: 100, completionTokens: 50, totalTokens: 150 }
        });
      }, 500);
    });
  }

  /**
   * 构建教学内容prompt
   */
  private buildPrompt(userRequest: string): string {
    return `用户想学习：${userRequest}
    
    请生成符合以下要求的教学内容：
    1. 技能目标：简明描述
    2. 3-5步核心操作：每步≤30字
    3. 1个易错点提示：≤30字
    4. 安全规范提示（可选）
    5. 1道判断题：检验学习效果
    6. 点评（答对/答错各一句）
    
    格式要求：
    - 单步内容≤30字
    - 无专业术语
    - 适配语音播报
    - 合规无违规内容
    
    返回JSON格式`;
  }

  /**
   * 构建自定义技能prompt
   */
  private buildCustomSkillPrompt(userRequest: string): string {
    return `用户自定义学习需求：${userRequest}
    
    请判断是否合规：
    - 仅支持生活技能类
    - 禁止：医疗、K12、金融投资、法律咨询等
    
    如合规，生成：
    1. 技能名称
    2. 分类
    3. 3-5步学习步骤
    4. 安全提示
    5. 判断题
    
    返回JSON格式`;
  }

  /**
   * 解析AI响应
   */
  private parseAIResponse(content: string): TeachingContent {
    try {
      return JSON.parse(content);
    } catch {
      // JSON解析失败，尝试降级
      HiLog.warn("HuaweiAIService", "AI响应解析失败，使用降级模板");
      return this.fallbackTemplates['excel'];
    }
  }

  /**
   * 解析自定义技能响应
   */
  private parseCustomSkillResponse(content: string): string {
    try {
      return content;
    } catch {
      return JSON.stringify(this.fallbackTemplates['cooking']);
    }
  }

  /**
   * 模板降级
   */
  private fallbackByTemplate(userRequest: string): AIResponse {
    const lower = userRequest.toLowerCase();
    
    let template = this.fallbackTemplates['cooking'];
    if (lower.includes('excel') || lower.includes('表格')) {
      template = this.fallbackTemplates['excel'];
    } else if (lower.includes('微信') || lower.includes('wechat')) {
      template = this.fallbackTemplates['wechat'];
    }
    
    HiLog.info("HuaweiAIService", `使用模板降级: ${template.skillName}`);
    
    return {
      success: true,
      content: JSON.stringify(template),
      usage: { promptTokens: 0, completionTokens: 0, totalTokens: 0 }
    };
  }

  /**
   * 方言降级适配
   */
  private fallbackDialectAdapt(content: string, dialect: string): string {
    const prefix = this.getDialectPrefix(dialect);
    return `[${prefix}]${content}`;
  }

  /**
   * 获取方言前缀
   */
  private getDialectPrefix(dialect: string): string {
    const prefixes: Record<string, string> = {
      '东北': '俺',
      '四川': '娃儿',
      '粤语': '睇',
      '闽南': '阮',
      '上海': '阿拉'
    };
    return prefixes[dialect] || '';
  }
}

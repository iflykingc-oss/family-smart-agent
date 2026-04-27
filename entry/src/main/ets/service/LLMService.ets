/**
 * ============================================================================
 * 大模型服务 - LLMService
 * 应用服务层：编排用例，连接领域层与表现层
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { GenerateSkillUseCase } from '../domain/usecases/GenerateSkillUseCase';
import { LLMRemoteDataSource } from '../data/datasources/impl/LLMRemoteDataSource';
import { FeatureFlags } from '../core/config/FeatureFlags';

/**
 * LLM 服务
 */
export class LLMService {
  private static instance: LLMService | null = null;
  
  private llmDataSource: LLMRemoteDataSource;
  private generateSkillUseCase: GenerateSkillUseCase;

  /**
   * 获取单例实例
   */
  static getInstance(): LLMService {
    if (!LLMService.instance) {
      LLMService.instance = new LLMService();
    }
    return LLMService.instance;
  }

  private constructor() {
    this.llmDataSource = LLMRemoteDataSource.getInstance();
    this.generateSkillUseCase = GenerateSkillUseCase.getInstance();
    HiLog.info("LLMService", "初始化");
  }

  /**
   * 生成教学内容
   */
  async generateTeachingContent(userRequest: string): Promise<string> {
    HiLog.info("LLMService", `生成教学内容：${userRequest}`);
    
    try {
      // 检查功能开关
      if (!FeatureFlags.ENABLE_LLM_GENERATION) {
        HiLog.warn("LLMService", "LLM 生成已禁用，使用降级模式");
        return this.getFallbackContent(userRequest);
      }
      
      // 调用 LLM 生成内容
      const prompt = this.buildTeachingPrompt(userRequest);
      const content = await this.llmDataSource.generateContent(prompt);
      
      if (content) {
        return content;
      }
      
      // 降级
      return this.getFallbackContent(userRequest);
    } catch (error: any) {
      HiLog.error("LLMService", `生成失败：${error.message}`);
      
      // 降级模式
      if (FeatureFlags.LLM_FALLBACK_MODE) {
        return this.getFallbackContent(userRequest);
      }
      
      throw error;
    }
  }

  /**
   * 构建教学 Prompt
   */
  private buildTeachingPrompt(userRequest: string): string {
    return `你是一个专业的教学助手，擅长将复杂技能拆解为简单易懂的学习步骤。

用户想学习：${userRequest}

请生成符合以下要求的教学内容：
1. 技能目标：简明描述
2. 3-5 步核心操作：每步≤30 字
3. 1 个易错点提示：≤30 字
4. 安全规范提示（可选）
5. 1 道判断题：检验学习效果
6. 点评（答对/答错各一句）

格式要求：
- 单步内容≤30 字
- 无专业术语
- 适配语音播报
- 合规无违规内容

返回 JSON 格式`;
  }

  /**
   * 降级内容（模板）
   */
  private getFallbackContent(userRequest: string): string {
    const lowerRequest = userRequest.toLowerCase();
    
    if (lowerRequest.includes('excel')) {
      return JSON.stringify({
        skillName: 'Excel 基础',
        steps: [
          { title: '认识 Excel 界面', content: 'Excel 由行和列组成，每个格子叫单元格', keyPoint: '先列后行' },
          { title: '单元格操作', content: '点击输入，按回车确认', keyPoint: '双击编辑' },
          { title: '简单公式', content: '公式用=开头，如=SUM(A1:A10)', keyPoint: '等号必须' },
          { title: '格式设置', content: '选中后右键设置单元格格式', keyPoint: '字体颜色' }
        ],
        quiz: { question: 'Excel 公式必须用什么开头？', answer: true, feedback: '正确！公式必须用=开头' }
      });
    }
    
    if (lowerRequest.includes('微信')) {
      return JSON.stringify({
        skillName: '微信使用',
        steps: [
          { title: '添加好友', content: '点击 + 号，选择添加朋友', keyPoint: '扫码最快' },
          { title: '发送消息', content: '输入文字，点击发送', keyPoint: '2 分钟内可撤回' },
          { title: '发朋友圈', content: '点击朋友圈入口，点击相机发布', keyPoint: '谁可以看' },
          { title: '使用支付', content: '我->支付，可付款缴费', keyPoint: '密码要保密' }
        ],
        quiz: { question: '微信支付在哪个菜单？', answer: true, feedback: '正确！在"我"的页面里' }
      });
    }
    
    // 默认模板
    return JSON.stringify({
      skillName: '生活技能',
      steps: [
        { title: '基础概念', content: '学习基础概念和术语', keyPoint: '理解核心概念' },
        { title: '基础操作', content: '学习基础操作方法', keyPoint: '动手练习' },
        { title: '实践应用', content: '实际应用场景练习', keyPoint: '学以致用' }
      ],
      quiz: { question: '你学会了吗？', answer: true, feedback: '太棒了！继续保持' }
    });
  }

  /**
   * 设置 API Token
   */
  setApiToken(token: string): void {
    this.llmDataSource.setAuthToken(token);
  }
}

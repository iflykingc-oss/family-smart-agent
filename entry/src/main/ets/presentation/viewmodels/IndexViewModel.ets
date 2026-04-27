/**
 * ============================================================================
 * 首页 ViewModel - IndexViewModel
 * 表现层：页面状态管理，无业务逻辑
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { LLMService } from '../../service/LLMService';
import { SceneClassificationService, SceneType } from '../../service/SceneClassificationService';
import { InteractionService, InteractionMode, InteractionMessage } from '../../service/InteractionService';

/**
 * 聊天消息
 */
export interface ChatMessage {
  id: string;
  sender: 'user' | 'assistant';
  content: string;
  timestamp: number;
  suggestions?: string[];
}

/**
 * 学习状态
 */
export interface LearningState {
  isLearning: boolean;
  currentSkillName?: string;
  currentStep: number;
  totalSteps: number;
  progress: number;
}

/**
 * 首页 ViewModel
 */
export class IndexViewModel {
  private llmService: LLMService;
  private sceneService: SceneClassificationService;
  private interactionService: InteractionService;
  
  // 状态
  private messages: ChatMessage[] = [];
  private learningState: LearningState = {
    isLearning: false,
    currentStep: 0,
    totalSteps: 0,
    progress: 0,
  };
  private interactionMode: InteractionMode = InteractionMode.TEACHER;
  
  // 回调
  private onStateChanged?: () => void;

  constructor() {
    this.llmService = LLMService.getInstance();
    this.sceneService = SceneClassificationService.getInstance();
    this.interactionService = InteractionService.getInstance();
    HiLog.info("IndexViewModel", "初始化");
  }

  /**
   * 设置状态变化回调
   */
  setOnStateChanged(callback: () => void): void {
    this.onStateChanged = callback;
  }

  /**
   * 获取消息列表
   */
  getMessages(): ChatMessage[] {
    return [...this.messages];
  }

  /**
   * 获取学习状态
   */
  getLearningState(): LearningState {
    return { ...this.learningState };
  }

  /**
   * 获取互动模式
   */
  getInteractionMode(): InteractionMode {
    return this.interactionMode;
  }

  /**
   * 发送用户消息
   */
  async sendMessage(userId: string, content: string): Promise<void> {
    HiLog.info("IndexViewModel", `发送消息：${content}`);
    
    // 1. 添加用户消息
    const userMessage: ChatMessage = {
      id: `msg_${Date.now()}`,
      sender: 'user',
      content,
      timestamp: Date.now(),
    };
    this.messages.push(userMessage);
    this.notifyStateChanged();
    
    // 2. 分类场景
    const sceneResult = await this.sceneService.classifyScene(content);
    
    // 3. 生成教学内容
    const teachingContent = await this.llmService.generateTeachingContent(content);
    
    // 4. 添加助手消息
    const assistantMessage: ChatMessage = {
      id: `msg_${Date.now()}`,
      sender: 'assistant',
      content: this.parseTeachingContent(teachingContent),
      timestamp: Date.now(),
      suggestions: ['开始学习', '换一个'],
    };
    this.messages.push(assistantMessage);
    
    // 5. 更新学习状态
    this.learningState = {
      isLearning: true,
      currentSkillName: sceneResult.sceneName,
      currentStep: 1,
      totalSteps: 4,
      progress: 25,
    };
    
    this.notifyStateChanged();
  }

  /**
   * 处理用户回答
   */
  async handleAnswer(userId: string, skillId: string, knowledgePointId: string, isCorrect: boolean): Promise<void> {
    HiLog.info("IndexViewModel", `处理回答：${isCorrect}`);
    
    // 1. 调用互动服务
    const result = await this.interactionService.handleUserAnswer(
      userId,
      skillId,
      knowledgePointId,
      isCorrect
    );
    
    // 2. 添加反馈消息
    const feedbackMessage: ChatMessage = {
      id: `msg_${Date.now()}`,
      sender: 'assistant',
      content: result.message.content,
      timestamp: Date.now(),
      suggestions: result.message.suggestions,
    };
    this.messages.push(feedbackMessage);
    
    // 3. 更新学习状态
    this.learningState.currentStep++;
    this.learningState.progress = Math.round((this.learningState.currentStep / this.learningState.totalSteps) * 100);
    
    this.notifyStateChanged();
  }

  /**
   * 切换互动模式
   */
  toggleInteractionMode(): void {
    this.interactionMode = this.interactionService.switchMode(this.interactionMode);
    this.notifyStateChanged();
  }

  /**
   * 解析教学内容
   */
  private parseTeachingContent(content: string): string {
    try {
      const parsed = JSON.parse(content);
      let result = `📚 **${parsed.skillName}**\n\n`;
      
      for (const step of parsed.steps || []) {
        result += `**${step.title}**\n${step.content}\n\n`;
      }
      
      if (parsed.quiz) {
        result += `\n**小测验**\n${parsed.quiz.question}\n`;
      }
      
      return result;
    } catch (error) {
      return content;
    }
  }

  /**
   * 通知状态变化
   */
  private notifyStateChanged(): void {
    if (this.onStateChanged) {
      this.onStateChanged();
    }
  }

  /**
   * 清理资源
   */
  destroy(): void {
    this.onStateChanged = undefined;
    this.messages = [];
  }
}

/**
 * ============================================================================
 * 教学页 ViewModel - TeachingViewModel
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { InteractionService, InteractionMode } from '../../service/InteractionService';
import { LLMService } from '../../service/LLMService';

/**
 * 教学步骤
 */
export interface TeachingStep {
  stepNumber: number;
  title: string;
  content: string;
  keyPoint: string;
  completed: boolean;
}

/**
 * 教学页 ViewModel
 */
export class TeachingViewModel {
  private interactionService: InteractionService;
  private llmService: LLMService;
  
  // 状态
  private steps: TeachingStep[] = [];
  private currentStepIndex: number = 0;
  private interactionMode: InteractionMode = InteractionMode.TEACHER;
  private isCompleted: boolean = false;
  
  // 回调
  private onStateChanged?: () => void;

  constructor() {
    this.interactionService = InteractionService.getInstance();
    this.llmService = LLMService.getInstance();
    HiLog.info("TeachingViewModel", "初始化");
  }

  /**
   * 设置状态变化回调
   */
  setOnStateChanged(callback: () => void): void {
    this.onStateChanged = callback;
  }

  /**
   * 获取教学步骤
   */
  getSteps(): TeachingStep[] {
    return [...this.steps];
  }

  /**
   * 获取当前步骤
   */
  getCurrentStep(): TeachingStep | null {
    if (this.steps.length === 0 || this.currentStepIndex >= this.steps.length) {
      return null;
    }
    return { ...this.steps[this.currentStepIndex] };
  }

  /**
   * 获取互动模式
   */
  getInteractionMode(): InteractionMode {
    return this.interactionMode;
  }

  /**
   * 获取完成状态
   */
  isTeachingCompleted(): boolean {
    return this.isCompleted;
  }

  /**
   * 获取进度
   */
  getProgress(): number {
    if (this.steps.length === 0) return 0;
    return Math.round(((this.currentStepIndex + 1) / this.steps.length) * 100);
  }

  /**
   * 开始教学
   */
  async startTeaching(skillId: string, skillName: string): Promise<void> {
    HiLog.info("TeachingViewModel", `开始教学：${skillName}`);
    
    // 1. 生成教学内容
    const content = await this.llmService.generateTeachingContent(`教${skillName}`);
    
    // 2. 解析步骤
    this.steps = this.parseSteps(content);
    this.currentStepIndex = 0;
    this.isCompleted = false;
    
    this.notifyStateChanged();
  }

  /**
   * 完成当前步骤
   */
  completeCurrentStep(): void {
    if (this.currentStepIndex < this.steps.length) {
      this.steps[this.currentStepIndex].completed = true;
      this.currentStepIndex++;
      
      if (this.currentStepIndex >= this.steps.length) {
        this.isCompleted = true;
      }
      
      this.notifyStateChanged();
    }
  }

  /**
   * 切换互动模式
   */
  toggleMode(): void {
    this.interactionMode = this.interactionMode === InteractionMode.TEACHER
      ? InteractionMode.PRACTICE
      : InteractionMode.TEACHER;
    this.notifyStateChanged();
  }

  /**
   * 重置教学
   */
  reset(): void {
    this.steps = [];
    this.currentStepIndex = 0;
    this.interactionMode = InteractionMode.TEACHER;
    this.isCompleted = false;
    this.notifyStateChanged();
  }

  /**
   * 解析步骤
   */
  private parseSteps(content: string): TeachingStep[] {
    try {
      const parsed = JSON.parse(content);
      return (parsed.steps || []).map((step: any, index: number) => ({
        stepNumber: index + 1,
        title: step.title || `步骤${index + 1}`,
        content: step.content || '',
        keyPoint: step.keyPoint || '',
        completed: false,
      }));
    } catch (error) {
      // 降级：返回空步骤
      return [];
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
    this.steps = [];
  }
}

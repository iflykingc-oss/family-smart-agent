/**
 * ============================================================================
 * 互动流程优化器 - InteractionFlowOptimizer
 * 目标：优化双角色互动流程，提升教学体验
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 互动模式
 */
export enum InteractionMode {
  TEACHER = 'teacher',    // 导师模式
  PRACTICE = 'practice'   // 陪练模式
}

/**
 * 互动状态
 */
export interface InteractionState {
  mode: InteractionMode;
  currentStep: number;
  userEngagement: number;   // 用户参与度 0-100
  responseTime: number;     // 平均响应时间（秒）
  hintUsage: number;        // 提示使用次数
  consecutiveCorrect: number;
  frustration Level: number; // 挫折度 0-100
}

/**
 * 互动配置
 */
export interface InteractionConfig {
  adaptiveMode: boolean;    // 自适应模式切换
  encouragementThreshold: number; // 鼓励阈值
  hintLimit: number;        // 提示上限
  responseTimeout: number;  // 响应超时（秒）
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: InteractionConfig = {
  adaptiveMode: true,
  encouragementThreshold: 0.7,
  hintLimit: 3,
  responseTimeout: 60
};

/**
 * 互动流程优化器
 */
export class InteractionFlowOptimizer {
  private static instance: InteractionFlowOptimizer | null = null;
  
  private config: InteractionConfig;
  private states: Map<string, InteractionState> = new Map();

  /**
   * 获取单例实例
   */
  static getInstance(config?: Partial<InteractionConfig>): InteractionFlowOptimizer {
    if (!InteractionFlowOptimizer.instance) {
      InteractionFlowOptimizer.instance = new InteractionFlowOptimizer(config);
    }
    return InteractionFlowOptimizer.instance;
  }

  private constructor(config?: Partial<InteractionConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    HiLog.info("InteractionFlowOptimizer", "初始化");
  }

  /**
   * 开始互动
   */
  startInteraction(userId: string, skillId: string): InteractionState {
    const key = this.generateKey(userId, skillId);
    
    const state: InteractionState = {
      mode: InteractionMode.TEACHER,
      currentStep: 0,
      userEngagement: 100,
      responseTime: 0,
      hintUsage: 0,
      consecutiveCorrect: 0,
      frustration Level: 0
    };
    
    this.states.set(key, state);
    
    HiLog.info("InteractionFlowOptimizer", `开始互动：${key}`);
    
    return state;
  }

  /**
   * 切换模式
   */
  switchMode(userId: string, skillId: string, newMode: InteractionMode): void {
    const state = this.getState(userId, skillId);
    if (!state) return;
    
    const oldMode = state.mode;
    state.mode = newMode;
    
    HiLog.info("InteractionFlowOptimizer", 
      `切换模式：${this.generateKey(userId, skillId)}, ${oldMode} → ${newMode}`);
    
    // 模式切换优化
    this.optimizeModeTransition(state, oldMode, newMode);
  }

  /**
   * 处理用户回答
   */
  handleUserAnswer(
    userId: string,
    skillId: string,
    isCorrect: boolean,
    responseTime?: number
  ): void {
    const state = this.getState(userId, skillId);
    if (!state) return;
    
    // 更新状态
    if (isCorrect) {
      state.consecutiveCorrect++;
      state.userEngagement = Math.min(100, state.userEngagement + 5);
      state.frustration Level = Math.max(0, state.frustration Level - 10);
    } else {
      state.consecutiveCorrect = 0;
      state.userEngagement = Math.max(0, state.userEngagement - 10);
      state.frustration Level = Math.min(100, state.frustration Level + 15);
    }
    
    // 更新响应时间
    if (responseTime) {
      state.responseTime = (state.responseTime + responseTime) / 2;
    }
    
    // 自适应优化
    this.adaptiveOptimize(state, isCorrect);
    
    HiLog.info("InteractionFlowOptimizer", 
      `处理回答：${this.generateKey(userId, skillId)}, 正确：${isCorrect}`);
  }

  /**
   * 请求提示
   */
  requestHint(userId: string, skillId: string): boolean {
    const state = this.getState(userId, skillId);
    if (!state) return false;
    
    // 检查提示上限
    if (state.hintUsage >= this.config.hintLimit) {
      HiLog.warn("InteractionFlowOptimizer", `提示已达上限：${this.generateKey(userId, skillId)}`);
      return false;
    }
    
    state.hintUsage++;
    state.frustration Level = Math.max(0, state.frustration Level - 5);
    
    HiLog.info("InteractionFlowOptimizer", 
      `请求提示：${this.generateKey(userId, skillId)}, 次数：${state.hintUsage}`);
    
    return true;
  }

  /**
   * 更新进度
   */
  updateProgress(userId: string, skillId: string, step: number): void {
    const state = this.getState(userId, skillId);
    if (!state) return;
    
    state.currentStep = step;
    
    HiLog.info("InteractionFlowOptimizer", 
      `更新进度：${this.generateKey(userId, skillId)}, 步骤：${step}`);
  }

  /**
   * 完成互动
   */
  completeInteraction(userId: string, skillId: string): void {
    const key = this.generateKey(userId, skillId);
    this.states.delete(key);
    
    HiLog.info("InteractionFlowOptimizer", `完成互动：${key}`);
  }

  /**
   * 获取互动状态
   */
  getInteractionState(userId: string, skillId: string): InteractionState | null {
    return this.getState(userId, skillId);
  }

  /**
   * 获取互动建议
   */
  getInteractionSuggestion(userId: string, skillId: string): {
    shouldSwitchMode: boolean;
    shouldEncourage: boolean;
    shouldProvideHint: boolean;
    shouldTakeBreak: boolean;
  } {
    const state = this.getState(userId, skillId);
    if (!state) {
      return {
        shouldSwitchMode: false,
        shouldEncourage: false,
        shouldProvideHint: false,
        shouldTakeBreak: false
      };
    }
    
    return {
      shouldSwitchMode: this.shouldSwitchMode(state),
      shouldEncourage: this.shouldEncourage(state),
      shouldProvideHint: this.shouldProvideHint(state),
      shouldTakeBreak: this.shouldTakeBreak(state)
    };
  }

  // ==================== 私有方法 ====================

  /**
   * 获取状态
   */
  private getState(userId: string, skillId: string): InteractionState | null {
    const key = this.generateKey(userId, skillId);
    return this.states.get(key) || null;
  }

  /**
   * 生成键
   */
  private generateKey(userId: string, skillId: string): string {
    return `${userId}_${skillId}`;
  }

  /**
   * 优化模式切换
   */
  private optimizeModeTransition(
    state: InteractionState,
    oldMode: InteractionMode,
    newMode: InteractionMode
  ): void {
    // 导师 → 陪练：准备练习题
    if (oldMode === InteractionMode.TEACHER && newMode === InteractionMode.PRACTICE) {
      HiLog.info("InteractionFlowOptimizer", "准备练习题");
    }
    
    // 陪练 → 导师：准备讲解
    if (oldMode === InteractionMode.PRACTICE && newMode === InteractionMode.TEACHER) {
      HiLog.info("InteractionFlowOptimizer", "准备讲解");
    }
  }

  /**
   * 自适应优化
   */
  private adaptiveOptimize(state: InteractionState, isCorrect: boolean): void {
    if (!this.config.adaptiveMode) return;
    
    // 连续答对：提升难度或切换陪练模式
    if (state.consecutiveCorrect >= 3 && state.mode === InteractionMode.TEACHER) {
      HiLog.info("InteractionFlowOptimizer", "连续答对，建议切换陪练模式");
    }
    
    // 连续答错：降低难度或提供提示
    if (state.consecutiveCorrect === 0 && state.frustration Level > 50) {
      HiLog.info("InteractionFlowOptimizer", "挫折度高，建议提供帮助");
    }
    
    // 参与度低：鼓励或休息
    if (state.userEngagement < 50) {
      HiLog.info("InteractionFlowOptimizer", "参与度低，建议鼓励或休息");
    }
  }

  /**
   * 是否应该切换模式
   */
  private shouldSwitchMode(state: InteractionState): boolean {
    // 连续答对 3 次，从导师切换到陪练
    if (state.consecutiveCorrect >= 3 && state.mode === InteractionMode.TEACHER) {
      return true;
    }
    
    // 连续答错 3 次，从陪练切换到导师
    if (state.consecutiveCorrect === 0 && state.mode === InteractionMode.PRACTICE) {
      return true;
    }
    
    return false;
  }

  /**
   * 是否应该鼓励
   */
  private shouldEncourage(state: InteractionState): boolean {
    return state.consecutiveCorrect >= 2 || state.userEngagement < 60;
  }

  /**
   * 是否应该提供提示
   */
  private shouldProvideHint(state: InteractionState): boolean {
    return state.frustration Level > 60 && state.hintUsage < this.config.hintLimit;
  }

  /**
   * 是否应该休息
   */
  private shouldTakeBreak(state: InteractionState): boolean {
    return state.userEngagement < 40 || state.frustration Level > 80;
  }
}

/**
 * 便捷函数
 */
export function startInteraction(userId: string, skillId: string): InteractionState {
  return InteractionFlowOptimizer.getInstance().startInteraction(userId, skillId);
}

export function switchInteractionMode(
  userId: string,
  skillId: string,
  mode: InteractionMode
): void {
  InteractionFlowOptimizer.getInstance().switchMode(userId, skillId, mode);
}

export function handleUserAnswer(
  userId: string,
  skillId: string,
  isCorrect: boolean,
  responseTime?: number
): void {
  InteractionFlowOptimizer.getInstance().handleUserAnswer(userId, skillId, isCorrect, responseTime);
}

export function requestHint(userId: string, skillId: string): boolean {
  return InteractionFlowOptimizer.getInstance().requestHint(userId, skillId);
}

export function getInteractionSuggestion(userId: string, skillId: string): any {
  return InteractionFlowOptimizer.getInstance().getInteractionSuggestion(userId, skillId);
}

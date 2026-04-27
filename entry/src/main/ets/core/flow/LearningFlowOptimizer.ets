/**
 * ============================================================================
 * 学习流程优化器 - LearningFlowOptimizer
 * 目标：优化学习流程，提升学习效率和用户体验
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 学习状态
 */
export enum LearningState {
  IDLE = 'idle',              // 空闲
  ASSESSING = 'assessing',    // 评估中
  LEARNING = 'learning',      // 学习中
  PRACTICING = 'practicing',  // 练习中
  REVIEWING = 'reviewing',    // 复习中
  COMPLETED = 'completed'     // 完成
}

/**
 * 学习进度
 */
export interface LearningProgress {
  state: LearningState;
  currentStep: number;
  totalSteps: number;
  completionRate: number;
  accuracy: number;
  timeSpent: number;
  streak: number;
}

/**
 * 学习会话
 */
export interface LearningSession {
  id: string;
  userId: string;
  skillId: string;
  startTime: number;
  endTime?: number;
  progress: LearningProgress;
  interruptions: number;      // 中断次数
  focusScore: number;         // 专注度评分
}

/**
 * 流程优化配置
 */
export interface FlowOptimizationConfig {
  autoSaveInterval: number;   // 自动保存间隔（秒）
  breakReminderInterval: number; // 休息提醒间隔（分钟）
  adaptiveDifficulty: boolean; // 自适应难度
  smartReview: boolean;       // 智能复习
  gamification: boolean;      // 游戏化
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: FlowOptimizationConfig = {
  autoSaveInterval: 30,
  breakReminderInterval: 25,
  adaptiveDifficulty: true,
  smartReview: true,
  gamification: true
};

/**
 * 学习流程优化器
 */
export class LearningFlowOptimizer {
  private static instance: LearningFlowOptimizer | null = null;
  
  private config: FlowOptimizationConfig;
  private activeSessions: Map<string, LearningSession> = new Map();
  private optimizationHistory: Map<string, any[]> = new Map();

  /**
   * 获取单例实例
   */
  static getInstance(config?: Partial<FlowOptimizationConfig>): LearningFlowOptimizer {
    if (!LearningFlowOptimizer.instance) {
      LearningFlowOptimizer.instance = new LearningFlowOptimizer(config);
    }
    return LearningFlowOptimizer.instance;
  }

  private constructor(config?: Partial<FlowOptimizationConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    HiLog.info("LearningFlowOptimizer", "初始化");
  }

  /**
   * 开始学习会话
   */
  startSession(userId: string, skillId: string): LearningSession {
    const sessionId = `session_${Date.now()}_${userId}`;
    
    const session: LearningSession = {
      id: sessionId,
      userId,
      skillId,
      startTime: Date.now(),
      progress: {
        state: LearningState.ASSESSING,
        currentStep: 0,
        totalSteps: 0,
        completionRate: 0,
        accuracy: 0,
        timeSpent: 0,
        streak: 0
      },
      interruptions: 0,
      focusScore: 100
    };
    
    this.activeSessions.set(sessionId, session);
    
    HiLog.info("LearningFlowOptimizer", `开始会话：${sessionId}`);
    
    // 自动保存
    this.startAutoSave(sessionId);
    
    // 休息提醒
    this.startBreakReminder(sessionId);
    
    return session;
  }

  /**
   * 更新学习进度
   */
  updateProgress(sessionId: string, updates: Partial<LearningProgress>): void {
    const session = this.activeSessions.get(sessionId);
    if (!session) {
      HiLog.warn("LearningFlowOptimizer", `会话不存在：${sessionId}`);
      return;
    }
    
    // 更新进度
    session.progress = { ...session.progress, ...updates };
    
    // 计算完成率
    if (session.progress.totalSteps > 0) {
      session.progress.completionRate = 
        (session.progress.currentStep / session.progress.totalSteps) * 100;
    }
    
    // 更新专注度
    this.updateFocusScore(session);
    
    // 记录优化历史
    this.recordOptimization(sessionId, {
      type: 'progress_update',
      timestamp: Date.now(),
      updates
    });
    
    HiLog.info("LearningFlowOptimizer", 
      `更新进度：${sessionId}, ${session.progress.completionRate.toFixed(1)}%`);
  }

  /**
   * 切换学习状态
   */
  transitionState(sessionId: string, newState: LearningState): void {
    const session = this.activeSessions.get(sessionId);
    if (!session) return;
    
    const oldState = session.progress.state;
    session.progress.state = newState;
    
    HiLog.info("LearningFlowOptimizer", 
      `状态切换：${sessionId}, ${oldState} → ${newState}`);
    
    // 状态切换优化
    this.optimizeStateTransition(session, oldState, newState);
  }

  /**
   * 完成学习
   */
  completeSession(sessionId: string): void {
    const session = this.activeSessions.get(sessionId);
    if (!session) return;
    
    session.endTime = Date.now();
    session.progress.state = LearningState.COMPLETED;
    session.progress.completionRate = 100;
    
    // 计算最终得分
    const finalScore = this.calculateFinalScore(session);
    
    HiLog.info("LearningFlowOptimizer", 
      `完成会话：${sessionId}, 得分：${finalScore}`);
    
    // 清理
    this.activeSessions.delete(sessionId);
  }

  /**
   * 中断学习
   */
  interruptSession(sessionId: string): void {
    const session = this.activeSessions.get(sessionId);
    if (!session) return;
    
    session.interruptions++;
    
    HiLog.warn("LearningFlowOptimizer", 
      `中断会话：${sessionId}, 中断次数：${session.interruptions}`);
    
    // 记录中断点
    this.saveCheckpoint(sessionId);
  }

  /**
   * 恢复学习
   */
  resumeSession(sessionId: string): void {
    const session = this.activeSessions.get(sessionId);
    if (!session) return;
    
    // 从检查点恢复
    this.loadCheckpoint(sessionId);
    
    HiLog.info("LearningFlowOptimizer", `恢复会话：${sessionId}`);
  }

  /**
   * 获取会话统计
   */
  getSessionStats(sessionId: string): {
    duration: number;
    averageFocus: number;
    interruptionRate: number;
    efficiency: number;
  } {
    const session = this.activeSessions.get(sessionId);
    if (!session) {
      return { duration: 0, averageFocus: 0, interruptionRate: 0, efficiency: 0 };
    }
    
    const duration = (session.endTime || Date.now()) - session.startTime;
    const durationMinutes = duration / 60000;
    
    return {
      duration,
      averageFocus: session.focusScore,
      interruptionRate: session.interruptions / durationMinutes,
      efficiency: this.calculateEfficiency(session)
    };
  }

  /**
   * 获取活跃会话数
   */
  getActiveSessionCount(): number {
    return this.activeSessions.size;
  }

  /**
   * 清理过期会话
   */
  cleanupExpiredSessions(maxDuration: number = 3600000): void {
    const now = Date.now();
    let cleaned = 0;
    
    for (const [id, session] of this.activeSessions.entries()) {
      const duration = now - session.startTime;
      if (duration > maxDuration) {
        this.completeSession(id);
        cleaned++;
      }
    }
    
    HiLog.info("LearningFlowOptimizer", `清理过期会话：${cleaned}个`);
  }

  // ==================== 私有方法 ====================

  /**
   * 优化状态切换
   */
  private optimizeStateTransition(
    session: LearningSession,
    oldState: LearningState,
    newState: LearningState
  ): void {
    // 评估 → 学习：预加载内容
    if (oldState === LearningState.ASSESSING && newState === LearningState.LEARNING) {
      this.preloadLearningContent(session);
    }
    
    // 学习 → 练习：准备练习题
    if (oldState === LearningState.LEARNING && newState === LearningState.PRACTICING) {
      this.preparePracticeQuestions(session);
    }
    
    // 练习 → 复习：安排复习计划
    if (oldState === LearningState.PRACTICING && newState === LearningState.REVIEWING) {
      this.scheduleReview(session);
    }
  }

  /**
   * 预加载学习内容
   */
  private preloadLearningContent(session: LearningSession): void {
    HiLog.info("LearningFlowOptimizer", `预加载学习内容：${session.skillId}`);
    // TODO: 预加载下一步内容
  }

  /**
   * 准备练习题
   */
  private preparePracticeQuestions(session: LearningSession): void {
    HiLog.info("LearningFlowOptimizer", `准备练习题：${session.skillId}`);
    // TODO: 根据学习情况生成练习题
  }

  /**
   * 安排复习计划
   */
  private scheduleReview(session: LearningSession): void {
    HiLog.info("LearningFlowOptimizer", `安排复习：${session.skillId}`);
    // TODO: 根据 FSRS 安排复习
  }

  /**
   * 更新专注度评分
   */
  private updateFocusScore(session: LearningSession): void {
    // 根据中断次数降低专注度
    const penalty = session.interruptions * 5;
    session.focusScore = Math.max(0, 100 - penalty);
  }

  /**
   * 计算最终得分
   */
  private calculateFinalScore(session: LearningSession): number {
    const progressScore = session.progress.completionRate * 0.5;
    const accuracyScore = session.progress.accuracy * 0.3;
    const focusScore = session.focusScore * 0.2;
    
    return progressScore + accuracyScore + focusScore;
  }

  /**
   * 计算效率
   */
  private calculateEfficiency(session: LearningSession): number {
    const duration = (session.endTime || Date.now()) - session.startTime;
    const durationMinutes = duration / 60000;
    
    if (durationMinutes === 0) return 0;
    
    return (session.progress.completionRate * session.focusScore) / durationMinutes;
  }

  /**
   * 开始自动保存
   */
  private startAutoSave(sessionId: string): void {
    setInterval(() => {
      this.saveCheckpoint(sessionId);
    }, this.config.autoSaveInterval * 1000);
  }

  /**
   * 开始休息提醒
   */
  private startBreakReminder(sessionId: string): void {
    setInterval(() => {
      HiLog.info("LearningFlowOptimizer", `休息提醒：${sessionId}`);
      // TODO: 发送休息提醒
    }, this.config.breakReminderInterval * 60 * 1000);
  }

  /**
   * 保存检查点
   */
  private saveCheckpoint(sessionId: string): void {
    HiLog.info("LearningFlowOptimizer", `保存检查点：${sessionId}`);
    // TODO: 保存到本地存储
  }

  /**
   * 加载检查点
   */
  private loadCheckpoint(sessionId: string): void {
    HiLog.info("LearningFlowOptimizer", `加载检查点：${sessionId}`);
    // TODO: 从本地存储加载
  }

  /**
   * 记录优化历史
   */
  private recordOptimization(sessionId: string, data: any): void {
    if (!this.optimizationHistory.has(sessionId)) {
      this.optimizationHistory.set(sessionId, []);
    }
    this.optimizationHistory.get(sessionId)!.push(data);
  }
}

/**
 * 便捷函数
 */
export function startLearningSession(userId: string, skillId: string): LearningSession {
  return LearningFlowOptimizer.getInstance().startSession(userId, skillId);
}

export function updateLearningProgress(sessionId: string, updates: Partial<LearningProgress>): void {
  LearningFlowOptimizer.getInstance().updateProgress(sessionId, updates);
}

export function transitionLearningState(sessionId: string, newState: LearningState): void {
  LearningFlowOptimizer.getInstance().transitionState(sessionId, newState);
}

export function completeLearningSession(sessionId: string): void {
  LearningFlowOptimizer.getInstance().completeSession(sessionId);
}

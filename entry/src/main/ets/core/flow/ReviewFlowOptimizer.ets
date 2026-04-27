/**
 * ============================================================================
 * 复习流程优化器 - ReviewFlowOptimizer
 * 目标：基于 FSRS 优化复习流程，最大化记忆保持率
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 复习项
 */
export interface ReviewItem {
  id: string;
  userId: string;
  skillId: string;
  stepNumber: number;
  
  // FSRS 参数
  stability: number;        // 稳定度
  difficulty: number;       // 难度
  retrievability: number;   // 可回忆性
  interval: number;         // 间隔（天）
  
  // 状态
  dueTime: number;          // 到期时间
  priority: 'high' | 'medium' | 'low';
  consecutiveCorrect: number;
  lastReviewTime: number;
}

/**
 * 复习队列
 */
export interface ReviewQueue {
  items: ReviewItem[];
  totalItems: number;
  estimatedTime: number;    // 预计用时（分钟）
  priority Distribution: {
    high: number;
    medium: number;
    low: number;
  };
}

/**
 * 复习配置
 */
export interface ReviewConfig {
  dailyLimit: number;       // 每日复习上限
  sessionLimit: number;     // 每次会话上限
  priorityThreshold: number; // 优先级阈值
  adaptiveScheduling: boolean; // 自适应调度
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: ReviewConfig = {
  dailyLimit: 100,
  sessionLimit: 20,
  priorityThreshold: 0.7,
  adaptiveScheduling: true
};

/**
 * 复习流程优化器
 */
export class ReviewFlowOptimizer {
  private static instance: ReviewFlowOptimizer | null = null;
  
  private config: ReviewConfig;
  private reviewQueue: Map<string, ReviewItem> = new Map();
  private completedToday: Map<string, number> = new Map(); // userId -> count

  /**
   * 获取单例实例
   */
  static getInstance(config?: Partial<ReviewConfig>): ReviewFlowOptimizer {
    if (!ReviewFlowOptimizer.instance) {
      ReviewFlowOptimizer.instance = new ReviewFlowOptimizer(config);
    }
    return ReviewFlowOptimizer.instance;
  }

  private constructor(config?: Partial<ReviewConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    HiLog.info("ReviewFlowOptimizer", "初始化");
  }

  /**
   * 添加复习项
   */
  addReviewItem(item: ReviewItem): void {
    const key = this.generateKey(item.userId, item.skillId, item.stepNumber);
    this.reviewQueue.set(key, item);
    
    HiLog.info("ReviewFlowOptimizer", 
      `添加复习项：${key}, 到期：${new Date(item.dueTime).toLocaleString()}`);
  }

  /**
   * 获取用户的复习队列
   */
  getUserReviewQueue(userId: string): ReviewQueue {
    const items: ReviewItem[] = [];
    const now = Date.now();
    
    // 筛选到期项
    for (const item of this.reviewQueue.values()) {
      if (item.userId === userId && item.dueTime <= now) {
        items.push(item);
      }
    }
    
    // 按优先级排序
    items.sort((a, b) => {
      const priorityOrder = { high: 0, medium: 1, low: 2 };
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    });
    
    // 限制数量
    const limited = items.slice(0, this.config.sessionLimit);
    
    // 计算统计
    const stats = {
      high: limited.filter(i => i.priority === 'high').length,
      medium: limited.filter(i => i.priority === 'medium').length,
      low: limited.filter(i => i.priority === 'low').length
    };
    
    return {
      items: limited,
      totalItems: limited.length,
      estimatedTime: limited.length * 2, // 每项约 2 分钟
      priority Distribution: stats
    };
  }

  /**
   * 完成复习
   */
  completeReview(
    userId: string,
    skillId: string,
    stepNumber: number,
    rating: 'again' | 'hard' | 'good' | 'easy'
  ): ReviewItem | null {
    const key = this.generateKey(userId, skillId, stepNumber);
    const item = this.reviewQueue.get(key);
    
    if (!item) {
      HiLog.warn("ReviewFlowOptimizer", `复习项不存在：${key}`);
      return null;
    }
    
    // 更新 FSRS 参数
    this.updateFSRSParams(item, rating);
    
    // 计算下次复习时间
    item.nextReviewTime = this.calculateNextReview(item);
    
    // 记录完成
    this.recordCompletion(userId);
    
    // 从队列移除
    this.reviewQueue.delete(key);
    
    HiLog.info("ReviewFlowOptimizer", 
      `完成复习：${key}, 评分：${rating}, 下次：${new Date(item.nextReviewTime).toLocaleString()}`);
    
    return item;
  }

  /**
   * 智能调度复习
   */
  smartSchedule(userId: string): ReviewItem[] {
    HiLog.info("ReviewFlowOptimizer", `智能调度：${userId}`);
    
    const queue = this.getUserReviewQueue(userId);
    const scheduled: ReviewItem[] = [];
    
    // 优先安排高优先级
    for (const item of queue.items) {
      if (item.priority === 'high') {
        scheduled.push(item);
      }
    }
    
    // 自适应调度
    if (this.config.adaptiveScheduling) {
      this.adaptiveSchedule(scheduled, userId);
    }
    
    return scheduled;
  }

  /**
   * 获取复习统计
   */
  getReviewStats(userId: string): {
    totalDue: number;
    completedToday: number;
    remainingToday: number;
    accuracy: number;
    streak: number;
  } {
    const queue = this.getUserReviewQueue(userId);
    const completed = this.completedToday.get(userId) || 0;
    const remaining = Math.max(0, this.config.dailyLimit - completed);
    
    return {
      totalDue: queue.totalItems,
      completedToday: completed,
      remainingToday: remaining,
      accuracy: 0, // TODO: 计算准确率
      streak: 0    // TODO: 获取连续天数
    };
  }

  /**
   * 清除过期复习项
   */
  cleanupExpiredItems(maxAge: number = 30): void {
    const now = Date.now();
    const maxAgeMs = maxAge * 24 * 60 * 60 * 1000;
    let cleaned = 0;
    
    for (const [key, item] of this.reviewQueue.entries()) {
      const age = now - item.lastReviewTime;
      if (age > maxAgeMs) {
        this.reviewQueue.delete(key);
        cleaned++;
      }
    }
    
    HiLog.info("ReviewFlowOptimizer", `清理过期复习项：${cleaned}个`);
  }

  // ==================== 私有方法 ====================

  /**
   * 生成键
   */
  private generateKey(userId: string, skillId: string, stepNumber: number): string {
    return `${userId}_${skillId}_${stepNumber}`;
  }

  /**
   * 更新 FSRS 参数
   */
  private updateFSRSParams(item: ReviewItem, rating: string): void {
    // 根据评分调整参数
    switch (rating) {
      case 'again':
        item.stability *= 0.5;
        item.difficulty = Math.min(10, item.difficulty + 2);
        break;
      case 'hard':
        item.stability *= 0.8;
        item.difficulty = Math.min(10, item.difficulty + 0.5);
        break;
      case 'good':
        item.stability *= 1.2;
        item.difficulty = Math.max(1, item.difficulty - 0.5);
        break;
      case 'easy':
        item.stability *= 1.5;
        item.difficulty = Math.max(1, item.difficulty - 1);
        break;
    }
    
    item.consecutiveCorrect = rating === 'again' ? 0 : item.consecutiveCorrect + 1;
  }

  /**
   * 计算下次复习时间
   */
  private calculateNextReview(item: ReviewItem): number {
    // 基于稳定度计算间隔
    const intervalDays = item.stability;
    const intervalMs = intervalDays * 24 * 60 * 60 * 1000;
    
    return Date.now() + intervalMs;
  }

  /**
   * 自适应调度
   */
  private adaptiveSchedule(items: ReviewItem[], userId: string): void {
    // 根据用户状态调整
    const stats = this.getReviewStats(userId);
    
    // 如果今天已完成很多，减少安排
    if (stats.completedToday > this.config.dailyLimit * 0.8) {
      items.splice(this.config.sessionLimit / 2);
    }
    
    // 如果准确率低，增加高优先级项
    if (stats.accuracy < 0.6) {
      items.sort((a, b) => {
        if (a.priority === 'high') return -1;
        if (b.priority === 'high') return 1;
        return 0;
      });
    }
  }

  /**
   * 记录完成
   */
  private recordCompletion(userId: string): void {
    const count = this.completedToday.get(userId) || 0;
    this.completedToday.set(userId, count + 1);
  }
}

/**
 * 便捷函数
 */
export function addReviewItem(item: ReviewItem): void {
  ReviewFlowOptimizer.getInstance().addReviewItem(item);
}

export function getUserReviewQueue(userId: string): ReviewQueue {
  return ReviewFlowOptimizer.getInstance().getUserReviewQueue(userId);
}

export function completeReview(
  userId: string,
  skillId: string,
  stepNumber: number,
  rating: 'again' | 'hard' | 'good' | 'easy'
): ReviewItem | null {
  return ReviewFlowOptimizer.getInstance().completeReview(userId, skillId, stepNumber, rating);
}

export function smartSchedule(userId: string): ReviewItem[] {
  return ReviewFlowOptimizer.getInstance().smartSchedule(userId);
}

export function getReviewStats(userId: string): any {
  return ReviewFlowOptimizer.getInstance().getReviewStats(userId);
}

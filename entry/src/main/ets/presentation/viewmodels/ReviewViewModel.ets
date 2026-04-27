/**
 * ============================================================================
 * 复习页 ViewModel - ReviewViewModel
 * FSRS 复习提醒
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { TemporalAbilityGraph } from '../../domain/algorithms/impl/TemporalAbilityGraph';

/**
 * 复习项
 */
export interface ReviewItem {
  skillId: string;
  skillName: string;
  stepNumber: number;
  dueTime: number;
  retrievability: number;
  interval: number;
  priority: 'high' | 'medium' | 'low';
}

/**
 * 复习页 ViewModel
 */
export class ReviewViewModel {
  private abilityGraph: TemporalAbilityGraph;
  
  // 状态
  private reviewItems: ReviewItem[] = [];
  private isRefreshing: boolean = false;
  private lastRefreshTime: number = 0;
  
  // 回调
  private onStateChanged?: () => void;

  constructor() {
    this.abilityGraph = TemporalAbilityGraph.getInstance();
    HiLog.info("ReviewViewModel", "初始化");
  }

  /**
   * 设置状态变化回调
   */
  setOnStateChanged(callback: () => void): void {
    this.onStateChanged = callback;
  }

  /**
   * 获取复习项列表
   */
  getReviewItems(): ReviewItem[] {
    return [...this.reviewItems];
  }

  /**
   * 获取刷新状态
   */
  isRefreshingData(): boolean {
    return this.isRefreshing;
  }

  /**
   * 刷新复习列表
   */
  async refresh(userId: string): Promise<void> {
    HiLog.info("ReviewViewModel", `刷新复习列表：${userId}`);
    
    this.isRefreshing = true;
    this.notifyStateChanged();
    
    try {
      // 获取待复习项
      const pendingReviews = this.abilityGraph.getPendingReviews(userId);
      
      // 转换为 ReviewItem
      this.reviewItems = pendingReviews.map(review => ({
        skillId: review.skillId,
        skillName: review.skillName || '未知技能',
        stepNumber: review.stepNumber,
        dueTime: review.nextReview,
        retrievability: review.retrievability || 0,
        interval: review.interval || 0,
        priority: this.calculatePriority(review.retrievability),
      }));
      
      // 按优先级排序
      this.reviewItems.sort((a, b) => {
        const priorityOrder = { high: 0, medium: 1, low: 2 };
        return priorityOrder[a.priority] - priorityOrder[b.priority];
      });
      
      this.lastRefreshTime = Date.now();
    } catch (error: any) {
      HiLog.error("ReviewViewModel", `刷新失败：${error.message}`);
    } finally {
      this.isRefreshing = false;
      this.notifyStateChanged();
    }
  }

  /**
   * 完成复习
   */
  completeReview(skillId: string, stepNumber: number, isCorrect: boolean): void {
    HiLog.info("ReviewViewModel", `完成复习：${skillId}/${stepNumber}, 正确：${isCorrect}`);
    
    // 从列表中移除
    this.reviewItems = this.reviewItems.filter(
      item => !(item.skillId === skillId && item.stepNumber === stepNumber)
    );
    
    this.notifyStateChanged();
  }

  /**
   * 跳过复习
   */
  skipReview(skillId: string, stepNumber: number): void {
    HiLog.info("ReviewViewModel", `跳过复习：${skillId}/${stepNumber}`);
    
    // 从列表中移除
    this.reviewItems = this.reviewItems.filter(
      item => !(item.skillId === skillId && item.stepNumber === stepNumber)
    );
    
    this.notifyStateChanged();
  }

  /**
   * 获取统计信息
   */
  getStats(): {
    total: number;
    highPriority: number;
    mediumPriority: number;
    lowPriority: number;
  } {
    return {
      total: this.reviewItems.length,
      highPriority: this.reviewItems.filter(i => i.priority === 'high').length,
      mediumPriority: this.reviewItems.filter(i => i.priority === 'medium').length,
      lowPriority: this.reviewItems.filter(i => i.priority === 'low').length,
    };
  }

  /**
   * 计算优先级
   */
  private calculatePriority(retrievability?: number): 'high' | 'medium' | 'low' {
    if (retrievability === undefined || retrievability < 0.5) {
      return 'high';
    }
    if (retrievability < 0.7) {
      return 'medium';
    }
    return 'low';
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
    this.reviewItems = [];
  }
}

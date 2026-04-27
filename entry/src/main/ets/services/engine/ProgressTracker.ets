/**
 * ============================================================================
 * 进度追踪服务 - ProgressTracker
 * 负责追踪用户学习进度、管理学习历史、提供进度报告
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 学习进度
 */
export interface LearningProgress {
  skillId: string;
  skillName: string;
  currentStep: number;
  totalSteps: number;
  completionPercent: number;
  totalTimeSpent: number;
  lastLearnDate: string;
  status: 'not_started' | 'in_progress' | 'completed' | 'review';
}

/**
 * 学习记录
 */
export interface LearningRecord {
  id: string;
  skillId: string;
  stepNumber: number;
  practiceResult: 'correct' | 'incorrect';
  timeSpent: number;
  timestamp: number;
  notes?: string;
}

/**
 * 进度报告
 */
export interface ProgressReport {
  totalSkills: number;
  completedSkills: number;
  inProgressSkills: number;
  totalTimeSpent: number;
  currentStreak: number;
  achievements: number;
  weakSkills: string[];
  recentActivity: LearningRecord[];
}

/**
 * 进度追踪服务
 */
export class ProgressTracker {
  private static instance: ProgressTracker | null = null;

  // 用户进度数据
  private userProgress: Map<string, Map<string, LearningProgress>> = new Map();
  private userRecords: Map<string, LearningRecord[]> = new Map();

  static getInstance(): ProgressTracker {
    if (!ProgressTracker.instance) {
      ProgressTracker.instance = new ProgressTracker();
    }
    return ProgressTracker.instance;
  }

  private constructor() {}

  /**
   * 追踪学习进度
   */
  track(
    userId: string,
    skillId: string,
    skillName: string,
    stepNumber: number,
    totalSteps: number,
    timeSpent: number
  ): LearningProgress {
    HiLog.info("ProgressTracker", `追踪: ${userId}/${skillId}, 步骤${stepNumber}/${totalSteps}`);
    
    // 获取或创建用户进度
    if (!this.userProgress.has(userId)) {
      this.userProgress.set(userId, new Map());
    }
    const userPro = this.userProgress.get(userId)!;

    // 计算完成度
    const completionPercent = totalSteps > 0 ? Math.round((stepNumber / totalSteps) * 100) : 0;

    // 确定状态
    let status: LearningProgress['status'] = 'in_progress';
    if (stepNumber === 0 || completionPercent === 0) {
      status = 'not_started';
    } else if (completionPercent >= 100) {
      status = 'completed';
    }

    // 创建或更新进度
    const progress: LearningProgress = {
      skillId,
      skillName,
      currentStep: stepNumber,
      totalSteps,
      completionPercent,
      totalTimeSpent: timeSpent,
      lastLearnDate: this.getTodayString(),
      status
    };

    userPro.set(skillId, progress);

    // 添加学习记录
    this.addRecord(userId, skillId, stepNumber, 'correct', timeSpent);

    return progress;
  }

  /**
   * 报告进度
   * 生成用户整体学习报告
   */
  report(userId: string): ProgressReport {
    HiLog.info("ProgressTracker", `生成报告: ${userId}`);
    
    const userPro = this.userProgress.get(userId);
    const records = this.userRecords.get(userId) || [];

    let totalSkills = 0;
    let completedSkills = 0;
    let inProgressSkills = 0;
    let totalTimeSpent = 0;
    const weakSkills: string[] = [];

    if (userPro) {
      userPro.forEach((progress, skillId) => {
        totalSkills++;
        totalTimeSpent += progress.totalTimeSpent;
        
        if (progress.status === 'completed') {
          completedSkills++;
        } else if (progress.status === 'in_progress') {
          inProgressSkills++;
          // 进度低于50%的算薄弱
          if (progress.completionPercent < 50) {
            weakSkills.push(progress.skillName);
          }
        }
      });
    }

    // 获取最近活动
    const recentActivity = records.slice(-10).reverse();

    // 获取连续学习天数（简化版）
    const currentStreak = this.calculateStreak(records);

    const report: ProgressReport = {
      totalSkills,
      completedSkills,
      inProgressSkills,
      totalTimeSpent,
      currentStreak,
      achievements: 0,
      weakSkills,
      recentActivity
    };

    return report;
  }

  /**
   * 推荐复习
   * 根据遗忘曲线推荐需要复习的技能
   */
  recommendReview(userId: string): LearningProgress[] {
    const userPro = this.userProgress.get(userId);
    if (!userPro) return [];

    const reviews: LearningProgress[] = [];
    const today = new Date();

    userPro.forEach((progress, skillId) => {
      if (progress.status === 'completed' || progress.completionPercent >= 80) {
        // 检查是否需要复习（超过7天没复习）
        const lastLearn = new Date(progress.lastLearnDate);
        const daysSince = Math.floor((today.getTime() - lastLearn.getTime()) / (1000 * 60 * 60 * 24));
        
        if (daysSince >= 7) {
          progress.status = 'review';
          reviews.push(progress);
        }
      }
    });

    // 按时间排序，最久没复习的排前面
    reviews.sort((a, b) => 
      new Date(a.lastLearnDate).getTime() - new Date(b.lastLearnDate).getTime()
    );

    return reviews.slice(0, 3);
  }

  /**
   * 获取技能进度
   */
  getSkillProgress(userId: string, skillId: string): LearningProgress | null {
    const userPro = this.userProgress.get(userId);
    if (!userPro) return null;
    return userPro.get(skillId) || null;
  }

  /**
   * 获取用户所有进度
   */
  getAllProgress(userId: string): LearningProgress[] {
    const userPro = this.userProgress.get(userId);
    if (!userPro) return [];
    return Array.from(userPro.values());
  }

  /**
   * 获取学习历史
   */
  getLearningHistory(userId: string, skillId?: string): LearningRecord[] {
    const records = this.userRecords.get(userId) || [];
    if (skillId) {
      return records.filter(r => r.skillId === skillId);
    }
    return records;
  }

  /**
   * 添加学习记录
   */
  private addRecord(
    userId: string,
    skillId: string,
    stepNumber: number,
    result: 'correct' | 'incorrect',
    timeSpent: number
  ): void {
    if (!this.userRecords.has(userId)) {
      this.userRecords.set(userId, []);
    }

    const record: LearningRecord = {
      id: `record_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      skillId,
      stepNumber,
      practiceResult: result,
      timeSpent,
      timestamp: Date.now()
    };

    this.userRecords.get(userId)!.push(record);
  }

  /**
   * 计算连续学习天数
   */
  private calculateStreak(records: LearningRecord[]): number {
    if (records.length === 0) return 0;

    // 获取所有学习日期（去重）
    const dates = new Set<string>();
    records.forEach(r => {
      const date = new Date(r.timestamp).toISOString().split('T')[0];
      dates.add(date);
    });

    // 排序日期
    const sortedDates = Array.from(dates).sort().reverse();
    
    const today = this.getTodayString();
    const yesterday = this.getYesterdayString();

    // 检查是否今天或昨天学习过
    if (sortedDates[0] !== today && sortedDates[0] !== yesterday) {
      return 0;
    }

    // 计算连续天数
    let streak = 1;
    for (let i = 1; i < sortedDates.length; i++) {
      const current = new Date(sortedDates[i - 1]);
      const previous = new Date(sortedDates[i]);
      const diffDays = Math.floor((current.getTime() - previous.getTime()) / (1000 * 60 * 60 * 24));
      
      if (diffDays === 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /**
   * 获取今日字符串
   */
  private getTodayString(): string {
    return new Date().toISOString().split('T')[0];
  }

  /**
   * 获取昨日字符串
   */
  private getYesterdayString(): string {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return yesterday.toISOString().split('T')[0];
  }
}

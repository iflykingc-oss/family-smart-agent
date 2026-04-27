/**
 * ============================================================================
 * 反馈服务 - FeedbackService
 * 负责学习反馈、难度调整、能力评估
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 学习反馈
 */
export interface LearningFeedback {
  correct: boolean;
  score: number;
  warmMessage: string;
  skillImprovement: number;
  nextStep: 'continue' | 'review' | 'complete';
  suggestions?: string[];
}

/**
 * 难度调整参数
 */
export interface DifficultyAdjustment {
  currentDifficulty: number;
  suggestedDifficulty: number;
  reason: string;
}

/**
 * 学习统计
 */
export interface LearningStats {
  totalAttempts: number;
  correctCount: number;
  averageTime: number;
  weakAreas: string[];
  strongAreas: string[];
}

/**
 * 反馈服务
 */
export class FeedbackService {
  private static instance: FeedbackService | null = null;

  // 用户学习统计
  private userStats: Map<string, Map<string, LearningStats>> = new Map();

  static getInstance(): FeedbackService {
    if (!FeedbackService.instance) {
      FeedbackService.instance = new FeedbackService();
    }
    return FeedbackService.instance;
  }

  private constructor() {}

  /**
   * 给予学习反馈
   * 根据答题情况生成温暖鼓励的反馈
   */
  giveFeedback(
    userId: string,
    skillId: string,
    stepNumber: number,
    correct: boolean,
    answerTime: number
  ): LearningFeedback {
    HiLog.info("FeedbackService", `反馈: ${userId}/${skillId}/步骤${stepNumber}, 正确:${correct}`);
    
    // 更新统计
    this.updateStats(userId, skillId, correct, answerTime);

    // 生成反馈
    const feedback: LearningFeedback = {
      correct,
      score: correct ? 100 : 30,  // 答错也给30%分鼓励
      warmMessage: this.generateWarmMessage(correct, stepNumber),
      skillImprovement: correct ? 0.15 : 0.03,
      nextStep: correct ? 'continue' : 'review',
      suggestions: correct ? [] : this.getSuggestions(skillId, stepNumber)
    };

    return feedback;
  }

  /**
   * 适应难度调整
   * 根据用户表现调整推荐难度
   */
  adaptDifficulty(userId: string, skillId: string, currentDifficulty: number): DifficultyAdjustment {
    const stats = this.getStats(userId, skillId);
    
    if (!stats || stats.totalAttempts < 3) {
      return {
        currentDifficulty,
        suggestedDifficulty: currentDifficulty,
        reason: '数据不足，保持当前难度'
      };
    }

    const accuracy = stats.correctCount / stats.totalAttempts;

    // 连续答对 → 降低难度
    if (accuracy > 0.8 && stats.correctCount >= 3) {
      const newDifficulty = Math.max(1, currentDifficulty - 1);
      return {
        currentDifficulty,
        suggestedDifficulty: newDifficulty,
        reason: '表现很好，降低难度挑战更有成就～'
      };
    }

    // 连续答错 → 提高难度（提供更多帮助）
    if (accuracy < 0.4 && stats.totalAttempts >= 5) {
      const newDifficulty = Math.min(5, currentDifficulty + 1);
      return {
        currentDifficulty,
        suggestedDifficulty: newDifficulty,
        reason: '有点难，我们放慢脚步，多练习一下基础'
      };
    }

    return {
      currentDifficulty,
      suggestedDifficulty: currentDifficulty,
      reason: '节奏不错，保持这个速度～'
    };
  }

  /**
   * 获取学习统计
   */
  getStats(userId: string, skillId: string): LearningStats | null {
    const userSkillStats = this.userStats.get(userId);
    if (!userSkillStats) return null;
    return userSkillStats.get(skillId) || null;
  }

  /**
   * 获取薄弱点
   */
  getWeakPoints(userId: string, skillId: string): string[] {
    const stats = this.getStats(userId, skillId);
    return stats?.weakAreas || [];
  }

  /**
   * 获取强项
   */
  getStrongPoints(userId: string, skillId: string): string[] {
    const stats = this.getStats(userId, skillId);
    return stats?.strongAreas || [];
  }

  /**
   * 生成温暖的反馈文案
   */
  private generateWarmMessage(correct: boolean, stepNumber: number): string {
    if (correct) {
      const messages = [
        '太棒了！继续保持～',
        '回答正确！您学得真快！',
        '太厉害了！一击即中！',
        '完全正确，太骄傲了！',
        '太棒了！继续保持这个节奏～'
      ];
      return messages[Math.floor(Math.random() * messages.length)];
    } else {
      const messages = [
        '没关系，慢慢来～熟能生巧！',
        '别灰心，提示一下：{hint}',
        '没关系的，我们再来一次！',
        '学习就是不断试错的过程，继续加油！',
        '暂时没答对，但你的努力不会白费的～'
      ];
      return messages[Math.floor(Math.random() * messages.length)];
    }
  }

  /**
   * 获取建议
   */
  private getSuggestions(skillId: string, stepNumber: number): string[] {
    const suggestions: Record<string, string[]> = {
      'excel_basic': [
        '多熟悉一下单元格的位置',
        '试试先在脑子里想想公式结构',
        '回顾一下上一步讲的内容'
      ],
      'wechat_basic': [
        '可以打开微信实际操作一下',
        '记住入口位置很重要',
        '多试几次就熟悉了'
      ],
      'harmony_share': [
        '先确认设备都登录了华为账号',
        '检查一下网络连接是否正常',
        '从简单的功能开始尝试'
      ]
    };

    return suggestions[skillId] || ['多练习几次，慢慢来'];
  }

  /**
   * 更新统计
   */
  private updateStats(userId: string, skillId: string, correct: boolean, answerTime: number): void {
    if (!this.userStats.has(userId)) {
      this.userStats.set(userId, new Map());
    }
    
    const userSkillStats = this.userStats.get(userId)!;
    let stats = userSkillStats.get(skillId);
    
    if (!stats) {
      stats = {
        totalAttempts: 0,
        correctCount: 0,
        averageTime: 0,
        weakAreas: [],
        strongAreas: [],
        lastAttempts: []
      };
      userSkillStats.set(skillId, stats);
    }

    // 更新基础统计
    stats.totalAttempts++;
    if (correct) stats.correctCount++;
    
    // 更新平均时间
    stats.averageTime = (stats.averageTime * (stats.totalAttempts - 1) + answerTime) / stats.totalAttempts;

    // 记录最近10次尝试
    if (!stats.lastAttempts) stats.lastAttempts = [];
    stats.lastAttempts.push({ correct, time: answerTime, step: stepNumber });
    if (stats.lastAttempts.length > 10) {
      stats.lastAttempts.shift();
    }

    // 分析薄弱点和强项
    this.updateAreas(stats);
  }

  /**
   * 更新强弱项分析
   */
  private updateAreas(stats: LearningStats): void {
    if (!stats.lastAttempts || stats.lastAttempts.length < 3) return;

    const recent = stats.lastAttempts.slice(-5);
    const correctCount = recent.filter(a => a.correct).length;
    const accuracy = correctCount / recent.length;

    // 更新强项
    if (accuracy > 0.8 && !stats.strongAreas.includes('recent')) {
      stats.strongAreas.push('recent');
    }

    // 更新薄弱点
    if (accuracy < 0.4 && !stats.weakAreas.includes('recent')) {
      stats.weakAreas.push('recent');
    }
  }
}

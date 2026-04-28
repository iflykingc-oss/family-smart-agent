/**
 * ============================================================================
 * 进度仪表盘 - ProgressDashboard
 * 学习进度可视化 + 数据统计
 * 
 * 功能：
 * 1. 学习统计（总时长/完成技能/正确率/连续天数）
 * 2. 技能掌握度分布
 * 3. 学习趋势图
 * 4. 复习提醒列表
 * 5. 成就系统
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { LearningDataStore, LearningStats } from '../storage/LearningDataStore';
import { TemporalAbilityGraph, AbilityLevel } from './TemporalAbilityGraph';

const TAG = 'ProgressDashboard';

/**
 * 技能掌握度
 */
export interface SkillMastery {
  skillId: string;
  skillName: string;
  level: AbilityLevel;
  levelName: string;
  progress: number;  // 0-100
  practiceCount: number;
  lastPracticed: number;
  needsReview: boolean;
}

/**
 * 学习趋势数据
 */
export interface LearningTrend {
  date: string;
  timeSpent: number;  // 分钟
  practices: number;
  correctCount: number;
}

/**
 * 成就
 */
export interface Achievement {
  id: string;
  name: string;
  description: string;
  icon: string;
  unlocked: boolean;
  unlockedAt?: number;
}

/**
 * 进度仪表盘
 */
export class ProgressDashboard {
  private static instance: ProgressDashboard | null = null;
  private dataStore: LearningDataStore;
  private abilityGraph: TemporalAbilityGraph;

  static getInstance(): ProgressDashboard {
    if (!ProgressDashboard.instance) {
      ProgressDashboard.instance = new ProgressDashboard();
    }
    return ProgressDashboard.instance;
  }

  private constructor() {
    this.dataStore = LearningDataStore.getInstance();
    this.abilityGraph = TemporalAbilityGraph.getInstance();
  }

  /**
   * 获取完整仪表盘数据
   */
  async getDashboard(userId: string): Promise<{
    stats: LearningStats;
    skillMastery: SkillMastery[];
    dueReviews: SkillMastery[];
    trends: LearningTrend[];
    achievements: Achievement[];
  }> {
    try {
      // 1. 学习统计
      const stats = await this.dataStore.getLearningStats(userId);

      // 2. 技能掌握度
      const skillMastery = await this.getSkillMastery(userId);

      // 3. 需要复习的技能
      const dueReviews = skillMastery.filter(s => s.needsReview);

      // 4. 学习趋势（最近7天）
      const trends = await this.getLearningTrends(userId, 7);

      // 5. 成就
      const achievements = this.getAchievements(userId, stats, skillMastery);

      return { stats, skillMastery, dueReviews, trends, achievements };
    } catch (error) {
      HiLog.error(TAG, `获取仪表盘数据失败: ${JSON.stringify(error)}`);
      return {
        stats: { totalLearningTime: 0, completedSkills: 0, averageAccuracy: 0, streak: 0, totalPractices: 0 },
        skillMastery: [],
        dueReviews: [],
        trends: [],
        achievements: []
      };
    }
  }

  /**
   * 获取技能掌握度
   */
  private async getSkillMastery(userId: string): Promise<SkillMastery[]> {
    const skills = this.abilityGraph.getUserSkills(userId);
    const skillLibrary = this.abilityGraph.getSkillLibrary();

    return skills.map(skill => {
      const libSkill = skillLibrary.find(s => s.id === skill.skillId);
      const levelNames: Record<number, string> = {
        0: '未学习',
        1: '了解',
        2: '入门',
        3: '基础',
        4: '中级',
        5: '高级',
        6: '精通'
      };

      // 检查是否需要复习
      const reviewCheck = this.abilityGraph.checkReviewNeeded(userId, skill.skillId);

      return {
        skillId: skill.skillId,
        skillName: libSkill?.name || skill.skillId,
        level: skill.level as AbilityLevel,
        levelName: levelNames[skill.level] || '未知',
        progress: Math.round((skill.level / AbilityLevel.MASTER) * 100),
        practiceCount: skill.practiceCount,
        lastPracticed: skill.lastPracticed,
        needsReview: reviewCheck.needed
      };
    });
  }

  /**
   * 获取学习趋势
   */
  private async getLearningTrends(userId: string, days: number): Promise<LearningTrend[]> {
    const records = await this.dataStore.getLearningRecords(userId, 1000);
    const trends: LearningTrend[] = [];

    for (let i = days - 1; i >= 0; i--) {
      const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
      const dayRecords = records.filter(r => {
        const recordDate = new Date(r.createdAt).toISOString().split('T')[0];
        return recordDate === date;
      });

      const timeSpent = dayRecords.reduce((sum, r) => sum + r.timeSpent, 0) / 60;
      const correctCount = dayRecords.filter(r => r.result === 'correct').length;

      trends.push({
        date,
        timeSpent: Math.round(timeSpent),
        practices: dayRecords.length,
        correctCount
      });
    }

    return trends;
  }

  /**
   * 获取成就
   */
  private getAchievements(userId: string, stats: LearningStats, skills: SkillMastery[]): Achievement[] {
    const achievements: Achievement[] = [
      { id: 'first_step', name: '第一步', description: '完成第一次学习', icon: '🎯', unlocked: stats.totalPractices > 0 },
      { id: 'streak_3', name: '三天打鱼', description: '连续学习3天', icon: '🔥', unlocked: stats.streak >= 3 },
      { id: 'streak_7', name: '一周达人', description: '连续学习7天', icon: '⭐', unlocked: stats.streak >= 7 },
      { id: 'streak_30', name: '月度之星', description: '连续学习30天', icon: '🏆', unlocked: stats.streak >= 30 },
      { id: 'skill_1', name: '初出茅庐', description: '完成1个技能', icon: '📚', unlocked: stats.completedSkills >= 1 },
      { id: 'skill_5', name: '学富五车', description: '完成5个技能', icon: '🎓', unlocked: stats.completedSkills >= 5 },
      { id: 'skill_10', name: '博览群书', description: '完成10个技能', icon: '🌟', unlocked: stats.completedSkills >= 10 },
      { id: 'practice_10', name: '勤能补拙', description: '练习10次', icon: '💪', unlocked: stats.totalPractices >= 10 },
      { id: 'practice_50', name: '百炼成钢', description: '练习50次', icon: '⚡', unlocked: stats.totalPractices >= 50 },
      { id: 'accuracy_90', name: '百发百中', description: '正确率达到90%', icon: '🎯', unlocked: stats.averageAccuracy >= 0.9 },
      { id: 'time_1h', name: '一小时达人', description: '累计学习1小时', icon: '⏰', unlocked: stats.totalLearningTime >= 60 },
      { id: 'time_10h', name: '十小时大师', description: '累计学习10小时', icon: '🕐', unlocked: stats.totalLearningTime >= 600 },
    ];

    // 设置解锁时间
    return achievements.map(a => ({
      ...a,
      unlockedAt: a.unlocked ? Date.now() : undefined
    }));
  }

  /**
   * 获取技能分类统计
   */
  async getCategoryStats(userId: string): Promise<{
    professional: number;
    office: number;
    life: number;
    digital: number;
  }> {
    const skills = this.abilityGraph.getUserSkills(userId);
    
    return {
      professional: skills.filter(s => s.skillId.startsWith('comm_') || s.skillId.startsWith('time_') || s.skillId.startsWith('workplace_') || s.skillId.startsWith('resume_') || s.skillId.startsWith('email_') || s.skillId.startsWith('team_') || s.skillId.startsWith('problem_')).length,
      office: skills.filter(s => s.skillId.startsWith('excel_')).length,
      life: skills.filter(s => s.skillId.startsWith('wechat_') || s.skillId.startsWith('online_')).length,
      digital: skills.filter(s => s.skillId.startsWith('harmony_') || s.skillId.startsWith('security_')).length,
    };
  }
}

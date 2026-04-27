/**
 * ============================================================================
 * 数据分析服务 - AnalyticsService
 * 运营必备：用户行为分析
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { FeatureFlags } from '../core/config/FeatureFlags';
import { LearningRecordRepository } from '../data/repositories/impl/LearningRecordRepository';

/**
 * 用户行为事件
 */
export interface UserBehaviorEvent {
  userId: string;
  eventType: string;
  eventData: Record<string, any>;
  timestamp: number;
}

/**
 * 转化漏斗阶段
 */
export interface ConversionFunnelStage {
  name: string;
  users: number;
  conversionRate: number;
}

/**
 * 留存分析结果
 */
export interface RetentionAnalysis {
  day1Retention: number;
  day7Retention: number;
  day30Retention: number;
}

/**
 * 数据分析服务
 */
export class AnalyticsService {
  private static instance: AnalyticsService | null = null;
  
  private learningRecordRepository: LearningRecordRepository;

  /**
   * 获取单例实例
   */
  static getInstance(): AnalyticsService {
    if (!AnalyticsService.instance) {
      AnalyticsService.instance = new AnalyticsService();
    }
    return AnalyticsService.instance;
  }

  private constructor() {
    this.learningRecordRepository = LearningRecordRepository.getInstance();
    HiLog.info("AnalyticsService", "初始化");
  }

  /**
   * 追踪用户行为
   */
  async trackBehavior(event: UserBehaviorEvent): Promise<void> {
    // 检查功能开关
    if (!FeatureFlags.ENABLE_ANALYTICS) {
      return;
    }
    
    HiLog.debug("AnalyticsService", `追踪行为：${event.userId}/${event.eventType}`);
    
    // TODO: 保存到 AnalyticsLocalDataSource
    // 简化实现：只记录日志
    console.log(`[Analytics] ${event.eventType}:`, event.eventData);
  }

  /**
   * 计算转化漏斗
   */
  async calculateConversionFunnel(): Promise<ConversionFunnelStage[]> {
    // 检查功能开关
    if (!FeatureFlags.ENABLE_CONVERSION_FUNNEL) {
      return [];
    }
    
    // 简化实现：返回模拟数据
    return [
      { name: '访问首页', users: 1000, conversionRate: 100 },
      { name: '开始学习', users: 600, conversionRate: 60 },
      { name: '完成第一步', users: 400, conversionRate: 40 },
      { name: '完成技能', users: 200, conversionRate: 20 },
      { name: '分享成就', users: 50, conversionRate: 5 },
    ];
  }

  /**
   * 分析留存率
   */
  async analyzeRetention(): Promise<RetentionAnalysis> {
    // 检查功能开关
    if (!FeatureFlags.ENABLE_RETENTION_ANALYSIS) {
      return { day1Retention: 0, day7Retention: 0, day30Retention: 0 };
    }
    
    // 简化实现：返回模拟数据
    return {
      day1Retention: 0.65,
      day7Retention: 0.35,
      day30Retention: 0.15,
    };
  }

  /**
   * 获取用户学习统计
   */
  async getUserStats(userId: string): Promise<{
    totalLearningTime: number;
    completedSkills: number;
    averageAccuracy: number;
    streak: number;
  }> {
    const records = await this.learningRecordRepository.findByUserId(userId, 1000);
    
    const totalLearningTime = records.reduce((sum, r) => sum + r.timeSpent, 0) / 60; // 转换为分钟
    const completedSkills = 0; // TODO: 统计完成技能数
    const correctCount = records.filter(r => r.isCorrect()).length;
    const averageAccuracy = records.length > 0 ? correctCount / records.length : 0;
    const streak = 0; // TODO: 统计连续学习天数
    
    return {
      totalLearningTime: Math.round(totalLearningTime),
      completedSkills,
      averageAccuracy: Math.round(averageAccuracy * 100),
      streak,
    };
  }

  /**
   * 导出分析报告
   */
  async exportReport(startDate: string, endDate: string): Promise<string> {
    const funnel = await this.calculateConversionFunnel();
    const retention = await this.analyzeRetention();
    
    const report = `
# 数据分析报告

## 时间范围
${startDate} - ${endDate}

## 转化漏斗
${funnel.map(s => `- ${s.name}: ${s.users}人 (${s.conversionRate}%)`).join('\n')}

## 留存率
- 次日留存：${(retention.day1Retention * 100).toFixed(1)}%
- 7 日留存：${(retention.day7Retention * 100).toFixed(1)}%
- 30 日留存：${(retention.day30Retention * 100).toFixed(1)}%

## 建议
${this.generateSuggestions(funnel, retention)}
`;
    
    return report;
  }

  /**
   * 生成优化建议
   */
  private generateSuggestions(
    funnel: ConversionFunnelStage[],
    retention: RetentionAnalysis
  ): string {
    const suggestions: string[] = [];
    
    // 分析转化漏斗
    if (funnel.length >= 2) {
      const dropOffRate = 1 - (funnel[1].conversionRate / 100);
      if (dropOffRate > 0.5) {
        suggestions.push('- 访问→学习转化率较低，建议优化首页引导');
      }
    }
    
    // 分析留存率
    if (retention.day1Retention < 0.5) {
      suggestions.push('- 次日留存较低，建议加强新手引导');
    }
    if (retention.day7Retention < 0.2) {
      suggestions.push('- 7 日留存较低，建议增加学习激励');
    }
    
    return suggestions.join('\n') || '- 数据表现良好，继续保持';
  }
}

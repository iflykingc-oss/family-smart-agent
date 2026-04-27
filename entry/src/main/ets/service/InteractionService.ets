/**
 * ============================================================================
 * 双角色互动服务 - InteractionService
 * 结合 BKT+FSRS 的互动服务
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { UpdateKnowledgeTrackingUseCase } from '../domain/usecases/UpdateKnowledgeTrackingUseCase';
import { KnowledgeTrackingEntity } from '../domain/entities/KnowledgeTrackingEntity';
import { LearningRecordEntity, LearningResult } from '../domain/entities/LearningRecordEntity';
import { LearningRecordRepository } from '../data/repositories/impl/LearningRecordRepository';

/**
 * 互动模式
 */
export enum InteractionMode {
  TEACHER = 'teacher',    // 导师模式（讲解）
  PRACTICE = 'practice',  // 陪练模式（练习）
}

/**
 * 互动消息
 */
export interface InteractionMessage {
  id: string;
  mode: InteractionMode;
  content: string;
  suggestions?: string[];
  metadata?: any;
}

/**
 * 互动服务
 */
export class InteractionService {
  private static instance: InteractionService | null = null;
  
  private knowledgeTrackingUseCase: UpdateKnowledgeTrackingUseCase;
  private learningRecordRepository: LearningRecordRepository;

  /**
   * 获取单例实例
   */
  static getInstance(): InteractionService {
    if (!InteractionService.instance) {
      InteractionService.instance = new InteractionService();
    }
    return InteractionService.instance;
  }

  private constructor() {
    this.learningRecordRepository = LearningRecordRepository.getInstance();
    this.knowledgeTrackingUseCase = UpdateKnowledgeTrackingUseCase.getInstance(
      this.learningRecordRepository // 简化实现，实际应该用 KnowledgeTrackingRepository
    );
    HiLog.info("InteractionService", "初始化");
  }

  /**
   * 处理用户回答
   */
  async handleUserAnswer(
    userId: string,
    skillId: string,
    knowledgePointId: string,
    isCorrect: boolean
  ): Promise<{
    masteryProbability: number;
    recommendation: 'review' | 'continue' | 'complete';
    message: InteractionMessage;
  }> {
    HiLog.info("InteractionService", `处理回答：${userId}/${knowledgePointId}, 正确：${isCorrect}`);
    
    // 1. 更新知识追踪（BKT 算法）
    const trackingResult = await this.knowledgeTrackingUseCase.execute({
      userId,
      skillId,
      knowledgePointId,
      isCorrect,
    });
    
    // 2. 保存学习记录
    const record = new LearningRecordEntity(
      `record_${Date.now()}`,
      userId,
      skillId,
      1, // stepNumber
      `practice_${Date.now()}`,
      isCorrect ? LearningResult.CORRECT : LearningResult.INCORRECT,
      30, // timeSpent
      0, // hintsUsed
      new Date().getHours(),
      'phone',
      new Date().toISOString().split('T')[0],
      new Date().getDay(),
      Date.now()
    );
    await this.learningRecordRepository.save(record);
    
    // 3. 生成反馈消息
    const message = this.generateFeedbackMessage(isCorrect, trackingResult.masteryProbability || 0);
    
    HiLog.info("InteractionService", 
      `处理完成：掌握度${(trackingResult.masteryProbability || 0) * 100}%, 推荐：${trackingResult.recommendation}`
    );
    
    return {
      masteryProbability: trackingResult.masteryProbability || 0,
      recommendation: trackingResult.recommendation || 'continue',
      message,
    };
  }

  /**
   * 生成反馈消息
   */
  private generateFeedbackMessage(isCorrect: boolean, masteryProbability: number): InteractionMessage {
    const mode = isCorrect ? InteractionMode.TEACHER : InteractionMode.PRACTICE;
    
    let content: string;
    const suggestions: string[] = [];
    
    if (isCorrect) {
      content = this.getPraiseMessage(masteryProbability);
      if (masteryProbability < 0.95) {
        suggestions.push('继续下一题');
        suggestions.push('休息一下');
      } else {
        suggestions.push('完成学习');
        suggestions.push '挑战更高难度');
      }
    } else {
      content = this.getEncouragementMessage(masteryProbability);
      suggestions.push '再试一次');
      suggestions.push '查看提示');
    }
    
    return {
      id: `msg_${Date.now()}`,
      mode,
      content,
      suggestions,
    };
  }

  /**
   * 表扬消息
   */
  private getPraiseMessage(masteryProbability: number): string {
    const messages = [
      '太棒了！回答正确！继续保持～',
      '回答正确！你学得真快！',
      '完全正确！你的理解力很强！',
      '正确！继续保持这个节奏～',
    ];
    
    if (masteryProbability >= 0.95) {
      return '🎉 恭喜！你已经完全掌握这个知识点了！';
    }
    
    return messages[Math.floor(Math.random() * messages.length)];
  }

  /**
   * 鼓励消息
   */
  private getEncouragementMessage(masteryProbability: number): string {
    const messages = [
      '没关系，慢慢来～熟能生巧！',
      '别灰心，提示一下：再想想看',
      '没关系的，我们再来一次！',
      '学习就是不断试错的过程，继续加油！',
    ];
    
    if (masteryProbability < 0.5) {
      return '这个知识点有点难，要不要先复习一下基础？';
    }
    
    return messages[Math.floor(Math.random() * messages.length)];
  }

  /**
   * 切换互动模式
   */
  switchMode(currentMode: InteractionMode): InteractionMode {
    return currentMode === InteractionMode.TEACHER
      ? InteractionMode.PRACTICE
      : InteractionMode.TEACHER;
  }

  /**
   * 获取模式说明
   */
  getModeDescription(mode: InteractionMode): string {
    switch (mode) {
      case InteractionMode.TEACHER:
        return '导师模式：讲解概念，温柔鼓励';
      case InteractionMode.PRACTICE:
        return '陪练模式：出题练习，即时反馈';
      default:
        return '';
    }
  }
}

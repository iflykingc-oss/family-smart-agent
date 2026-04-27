/**
 * ============================================================================
 * 更新知识追踪用例 - UpdateKnowledgeTrackingUseCase
 * 单一职责：根据学习结果更新知识追踪状态
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { KnowledgeTrackingEntity } from '../entities/KnowledgeTrackingEntity';

/**
 * 更新知识追踪请求
 */
export interface UpdateKnowledgeTrackingRequest {
  /** 用户 ID */
  userId: string;
  
  /** 技能 ID */
  skillId: string;
  
  /** 知识点 ID */
  knowledgePointId: string;
  
  /** 是否正确 */
  isCorrect: boolean;
}

/**
 * 更新知识追踪结果
 */
export interface UpdateKnowledgeTrackingResult {
  /** 是否成功 */
  success: boolean;
  
  /** 掌握概率 */
  masteryProbability?: number;
  
  /** 是否已掌握 */
  isMastered?: boolean;
  
  /** 推荐操作 */
  recommendation?: 'review' | 'continue' | 'complete';
  
  /** 错误信息 */
  error?: string;
}

/**
 * 知识追踪仓库接口（依赖倒置）
 */
export interface IKnowledgeTrackingRepository {
  findById(userId: string, skillId: string, knowledgePointId: string): Promise<KnowledgeTrackingEntity | null>;
  save(entity: KnowledgeTrackingEntity): Promise<void>;
}

/**
 * 更新知识追踪用例
 */
export class UpdateKnowledgeTrackingUseCase {
  private repository: IKnowledgeTrackingRepository;
  private static instance: UpdateKnowledgeTrackingUseCase | null = null;

  constructor(repository: IKnowledgeTrackingRepository) {
    this.repository = repository;
  }

  static getInstance(repository: IKnowledgeTrackingRepository): UpdateKnowledgeTrackingUseCase {
    if (!UpdateKnowledgeTrackingUseCase.instance) {
      UpdateKnowledgeTrackingUseCase.instance = new UpdateKnowledgeTrackingUseCase(repository);
    }
    return UpdateKnowledgeTrackingUseCase.instance;
  }

  /**
   * 执行用例
   */
  async execute(request: UpdateKnowledgeTrackingRequest): Promise<UpdateKnowledgeTrackingResult> {
    HiLog.info("UpdateKnowledgeTrackingUseCase", `执行：${request.userId}/${request.knowledgePointId}`);
    
    try {
      // 1. 获取或创建知识追踪实体
      let entity = await this.repository.findById(
        request.userId,
        request.skillId,
        request.knowledgePointId
      );
      
      if (!entity) {
        // 创建新的追踪实体
        entity = new KnowledgeTrackingEntity(
          `kt_${Date.now()}`,
          request.userId,
          request.skillId,
          request.knowledgePointId
        );
      }
      
      // 2. 更新知识状态（BKT 算法）
      entity.update(request.isCorrect);
      
      // 3. 保存
      await this.repository.save(entity);
      
      HiLog.info("UpdateKnowledgeTrackingUseCase", 
        `知识追踪更新成功：掌握度${(entity.getMasteryProbability() * 100).toFixed(1)}%`
      );
      
      return {
        success: true,
        masteryProbability: entity.getMasteryProbability(),
        isMastered: entity.isMastered(),
        recommendation: entity.getRecommendation(),
      };
    } catch (error: any) {
      HiLog.error("UpdateKnowledgeTrackingUseCase", `知识追踪更新失败：${error.message}`);
      return {
        success: false,
        error: error.message,
      };
    }
  }
}

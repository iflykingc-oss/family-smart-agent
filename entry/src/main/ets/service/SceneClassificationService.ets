/**
 * ============================================================================
 * 场景分类服务 - SceneClassificationService
 * 场景分类服务
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { FeatureFlags } from '../core/config/FeatureFlags';
import { LLMRemoteDataSource } from '../data/datasources/impl/LLMRemoteDataSource';

/**
 * 场景类型
 */
export enum SceneType {
  OFFICE_REPORT = 'office_report',         // 办公报表
  OFFICE_ANALYSIS = 'office_analysis',     // 数据分析
  LIFE_FINANCE = 'life_finance',           // 家庭财务
  LIFE_HEALTH = 'life_health',             // 健康管理
  LIFE_COOKING = 'life_cooking',           // 烹饪学习
  STUDY_SKILL = 'study_skill',             // 技能学习
  SOCIAL_COMMUNICATION = 'social_comm',    // 沟通社交
  UNKNOWN = 'unknown',                     // 未知
}

/**
 * 场景分类结果
 */
export interface SceneClassificationResult {
  sceneType: SceneType;
  confidence: number;
  sceneName: string;
  keywords: string[];
}

/**
 * 场景分类服务
 */
export class SceneClassificationService {
  private static instance: SceneClassificationService | null = null;
  
  private llmDataSource: LLMRemoteDataSource;

  /**
   * 场景关键词库
   */
  private readonly keywordLibrary: Record<SceneType, string[]> = {
    [SceneType.OFFICE_REPORT]: ['报表', '报告', '汇总', '统计', 'Excel', '表格'],
    [SceneType.OFFICE_ANALYSIS]: ['分析', '数据', '透视表', '图表', '可视化'],
    [SceneType.LIFE_FINANCE]: ['家庭开支', '记账', '理财', '预算', '花钱', '收入'],
    [SceneType.LIFE_HEALTH]: ['健康', '运动', '减肥', '健身', '饮食', '体检'],
    [SceneType.LIFE_COOKING]: ['做菜', '做饭', '烹饪', '菜谱', '红烧肉', '炒菜'],
    [SceneType.STUDY_SKILL]: ['学习', '学会', '教程', '怎么学', '入门'],
    [SceneType.SOCIAL_COMMUNICATION]: ['微信', '聊天', '朋友圈', '社交', '沟通'],
    [SceneType.UNKNOWN]: [],
  };

  /**
   * 场景名称映射
   */
  private readonly sceneNames: Record<SceneType, string> = {
    [SceneType.OFFICE_REPORT]: '办公报表',
    [SceneType.OFFICE_ANALYSIS]: '数据分析',
    [SceneType.LIFE_FINANCE]: '家庭财务',
    [SceneType.LIFE_HEALTH]: '健康管理',
    [SceneType.LIFE_COOKING]: '烹饪学习',
    [SceneType.STUDY_SKILL]: '技能学习',
    [SceneType.SOCIAL_COMMUNICATION]: '沟通社交',
    [SceneType.UNKNOWN]: '未知场景',
  };

  /**
   * 获取单例实例
   */
  static getInstance(): SceneClassificationService {
    if (!SceneClassificationService.instance) {
      SceneClassificationService.instance = new SceneClassificationService();
    }
    return SceneClassificationService.instance;
  }

  private constructor() {
    this.llmDataSource = LLMRemoteDataSource.getInstance();
    HiLog.info("SceneClassificationService", "初始化");
  }

  /**
   * 分类场景
   */
  async classifyScene(userInput: string): Promise<SceneClassificationResult> {
    HiLog.info("SceneClassificationService", `分类场景：${userInput}`);
    
    // 检查功能开关
    if (!FeatureFlags.ENABLE_SCENE_CLASSIFIER) {
      HiLog.warn("SceneClassificationService", "场景分类已禁用");
      return {
        sceneType: SceneType.UNKNOWN,
        confidence: 0,
        sceneName: '未知场景',
        keywords: [],
      };
    }
    
    // 1. 关键词匹配（快速路径）
    const keywordMatch = this.matchByKeywords(userInput);
    if (keywordMatch && keywordMatch.confidence >= 0.7) {
      HiLog.info("SceneClassificationService", `关键词匹配：${keywordMatch.sceneType}`);
      return keywordMatch;
    }
    
    // 2. LLM 辅助分类（如果启用）
    if (FeatureFlags.ENABLE_LLM_GENERATION && FeatureFlags.ENABLE_LLM_ASSIST) {
      try {
        const llmResult = await this.classifyByLLM(userInput);
        if (llmResult.confidence >= 0.8) {
          return llmResult;
        }
      } catch (error: any) {
        HiLog.error("SceneClassificationService", `LLM 分类失败：${error.message}`);
      }
    }
    
    // 3. 降级：返回关键词匹配结果（即使置信度低）
    return keywordMatch || {
      sceneType: SceneType.UNKNOWN,
      confidence: 0,
      sceneName: '未知场景',
      keywords: [],
    };
  }

  /**
   * 关键词匹配
   */
  private matchByKeywords(userInput: string): SceneClassificationResult | null {
    const lowerInput = userInput.toLowerCase();
    
    let bestMatch: SceneClassificationResult | null = null;
    let bestScore = 0;
    
    for (const [sceneType, keywords] of Object.entries(this.keywordLibrary)) {
      let matchCount = 0;
      const matchedKeywords: string[] = [];
      
      for (const keyword of keywords) {
        if (lowerInput.includes(keyword.toLowerCase())) {
          matchCount++;
          matchedKeywords.push(keyword);
        }
      }
      
      const score = matchCount / keywords.length;
      if (score > bestScore && score > 0.3) {
        bestScore = score;
        bestMatch = {
          sceneType: sceneType as SceneType,
          confidence: score,
          sceneName: this.sceneNames[sceneType as SceneType],
          keywords: matchedKeywords,
        };
      }
    }
    
    return bestMatch;
  }

  /**
   * LLM 辅助分类
   */
  private async classifyByLLM(userInput: string): Promise<SceneClassificationResult> {
    const prompt = `分析用户的学习需求，将其分类到以下场景之一：
- office_report: 办公报表
- office_analysis: 数据分析
- life_finance: 家庭财务
- life_health: 健康管理
- life_cooking: 烹饪学习
- study_skill: 技能学习
- social_communication: 沟通社交

用户输入：${userInput}

返回 JSON 格式：{"sceneType": "场景类型", "confidence": 0.0-1.0, "keywords": ["关键词"]}`;

    const response = await this.llmDataSource.generateContent(prompt);
    
    try {
      const parsed = JSON.parse(response);
      return {
        sceneType: parsed.sceneType || SceneType.UNKNOWN,
        confidence: parsed.confidence || 0.5,
        sceneName: this.sceneNames[parsed.sceneType as SceneType] || '未知场景',
        keywords: parsed.keywords || [],
      };
    } catch (error) {
      HiLog.error("SceneClassificationService", `解析 LLM 响应失败：${error}`);
      return {
        sceneType: SceneType.UNKNOWN,
        confidence: 0,
        sceneName: '未知场景',
        keywords: [],
      };
    }
  }

  /**
   * 获取场景名称
   */
  getSceneName(sceneType: SceneType): string {
    return this.sceneNames[sceneType] || '未知场景';
  }

  /**
   * 获取场景关键词
   */
  getSceneKeywords(sceneType: SceneType): string[] {
    return this.keywordLibrary[sceneType] || [];
  }

  /**
   * 方言适配（简化实现）
   */
  adaptToDialect(text: string, dialect: string): string {
    const dialectPrefixes: Record<string, string> = {
      '东北': '俺',
      '四川': '娃儿',
      '粤语': '睇',
      '闽南': '阮',
      '上海': '阿拉',
    };
    
    const prefix = dialectPrefixes[dialect] || '';
    if (prefix) {
      return `[${prefix}]${text}`;
    }
    return text;
  }
}

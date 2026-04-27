/**
 * ============================================================================
 * 记忆搜索工具 - MemorySearch
 * 目标：语义搜索记忆文件，只拉取相关片段
 * 替代方案：全文加载 → 向量检索
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { MemoryItem, MemoryTier, ContextManager } from '../context/ContextManager';

/**
 * 搜索结果
 */
export interface SearchResult {
  id: string;
  content: string;
  score: number;        // 相关性得分 0-1
  source: string;       // 来源文件
  tier: MemoryTier;
}

/**
 * 搜索配置
 */
export interface SearchConfig {
  maxResults: number;
  minScore: number;
  includeHot: boolean;
  includeWarm: boolean;
  includeCold: boolean;
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: SearchConfig = {
  maxResults: 10,
  minScore: 0.3,
  includeHot: true,
  includeWarm: true,
  includeCold: true
};

/**
 * 记忆搜索工具
 */
export class MemorySearch {
  private static instance: MemorySearch | null = null;
  
  private config: SearchConfig;
  private contextManager: ContextManager;

  /**
   * 获取单例实例
   */
  static getInstance(config?: Partial<SearchConfig>): MemorySearch {
    if (!MemorySearch.instance) {
      MemorySearch.instance = new MemorySearch(config);
    }
    return MemorySearch.instance;
  }

  private constructor(config?: Partial<SearchConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.contextManager = ContextManager.getInstance();
    HiLog.info("MemorySearch", "初始化");
  }

  /**
   * 语义搜索（简化版：关键词匹配）
   */
  search(query: string, config?: Partial<SearchConfig>): SearchResult[] {
    const searchConfig = { ...this.config, ...config };
    HiLog.info("MemorySearch", `搜索：${query}`);
    
    const results: SearchResult[] = [];
    
    // 搜索热记忆
    if (searchConfig.includeHot) {
      const hotResults = this.searchInTier(query, MemoryTier.HOT);
      results.push(...hotResults);
    }
    
    // 搜索温记忆
    if (searchConfig.includeWarm) {
      const warmResults = this.searchInTier(query, MemoryTier.WARM);
      results.push(...warmResults);
    }
    
    // 搜索冷记忆
    if (searchConfig.includeCold) {
      const coldResults = this.searchInTier(query, MemoryTier.COLD);
      results.push(...coldResults);
    }
    
    // 按得分排序
    results.sort((a, b) => b.score - a.score);
    
    // 过滤最低得分
    const filtered = results.filter(r => r.score >= searchConfig.minScore);
    
    // 限制结果数量
    return filtered.slice(0, searchConfig.maxResults);
  }

  /**
   * 智能搜索（自动判断搜索范围）
   */
  smartSearch(query: string): SearchResult[] {
    const usage = this.contextManager.getUsagePercentage();
    
    // 高使用率时只搜索热记忆
    if (usage > 0.8) {
      return this.search(query, { includeHot: true, includeWarm: false, includeCold: false });
    }
    
    // 中等使用率时搜索热 + 温
    if (usage > 0.5) {
      return this.search(query, { includeHot: true, includeWarm: true, includeCold: false });
    }
    
    // 低使用率时搜索全部
    return this.search(query);
  }

  /**
   * 搜索并加载到上下文
   */
  searchAndLoad(query: string, limit: number = 3): void {
    const results = this.smartSearch(query);
    
    for (const result of results.slice(0, limit)) {
      // 提升重要结果到热记忆
      this.contextManager.promoteMemory(result.id, MemoryTier.HOT);
      HiLog.info("MemorySearch", `加载到上下文：${result.id}`);
    }
  }

  /**
   * 搜索相关文件
   */
  searchFiles(query: string, files: string[]): SearchResult[] {
    HiLog.info("MemorySearch", `搜索文件：${files.length}个文件`);
    
    const results: SearchResult[] = [];
    
    // TODO: 实际应该读取文件并搜索
    // 简化实现：返回空结果
    
    return results;
  }

  /**
   * 获取搜索结果摘要
   */
  getSearchSummary(results: SearchResult[]): string {
    if (results.length === 0) {
      return '未找到相关记忆';
    }
    
    const summary = results.map(r => {
      const preview = r.content.substring(0, 100);
      return `[${r.source}] ${preview}... (得分：${r.score.toFixed(2)})`;
    }).join('\n');
    
    return `找到${results.length}条相关记忆：\n${summary}`;
  }

  // ==================== 私有方法 ====================

  /**
   * 在层级中搜索
   */
  private searchInTier(query: string, tier: MemoryTier): SearchResult[] {
    const results: SearchResult[] = [];
    const lowerQuery = query.toLowerCase();
    
    // 获取对应层级的记忆
    const memories = this.getMemoriesByTier(tier);
    
    for (const memory of memories) {
      const score = this.calculateScore(lowerQuery, memory.content);
      
      if (score > 0) {
        results.push({
          id: memory.id,
          content: memory.content,
          score,
          source: this.getSourceName(memory),
          tier
        });
      }
    }
    
    return results;
  }

  /**
   * 获取层级的记忆
   */
  private getMemoriesByTier(tier: MemoryTier): MemoryItem[] {
    // 简化实现：实际应该从 ContextManager 获取
    return [];
  }

  /**
   * 计算相关性得分
   */
  private calculateScore(query: string, content: string): number {
    const lowerContent = content.toLowerCase();
    
    // 完全匹配
    if (lowerContent === query) {
      return 1.0;
    }
    
    // 包含查询
    if (lowerContent.includes(query)) {
      return 0.8;
    }
    
    // 关键词匹配
    const keywords = query.split(/\s+/);
    let matchCount = 0;
    for (const keyword of keywords) {
      if (lowerContent.includes(keyword)) {
        matchCount++;
      }
    }
    
    return matchCount / keywords.length;
  }

  /**
   * 获取来源名称
   */
  private getSourceName(memory: MemoryItem): string {
    return `memory_${memory.tier}`;
  }
}

/**
 * 便捷函数
 */
export function searchMemory(query: string, config?: Partial<SearchConfig>): SearchResult[] {
  return MemorySearch.getInstance().search(query, config);
}

export function smartSearch(query: string): SearchResult[] {
  return MemorySearch.getInstance().smartSearch(query);
}

export function searchAndLoad(query: string, limit?: number): void {
  MemorySearch.getInstance().searchAndLoad(query, limit);
}

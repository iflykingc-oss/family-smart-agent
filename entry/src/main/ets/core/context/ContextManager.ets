/**
 * ============================================================================
 * 分层上下文管理器 - ContextManager
 * 目标：热/温/冷记忆分层管理，减少 token 消耗
 * 参考：https://github.com/danielmiessler/Personal_AI_Infrastructure
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 记忆层级
 */
export enum MemoryTier {
  /** 热记忆 - 始终在上下文 */
  HOT = 'hot',
  
  /** 温记忆 - 按需加载 */
  WARM = 'warm',
  
  /** 冷记忆 - 语义搜索 */
  COLD = 'cold'
}

/**
 * 记忆项
 */
export interface MemoryItem {
  id: string;
  tier: MemoryTier;
  content: string;
  tokens: number;
  lastAccessed: number;
  accessCount: number;
  importance: number; // 0-1
}

/**
 * 上下文配置
 */
export interface ContextConfig {
  maxTokens: number;           // 最大上下文 tokens
  hotThreshold: number;        // 热记忆阈值（%）
  warmThreshold: number;       // 温记忆阈值（%）
  compactAt: number;           // 压缩触发阈值（%）
  autoPromote: boolean;        // 自动提升重要记忆
  autoDemote: boolean;         // 自动降级旧记忆
}

/**
 * 默认配置
 */
const DEFAULT_CONFIG: ContextConfig = {
  maxTokens: 100000,           // 100k tokens
  hotThreshold: 0.50,          // 50% 热记忆
  warmThreshold: 0.30,         // 30% 温记忆
  compactAt: 0.70,             // 70% 触发压缩
  autoPromote: true,
  autoDemote: true
};

/**
 * 分层上下文管理器
 */
export class ContextManager {
  private static instance: ContextManager | null = null;
  
  private config: ContextConfig;
  private hotMemory: MemoryItem[] = [];
  private warmMemory: MemoryItem[] = [];
  private coldMemory: MemoryItem[] = [];
  private currentTokens: number = 0;

  /**
   * 获取单例实例
   */
  static getInstance(config?: Partial<ContextConfig>): ContextManager {
    if (!ContextManager.instance) {
      ContextManager.instance = new ContextManager(config);
    }
    return ContextManager.instance;
  }

  private constructor(config?: Partial<ContextConfig>) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    HiLog.info("ContextManager", `初始化：maxTokens=${this.config.maxTokens}`);
  }

  /**
   * 添加记忆项
   */
  addMemory(content: string, importance: number = 0.5, tier?: MemoryTier): string {
    const id = `mem_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const tokens = this.estimateTokens(content);
    
    const item: MemoryItem = {
      id,
      tier: tier || this.inferTier(importance),
      content,
      tokens,
      lastAccessed: Date.now(),
      accessCount: 0,
      importance
    };
    
    // 添加到对应层级
    switch (item.tier) {
      case MemoryTier.HOT:
        this.hotMemory.push(item);
        break;
      case MemoryTier.WARM:
        this.warmMemory.push(item);
        break;
      case MemoryTier.COLD:
        this.coldMemory.push(item);
        break;
    }
    
    this.currentTokens += tokens;
    
    // 自动管理
    this.autoManage();
    
    HiLog.info("ContextManager", `添加记忆：${id}, tier=${item.tier}, tokens=${tokens}`);
    return id;
  }

  /**
   * 获取记忆项
   */
  getMemory(id: string): MemoryItem | null {
    // 搜索所有层级
    for (const memory of [...this.hotMemory, ...this.warmMemory, ...this.coldMemory]) {
      if (memory.id === id) {
        // 更新访问统计
        memory.accessCount++;
        memory.lastAccessed = Date.now();
        
        // 自动提升重要记忆
        if (this.config.autoPromote && memory.importance > 0.8 && memory.tier !== MemoryTier.HOT) {
          this.promoteMemory(id, MemoryTier.HOT);
        }
        
        return memory;
      }
    }
    return null;
  }

  /**
   * 搜索记忆（语义搜索简化版）
   */
  searchMemory(query: string, limit: number = 5): MemoryItem[] {
    HiLog.info("ContextManager", `搜索记忆：${query}`);
    
    const results: MemoryItem[] = [];
    const lowerQuery = query.toLowerCase();
    
    // 简单关键词匹配（实际应该用语义搜索）
    for (const memory of [...this.hotMemory, ...this.warmMemory, ...this.coldMemory]) {
      if (memory.content.toLowerCase().includes(lowerQuery)) {
        results.push(memory);
        if (results.length >= limit) break;
      }
    }
    
    // 按重要性排序
    results.sort((a, b) => b.importance - a.importance);
    
    return results;
  }

  /**
   * 获取当前上下文（热 + 温）
   */
  getCurrentContext(): string {
    const hotContent = this.hotMemory.map(m => m.content).join('\n');
    const warmContent = this.warmMemory.slice(0, 10).map(m => m.content).join('\n'); // 限制温记忆
    
    return `${hotContent}\n---\n${warmContent}`;
  }

  /**
   * 获取当前 token 使用
   */
  getCurrentTokens(): number {
    return this.currentTokens;
  }

  /**
   * 获取使用率
   */
  getUsagePercentage(): number {
    return this.currentTokens / this.config.maxTokens;
  }

  /**
   * 压缩上下文
   */
  compactContext(): void {
    HiLog.info("ContextManager", `压缩上下文：current=${this.currentTokens}, max=${this.config.maxTokens}`);
    
    // 压缩冷记忆
    const oldColdCount = this.coldMemory.length;
    this.coldMemory = this.coldMemory.filter(m => m.importance > 0.3); // 删除低重要性
    const newColdCount = this.coldMemory.length;
    
    // 压缩温记忆
    const oldWarmCount = this.warmMemory.length;
    this.warmMemory = this.warmMemory.slice(-20); // 保留最近 20 个
    const newWarmCount = this.warmMemory.length;
    
    // 重新计算 tokens
    this.recalculateTokens();
    
    HiLog.info("ContextManager", `压缩完成：冷记忆${oldColdCount}→${newColdCount}, 温记忆${oldWarmCount}→${newWarmCount}`);
  }

  /**
   * 提升记忆层级
   */
  promoteMemory(id: string, newTier: MemoryTier): void {
    const memory = this.getMemory(id);
    if (!memory) return;
    
    // 从原层级移除
    this.removeFromTier(memory, memory.tier);
    
    // 添加到新层级
    memory.tier = newTier;
    this.addToTier(memory, newTier);
    
    HiLog.info("ContextManager", `提升记忆：${id} → ${newTier}`);
  }

  /**
   * 降级记忆层级
   */
  demoteMemory(id: string, newTier: MemoryTier): void {
    const memory = this.getMemory(id);
    if (!memory) return;
    
    // 从原层级移除
    this.removeFromTier(memory, memory.tier);
    
    // 添加到新层级
    memory.tier = newTier;
    this.addToTier(memory, newTier);
    
    HiLog.info("ContextManager", `降级记忆：${id} → ${newTier}`);
  }

  /**
   * 清除记忆
   */
  clearMemory(id: string): void {
    const memory = this.getMemory(id);
    if (!memory) return;
    
    this.removeFromTier(memory, memory.tier);
    this.currentTokens -= memory.tokens;
    
    HiLog.info("ContextManager", `清除记忆：${id}`);
  }

  /**
   * 清除所有记忆
   */
  clearAll(): void {
    this.hotMemory = [];
    this.warmMemory = [];
    this.coldMemory = [];
    this.currentTokens = 0;
    
    HiLog.info("ContextManager", `清除所有记忆`);
  }

  /**
   * 获取记忆统计
   */
  getStats(): {
    hotCount: number;
    warmCount: number;
    coldCount: number;
    totalTokens: number;
    usagePercentage: number;
  } {
    return {
      hotCount: this.hotMemory.length,
      warmCount: this.warmMemory.length,
      coldCount: this.coldMemory.length,
      totalTokens: this.currentTokens,
      usagePercentage: this.getUsagePercentage()
    };
  }

  // ==================== 私有方法 ====================

  /**
   * 推断记忆层级
   */
  private inferTier(importance: number): MemoryTier {
    if (importance >= 0.8) return MemoryTier.HOT;
    if (importance >= 0.5) return MemoryTier.WARM;
    return MemoryTier.COLD;
  }

  /**
   * 添加到层级
   */
  private addToTier(memory: MemoryItem, tier: MemoryTier): void {
    switch (tier) {
      case MemoryTier.HOT:
        this.hotMemory.push(memory);
        break;
      case MemoryTier.WARM:
        this.warmMemory.push(memory);
        break;
      case MemoryTier.COLD:
        this.coldMemory.push(memory);
        break;
    }
  }

  /**
   * 从层级移除
   */
  private removeFromTier(memory: MemoryItem, tier: MemoryTier): void {
    switch (tier) {
      case MemoryTier.HOT:
        this.hotMemory = this.hotMemory.filter(m => m.id !== memory.id);
        break;
      case MemoryTier.WARM:
        this.warmMemory = this.warmMemory.filter(m => m.id !== memory.id);
        break;
      case MemoryTier.COLD:
        this.coldMemory = this.coldMemory.filter(m => m.id !== memory.id);
        break;
    }
  }

  /**
   * 自动管理（压缩/提升/降级）
   */
  private autoManage(): void {
    const usage = this.getUsagePercentage();
    
    // 触发压缩
    if (usage > this.config.compactAt) {
      this.compactContext();
    }
    
    // 自动降级旧记忆
    if (this.config.autoDemote && usage > this.config.hotThreshold) {
      this.autoDemoteOldMemories();
    }
  }

  /**
   * 自动降级旧记忆
   */
  private autoDemoteOldMemories(): void {
    const now = Date.now();
    const oneDayAgo = now - 86400000;
    
    // 降级 1 天前未访问的热记忆
    for (const memory of this.hotMemory) {
      if (memory.lastAccessed < oneDayAgo && memory.importance < 0.7) {
        this.demoteMemory(memory.id, MemoryTier.WARM);
      }
    }
    
    // 降级 7 天前未访问的温记忆
    const oneWeekAgo = now - 604800000;
    for (const memory of this.warmMemory) {
      if (memory.lastAccessed < oneWeekAgo && memory.importance < 0.5) {
        this.demoteMemory(memory.id, MemoryTier.COLD);
      }
    }
  }

  /**
   * 重新计算 tokens
   */
  private recalculateTokens(): void {
    this.currentTokens = [
      ...this.hotMemory,
      ...this.warmMemory,
      ...this.coldMemory
    ].reduce((sum, m) => sum + m.tokens, 0);
  }

  /**
   * 估算 tokens（简化版）
   */
  private estimateTokens(content: string): number {
    // 中文：1 字符≈1 token
    // 英文：1 单词≈1.3 tokens
    const chineseChars = (content.match(/[\u4e00-\u9fa5]/g) || []).length;
    const englishWords = (content.match(/[a-zA-Z]+/g) || []).length;
    return chineseChars + Math.round(englishWords * 1.3);
  }
}

/**
 * 便捷函数
 */
export function addMemory(content: string, importance?: number): string {
  return ContextManager.getInstance().addMemory(content, importance);
}

export function searchMemory(query: string, limit?: number): MemoryItem[] {
  return ContextManager.getInstance().searchMemory(query, limit);
}

export function getContext(): string {
  return ContextManager.getInstance().getCurrentContext();
}

export function getContextStats(): any {
  return ContextManager.getInstance().getStats();
}

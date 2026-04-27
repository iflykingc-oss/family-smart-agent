/**
 * ============================================================================
 * 资源压缩优化 - ResourceCompression
 * 目标：减少资源体积，提升加载速度
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 资源类型
 */
export enum ResourceType {
  IMAGE = 'image',
  AUDIO = 'audio',
  VIDEO = 'video',
  FONT = 'font',
  JSON = 'json',
  OTHER = 'other'
}

/**
 * 压缩配置
 */
export interface CompressionConfig {
  quality: number;            // 质量 0-100
  maxWidth?: number;          // 最大宽度
  maxHeight?: number;         // 最大高度
  format?: string;            // 输出格式
}

/**
 * 资源信息
 */
export interface ResourceInfo {
  id: string;
  type: ResourceType;
  originalSize: number;       // 原始大小（KB）
  compressedSize: number;     // 压缩后大小（KB）
  compressionRatio: number;   // 压缩率
  url: string;
  cached: boolean;
}

/**
 * 资源压缩管理器
 */
export class ResourceCompressionManager {
  private static instance: ResourceCompressionManager | null = null;
  
  private resources: Map<string, ResourceInfo> = new Map();
  private cache: Map<string, any> = new Map();

  /**
   * 获取单例实例
   */
  static getInstance(): ResourceCompressionManager {
    if (!ResourceCompressionManager.instance) {
      ResourceCompressionManager.instance = new ResourceCompressionManager();
    }
    return ResourceCompressionManager.instance;
  }

  private constructor() {
    HiLog.info("ResourceCompressionManager", "初始化");
  }

  /**
   * 压缩图片
   */
  async compressImage(
    imageUrl: string,
    config: CompressionConfig = { quality: 80 }
  ): Promise<ResourceInfo> {
    HiLog.info("ResourceCompressionManager", `压缩图片：${imageUrl}`);
    
    const resourceId = this.generateResourceId(imageUrl, ResourceType.IMAGE);
    
    // 检查缓存
    if (this.cache.has(resourceId)) {
      HiLog.info("ResourceCompressionManager", `使用缓存：${resourceId}`);
      return this.cache.get(resourceId);
    }
    
    // TODO: 实际应该调用图片压缩 API
    // 模拟压缩
    const originalSize = 1000; // KB
    const compressedSize = originalSize * (config.quality / 100);
    
    const info: ResourceInfo = {
      id: resourceId,
      type: ResourceType.IMAGE,
      originalSize,
      compressedSize,
      compressionRatio: compressedSize / originalSize,
      url: imageUrl,
      cached: false
    };
    
    this.resources.set(resourceId, info);
    this.cache.set(resourceId, info);
    
    HiLog.info("ResourceCompressionManager", 
      `压缩完成：${resourceId}, ${originalSize}KB → ${compressedSize}KB (${(info.compressionRatio * 100).toFixed(1)}%)`);
    
    return info;
  }

  /**
   * 压缩音频
   */
  async compressAudio(
    audioUrl: string,
    config: CompressionConfig = { quality: 60 }
  ): Promise<ResourceInfo> {
    HiLog.info("ResourceCompressionManager", `压缩音频：${audioUrl}`);
    
    const resourceId = this.generateResourceId(audioUrl, ResourceType.AUDIO);
    
    // 检查缓存
    if (this.cache.has(resourceId)) {
      return this.cache.get(resourceId);
    }
    
    // TODO: 实际应该调用音频压缩 API
    const originalSize = 5000; // KB
    const compressedSize = originalSize * (config.quality / 100);
    
    const info: ResourceInfo = {
      id: resourceId,
      type: ResourceType.AUDIO,
      originalSize,
      compressedSize,
      compressionRatio: compressedSize / originalSize,
      url: audioUrl,
      cached: false
    };
    
    this.resources.set(resourceId, info);
    this.cache.set(resourceId, info);
    
    HiLog.info("ResourceCompressionManager", 
      `压缩完成：${resourceId}, ${originalSize}KB → ${compressedSize}KB`);
    
    return info;
  }

  /**
   * 压缩视频
   */
  async compressVideo(
    videoUrl: string,
    config: CompressionConfig = { quality: 50 }
  ): Promise<ResourceInfo> {
    HiLog.info("ResourceCompressionManager", `压缩视频：${videoUrl}`);
    
    const resourceId = this.generateResourceId(videoUrl, ResourceType.VIDEO);
    
    // 检查缓存
    if (this.cache.has(resourceId)) {
      return this.cache.get(resourceId);
    }
    
    // TODO: 实际应该调用视频压缩 API
    const originalSize = 50000; // KB
    const compressedSize = originalSize * (config.quality / 100);
    
    const info: ResourceInfo = {
      id: resourceId,
      type: ResourceType.VIDEO,
      originalSize,
      compressedSize,
      compressionRatio: compressedSize / originalSize,
      url: videoUrl,
      cached: false
    };
    
    this.resources.set(resourceId, info);
    this.cache.set(resourceId, info);
    
    HiLog.info("ResourceCompressionManager", 
      `压缩完成：${resourceId}, ${originalSize}KB → ${compressedSize}KB`);
    
    return info;
  }

  /**
   * 压缩 JSON
   */
  async compressJson(
    jsonData: any,
    config: CompressionConfig = {}
  ): Promise<ResourceInfo> {
    HiLog.info("ResourceCompressionManager", `压缩 JSON`);
    
    const resourceId = `json_${Date.now()}`;
    const jsonString = JSON.stringify(jsonData);
    
    // 检查缓存
    if (this.cache.has(resourceId)) {
      return this.cache.get(resourceId);
    }
    
    // 压缩（移除空格）
    const compressed = jsonString.replace(/\s+/g, ' ');
    
    const originalSize = jsonString.length / 1024; // KB
    const compressedSize = compressed.length / 1024;
    
    const info: ResourceInfo = {
      id: resourceId,
      type: ResourceType.JSON,
      originalSize,
      compressedSize,
      compressionRatio: compressedSize / originalSize,
      url: 'data:application/json',
      cached: false
    };
    
    this.resources.set(resourceId, info);
    this.cache.set(resourceId, compressed);
    
    HiLog.info("ResourceCompressionManager", 
      `压缩完成：${resourceId}, ${originalSize.toFixed(2)}KB → ${compressedSize.toFixed(2)}KB`);
    
    return info;
  }

  /**
   * 批量压缩
   */
  async compressBatch(
    resources: Array<{ url: string; type: ResourceType }>,
    config: CompressionConfig = { quality: 80 }
  ): Promise<ResourceInfo[]> {
    HiLog.info("ResourceCompressionManager", `批量压缩：${resources.length}个资源`);
    
    const results: ResourceInfo[] = [];
    
    for (const resource of resources) {
      try {
        let info: ResourceInfo;
        
        switch (resource.type) {
          case ResourceType.IMAGE:
            info = await this.compressImage(resource.url, config);
            break;
          case ResourceType.AUDIO:
            info = await this.compressAudio(resource.url, config);
            break;
          case ResourceType.VIDEO:
            info = await this.compressVideo(resource.url, config);
            break;
          default:
            continue;
        }
        
        results.push(info);
      } catch (error: any) {
        HiLog.error("ResourceCompressionManager", `压缩失败：${resource.url}`);
      }
    }
    
    return results;
  }

  /**
   * 获取压缩统计
   */
  getCompressionStats(): {
    totalResources: number;
    totalOriginalSize: number;
    totalCompressedSize: number;
    averageCompressionRatio: number;
    totalSaved: number;
  } {
    let totalOriginal = 0;
    let totalCompressed = 0;
    
    for (const resource of this.resources.values()) {
      totalOriginal += resource.originalSize;
      totalCompressed += resource.compressedSize;
    }
    
    return {
      totalResources: this.resources.size,
      totalOriginalSize: totalOriginal,
      totalCompressedSize: totalCompressed,
      averageCompressionRatio: totalCompressed / totalOriginal,
      totalSaved: totalOriginal - totalCompressed
    };
  }

  /**
   * 清除缓存
   */
  clearCache(): void {
    this.cache.clear();
    HiLog.info("ResourceCompressionManager", "缓存已清除");
  }

  /**
   * 清除指定资源缓存
   */
  clearResourceCache(resourceId: string): void {
    this.cache.delete(resourceId);
    this.resources.delete(resourceId);
    HiLog.info("ResourceCompressionManager", `资源缓存已清除：${resourceId}`);
  }

  /**
   * 生成资源 ID
   */
  private generateResourceId(url: string, type: ResourceType): string {
    return `${type}_${this.hashUrl(url)}`;
  }

  /**
   * URL 哈希
   */
  private hashUrl(url: string): string {
    let hash = 0;
    for (let i = 0; i < url.length; i++) {
      const char = url.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash).toString(36);
  }
}

/**
 * 便捷函数
 */
export async function compressImage(url: string, quality?: number): Promise<ResourceInfo> {
  return ResourceCompressionManager.getInstance().compressImage(url, { quality });
}

export async function compressAudio(url: string, quality?: number): Promise<ResourceInfo> {
  return ResourceCompressionManager.getInstance().compressAudio(url, { quality });
}

export async function compressVideo(url: string, quality?: number): Promise<ResourceInfo> {
  return ResourceCompressionManager.getInstance().compressVideo(url, { quality });
}

export async function compressBatch(
  resources: Array<{ url: string; type: ResourceType }>,
  quality?: number
): Promise<ResourceInfo[]> {
  return ResourceCompressionManager.getInstance().compressBatch(resources, { quality });
}

export function getCompressionStats(): any {
  return ResourceCompressionManager.getInstance().getCompressionStats();
}

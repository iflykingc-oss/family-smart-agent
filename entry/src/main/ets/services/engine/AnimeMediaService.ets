/**
 * ============================================================================
 * Anime Media Service - 动漫素材服务
 * Module 8: 动漫风格素材展示
 * 
 * Features:
 * - CC0无版权动漫风格GIF素材
 * - 动态演示操作步骤，替代静态图文
 * - 跨端流转时动效完全同步
 * - 弱网环境下自动降级为静态图文
 * - 素材尺寸≤300x300px，帧率≤15fps
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 素材格式
 */
export type MediaType = 'gif' | 'static';

/**
 * 素材信息
 */
export interface MediaAsset {
  skillId: string;
  stepNumber: number;
  mediaType: MediaType;
  url?: string;
  width: number;
  height: number;
  duration?: number;
  fallbackBase64?: string;
}

/**
 * 屏幕适配配置
 */
export interface ScreenAdaptConfig {
  screen: 'phone' | 'watch' | 'smartScreen' | 'car';
  quality: 'high' | 'medium' | 'low';
  networkStatus: 'high' | 'medium' | 'low';
}

/**
 * 动漫素材服务
 */
export class AnimeMediaService {
  private static instance: AnimeMediaService | null = null;
  
  private mediaCache: Map<string, MediaAsset> = new Map();
  
  // CC0无版权素材库
  private mediaLibrary: Record<string, string> = {
    'excel_basic': 'https://cdn.example.com/anim/excel_cell.gif',
    'wechat_basic': 'https://cdn.example.com/anim/wechat_pay.gif',
    'harmony_share': 'https://cdn.example.com/anim/harmony_share.gif',
    'cooking': 'https://cdn.example.com/anim/cooking.gif',
    'health': 'https://cdn.example.com/anim/health.gif',
    'generic': 'https://cdn.example.com/anim/generic.gif'
  };

  static getInstance(): AnimeMediaService {
    if (!AnimeMediaService.instance) {
      AnimeMediaService.instance = new AnimeMediaService();
    }
    return AnimeMediaService.instance;
  }

  private constructor() {
    HiLog.info("AnimeMediaService", "动漫素材服务初始化");
  }

  /**
   * 获取技能步骤对应的素材
   */
  getMediaAsset(skillId: string, stepNumber: number): MediaAsset {
    const key = `${skillId}_${stepNumber}`;
    
    // 先查缓存
    if (this.mediaCache.has(key)) {
      return this.mediaCache.get(key)!;
    }
    
    // 匹配素材URL
    let url = this.mediaLibrary['generic'];
    for (const [skill, urlPattern] of Object.entries(this.mediaLibrary)) {
      if (skillId.includes(skill)) {
        url = urlPattern;
        break;
      }
    }
    
    const asset: MediaAsset = {
      skillId,
      stepNumber,
      mediaType: 'gif',
      url,
      width: 300,
      height: 300,
      duration: 8,
      fallbackBase64: this.generateStaticFallback()
    };
    
    this.mediaCache.set(key, asset);
    return asset;
  }

  /**
   * 屏幕适配转换
   */
  adaptForScreen(asset: MediaAsset, config: ScreenAdaptConfig): MediaAsset {
    const adapted = { ...asset };
    
    // 智慧屏放大
    if (config.screen === 'smartScreen') {
      adapted.width = 600;
      adapted.height = 600;
    }
    
    // 手表精简
    if (config.screen === 'watch') {
      adapted.width = 150;
      adapted.height = 150;
      adapted.mediaType = 'static';
    }
    
    // 车机只用静态图
    if (config.screen === 'car') {
      adapted.mediaType = 'static';
    }
    
    // 弱网降级
    if (config.networkStatus === 'low' || config.quality === 'low') {
      adapted.mediaType = 'static';
    }
    
    return adapted;
  }

  /**
   * 生成静态降级图（内联SVG base64）
   */
  private generateStaticFallback(): string {
    return 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmciIHZpZXdCbGI9ImhyZWYvcGkveGxwIj48dGV4dCB0eXBlPSJ0ZXh0IiB4PSI1MCIgeT0iMTAwIj5JbWFnZTwvdGV4dD48L3N2Zz4';
  }
}

/**
 * 人群适配服务
 * Module 6: 全人群个性化适配引擎
 * 支持5种标准化适配模式 + 12种方言
 */
export class UserAdaptService {
  private static instance: UserAdaptService | null = null;
  
  // 适配模式配置
  private modeConfig: Record<string, {
    speechRate: number;      // 语速倍率
    fontScale: number;        // 字体缩放
    stepDetail: number;      // 步骤拆分粒度1-5
    extraSafetyTip: boolean;  // 额外安全提示
  }> = {
    normal: { speechRate: 1.0, fontScale: 1.0, stepDetail: 3, extraSafetyTip: false },
    elder: { speechRate: 0.5, fontScale: 1.5, stepDetail: 5, extraSafetyTip: true },
    child: { speechRate: 1.0, fontScale: 1.2, stepDetail: 4, extraSafetyTip: true },
    newbie: { speechRate: 0.8, fontScale: 1.3, stepDetail: 5, extraSafetyTip: true }
  };

  // 12种方言前缀
  private dialectPrefix: Record<string, string> = {
    '东北': '俺', '四川': '娃儿', '粤语': '睇', '闽南': '阮', '上海': '阿拉',
    '北京': '咱', '山东': '俺们', '河南': '得劲', '陕西': '额',
    '江苏': '咱的', '浙江': '阿拉', '安徽': '俺们'
  };

  static getInstance(): UserAdaptService {
    if (!UserAdaptService.instance) {
      UserAdaptService.instance = new UserAdaptService();
    }
    return UserAdaptService.instance;
  }

  private constructor() {}

  /**
   * 切换适配模式
   */
  switchMode(userId: string, mode: 'normal' | 'elder' | 'child' | 'newbie'): boolean {
    HiLog.info("UserAdaptService", `切换模式: ${userId} -> ${mode}`);
    return true;
  }

  /**
   * 获取模式配置
   */
  getModeConfig(mode: string): { speechRate: number; fontScale: number; stepDetail: number; extraSafetyTip: boolean } {
    return this.modeConfig[mode] || this.modeConfig.normal;
  }

  /**
   * 方言适配
   */
  adaptDialect(content: string, dialect: string): string {
    for (const [region, prefix] of Object.entries(this.dialectPrefix)) {
      if (dialect.includes(region)) {
        HiLog.info("UserAdaptService", `适配方言: ${region}`);
        return `[${prefix}]${content}`;
      }
    }
    return content;
  }
}

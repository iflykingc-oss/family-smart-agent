/**
 * ============================================================================
 * 应用路由导航 - AppNavigator
 * 统一管理页面跳转，页面间解耦
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';

/**
 * 路由路径
 */
export enum RoutePath {
  HOME = 'pages/Index',
  TEACHING = 'pages/TeachingPage',
  REVIEW = 'pages/ReviewPage',
  SKILLS = 'pages/SkillsPage',
  PROFILE = 'pages/ProfilePage',
  SETTINGS = 'pages/SettingsPage',
}

/**
 * 路由参数
 */
export interface RouteParams {
  skillId?: string;
  skillName?: string;
  userId?: string;
  [key: string]: any;
}

/**
 * 应用导航器
 */
export class AppNavigator {
  private static instance: AppNavigator | null = null;

  /**
   * 获取单例实例
   */
  static getInstance(): AppNavigator {
    if (!AppNavigator.instance) {
      AppNavigator.instance = new AppNavigator();
    }
    return AppNavigator.instance;
  }

  private constructor() {
    HiLog.info("AppNavigator", "初始化");
  }

  /**
   * 跳转到首页
   */
  goToHome(): void {
    this.navigate(RoutePath.HOME);
  }

  /**
   * 跳转到教学页
   */
  goToTeaching(skillId: string, skillName: string): void {
    this.navigate(RoutePath.TEACHING, { skillId, skillName });
  }

  /**
   * 跳转到复习页
   */
  goToReview(): void {
    this.navigate(RoutePath.REVIEW);
  }

  /**
   * 跳转到技能页
   */
  goToSkills(): void {
    this.navigate(RoutePath.SKILLS);
  }

  /**
   * 跳转到个人页
   */
  goToProfile(userId: string): void {
    this.navigate(RoutePath.PROFILE, { userId });
  }

  /**
   * 跳转到设置页
   */
  goToSettings(): void {
    this.navigate(RoutePath.SETTINGS);
  }

  /**
   * 返回上一页
   */
  goBack(): void {
    router.back();
    HiLog.info("AppNavigator", "返回上一页");
  }

  /**
   * 返回指定页
   */
  goBackTo(route: RoutePath): void {
    router.back({ name: route });
    HiLog.info("AppNavigator", `返回到：${route}`);
  }

  /**
   * 替换当前页
   */
  replace(route: RoutePath, params?: RouteParams): void {
    this.navigate(route, params, true);
  }

  /**
   * 导航到指定页
   */
  private navigate(route: RoutePath, params?: RouteParams, replace?: boolean): void {
    HiLog.info("AppNavigator", `导航到：${route}`, params);
    
    const url = params ? this.buildUrl(route, params) : route;
    
    if (replace) {
      router.replaceUrl({ url });
    } else {
      router.pushUrl({ url });
    }
  }

  /**
   * 构建带参数的 URL
   */
  private buildUrl(route: RoutePath, params: RouteParams): string {
    const queryString = Object.entries(params)
      .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
      .join('&');
    return `${route}?${queryString}`;
  }

  /**
   * 获取当前路由
   */
  getCurrentRoute(): string {
    return router.getState().stack[this.getState().stack.length - 1].name;
  }

  /**
   * 获取路由状态
   */
  getState(): any {
    return router.getState();
  }
}

/**
 * 便捷导航函数
 */
export function goToHome(): void {
  AppNavigator.getInstance().goToHome();
}

export function goToTeaching(skillId: string, skillName: string): void {
  AppNavigator.getInstance().goToTeaching(skillId, skillName);
}

export function goToReview(): void {
  AppNavigator.getInstance().goToReview();
}

export function goToSkills(): void {
  AppNavigator.getInstance().goToSkills();
}

export function goBack(): void {
  AppNavigator.getInstance().goBack();
}

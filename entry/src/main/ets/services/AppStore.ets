/**
 * 应用状态管理
 * 基于 AppStorage + LocalStorage 的响应式状态管理
 */
import { FamilyMember } from '../model/FamilyMember';

/**
 * 全局状态 Keys
 */
export const AppStateKeys = {
  MEMBERS: 'app.members',
  CURRENT_TASK: 'app.currentTask',
  SELECTED_DEVICES: 'app.selectedDevices',
  IS_PROCESSING: 'app.isProcessing',
  LAST_INTENT: 'app.lastIntent',
} as const;

/**
 * 家庭状态管理
 */
export class AppStore {
  private static instance: AppStore | null = null;

  static getInstance(): AppStore {
    if (!AppStore.instance) {
      AppStore.instance = new AppStore();
    }
    return AppStore.instance;
  }

  private constructor() {}

  /**
   * 获取家庭成员列表
   */
  getMembers(): FamilyMember[] {
    try {
      const data = AppStorage.get<string>(AppStateKeys.MEMBERS);
      if (data) {
        return JSON.parse(data) as FamilyMember[];
      }
    } catch (e) {
      console.error('Failed to get members from storage:', e);
    }
    return [];
  }

  /**
   * 保存家庭成员列表
   */
  saveMembers(members: FamilyMember[]): void {
    AppStorage.setOrCreate(AppStateKeys.MEMBERS, JSON.stringify(members));
  }

  /**
   * 添加或更新成员
   */
  updateMember(member: FamilyMember): void {
    const members = this.getMembers();
    const index = members.findIndex(m => m.id === member.id);
    if (index >= 0) {
      members[index] = member;
    } else {
      members.push(member);
    }
    this.saveMembers(members);
  }

  /**
   * 删除成员
   */
  removeMember(memberId: string): void {
    const members = this.getMembers().filter(m => m.id !== memberId);
    this.saveMembers(members);
  }

  /**
   * 获取选中的设备列表
   */
  getSelectedDevices(): string[] {
    try {
      const data = AppStorage.get<string>(AppStateKeys.SELECTED_DEVICES);
      if (data) {
        return JSON.parse(data) as string[];
      }
    } catch (e) {
      console.error('Failed to get selected devices:', e);
    }
    return [];
  }

  /**
   * 保存选中的设备
   */
  saveSelectedDevices(deviceIds: string[]): void {
    AppStorage.setOrCreate(AppStateKeys.SELECTED_DEVICES, JSON.stringify(deviceIds));
  }

  /**
   * 检查是否正在处理
   */
  isProcessing(): boolean {
    return AppStorage.get<boolean>(AppStateKeys.IS_PROCESSING) ?? false;
  }

  /**
   * 设置处理状态
   */
  setProcessing(processing: boolean): void {
    AppStorage.setOrCreate(AppStateKeys.IS_PROCESSING, processing);
  }

  /**
   * 清除所有状态（登出/重置）
   */
  clearAll(): void {
    AppStorage.delete(AppStateKeys.MEMBERS);
    AppStorage.delete(AppStateKeys.CURRENT_TASK);
    AppStorage.delete(AppStateKeys.SELECTED_DEVICES);
    AppStorage.delete(AppStateKeys.IS_PROCESSING);
    AppStorage.delete(AppStateKeys.LAST_INTENT);
  }
}

/**
 * 轻量级存储键名
 */
export const StorageKeys = {
  USER_NAME: 'user_name',
  USER_ID: 'user_id',
  FIRST_LAUNCH: 'first_launch',
  LAST_SYNC_TIME: 'last_sync_time',
} as const;

/**
 * 持久化存储帮助类
 * 用于需要跨会话持久化的数据
 */
export class PersistentStorageHelper {
  /**
   * 保存字符串
   */
  static setString(key: string, value: string): void {
    AppStorage.setOrCreate(key, value);
    // 实际项目应使用 persistentStorage.persistProp
  }

  /**
   * 获取字符串
   */
  static getString(key: string, defaultValue: string = ''): string {
    return AppStorage.get<string>(key) ?? defaultValue;
  }

  /**
   * 保存布尔值
   */
  static setBoolean(key: string, value: boolean): void {
    AppStorage.setOrCreate(key, value);
  }

  /**
   * 获取布尔值
   */
  static getBoolean(key: string, defaultValue: boolean = false): boolean {
    return AppStorage.get<boolean>(key) ?? defaultValue;
  }

  /**
   * 保存数字
   */
  static setNumber(key: string, value: number): void {
    AppStorage.setOrCreate(key, value);
  }

  /**
   * 获取数字
   */
  static getNumber(key: string, defaultValue: number = 0): number {
    return AppStorage.get<number>(key) ?? defaultValue;
  }

  /**
   * 删除键
   */
  static delete(key: string): void {
    AppStorage.delete(key);
  }
}

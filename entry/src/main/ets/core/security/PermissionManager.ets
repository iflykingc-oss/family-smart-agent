/**
 * ============================================================================
 * 权限管理器 - PermissionManager
 * 提供权限检查和管理功能
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

/**
 * 权限类型
 */
export enum PermissionType {
  // 基础权限
  READ_USER_INFO = 'read_user_info',
  WRITE_USER_INFO = 'write_user_info',
  
  // 数据权限
  READ_LEARNING_DATA = 'read_learning_data',
  WRITE_LEARNING_DATA = 'write_learning_data',
  DELETE_LEARNING_DATA = 'delete_learning_data',
  
  // 系统权限
  CAMERA = 'camera',
  MICROPHONE = 'microphone',
  LOCATION = 'location',
  STORAGE = 'storage',
  NETWORK = 'network',
  
  // 高级权限
  ADMIN = 'admin',
  EXPORT_DATA = 'export_data',
  IMPORT_DATA = 'import_data'
}

/**
 * 权限检查结果
 */
export interface PermissionCheckResult {
  granted: boolean;
  permission: PermissionType;
  reason?: string;
}

/**
 * 权限请求结果
 */
export interface PermissionRequestResult {
  granted: boolean;
  permissions: PermissionType[];
  denied: PermissionType[];
}

/**
 * 用户角色
 */
export enum UserRole {
  USER = 'user',           // 普通用户
  PREMIUM = 'premium',     // 高级用户
  ADMIN = 'admin'          // 管理员
}

/**
 * 角色权限映射
 */
const ROLE_PERMISSIONS: Record<UserRole, PermissionType[]> = {
  [UserRole.USER]: [
    PermissionType.READ_USER_INFO,
    PermissionType.WRITE_USER_INFO,
    PermissionType.READ_LEARNING_DATA,
    PermissionType.WRITE_LEARNING_DATA
  ],
  
  [UserRole.PREMIUM]: [
    PermissionType.READ_USER_INFO,
    PermissionType.WRITE_USER_INFO,
    PermissionType.READ_LEARNING_DATA,
    PermissionType.WRITE_LEARNING_DATA,
    PermissionType.DELETE_LEARNING_DATA,
    PermissionType.EXPORT_DATA,
    PermissionType.IMPORT_DATA
  ],
  
  [UserRole.ADMIN]: [
    PermissionType.READ_USER_INFO,
    PermissionType.WRITE_USER_INFO,
    PermissionType.READ_LEARNING_DATA,
    PermissionType.WRITE_LEARNING_DATA,
    PermissionType.DELETE_LEARNING_DATA,
    PermissionType.EXPORT_DATA,
    PermissionType.IMPORT_DATA,
    PermissionType.ADMIN,
    PermissionType.CAMERA,
    PermissionType.MICROPHONE,
    PermissionType.LOCATION,
    PermissionType.STORAGE,
    PermissionType.NETWORK
  ]
};

/**
 * 权限管理器
 */
export class PermissionManager {
  private static instance: PermissionManager | null = null;
  
  private userRole: UserRole = UserRole.USER;
  private grantedPermissions: Set<PermissionType> = new Set();

  /**
   * 获取单例实例
   */
  static getInstance(): PermissionManager {
    if (!PermissionManager.instance) {
      PermissionManager.instance = new PermissionManager();
    }
    return PermissionManager.instance;
  }

  private constructor() {
    HiLog.info("PermissionManager", "初始化");
  }

  /**
   * 设置用户角色
   */
  setUserRole(role: UserRole): void {
    this.userRole = role;
    HiLog.info("PermissionManager", `设置用户角色：${role}`);
  }

  /**
   * 获取用户角色
   */
  getUserRole(): UserRole {
    return this.userRole;
  }

  /**
   * 检查权限
   */
  checkPermission(permission: PermissionType): PermissionCheckResult {
    // 检查角色是否有此权限
    const rolePermissions = ROLE_PERMISSIONS[this.userRole];
    if (!rolePermissions.includes(permission)) {
      return {
        granted: false,
        permission,
        reason: '角色权限不足'
      };
    }
    
    // 检查是否已授权
    if (!this.grantedPermissions.has(permission)) {
      return {
        granted: false,
        permission,
        reason: '用户未授权'
      };
    }
    
    return {
      granted: true,
      permission
    };
  }

  /**
   * 批量检查权限
   */
  checkPermissions(permissions: PermissionType[]): PermissionCheckResult[] {
    return permissions.map(p => this.checkPermission(p));
  }

  /**
   * 请求权限
   */
  async requestPermission(permission: PermissionType): Promise<PermissionCheckResult> {
    HiLog.info("PermissionManager", `请求权限：${permission}`);
    
    // 检查角色权限
    const checkResult = this.checkPermission(permission);
    if (!checkResult.granted && checkResult.reason === '角色权限不足') {
      return checkResult;
    }
    
    // 模拟权限请求（实际应该调用系统 API）
    const granted = await this.simulatePermissionRequest(permission);
    
    if (granted) {
      this.grantedPermissions.add(permission);
      HiLog.info("PermissionManager", `权限已授权：${permission}`);
    } else {
      HiLog.warn("PermissionManager", `权限被拒绝：${permission}`);
    }
    
    return {
      granted,
      permission
    };
  }

  /**
   * 批量请求权限
   */
  async requestPermissions(permissions: PermissionType[]): Promise<PermissionRequestResult> {
    HiLog.info("PermissionManager", `批量请求权限：${permissions.length}个`);
    
    const granted: PermissionType[] = [];
    const denied: PermissionType[] = [];
    
    for (const permission of permissions) {
      const result = await this.requestPermission(permission);
      if (result.granted) {
        granted.push(permission);
      } else {
        denied.push(permission);
      }
    }
    
    return {
      granted: granted.length > 0,
      permissions: granted,
      denied
    };
  }

  /**
   * 撤销权限
   */
  revokePermission(permission: PermissionType): void {
    this.grantedPermissions.delete(permission);
    HiLog.info("PermissionManager", `权限已撤销：${permission}`);
  }

  /**
   * 获取已授权权限列表
   */
  getGrantedPermissions(): PermissionType[] {
    return Array.from(this.grantedPermissions);
  }

  /**
   * 获取可用权限列表（角色权限）
   */
  getAvailablePermissions(): PermissionType[] {
    return ROLE_PERMISSIONS[this.userRole];
  }

  /**
   * 是否有权限
   */
  hasPermission(permission: PermissionType): boolean {
    return this.checkPermission(permission).granted;
  }

  /**
   * 是否有所有权限
   */
  hasAllPermissions(permissions: PermissionType[]): boolean {
    return permissions.every(p => this.hasPermission(p));
  }

  /**
   * 是否有任意权限
   */
  hasAnyPermission(permissions: PermissionType[]): boolean {
    return permissions.some(p => this.hasPermission(p));
  }

  /**
   * 要求权限（无权限时抛出异常）
   */
  requirePermission(permission: PermissionType): void {
    const result = this.checkPermission(permission);
    if (!result.granted) {
      throw new Error(`权限不足：${permission}，原因：${result.reason}`);
    }
  }

  /**
   * 要求所有权限
   */
  requireAllPermissions(permissions: PermissionType[]): void {
    for (const permission of permissions) {
      this.requirePermission(permission);
    }
  }

  /**
   * 清除所有授权
   */
  clearAllPermissions(): void {
    this.grantedPermissions.clear();
    HiLog.info("PermissionManager", "已清除所有授权");
  }

  /**
   * 模拟权限请求（实际应该调用系统 API）
   */
  private async simulatePermissionRequest(permission: PermissionType): Promise<boolean> {
    // 敏感权限默认拒绝
    const sensitivePermissions = [
      PermissionType.CAMERA,
      PermissionType.MICROPHONE,
      PermissionType.LOCATION
    ];
    
    if (sensitivePermissions.includes(permission)) {
      // 模拟用户拒绝
      return false;
    }
    
    // 其他权限默认授权
    return true;
  }

  /**
   * 获取权限说明
   */
  getPermissionDescription(permission: PermissionType): string {
    const descriptions: Record<PermissionType, string> = {
      [PermissionType.READ_USER_INFO]: '读取用户信息',
      [PermissionType.WRITE_USER_INFO]: '写入用户信息',
      [PermissionType.READ_LEARNING_DATA]: '读取学习数据',
      [PermissionType.WRITE_LEARNING_DATA]: '写入学习数据',
      [PermissionType.DELETE_LEARNING_DATA]: '删除学习数据',
      [PermissionType.CAMERA]: '使用摄像头',
      [PermissionType.MICROPHONE]: '使用麦克风',
      [PermissionType.LOCATION]: '获取位置信息',
      [PermissionType.STORAGE]: '访问存储空间',
      [PermissionType.NETWORK]: '访问网络',
      [PermissionType.ADMIN]: '管理员权限',
      [PermissionType.EXPORT_DATA]: '导出数据',
      [PermissionType.IMPORT_DATA]: '导入数据'
    };
    
    return descriptions[permission] || '未知权限';
  }

  /**
   * 获取权限分组
   */
  getPermissionGroups(): Record<string, PermissionType[]> {
    return {
      '用户信息': [
        PermissionType.READ_USER_INFO,
        PermissionType.WRITE_USER_INFO
      ],
      '学习数据': [
        PermissionType.READ_LEARNING_DATA,
        PermissionType.WRITE_LEARNING_DATA,
        PermissionType.DELETE_LEARNING_DATA
      ],
      '设备功能': [
        PermissionType.CAMERA,
        PermissionType.MICROPHONE,
        PermissionType.LOCATION
      ],
      '系统': [
        PermissionType.STORAGE,
        PermissionType.NETWORK
      ],
      '高级': [
        PermissionType.ADMIN,
        PermissionType.EXPORT_DATA,
        PermissionType.IMPORT_DATA
      ]
    };
  }
}

/**
 * 权限装饰器
 */
export function RequirePermission(permission: PermissionType) {
  return function (target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    
    descriptor.value = function (...args: any[]) {
      PermissionManager.getInstance().requirePermission(permission);
      return originalMethod.apply(this, args);
    };
    
    return descriptor;
  };
}

/**
 * 便捷函数
 */
export function checkPermission(permission: PermissionType): PermissionCheckResult {
  return PermissionManager.getInstance().checkPermission(permission);
}

export function hasPermission(permission: PermissionType): boolean {
  return PermissionManager.getInstance().hasPermission(permission);
}

export async function requestPermission(permission: PermissionType): Promise<PermissionCheckResult> {
  return PermissionManager.getInstance().requestPermission(permission);
}

export function requirePermission(permission: PermissionType): void {
  PermissionManager.getInstance().requirePermission(permission);
}

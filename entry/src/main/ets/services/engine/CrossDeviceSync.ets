/**
 * ============================================================================
 * 跨设备同步服务 - CrossDeviceSync
 * 核心差异化：鸿蒙全场景断点续学能力
 * 
 * 功能：
 * - 跨设备进度同步
 * - 断点续学
 * - 多设备协同
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';

/**
 * 设备类型
 */
export enum DeviceType {
  PHONE = 'phone',
  TABLET = 'tablet',
  PC = 'pc',
  SMART_SCREEN = 'smartScreen',
  SPEAKER = 'speaker',
  WATCH = 'watch',
  UNKNOWN = 'unknown'
}

/**
 * 设备信息
 */
export interface DeviceInfo {
  deviceId: string;
  deviceName: string;
  deviceType: DeviceType;
  isOnline: boolean;
  lastSyncTime: number;
}

/**
 * 学习进度数据
 */
export interface LearningProgressData {
  userId: string;
  currentSkill: {
    skillId: string;
    skillName: string;
  };
  currentStep: number;
  totalSteps: number;
  completedSteps: number[];
  weakPoints: string[];
  stepResults: Record<number, 'correct' | 'incorrect' | 'not_tried'>;
  lastLearnTime: number;
  totalTimeSpent: number;
  streak: number;
}

/**
 * 同步状态
 */
export enum SyncStatus {
  IDLE = 'idle',
  SYNCING = 'syncing',
  SUCCESS = 'success',
  FAILED = 'failed'
}

/**
 * 跨设备同步服务
 */
export class CrossDeviceSync {
  private static instance: CrossDeviceSync | null = null;

  // 本地缓存的进度
  private localProgress: LearningProgressData | null = null;
  
  // 设备列表
  private devices: Map<string, DeviceInfo> = new Map();
  
  // 当前同步状态
  private syncStatus: SyncStatus = SyncStatus.IDLE;
  
  // 上次同步时间
  private lastSyncTime: number = 0;

  static getInstance(): CrossDeviceSync {
    if (!CrossDeviceSync.instance) {
      CrossDeviceSync.instance = new CrossDeviceSync();
    }
    return CrossDeviceSync.instance;
  }

  private constructor() {
    HiLog.info("CrossDeviceSync", "跨设备同步服务初始化");
  }

  /**
   * 初始化服务
   * 发现同网段的鸿蒙设备
   */
  async initialize(): Promise<void> {
    HiLog.info("CrossDeviceSync", "初始化跨设备同步...");
    
    try {
      // 获取设备管理器
      const deviceManager = distributedDeviceManager.getDeviceManager('app');
      
      // 获取可信设备列表
      const trustedDevices = deviceManager.getTrustedDeviceListSync();
      
      HiLog.info("CrossDeviceSync", `发现${trustedDevices.length}个可信设备`);
      
      // 解析设备信息
      for (const device of trustedDevices) {
        const deviceInfo = this.parseDeviceInfo(device);
        this.devices.set(device.deviceId, deviceInfo);
      }
      
      HiLog.info("CrossDeviceSync", `设备列表: ${JSON.stringify(Array.from(this.devices.keys()))}`);
    } catch (error) {
      HiLog.error("CrossDeviceSync", `初始化失败: ${error}`);
      // 降级处理：单设备模式
      this.devices.set('local', {
        deviceId: 'local',
        deviceName: '本设备',
        deviceType: DeviceType.PHONE,
        isOnline: true,
        lastSyncTime: Date.now()
      });
    }
  }

  /**
   * 保存学习进度
   * 当用户在一个设备上学习时调用
   */
  async saveProgress(progress: LearningProgressData): Promise<void> {
    HiLog.info("CrossDeviceSync", `保存进度: ${progress.userId}/${progress.currentSkill.skillName} 步骤${progress.currentStep}`);
    
    // 保存到本地
    this.localProgress = {
      ...progress,
      lastLearnTime: Date.now()
    };
    
    // 同步到其他设备
    await this.syncToDevices();
  }

  /**
   * 获取学习进度
   * 当用户切换到新设备时调用
   */
  async getProgress(userId: string): Promise<LearningProgressData | null> {
    HiLog.info("CrossDeviceSync", `获取进度: ${userId}`);
    
    // 先尝试从其他设备同步最新进度
    await this.syncFromDevices();
    
    // 返回本地缓存的进度
    if (this.localProgress && this.localProgress.userId === userId) {
      HiLog.info("CrossDeviceSync", `返回缓存进度: ${this.localProgress.currentSkill.skillName} 步骤${this.localProgress.currentStep}`);
      return this.localProgress;
    }
    
    return null;
  }

  /**
   * 断点续学
   * 获取上一个学习的断点
   */
  async resumeFromBreakpoint(userId: string): Promise<{
    canResume: boolean;
    progress?: LearningProgressData;
    targetDevice?: DeviceInfo;
    message?: string;
  }> {
    HiLog.info("CrossDeviceSync", `断点续学: ${userId}`);
    
    const progress = await this.getProgress(userId);
    
    if (!progress) {
      return {
        canResume: false,
        message: '没有找到学习记录，开始新学习吧～'
      };
    }
    
    // 计算断点位置
    const lastStep = progress.currentStep;
    const skillName = progress.currentSkill.skillName;
    
    // 找出最适合的设备
    const targetDevice = this.findBestDevice();
    
    const message = `检测到上次学习到"${skillName}"第${lastStep}步，是否继续？`;
    
    return {
      canResume: true,
      progress,
      targetDevice,
      message
    };
  }

  /**
   * 跨设备推送到屏幕
   * 比如在智慧屏上显示教程
   */
  async pushToScreen(progress: LearningProgressData, screenDeviceId?: string): Promise<boolean> {
    HiLog.info("CrossDeviceSync", `推送到屏幕: ${progress.currentSkill.skillName}`);
    
    try {
      // 找到智慧屏设备
      let targetDevice = screenDeviceId;
      
      if (!targetDevice) {
        for (const [deviceId, device] of this.devices) {
          if (device.deviceType === DeviceType.SMART_SCREEN && device.isOnline) {
            targetDevice = deviceId;
            break;
          }
        }
      }
      
      if (!targetDevice) {
        HiLog.warn("CrossDeviceSync", "没有找到可用的智慧屏设备");
        return false;
      }
      
      // 构建推送内容
      const pushContent = {
        type: 'learning_tutorial',
        skillName: progress.currentSkill.skillName,
        currentStep: progress.currentStep,
        totalSteps: progress.totalSteps,
        content: `正在学习：${progress.currentSkill.skillName}`,
        action: 'display_tutorial'
      };
      
      HiLog.info("CrossDeviceSync", `推送内容: ${JSON.stringify(pushContent)}`);
      
      // TODO: 调用鸿蒙分布式API实际推送
      // await this.sendToDevice(targetDevice, pushContent);
      
      return true;
    } catch (error) {
      HiLog.error("CrossDeviceSync", `推送失败: ${error}`);
      return false;
    }
  }

  /**
   * 同步到其他设备
   */
  private async syncToDevices(): Promise<void> {
    if (this.syncStatus === SyncStatus.SYNCING) {
      HiLog.warn("CrossDeviceSync", "正在同步中，跳过");
      return;
    }
    
    this.syncStatus = SyncStatus.SYNCING;
    
    try {
      for (const [deviceId, device] of this.devices) {
        if (deviceId !== 'local' && device.isOnline) {
          HiLog.info("CrossDeviceSync", `同步到设备: ${device.deviceName}`);
          // TODO: 调用鸿蒙分布式API实际同步
          // await this.sendProgressToDevice(deviceId, this.localProgress);
        }
      }
      
      this.syncStatus = SyncStatus.SUCCESS;
      this.lastSyncTime = Date.now();
      HiLog.info("CrossDeviceSync", "同步完成");
    } catch (error) {
      this.syncStatus = SyncStatus.FAILED;
      HiLog.error("CrossDeviceSync", `同步失败: ${error}`);
    }
  }

  /**
   * 从其他设备同步
   */
  private async syncFromDevices(): Promise<void> {
    HiLog.info("CrossDeviceSync", "从其他设备同步...");
    
    try {
      for (const [deviceId, device] of this.devices) {
        if (deviceId !== 'local' && device.isOnline) {
          HiLog.info("CrossDeviceSync", `从设备同步: ${device.deviceName}`);
          // TODO: 调用鸿蒙分布式API实际同步
          // const remoteProgress = await this.getProgressFromDevice(deviceId);
          // 比较时间戳，取最新的
        }
      }
    } catch (error) {
      HiLog.error("CrossDeviceSync", `同步失败: ${error}`);
    }
  }

  /**
   * 查找最佳设备
   * 根据学习场景选择最合适的设备
   */
  private findBestDevice(): DeviceInfo | null {
    let bestDevice: DeviceInfo | null = null;
    
    for (const device of this.devices.values()) {
      if (!device.isOnline) continue;
      
      // 优先选择手机（最常用）
      if (device.deviceType === DeviceType.PHONE) {
        return device;
      }
      
      // 其次选择平板
      if (device.deviceType === DeviceType.TABLET) {
        bestDevice = device;
      }
    }
    
    return bestDevice || null;
  }

  /**
   * 解析设备信息
   */
  private parseDeviceInfo(device: any): DeviceInfo {
    const deviceType = this.inferDeviceType(device.deviceName || '');
    
    return {
      deviceId: device.deviceId || `device_${Date.now()}`,
      deviceName: device.deviceName || '未知设备',
      deviceType,
      isOnline: device.isOnline || false,
      lastSyncTime: Date.now()
    };
  }

  /**
   * 根据设备名称推断设备类型
   */
  private inferDeviceType(deviceName: string): DeviceType {
    const name = deviceName.toLowerCase();
    
    if (name.includes('phone') || name.includes('手机') || name.includes('mate') || name.includes('pura')) {
      return DeviceType.PHONE;
    }
    if (name.includes('tablet') || name.includes('pad') || name.includes('平板')) {
      return DeviceType.TABLET;
    }
    if (name.includes('pc') || name.includes('电脑') || name.includes('matebook')) {
      return DeviceType.PC;
    }
    if (name.includes('screen') || name.includes('智慧屏') || name.includes('tv')) {
      return DeviceType.SMART_SCREEN;
    }
    if (name.includes('watch') || name.includes('手表')) {
      return DeviceType.WATCH;
    }
    if (name.includes('speaker') || name.includes('音箱') || name.includes('sound')) {
      return DeviceType.SPEAKER;
    }
    
    return DeviceType.UNKNOWN;
  }

  /**
   * 获取设备列表
   */
  getDevices(): DeviceInfo[] {
    return Array.from(this.devices.values());
  }

  /**
   * 获取同步状态
   */
  getSyncStatus(): SyncStatus {
    return this.syncStatus;
  }

  /**
   * 获取上次同步时间
   */
  getLastSyncTime(): number {
    return this.lastSyncTime;
  }

  /**
   * 强制刷新设备列表
   */
  async refreshDevices(): Promise<void> {
    HiLog.info("CrossDeviceSync", "刷新设备列表...");
    await this.initialize();
  }

  /**
   * 创建同步会话
   * 用于多设备协同学习
   */
  async createCollaborativeSession(progress: LearningProgressData): Promise<string> {
    HiLog.info("CrossDeviceSync", `创建协作会话: ${progress.userId}`);
    
    const sessionId = `session_${Date.now()}_${progress.userId}`;
    
    // TODO: 在分布式数据中创建会话
    // DistributedDataService.createSession(sessionId, progress);
    
    return sessionId;
  }

  /**
   * 加入协作会话
   * 比如用平板继续手机上的学习
   */
  async joinCollaborativeSession(sessionId: string): Promise<LearningProgressData | null> {
    HiLog.info("CrossDeviceSync", `加入协作会话: ${sessionId}`);
    
    // TODO: 从分布式数据获取会话进度
    // return await DistributedDataService.getSessionProgress(sessionId);
    
    return null;
  }
}

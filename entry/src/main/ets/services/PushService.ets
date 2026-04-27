import { Task } from '../model/Task';
import { DeviceService, HarmonyDevice } from './DeviceService';

/**
 * 推送服务
 * 负责将任务推送到鸿蒙设备
 */
export class PushService {
  private deviceService: DeviceService;
  private static instance: PushService | null = null;

  static getInstance(): PushService {
    if (!PushService.instance) {
      PushService.instance = new PushService();
    }
    return PushService.instance;
  }

  private constructor() {
    this.deviceService = DeviceService.getInstance();
  }

  /**
   * 推送任务到指定设备
   */
  async pushToDevices(task: Task): Promise<PushResult> {
    if (task.deviceIds.length === 0) {
      return {
        success: false,
        pushedDevices: [],
        message: '未选择推送设备',
      };
    }

    const pushedDevices: string[] = [];
    const failedDevices: string[] = [];

    for (const deviceId of task.deviceIds) {
      try {
        const success = await this.pushToSingleDevice(task, deviceId);
        if (success) {
          pushedDevices.push(deviceId);
        } else {
          failedDevices.push(deviceId);
        }
      } catch {
        failedDevices.push(deviceId);
      }
    }

    if (pushedDevices.length === 0) {
      return {
        success: false,
        pushedDevices: [],
        message: `推送失败：${failedDevices.join(', ')}`,
      };
    }

    const deviceNames = pushedDevices
      .map(id => this.deviceService.getDeviceName(id))
      .join('、');

    return {
      success: true,
      pushedDevices,
      message: `已推送到：${deviceNames}`,
    };
  }

  /**
   * 推送到单个设备
   */
  private async pushToSingleDevice(task: Task, deviceId: string): Promise<boolean> {
    const device = this.deviceService.getAllDevices().find(d => d.id === deviceId);
    
    if (!device) {
      console.error(`设备不存在: ${deviceId}`);
      return false;
    }

    if (!device.online) {
      console.error(`设备不在线: ${device.name}`);
      return false;
    }

    // 根据设备类型选择推送方式
    switch (device.type) {
      case 'smart_phone':
        return await this.pushToPhone(task);
      case 'smart_screen':
        return await this.pushToSmartScreen(task);
      case 'smart_speaker':
        return await this.pushToSpeaker(task);
      case 'tablet':
        return await this.pushToTablet(task);
      default:
        return false;
    }
  }

  /**
   * 推送到手机
   */
  private async pushToPhone(task: Task): Promise<boolean> {
    // 接入华为 Push Kit
    // 模拟推送
    console.log(`[Push] 推送到手机: ${task.title}`);
    return true;
  }

  /**
   * 推送到智慧屏
   */
  private async pushToSmartScreen(task: Task): Promise<boolean> {
    // 接入鸿蒙分布式推送
    // 模拟推送
    console.log(`[Push] 推送到智慧屏: ${task.title}`);
    return true;
  }

  /**
   * 推送到音箱
   */
  private async pushToSpeaker(task: Task): Promise<boolean> {
    // 文字转语音播报
    console.log(`[Push] 音箱播报: ${task.title}`);
    return true;
  }

  /**
   * 推送到平板
   */
  private async pushToTablet(task: Task): Promise<boolean> {
    // 平板通知
    console.log(`[Push] 推送到平板: ${task.title}`);
    return true;
  }

  /**
   * 构建推送卡片内容
   */
  buildPushCard(task: Task): PushCard {
    return {
      title: task.title,
      content: task.description || task.title,
      assigneeName: task.assigneeName,
      dueTime: task.dueTime ? new Date(task.dueTime).toLocaleString('zh-CN') : undefined,
      priority: task.priority,
      status: task.status,
    };
  }

  /**
   * 广播到所有在线设备
   */
  async broadcastToAll(task: Task): Promise<PushResult> {
    const onlineDevices = this.deviceService.getOnlineDevices();
    task.deviceIds = onlineDevices.map(d => d.id);
    return await this.pushToDevices(task);
  }
}

/**
 * 推送结果
 */
export interface PushResult {
  success: boolean;
  pushedDevices: string[];
  message: string;
}

/**
 * 推送卡片内容
 */
export interface PushCard {
  title: string;
  content: string;
  assigneeName?: string;
  dueTime?: string;
  priority: string;
  status: string;
}

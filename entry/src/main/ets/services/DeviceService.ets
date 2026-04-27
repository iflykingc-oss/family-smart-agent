/**
 * 设备服务
 * 负责管理鸿蒙设备的发现和选择
 */
export class DeviceService {
  private static instance: DeviceService | null = null;

  // 模拟设备列表
  private devices: HarmonyDevice[] = [
    { id: 'phone_001', name: '我的手机', type: 'smart_phone', online: true },
    { id: 'tablet_001', name: '平板', type: 'tablet', online: true },
    { id: 'screen_001', name: '客厅智慧屏', type: 'smart_screen', online: true },
    { id: 'speaker_001', name: '小艺音箱', type: 'smart_speaker', online: true },
  ];

  static getInstance(): DeviceService {
    if (!DeviceService.instance) {
      DeviceService.instance = new DeviceService();
    }
    return DeviceService.instance;
  }

  private constructor() {}

  /**
   * 获取所有可用设备
   */
  getAllDevices(): HarmonyDevice[] {
    return [...this.devices];
  }

  /**
   * 获取在线设备
   */
  getOnlineDevices(): HarmonyDevice[] {
    return this.devices.filter(d => d.online);
  }

  /**
   * 获取特定类型的设备
   */
  getDevicesByType(type: DeviceType): HarmonyDevice[] {
    return this.devices.filter(d => d.type === type && d.online);
  }

  /**
   * 获取设备名称
   */
  getDeviceName(id: string): string {
    const device = this.devices.find(d => d.id === id);
    return device?.name ?? '未知设备';
  }

  /**
   * 根据名称模糊搜索设备
   */
  findDeviceByName(name: string): HarmonyDevice | undefined {
    return this.devices.find(d => 
      d.name.includes(name) || name.includes(d.name)
    );
  }

  /**
   * 判断是否需要推送到智慧屏
   */
  shouldPushToSmartScreen(context: string): boolean {
    const keywords = ['家庭', '大家', '一起', '同步', '智慧屏'];
    return keywords.some(k => context.includes(k));
  }
}

/**
 * 设备类型
 */
export type DeviceType = 
  | 'smart_phone'   // 手机
  | 'tablet'         // 平板
  | 'smart_screen'   // 智慧屏
  | 'smart_speaker'; // 智能音箱

/**
 * 鸿蒙设备
 */
export interface HarmonyDevice {
  id: string;
  name: string;
  type: DeviceType;
  online: boolean;
}

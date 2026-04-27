import { DeviceService } from '../services/DeviceService';
import { HarmonyDevice } from '../services/DeviceService';
import { DeviceCard } from '../components/DeviceCard';

/**
 * 设备管理页面
 */
@Entry
@Component
struct Devices {
  @State devices: HarmonyDevice[] = [];
  @State selectedDevices: Set<string> = new Set();
  private deviceService: DeviceService;

  aboutToAppear() {
    this.deviceService = DeviceService.getInstance();
    this.loadDevices();
  }

  loadDevices() {
    this.devices = this.deviceService.getAllDevices();
  }

  build() {
    Column() {
      // 标题栏
      this.TitleBar()

      // 设备列表
      List() {
        ForEach(this.devices, (device: HarmonyDevice) => {
          ListItem() {
            DeviceCard({
              device: device,
              isSelected: this.selectedDevices.has(device.id),
              onToggle: (deviceId: string, selected: boolean) => {
                this.toggleDevice(deviceId, selected);
              }
            })
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F2F2F7')

      // 底部操作栏
      this.BottomBar()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  TitleBar() {
    Row() {
      Text('📱 设备管理')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      
      Blank()
      
      Text(`${this.selectedDevices.size} 台已选`)
        .fontSize(14)
        .fontColor('#007AFF')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  BottomBar() {
    Column() {
      // 快捷选择
      Row() {
        Text('快速选择：')
          .fontSize(14)
          .fontColor('#666666')
        
        Button('全部手机')
          .fontSize(12)
          .fontColor('#007AFF')
          .backgroundColor('#E8F4FF')
          .borderRadius(16)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .onClick(() => {
            this.selectByType('smart_phone');
          })
        
        Button('智慧屏')
          .fontSize(12)
          .fontColor('#007AFF')
          .backgroundColor('#E8F4FF')
          .borderRadius(16)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .margin({ left: 8 })
          .onClick(() => {
            this.selectByType('smart_screen');
          })
        
        Button('全选')
          .fontSize(12)
          .fontColor('#34C759')
          .backgroundColor('#E8F5E9')
          .borderRadius(16)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .margin({ left: 8 })
          .onClick(() => {
            this.selectAll();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })

      // 确认按钮
      Button('确认同步到 ' + this.selectedDevices.size + ' 台设备')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor(this.selectedDevices.size > 0 ? '#007AFF' : '#E5E5EA')
        .borderRadius(24)
        .width('100%')
        .padding({ left: 24, right: 24, top: 16, bottom: 16 })
        .margin(16)
        .enabled(this.selectedDevices.size > 0)
        .onClick(() => {
          this.confirmSync();
        })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  toggleDevice(deviceId: string, selected: boolean) {
    if (selected) {
      this.selectedDevices.add(deviceId);
    } else {
      this.selectedDevices.delete(deviceId);
    }
    // 触发UI更新
    this.selectedDevices = new Set(this.selectedDevices);
  }

  selectByType(type: string) {
    const typeDevices = this.devices.filter(d => d.type === type && d.online);
    typeDevices.forEach(d => this.selectedDevices.add(d.id));
    this.selectedDevices = new Set(this.selectedDevices);
  }

  selectAll() {
    this.devices.filter(d => d.online).forEach(d => this.selectedDevices.add(d.id));
    this.selectedDevices = new Set(this.selectedDevices);
  }

  confirmSync() {
    // 获取选中的设备名称
    const selectedNames = this.devices
      .filter(d => this.selectedDevices.has(d.id))
      .map(d => d.name)
      .join('、');
    
    // 这里应该触发全局同步操作
    console.info(`同步到: ${selectedNames}`);
  }
}

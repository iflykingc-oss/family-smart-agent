import { HarmonyDevice, DeviceType } from '../services/DeviceService';

/**
 * 设备卡片组件
 */
@Component
export struct DeviceCard {
  @ObjectLink device: HarmonyDevice;
  @Prop isSelected: boolean = false;
  onToggle: (deviceId: string, selected: boolean) => void = () => {};

  build() {
    Row() {
      // 设备图标
      Text(this.getDeviceIcon())
        .fontSize(28)
        .margin({ right: 12 })

      // 设备信息
      Column() {
        Text(this.device.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        
        Text(this.getDeviceTypeName())
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 在线状态
      Row() {
        Circle()
          .fill(this.device.online ? '#34C759' : '#FF3B30')
          .width(8)
          .height(8)
          .margin({ right: 4 })
        
        Text(this.device.online ? '在线' : '离线')
          .fontSize(12)
          .fontColor(this.device.online ? '#34C759' : '#FF3B30')
      }

      // 选择框
      Checkbox()
        .select(this.isSelected)
        .onChange((value: boolean) => {
          this.onToggle(this.device.id, value);
        })
        .margin({ left: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isSelected ? '#E8F4FF' : '#FFFFFF')
    .border({
      width: this.isSelected ? 2 : 1,
      color: this.isSelected ? '#007AFF' : '#E5E5EA',
      radius: 12
    })
    .onClick(() => {
      this.onToggle(this.device.id, !this.isSelected);
    })
  }

  getDeviceIcon(): string {
    switch (this.device.type) {
      case 'smart_phone': return '📱';
      case 'tablet': return '📲';
      case 'smart_screen': return '📺';
      case 'smart_speaker': return '🔊';
      default: return '📱';
    }
  }

  getDeviceTypeName(): string {
    switch (this.device.type) {
      case 'smart_phone': return '手机';
      case 'tablet': return '平板';
      case 'smart_screen': return '智慧屏';
      case 'smart_speaker': return '智能音箱';
      default: return '设备';
    }
  }
}

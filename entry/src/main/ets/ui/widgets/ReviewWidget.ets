/**
 * ============================================================================
 * 复习卡片组件 - ReviewWidget
 * ============================================================================
 */

import { ReviewItem } from '../../presentation/viewmodels/ReviewViewModel';

/**
 * 复习卡片属性
 */
export interface ReviewWidgetProps {
  item: ReviewItem;
  onComplete?: () => void;
  onSkip?: () => void;
}

@Component
export struct ReviewWidget {
  @Prop item: ReviewItem = {
    skillId: '',
    skillName: '未知技能',
    stepNumber: 1,
    dueTime: Date.now(),
    retrievability: 0,
    interval: 0,
    priority: 'medium',
  };
  @Prop onComplete?: () => void = undefined;
  @Prop onSkip?: () => void = undefined;

  build() {
    Column() {
      // 标题和优先级
      Row() {
        Text(this.item.skillName)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        // 优先级标签
        Text(this.getPriorityText())
          .fontSize(10)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getPriorityColor())
          .borderRadius(12)
          .fontColor('#FFFFFF')
      }
      .width('100%')

      // 复习信息
      Row() {
        Text(`步骤：${this.item.stepNumber}`)
          .fontSize(12)
          .fontColor('#666666')

        Text(`间隔：${this.item.interval}天`)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ left: 16 })

        Text(`记忆：${Math.round(this.item.retrievability * 100)}%`)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ left: 16 })
      }
      .width('100%')
      .margin({ top: 8 })

      // 操作按钮
      Row() {
        Button('跳过')
          .fontSize(14)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor('#E5E5EA')
          .fontColor('#333333')
          .onClick(() => {
            if (this.onSkip) {
              this.onSkip();
            }
          })

        Blank()

        Button('开始复习')
          .fontSize(14)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor('#007AFF')
          .fontColor('#FFFFFF')
          .onClick(() => {
            if (this.onComplete) {
              this.onComplete();
            }
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  /**
   * 获取优先级文本
   */
  private getPriorityText(): string {
    switch (this.item.priority) {
      case 'high':
        return '🔴 紧急';
      case 'medium':
        return '🟡 普通';
      case 'low':
        return '🟢 不急';
      default:
        return '未知';
    }
  }

  /**
   * 获取优先级颜色
   */
  private getPriorityColor(): string {
    switch (this.item.priority) {
      case 'high':
        return '#FF3B30';
      case 'medium':
        return '#FF9500';
      case 'low':
        return '#34C759';
      default:
        return '#999999';
    }
  }
}

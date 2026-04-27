/**
 * ============================================================================
 * 复习页 UI - ReviewPage
 * FSRS 复习提醒
 * ============================================================================
 */

import { ReviewViewModel, ReviewItem } from '../../presentation/viewmodels/ReviewViewModel';
import { ReviewWidget } from '../widgets/ReviewWidget';

@Entry
@Component
struct ReviewPage {
  @State reviewItems: ReviewItem[] = [];
  @State isRefreshing: boolean = false;
  @State stats: { total: number; high: number; medium: number; low: number } = {
    total: 0,
    high: 0,
    medium: 0,
    low: 0,
  };
  
  private viewModel: ReviewViewModel = new ReviewViewModel();
  private userId: string = 'user_001';

  aboutToAppear() {
    // 设置状态变化回调
    this.viewModel.setOnStateChanged(() => {
      this.reviewItems = this.viewModel.getReviewItems();
      this.isRefreshing = this.viewModel.isRefreshingData();
      this.stats = this.viewModel.getStats();
    });
    
    // 刷新复习列表
    this.viewModel.refresh(this.userId);
  }

  aboutToDisappear() {
    this.viewModel.destroy();
  }

  build() {
    Column() {
      // 标题栏
      this.TitleBar()
      
      // 统计卡片
      this.StatsCard()
      
      // 复习列表
      Scroll() {
        Column() {
          if (this.isRefreshing) {
            this.LoadingView()
          } else if (this.reviewItems.length === 0) {
            this.EmptyView()
          } else {
            this.ReviewList()
          }
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  TitleBar() {
    Row() {
      Column() {
        Text('📖 复习')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text('基于 FSRS 遗忘曲线')
          .fontSize(12)
          .fontColor('#666666')
      }
      .alignItems(HorizontalAlign.Start)
      
      Blank()
      
      // 刷新按钮
      Button() {
        Image(this.isRefreshing ? '🔄' : '🔃')
          .width(20)
          .height(20)
      }
      .width(40)
      .height(40)
      .backgroundColor('#FFFFFF')
      .onClick(() => {
        this.viewModel.refresh(this.userId);
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  StatsCard() {
    Row() {
      // 总计
      Column() {
        Text(this.stats.total.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007AFF')
        Text('待复习')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('25%')
      
      // 紧急
      Column() {
        Text(this.stats.high.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF3B30')
        Text('紧急')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('25%')
      
      // 普通
      Column() {
        Text(this.stats.medium.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF9500')
        Text('普通')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('25%')
      
      // 不急
      Column() {
        Text(this.stats.low.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#34C759')
        Text('不急')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('25%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .margin({ bottom: 8 })
  }

  @Builder
  ReviewList() {
    Column() {
      ForEach(this.reviewItems, (item: ReviewItem) => {
        ReviewWidget({
          item: item,
          onComplete: () => {
            this.completeReview(item);
          },
          onSkip: () => {
            this.skipReview(item);
          }
        })
        .margin({ bottom: 12 })
      })
    }
    .width('100%')
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
      
      Text('正在加载复习列表...')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 16 })
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  EmptyView() {
    Column() {
      Text('🎉')
        .fontSize(48)
      
      Text('太棒了！')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16 })
      
      Text('所有复习都已完成')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })
      
      Text('下次复习时间会另行通知')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .width('100%')
    .height(300)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 完成复习
   */
  completeReview(item: ReviewItem) {
    this.viewModel.completeReview(item.skillId, item.stepNumber, true);
    // TODO: 调用 InteractionService 处理复习
  }

  /**
   * 跳过复习
   */
  skipReview(item: ReviewItem) {
    this.viewModel.skipReview(item.skillId, item.stepNumber);
  }
}

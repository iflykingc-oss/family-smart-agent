/**
 * ============================================================================
 * 主页面 - TabBar 容器（教学智能体版）
 * 重构自原家庭管家MainPage.ets
 * ============================================================================
 */

import router from '@ohos.router';

/**
 * 主页面 - TabBar 容器
 */
@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0;

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabController }) {
      TabContent() {
        Index()
      }
      .tabBar(this.TabBarItem('首页', '📚', 0))

      TabContent() {
        Progress()
      }
      .tabBar(this.TabBarItem('进度', '📊', 1))

      TabContent() {
        Skills()
      }
      .tabBar(this.TabBarItem('技能', '🎯', 2))

      TabContent() {
        Settings()
      }
      .tabBar(this.TabBarItem('设置', '⚙️', 3))
    }
    .barHeight(60)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }

  tabController: TabsController = new TabsController();

  @Builder
  TabBarItem(title: string, icon: string, index: number) {
    Column() {
      Text(icon)
        .fontSize(24)
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === index ? '#007AFF' : '#999999')
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }
}

/**
 * 进度页面
 */
@Entry
@Component
struct Progress {
  @State totalSkills: number = 0;
  @State completedSkills: number = 0;
  @State totalTimeSpent: number = 0;
  @State streak: number = 0;
  @State coins: number = 0;
  @State weakSkills: string[] = [];

  private progressTracker: any;

  aboutToAppear() {
    // TODO: 接入实际的ProgressTracker
  }

  build() {
    Column() {
      // 标题
      Text('学习进度')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding(16)

      Scroll() {
        Column({ space: 16 }) {
          // 学习数据卡片
          this.DataCard()

          // 连续学习
          this.StreakCard()

          // 薄弱技能
          this.WeakSkillsCard()

          // 推荐复习
          this.ReviewCard()
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  DataCard() {
    Row() {
      Column() {
        Text(`${this.completedSkills}`)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007AFF')
        Text('已完成技能')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('50%')

      Column() {
        Text(`${this.totalSkills}`)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#34C759')
        Text('学习中')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('50%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  StreakCard() {
    Column() {
      Row() {
        Text('🔥')
          .fontSize(24)
        Text('连续学习')
          .fontSize(16)
          .margin({ left: 8 })
      }
      .width('100%')

      Text(`${this.streak} 天`)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FF6B6B')
        .margin({ top: 8 })

      Text(`累计学习 ${this.totalTimeSpent} 分钟`)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFF3E0')
    .borderRadius(12)
  }

  @Builder
  WeakSkillsCard() {
    Column() {
      Text('📌 薄弱技能')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 12 })

      if (this.weakSkills.length === 0) {
        Text('暂无薄弱技能，继续保持！')
          .fontSize(14)
          .fontColor('#999999')
          .width('100%')
      } else {
        ForEach(this.weakSkills, (skill: string) => {
          Row() {
            Text(skill)
              .fontSize(14)
            Blank()
            Text('复习')
              .fontSize(14)
              .fontColor('#007AFF')
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ bottom: 8 })
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  ReviewCard() {
    Column() {
      Text('💡 推荐复习')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 12 })

      Text('根据遗忘曲线，这些技能该复习了')
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')

      Button('开始复习')
        .width('100%')
        .margin({ top: 12 })
        .backgroundColor('#007AFF')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}

/**
 * 技能库页面
 */
@Entry
@Component
struct Skills {
  @State skills: any[] = [];
  @State categories: string[] = ['全部', '办公', '生活', '数字'];
  @State selectedCategory: string = '全部';

  aboutToAppear() {
    // TODO: 从AbilityGraph获取技能库
    this.skills = [
      { id: 'excel_basic', name: 'Excel基础', category: '办公', difficulty: 1, progress: 75 },
      { id: 'wechat_basic', name: '微信使用', category: '生活', difficulty: 1, progress: 100 },
      { id: 'harmony_share', name: '鸿蒙协同', category: '数字', difficulty: 2, progress: 30 },
    ];
  }

  build() {
    Column() {
      // 标题
      Row() {
        Text('技能库')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Blank()

        Text('🏆 排行榜')
          .fontSize(14)
          .fontColor('#007AFF')
      }
      .width('100%')
      .padding(16)

      // 分类筛选
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.categories, (category: string) => {
            Text(category)
              .fontSize(14)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor(this.selectedCategory === category ? '#007AFF' : '#E5E5EA')
              .fontColor(this.selectedCategory === category ? '#FFFFFF' : '#333333')
              .borderRadius(16)
              .onClick(() => {
                this.selectedCategory = category;
              })
          })
        }
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .scrollBar(BarState.Off)

      // 技能列表
      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.skills.filter(s => this.selectedCategory === '全部' || s.category === this.selectedCategory), (skill: any) => {
            this.SkillCard(skill)
          })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  SkillCard(skill: any) {
    Column() {
      Row() {
        Column() {
          Text(skill.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
          Text(skill.category)
            .fontSize(12)
            .fontColor('#999999')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          Text(`${skill.progress}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(skill.progress === 100 ? '#34C759' : '#007AFF')
          Text(skill.progress === 100 ? '已完成' : '学习中')
            .fontSize(10)
            .fontColor('#999999')
        }
      }
      .width('100%')

      if (skill.progress < 100) {
        Progress({
          value: skill.progress,
          total: 100,
          type: ProgressType.Linear
        })
          .color('#007AFF')
          .width('100%')
          .height(4)
          .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}

/**
 * 设置页面
 */
@Entry
@Component
struct Settings {
  @State items: any[] = [
    { icon: '🔔', title: '提醒设置', desc: '学习提醒和复习提醒' },
    { icon: '🌙', title: '学习时间', desc: '设置适合您的学习时段' },
    { icon: '📱', title: '设备管理', desc: '管理您的学习设备' },
    { icon: '👤', title: '个人信息', desc: '昵称、头像等' },
    { icon: '🏆', title: '成就一览', desc: '查看已解锁成就' },
    { icon: '❓', title: '帮助反馈', desc: '使用帮助和反馈问题' },
  ];

  build() {
    Column() {
      // 标题
      Text('设置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding(16)

      // 设置列表
      Scroll() {
        Column({ space: 1 }) {
          ForEach(this.items, (item: any) => {
            Row() {
              Text(item.icon)
                .fontSize(20)
                .width(40)

              Column() {
                Text(item.title)
                  .fontSize(16)
                Text(item.desc)
                  .fontSize(12)
                  .fontColor('#999999')
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 12 })

              Blank()

              Text('>')
                .fontSize(16)
                .fontColor('#CCCCCC')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
          })
        }
        .width('100%')
      }
      .layoutWeight(1)

      // 版本信息
      Text('小艺教学助手 v1.0')
        .fontSize(12)
        .fontColor('#CCCCCC')
        .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }
}

// 导入页面
import { Index } from './Index';

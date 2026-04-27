/**
 * ============================================================================
 * 教学页 UI - TeachingPage
 * 完整教学交互流程
 * ============================================================================
 */

import { TeachingViewModel, TeachingStep } from '../../presentation/viewmodels/TeachingViewModel';
import { InteractionMode } from '../../service/InteractionService';

@Entry
@Component
struct TeachingPage {
  @State steps: TeachingStep[] = [];
  @State currentStepIndex: number = 0;
  @State interactionMode: InteractionMode = InteractionMode.TEACHER;
  @State progress: number = 0;
  @State isCompleted: boolean = false;
  @State userAnswer: string = '';
  
  private viewModel: TeachingViewModel = new TeachingViewModel();
  private skillId: string = '';
  private skillName: string = '';

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as { skillId?: string; skillName?: string };
    this.skillId = params.skillId || '';
    this.skillName = params.skillName || '未知技能';
    
    // 设置状态变化回调
    this.viewModel.setOnStateChanged(() => {
      this.steps = this.viewModel.getSteps();
      this.currentStepIndex = this.steps.findIndex(s => !s.completed);
      if (this.currentStepIndex < 0) {
        this.currentStepIndex = this.steps.length - 1;
      }
      this.progress = this.viewModel.getProgress();
      this.interactionMode = this.viewModel.getInteractionMode();
      this.isCompleted = this.viewModel.isTeachingCompleted();
    });
    
    // 开始教学
    this.viewModel.startTeaching(this.skillId, this.skillName);
  }

  aboutToDisappear() {
    this.viewModel.destroy();
  }

  build() {
    Column() {
      // 标题栏
      this.TitleBar()
      
      // 进度条
      this.ProgressBar()
      
      // 内容区域
      Scroll() {
        Column() {
          if (this.steps.length > 0) {
            // 当前步骤
            this.CurrentStepCard()
            
            // 步骤列表
            this.StepsList()
            
            // 操作按钮
            this.ActionButtons()
          } else {
            // 加载中
            this.LoadingView()
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
        Text('📚 学习')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text(this.skillName)
          .fontSize(14)
          .fontColor('#666666')
      }
      .alignItems(HorizontalAlign.Start)
      
      Blank()
      
      // 互动模式切换
      Button(this.interactionMode === InteractionMode.TEACHER ? '👨‍🏫 导师' : '🤝 陪练')
        .fontSize(12)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(this.interactionMode === InteractionMode.TEACHER ? '#007AFF' : '#34C759')
        .onClick(() => {
          this.viewModel.toggleMode();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ProgressBar() {
    Column() {
      Row() {
        Text(`进度：${this.progress}%`)
          .fontSize(14)
          .fontColor('#007AFF')
        Blank()
        Text(`${this.currentStepIndex + 1}/${this.steps.length}`)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      
      Progress({
        value: this.progress,
        total: 100,
        type: ProgressType.Linear
      })
        .color('#007AFF')
        .width('100%')
        .height(6)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .margin({ bottom: 8 })
  }

  @Builder
  CurrentStepCard() {
    const currentStep = this.steps[this.currentStepIndex];
    if (!currentStep) return;
    
    Column() {
      // 步骤标题
      Row() {
        Text(`步骤 ${currentStep.stepNumber}`)
          .fontSize(12)
          .fontColor('#007AFF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#E3F2FD')
          .borderRadius(12)
        
        Text(currentStep.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 12 })
      }
      .width('100%')
      
      // 步骤内容
      Text(currentStep.content)
        .fontSize(16)
        .fontColor('#333333')
        .lineHeight(24)
        .width('100%')
        .margin({ top: 16 })
      
      // 关键点
      if (currentStep.keyPoint) {
        Row() {
          Text('💡')
            .fontSize(16)
          Text(currentStep.keyPoint)
            .fontSize(14)
            .fontColor('#FF9500')
            .margin({ left: 8 })
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF8E1')
        .borderRadius(8)
        .margin({ top: 16 })
      }
      
      // 互动模式内容
      if (this.interactionMode === InteractionMode.PRACTICE) {
        this.PracticeSection()
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  PracticeSection() {
    Column() {
      Text('🤔 小测验')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 12 })
      
      // 输入框
      TextInput({ placeholder: '输入你的答案...', text: this.userAnswer })
        .fontSize(14)
        .padding(12)
        .backgroundColor('#F2F2F7')
        .borderRadius(8)
        .onChange((value: string) => {
          this.userAnswer = value;
        })
      
      // 提交按钮
      Button('提交答案')
        .width('100%')
        .margin({ top: 12 })
        .backgroundColor('#007AFF')
        .enabled(this.userAnswer.trim().length > 0)
        .onClick(() => {
          this.submitAnswer();
        })
    }
    .width('100%')
    .margin({ top: 16 })
  }

  @Builder
  StepsList() {
    Column() {
      Text('学习步骤')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 12 })
      
      ForEach(this.steps, (step: TeachingStep, index: number) => {
        Row() {
          // 完成状态
          Image(step.completed ? '✅' : '⏳')
            .width(24)
            .height(24)
          
          Text(step.title)
            .fontSize(14)
            .fontColor(step.completed ? '#34C759' : '#333333')
            .margin({ left: 12 })
          
          Blank()
          
          // 当前步骤标记
          if (index === this.currentStepIndex) {
            Text('当前')
              .fontSize(10)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#007AFF')
              .borderRadius(12)
              .fontColor('#FFFFFF')
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor(step.completed ? '#E8F5E9' : '#F2F2F7')
        .borderRadius(8)
        .margin({ bottom: 8 })
        .onClick(() => {
          if (step.completed) {
            this.currentStepIndex = index;
          }
        })
      })
    }
    .width('100%')
    .margin({ top: 16 })
  }

  @Builder
  ActionButtons() {
    Row() {
      Button('上一 步')
        .layoutWeight(1)
        .backgroundColor('#E5E5EA')
        .fontColor('#333333')
        .enabled(this.currentStepIndex > 0)
        .onClick(() => {
          if (this.currentStepIndex > 0) {
            this.currentStepIndex--;
          }
        })
      
      Button(this.isCompleted ? '完成学习' : '下一步')
        .layoutWeight(1)
        .backgroundColor('#007AFF')
        .fontColor('#FFFFFF')
        .margin({ left: 12 })
        .enabled(!this.isCompleted)
        .onClick(() => {
          if (this.isCompleted) {
            this.completeLearning();
          } else {
            this.nextStep();
          }
        })
    }
    .width('100%')
    .margin({ top: 24 })
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
      
      Text('正在加载教学内容...')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 16 })
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 提交答案
   */
  submitAnswer() {
    // TODO: 调用 viewModel 处理答案
    this.userAnswer = '';
  }

  /**
   * 下一步
   */
  nextStep() {
    this.viewModel.completeCurrentStep();
  }

  /**
   * 完成学习
   */
  completeLearning() {
    // TODO: 显示完成对话框
    // TODO: 发布 LearningCompletedEvent
  }
}

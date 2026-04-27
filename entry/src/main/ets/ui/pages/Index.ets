/**
 * ============================================================================
 * 首页 UI - Index
 * 纯 UI，无业务逻辑，仅绑定 VM 状态
 * ============================================================================
 */

import { IndexViewModel, ChatMessage } from '../../presentation/viewmodels/IndexViewModel';
import { InteractionMode } from '../../service/InteractionService';

@Entry
@Component
struct Index {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isProcessing: boolean = false;
  @State learningState: { isLearning: boolean; currentSkillName?: string; progress: number } = {
    isLearning: false,
    progress: 0,
  };
  @State interactionMode: InteractionMode = InteractionMode.TEACHER;
  
  private viewModel: IndexViewModel = new IndexViewModel();
  private scrollController: Scroller = new Scroller();

  aboutToAppear() {
    // 设置状态变化回调
    this.viewModel.setOnStateChanged(() => {
      this.messages = this.viewModel.getMessages();
      this.learningState = {
        isLearning: this.viewModel.getLearningState().isLearning,
        currentSkillName: this.viewModel.getLearningState().currentSkillName,
        progress: this.viewModel.getLearningState().progress,
      };
      this.interactionMode = this.viewModel.getInteractionMode();
    });
    
    // 添加欢迎消息
    this.messages.push({
      id: 'welcome',
      sender: 'assistant',
      content: '👋 你好！我是小艺教学智能体！\n\n我可以教你学会各种生活技能：\n📊 Excel 数据分析\n💬 微信使用\n📱 鸿蒙设备协同\n\n试试说："教我用 Excel" 或 "我想学微信支付"',
      timestamp: Date.now(),
    });
  }

  aboutToDisappear() {
    this.viewModel.destroy();
  }

  build() {
    Column() {
      // 标题栏
      this.TitleBar()

      // 对话区域
      Scroll(this.scrollController) {
        Column() {
          ForEach(this.messages, (msg: ChatMessage) => {
            this.ChatBubble(msg)
          })

          if (this.isProcessing) {
            Row() {
              Text('🤔 学习中...')
                .fontSize(14)
                .fontColor('#999999')
                .padding(12)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      // 学习进度条
      if (this.learningState.isLearning) {
        this.LearningProgressBar()
      }

      // 输入区域
      this.InputArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  TitleBar() {
    Row() {
      Text('📚 小艺教学助手')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')

      Blank()

      // 互动模式切换按钮
      Button(this.interactionMode === InteractionMode.TEACHER ? '👨‍🏫 导师' : '🤝 陪练')
        .fontSize(12)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(this.interactionMode === InteractionMode.TEACHER ? '#007AFF' : '#34C759')
        .onClick(() => {
          this.viewModel.toggleInteractionMode();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  LearningProgressBar() {
    Column() {
      Row() {
        Text(`正在学习：${this.learningState.currentSkillName || '未知'}`)
          .fontSize(12)
          .fontColor('#333333')
        Text(`${this.learningState.progress}%`)
          .fontSize(12)
          .fontColor('#007AFF')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Progress({
        value: this.learningState.progress,
        total: 100,
        type: ProgressType.Linear
      })
        .color('#007AFF')
        .width('100%')
        .height(4)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#E3F2FD')
    .borderRadius(8)
    .margin({ left: 16, right: 16, bottom: 8 })
  }

  @Builder
  InputArea() {
    Row() {
      TextInput({ placeholder: '输入想学的技能...', text: this.inputText })
        .fontSize(16)
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.inputText = value;
        })
        .onSubmit(() => {
          this.sendMessage();
        })

      Button() {
        Text('发送')
          .fontSize(16)
          .fontColor('#FFFFFF')
      }
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor(this.inputText.trim() ? '#007AFF' : '#E5E5EA')
      .borderRadius(24)
      .enabled(this.inputText.trim().length > 0 && !this.isProcessing)
      .onClick(() => {
        this.sendMessage();
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ChatBubble(msg: ChatMessage) {
    Row() {
      if (msg.sender === 'user') {
        Blank()
      }

      Column() {
        Text(msg.content)
          .fontSize(16)
          .fontColor(msg.sender === 'user' ? '#FFFFFF' : '#333333')
          .padding(12)
      }
      .backgroundColor(msg.sender === 'user' ? '#007AFF' : '#FFFFFF')
      .borderRadius(16)
      .margin(8)
      .maxWidth('70%')

      if (msg.sender === 'assistant') {
        Blank()
      }
    }
    .width('100%')
    .justifyContent(msg.sender === 'user' ? FlexAlign.End : FlexAlign.Start)
  }

  /**
   * 发送消息
   */
  async sendMessage() {
    const text = this.inputText.trim();
    if (!text || this.isProcessing) return;

    this.isProcessing = true;
    
    try {
      await this.viewModel.sendMessage('user_001', text);
      this.inputText = '';
      
      // 滚动到底部
      setTimeout(() => {
        this.scrollController.scrollEdge(Edge.Bottom);
      }, 100);
    } catch (error) {
      console.error('发送消息失败:', error);
    } finally {
      this.isProcessing = false;
    }
  }
}

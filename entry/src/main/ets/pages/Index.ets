/**
 * ============================================================================
 * 首页 - 教学智能体对话界面
 * 重构自原家庭管家Index.ets
 * ============================================================================
 */

import { LearningEngine } from '../services/engine/LearningEngine';
import { TemporalAbilityGraph } from '../services/engine/TemporalAbilityGraph';
import { DualRoleEngine } from '../services/engine/DualRoleEngine';
import { MotivationService } from '../services/engine/MotivationService';
import { HarmonyReminderService } from '../services/engine/HarmonyReminderService';
import { ChatBubble, ChatMessage } from '../components/ChatBubble';

/**
 * 首页 - 教学对话界面
 */
@Entry
@Component
struct Index {
  @State inputText: string = '';
  @State messages: ChatMessage[] = [];
  @State isProcessing: boolean = false;
  @State currentSkillName: string = '';
  @State currentStep: number = 0;
  @State totalSteps: number = 0;
  @State streak: number = 0;
  @State coins: number = 0;

  private learningEngine: LearningEngine;
  private abilityGraph: TemporalAbilityGraph;
  private dualRoleEngine: DualRoleEngine;
  private motivationService: MotivationService;
  private reminderService: HarmonyReminderService;
  private scrollController: Scroller = new Scroller();

  aboutToAppear() {
    this.learningEngine = LearningEngine.getInstance();
    this.abilityGraph = TemporalAbilityGraph.getInstance();
    this.dualRoleEngine = DualRoleEngine.getInstance();
    this.motivationService = MotivationService.getInstance();
    this.reminderService = HarmonyReminderService.getInstance();

    // 初始化学习引擎
    this.learningEngine.init();

    // 欢迎消息
    this.messages.push({
      id: `msg_welcome`,
      content: '👋 你好！我是小艺・全场景生活实践能力教学智能体！\n\n' +
               '我可以教你学会各种生活技能：\n' +
               '📊 Excel数据分析\n' +
               '💬 微信使用\n' +
               '📱 鸿蒙设备协同\n\n' +
               '试试说："教我用Excel" 或 "我想学微信支付"',
      sender: 'assistant',
      senderName: '小艺老师',
      timestamp: Date.now(),
      type: 'text',
    });
  }

  build() {
    Column() {
      // 标题栏
      this.TitleBar()

      // 对话区域
      Scroll(this.scrollController) {
        Column() {
          ForEach(this.messages, (msg: ChatMessage) => {
            ChatBubble({
              message: msg,
              isMine: msg.sender === 'user',
            })
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

      // 学习进度条（如果有在学习）
      if (this.currentSkillName) {
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

      // 学习数据
      Row({ space: 12 }) {
        Column() {
          Text(`${this.streak}天`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
          Text('连续')
            .fontSize(10)
            .fontColor('#999999')
        }

        Column() {
          Text(`${this.coins}`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFD700')
          Text('金币')
            .fontSize(10)
            .fontColor('#999999')
        }
      }
      .onClick(() => {
        // 跳转到进度页面
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
        Text(`正在学习：${this.currentSkillName}`)
          .fontSize(12)
          .fontColor('#333333')
        Text(`步骤 ${this.currentStep}/${this.totalSteps}`)
          .fontSize(12)
          .fontColor('#007AFF')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Progress({
        value: this.totalSteps > 0 ? (this.currentStep / this.totalSteps) * 100 : 0,
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

  /**
   * 发送消息并处理教学
   */
  async sendMessage() {
    const text = this.inputText.trim();
    if (!text || this.isProcessing) return;

    // 添加用户消息
    const userMsg: ChatMessage = {
      id: `msg_${Date.now()}`,
      content: text,
      sender: 'user',
      senderName: '我',
      timestamp: Date.now(),
      type: 'text',
    };
    this.messages.push(userMsg);
    this.inputText = '';
    this.isProcessing = true;
    this.scrollToBottom();

    try {
      // 1. 解析教学意图
      const intent = this.learningEngine.parseTeachIntent(text);

      if (intent.needsClarification) {
        // 需要追问
        const assistantMsg: ChatMessage = {
          id: `msg_${Date.now()}`,
          content: intent.clarificationQuestion || '您想学习什么技能呢？',
          sender: 'assistant',
          senderName: '小艺老师',
          timestamp: Date.now(),
          type: 'text',
        };
        this.messages.push(assistantMsg);
      } else if (intent.skillId && intent.skillName) {
        // 2. 构建学习路径
        const learningPath = this.learningEngine.buildLearningPath(intent.skillId);

        this.currentSkillName = learningPath.skillName;
        this.totalSteps = learningPath.steps.length;
        this.currentStep = 1;

        // 3. 开启双角色对话
        this.dualRoleEngine.startConversation('default_user', intent.skillId, intent.skillName);

        // 发送开始学习消息
        const startMsg: ChatMessage = {
          id: `msg_${Date.now()}`,
          content: `🎯 开始学习「${learningPath.skillName}」！\n\n` +
                   `预计${learningPath.estimatedTime}分钟，共${learningPath.steps.length}个步骤。\n\n` +
                   `准备好了吗？我们先从第一步开始～`,
          sender: 'assistant',
          senderName: '小艺老师',
          timestamp: Date.now(),
          type: 'text',
        };
        this.messages.push(startMsg);

        // 4. 开始第一步教学
        await this.teachCurrentStep(learningPath);

        // 5. 设置复习提醒
        await this.reminderService.scheduleReviewReminder(
          'default_user',
          intent.skillId,
          intent.skillName,
          new Date()
        );
      }

    } catch (error) {
      const errorMsg: ChatMessage = {
        id: `msg_${Date.now()}`,
        content: '处理时出现了一些问题，请稍后再试。',
        sender: 'assistant',
        senderName: '小艺老师',
        timestamp: Date.now(),
        type: 'error',
      };
      this.messages.push(errorMsg);
    } finally {
      this.isProcessing = false;
      this.scrollToBottom();
    }
  }

  /**
   * 教学当前步骤
   */
  private async teachCurrentStep(learningPath: any) {
    const currentStepData = learningPath.steps.find((s: any) => s.stepNumber === this.currentStep);
    if (!currentStepData) {
      // 学习完成
      await this.completeLearning(learningPath);
      return;
    }

    // 使用双角色引擎获取教学内容
    const dialog = this.dualRoleEngine.getCurrentDialog('default_user');

    if (dialog) {
      const teachMsg: ChatMessage = {
        id: `msg_${Date.now()}`,
        content: dialog.content || currentStepData.content,
        sender: 'assistant',
        senderName: '小艺老师',
        timestamp: Date.now(),
        type: 'text',
      };
      this.messages.push(teachMsg);

      // 如果有练习题，展示选项
      if (dialog.suggestions && dialog.suggestions.length > 0) {
        const practiceMsg: ChatMessage = {
          id: `msg_${Date.now()}`,
          content: `请选择答案：${dialog.suggestions.join(' / ')}`,
          sender: 'assistant',
          senderName: '小艺老师',
          timestamp: Date.now(),
          type: 'choice',
          options: dialog.suggestions,
        };
        this.messages.push(practiceMsg);
      }
    }
  }

  /**
   * 处理用户回答
   */
  async handleAnswer(answer: string) {
    // 添加用户答案
    const userMsg: ChatMessage = {
      id: `msg_${Date.now()}`,
      content: answer,
      sender: 'user',
      senderName: '我',
      timestamp: Date.now(),
      type: 'text',
    };
    this.messages.push(userMsg);

    // 处理答案
    const result = this.dualRoleEngine.processUserInput('default_user', answer);
    const roleState = this.dualRoleEngine.getRoleState('default_user');

    if (result) {
      const feedbackMsg: ChatMessage = {
        id: `msg_${Date.now()}`,
        content: result.content,
        sender: 'assistant',
        senderName: '小艺老师',
        timestamp: Date.now(),
        type: 'text',
      };
      this.messages.push(feedbackMsg);

      // 记录学习结果
      const correct = result.id.includes('correct');
      this.learningEngine.recordLearningResult(
        'default_user',
        roleState?.currentStep?.toString() || '',
        roleState?.currentStep || 0,
        correct
      );

      // 给予奖励
      if (correct) {
        const reward = this.motivationService.reward('default_user', {
          skillName: this.currentSkillName,
          correct: true
        });
        this.coins += reward.coins;

        if (reward.achievement) {
          const achieveMsg: ChatMessage = {
            id: `msg_${Date.now()}`,
            content: `🎉 解锁成就：${reward.achievement.name}！`,
            sender: 'assistant',
            senderName: '小艺老师',
            timestamp: Date.now(),
            type: 'achievement',
          };
          this.messages.push(achieveMsg);
        }
      }

      // 自动进入下一步
      if (roleState && !this.dualRoleEngine.isLearningComplete('default_user')) {
        setTimeout(() => {
          this.dualRoleEngine.advanceDialog('default_user');
          const nextDialog = this.dualRoleEngine.getCurrentDialog('default_user');
          if (nextDialog) {
            const nextMsg: ChatMessage = {
              id: `msg_${Date.now()}`,
              content: nextDialog.content,
              sender: 'assistant',
              senderName: '小艺老师',
              timestamp: Date.now(),
              type: 'text',
            };
            this.messages.push(nextMsg);
            this.scrollToBottom();
          }
        }, 2000);
      }
    }
  }

  /**
   * 完成学习
   */
  private async completeLearning(learningPath: any) {
    this.currentSkillName = '';
    this.currentStep = 0;
    this.totalSteps = 0;

    // 给予完成奖励
    const reward = this.motivationService.reward('default_user', {
      skillName: learningPath.skillName,
      completed: true
    });
    this.coins += reward.coins;

    // 连续学习奖励
    const streakInfo = this.motivationService.checkStreak('default_user');
    this.streak = streakInfo.currentStreak;

    // 结束对话
    this.dualRoleEngine.endConversation('default_user');

    const completeMsg: ChatMessage = {
      id: `msg_${Date.now()}`,
      content: `🎉 恭喜完成「${learningPath.skillName}」学习！\n\n` +
               `✨ 获得 ${reward.coins} 金币\n` +
               `🔥 连续学习 ${this.streak} 天\n\n` +
               `想学习其他技能吗？`,
      sender: 'assistant',
      senderName: '小艺老师',
      timestamp: Date.now(),
      type: 'complete',
    };
    this.messages.push(completeMsg);
  }

  private scrollToBottom() {
    setTimeout(() => {
      this.scrollController.scrollEdge(Edge.Bottom);
    }, 100);
  }
}

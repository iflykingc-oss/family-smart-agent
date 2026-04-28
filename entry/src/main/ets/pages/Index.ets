/**
 * ============================================================================
 * 首页 - 小 e 教学智能体对话界面
 * v2.0 重构：
 * - 品牌替换：小艺 → 小 e
 * - 新增职业素养技能展示
 * - 新增技能分类标签
 * - 修复欢迎文案
 * ============================================================================
 */

import { LearningEngine, TeachSceneType, SkillCategory } from '../services/engine/LearningEngine';
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
  @State selectedCategory: SkillCategory = SkillCategory.PROFESSIONAL; // 默认显示职业素养

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

    // 欢迎消息（v2.0 更新）
    this.messages.push({
      id: `msg_welcome`,
      content: '👋 你好！我是小 e・轻量化职业素养智能导学助手！\n\n' +
               '我可以教你学会各种技能：\n' +
               '💼 职业素养：沟通技巧、时间管理、职场礼仪\n' +
               '📊 办公技能：Excel、PPT、邮件写作\n' +
               '📱 生活技能：微信使用、网上挂号\n' +
               '🔧 数字技能：鸿蒙协同、手机安全\n\n' +
               '试试说："教我沟通技巧" 或 "教我用Excel"',
      sender: 'assistant',
      senderName: '小 e 老师',
      timestamp: Date.now(),
      type: 'text',
    });
  }

  build() {
    Column() {
      // 标题栏
      this.TitleBar()

      // 技能分类标签（新增）
      this.CategoryTabs()

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
      Text('📚 小 e 导学助手')
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

  /**
   * 技能分类标签（新增）
   */
  @Builder
  CategoryTabs() {
    Row() {
      ForEach([
        { category: SkillCategory.PROFESSIONAL, name: '职业素养', icon: '💼' },
        { category: SkillCategory.OFFICE, name: '办公技能', icon: '📊' },
        { category: SkillCategory.LIFE, name: '生活技能', icon: '📱' },
        { category: SkillCategory.DIGITAL, name: '数字技能', icon: '🔧' }
      ], (item: { category: SkillCategory, name: string, icon: string }) => {
        Row() {
          Text(`${item.icon} ${item.name}`)
            .fontSize(13)
            .fontColor(this.selectedCategory === item.category ? '#FFFFFF' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .backgroundColor(this.selectedCategory === item.category ? '#007AFF' : '#F0F0F0')
        }
        .onClick(() => {
          this.selectedCategory = item.category;
          this.loadSkillsByCategory(item.category);
        })
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  LearningProgressBar() {
    Column() {
      Row() {
        Text(this.currentSkillName)
          .fontSize(13)
          .fontColor('#666666')
        Blank()
        Text(`${this.currentStep}/${this.totalSteps}`)
          .fontSize(13)
          .fontColor('#007AFF')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Progress({ value: this.currentStep, total: this.totalSteps, type: ProgressType.Linear })
        .width('100%')
        .color('#007AFF')
        .height(4)
        .margin({ left: 16, right: 16, top: 4, bottom: 8 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  InputArea() {
    Row() {
      TextInput({ text: this.inputText, placeholder: '输入你想学的技能...' })
        .width('75%')
        .height(40)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .padding({ left: 16 })
        .onChange((value: string) => {
          this.inputText = value;
        })

      Button('发送')
        .width('20%')
        .height(40)
        .backgroundColor('#007AFF')
        .borderRadius(20)
        .margin({ left: 8 })
        .onClick(() => {
          if (this.inputText.trim()) {
            this.sendMessage(this.inputText.trim());
            this.inputText = '';
          }
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  /**
   * 发送消息
   */
  private sendMessage(text: string): void {
    // 添加用户消息
    this.messages.push({
      id: `msg_${Date.now()}`,
      content: text,
      sender: 'user',
      senderName: '我',
      timestamp: Date.now(),
      type: 'text',
    });

    this.isProcessing = true;

    // 解析意图
    const intent = this.learningEngine.parseTeachIntent(text);

    setTimeout(() => {
      if (intent.needsClarification) {
        // 需要追问
        this.messages.push({
          id: `msg_${Date.now()}`,
          content: intent.clarificationQuestion || '您想学习什么技能呢？',
          sender: 'assistant',
          senderName: '小 e 老师',
          timestamp: Date.now(),
          type: 'text',
        });
      } else {
        // 开始学习
        this.startLearning(intent.skillId!, intent.skillName!);
      }

      this.isProcessing = false;
      this.scrollController.scrollToEnd();
    }, 500);
  }

  /**
   * 开始学习
   */
  private startLearning(skillId: string, skillName: string): void {
    // 构建学习路径
    const path = this.learningEngine.buildLearningPath(skillId);
    this.currentSkillName = skillName;
    this.currentStep = 1;
    this.totalSteps = path.steps.length;

    // 开始对话
    this.dualRoleEngine.startConversation('default', skillId, skillName);

    // 获取第一个对话节点
    const dialog = this.dualRoleEngine.getCurrentDialog('default');

    this.messages.push({
      id: `msg_${Date.now()}`,
      content: dialog?.content || `让我们开始学习${skillName}吧！`,
      sender: 'assistant',
      senderName: '小 e 老师',
      timestamp: Date.now(),
      type: 'text',
    });

    this.scrollController.scrollToEnd();
  }

  /**
   * 按分类加载技能
   */
  private loadSkillsByCategory(category: SkillCategory): void {
    const skills = this.learningEngine.getSkillList(category);
    const categoryName = this.learningEngine.getSkillCategoryName(category);

    this.messages.push({
      id: `msg_${Date.now()}`,
      content: `📚 ${categoryName}技能：\n\n${skills.map(s => `• ${s.name}`).join('\n')}`,
      sender: 'assistant',
      senderName: '小 e 老师',
      timestamp: Date.now(),
      type: 'text',
    });

    this.scrollController.scrollToEnd();
  }
}

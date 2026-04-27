import { MemoryService } from '../services/MemoryService';
import { FamilyMember } from '../model/FamilyMember';

/**
 * 记忆页面 - 展示家庭成员和记忆信息
 */
@Entry
@Component
struct Memory {
  @State members: FamilyMember[] = [];
  @State selectedMember: FamilyMember | null = null;
  private memoryService: MemoryService;

  aboutToAppear() {
    this.memoryService = MemoryService.getInstance();
    this.loadMembers();
  }

  loadMembers() {
    this.members = this.memoryService.getAllMembers();
  }

  build() {
    Column() {
      // 标题栏
      this.TitleBar()

      if (this.selectedMember) {
        // 成员详情
        this.MemberDetail()
      } else {
        // 成员列表
        this.MemberList()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  TitleBar() {
    Row() {
      if (this.selectedMember) {
        Text('← 返回')
          .fontSize(16)
          .fontColor('#007AFF')
          .onClick(() => {
            this.selectedMember = null;
          })
      } else {
        Text('👨‍👩‍👧 家庭记忆')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      
      Blank()
      
      Text(`${this.members.length} 位成员`)
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  MemberList() {
    List() {
      ForEach(this.members, (member: FamilyMember) => {
        ListItem() {
          this.MemberCard(member)
        }
        .onClick(() => {
          this.selectedMember = member;
        })
      })
    }
    .width('100%')
    .layoutWeight(1)
    .padding(16)
  }

  @Builder
  MemberCard(member: FamilyMember) {
    Column() {
      Row() {
        // 头像占位
        Circle()
          .fill(this.getAvatarColor(member.name))
          .width(50)
          .height(50)
          .align(Alignment.Center)
          .overlay(
            Text(member.name.charAt(0))
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          )
          .margin({ right: 16 })

        Column() {
          Text(member.name)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          
          Text(member.relation)
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('>')
          .fontSize(20)
          .fontColor('#CCCCCC')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)

      // 健康标签
      if (member.healthNotes.length > 0 || member.constraints.length > 0) {
        Row() {
          ForEach(member.healthNotes, (note: string) => {
            Text(`🩺 ${note}`)
              .fontSize(12)
              .fontColor('#FF3B30')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#FFEBEE')
              .borderRadius(4)
              .margin({ right: 8 })
          })
          
          ForEach(member.constraints, (constraint: string) => {
            Text(`⚠️ ${constraint}`)
              .fontSize(12)
              .fontColor('#FF9500')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#FFF3E0')
              .borderRadius(4)
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius({ bottomLeft: 12, bottomRight: 12 })
      }
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  MemberDetail() {
    Scroll() {
      Column() {
        // 头部信息
        Column() {
          Circle()
            .fill(this.getAvatarColor(this.selectedMember!.name))
            .width(80)
            .height(80)
            .align(Alignment.Center)
            .overlay(
              Text(this.selectedMember!.name.charAt(0))
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
            )
            .margin({ bottom: 12 })
          
          Text(this.selectedMember!.name)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          
          Text(this.selectedMember!.relation)
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding(32)
        .backgroundColor('#FFFFFF')

        // 健康备注
        if (this.selectedMember!.healthNotes.length > 0) {
          this.SectionCard('🩺 健康备注', this.selectedMember!.healthNotes, '#FF3B30', '#FFEBEE')
        }

        // 照料约束
        if (this.selectedMember!.constraints.length > 0) {
          this.SectionCard('⚠️ 照料约束', this.selectedMember!.constraints, '#FF9500', '#FFF3E0')
        }

        // 习惯偏好
        if (this.selectedMember!.habits.length > 0) {
          this.SectionCard('📌 习惯偏好', this.selectedMember!.habits, '#007AFF', '#E8F4FF')
        }

        // 操作按钮
        Row() {
          Button('编辑信息')
            .fontSize(16)
            .fontColor('#007AFF')
            .backgroundColor('#FFFFFF')
            .borderWidth(1)
            .borderColor('#007AFF')
            .borderRadius(8)
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          
          Button('添加记忆')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#007AFF')
            .borderRadius(8)
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
        }
        .width('100%')
        .padding(16)
        .justifyContent(FlexAlign.SpaceEvenly)
      }
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  SectionCard(title: string, items: string[], textColor: string, bgColor: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 8 })
      
      Flow() {
        ForEach(items, (item: string) => {
          Text(item)
            .fontSize(14)
            .fontColor(textColor)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(bgColor)
            .borderRadius(16)
            .margin(4)
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .margin({ top: 12 })
  }

  getAvatarColor(name: string): string {
    const colors = ['#007AFF', '#34C759', '#FF9500', '#FF3B30', '#AF52DE', '#5856D6'];
    const index = name.charCodeAt(0) % colors.length;
    return colors[index];
  }
}

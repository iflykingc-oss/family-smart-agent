/**
 * 聊天气泡组件
 */
@Component
export struct ChatBubble {
  @Prop message: ChatMessage;
  @Prop isMine: boolean = false;

  build() {
    Row() {
      if (this.isMine) {
        Blank()
      }
      
      Column() {
        if (!this.isMine) {
          Text(this.message.senderName)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ bottom: 4 })
        }
        
        Text(this.message.content)
          .fontSize(16)
          .fontColor(this.isMine ? '#FFFFFF' : '#333333')
          .padding(12)
          .backgroundColor(this.isMine ? '#007AFF' : '#F2F2F7')
          .borderRadius(18)
          .margin({ bottom: 4 })
        
        if (this.message.type === 'task') {
          this.TaskCard()
        }
        
        Text(this.formatTime(this.message.timestamp))
          .fontSize(10)
          .fontColor('#999999')
      }
      .alignItems(this.isMine ? HorizontalAlign.End : HorizontalAlign.Start)
      .layoutWeight(1)
      
      if (!this.isMine) {
        Blank()
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  TaskCard() {
    Column() {
      if (this.message.tasks && this.message.tasks.length > 0) {
        ForEach(this.message.tasks, (task: string) => {
          Row() {
            Text('📋')
              .fontSize(14)
            Text(task)
              .fontSize(14)
              .fontColor('#333333')
          }
          .padding(8)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ top: 4 })
        })
      }
    }
  }

  formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }
}

/**
 * 聊天消息
 */
export interface ChatMessage {
  id: string;
  content: string;
  sender: 'user' | 'assistant';
  senderName: string;
  timestamp: number;
  type: 'text' | 'task' | 'memory' | 'error';
  tasks?: string[];
}

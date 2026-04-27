import { Task } from '../model/Task';

/**
 * 鸿蒙日历服务
 * 负责创建和管理日历事件/提醒
 */
export class CalendarService {
  private static instance: CalendarService | null = null;

  static getInstance(): CalendarService {
    if (!CalendarService.instance) {
      CalendarService.instance = new CalendarService();
    }
    return CalendarService.instance;
  }

  private constructor() {}

  /**
   * 创建日历事件
   * 接入鸿蒙 Calendar Kit
   */
  async createCalendarEvent(task: Task): Promise<CalendarEventResult> {
    // 模拟鸿蒙日历API调用
    // 正式项目需要接入 @ohos.calendar 能力
    
    if (!task.dueTime) {
      return {
        success: false,
        eventId: undefined,
        message: '缺少时间信息',
      };
    }

    // 模拟创建成功
    const eventId = `cal_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
    
    return {
      success: true,
      eventId,
      message: '已添加到日历',
    };
  }

  /**
   * 创建提醒
   */
  async createReminder(task: Task): Promise<ReminderResult> {
    if (!task.dueTime) {
      return {
        success: false,
        reminderId: undefined,
        message: '缺少提醒时间',
      };
    }

    // 模拟提醒创建
    const reminderId = `rem_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;

    return {
      success: true,
      reminderId,
      message: `已设置提醒：${task.title}`,
    };
  }

  /**
   * 查询日历事件
   */
  async queryEvents(startTime: number, endTime: number): Promise<CalendarEvent[]> {
    // 模拟查询
    return [];
  }

  /**
   * 删除日历事件
   */
  async deleteEvent(eventId: string): Promise<boolean> {
    return true;
  }
}

/**
 * 日历事件结果
 */
export interface CalendarEventResult {
  success: boolean;
  eventId?: string;
  message: string;
}

/**
 * 提醒结果
 */
export interface ReminderResult {
  success: boolean;
  reminderId?: string;
  message: string;
}

/**
 * 日历事件
 */
export interface CalendarEvent {
  id: string;
  title: string;
  startTime: number;
  endTime?: number;
  reminderTime?: number;
  location?: string;
  description?: string;
}

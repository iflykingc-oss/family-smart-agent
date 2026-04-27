/**
 * 鸿蒙日历服务（真实API集成）
 * 使用 HarmonyOS Calendar Kit 创建和管理日历事件
 * 
 * API参考：
 * https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-calendar
 */
import calendar from '@ohos.calendar';
import reminder from '@ohos.reminder';

/**
 * 鸿蒙日历服务
 * 负责创建和管理日历事件/提醒
 */
export class HarmonyCalendarService {
  private static instance: HarmonyCalendarService | null = null;
  private calendarManager: calendar.CalendarManager | null = null;
  private calendarId: number | null = null;

  static getInstance(): HarmonyCalendarService {
    if (!HarmonyCalendarService.instance) {
      HarmonyCalendarService.instance = new HarmonyCalendarService();
    }
    return HarmonyCalendarService.instance;
  }

  private constructor() {
    this.initCalendar();
  }

  /**
   * 初始化日历管理器
   */
  private async initCalendar(): Promise<void> {
    try {
      // 获取日历管理器
      this.calendarManager = calendar.getCalendarManager();
      
      // 获取默认日历账户
      // 注意：实际使用需要ohos.permission.WRITE_CALENDAR权限
      const calendars = await this.calendarManager.getCalendars();
      if (calendars && calendars.length > 0) {
        this.calendarId = calendars[0].id;
      }
    } catch (error) {
      console.error('Failed to initialize calendar:', JSON.stringify(error));
    }
  }

  /**
   * 创建日历事件
   * @param title 事件标题
   * @param description 事件描述
   * @param startTime 开始时间（毫秒）
   * @param endTime 结束时间（毫秒）
   * @param reminderMinutes 提前提醒分钟数
   */
  async createEvent(options: {
    title: string;
    description?: string;
    startTime: number;
    endTime?: number;
    reminderMinutes?: number;
    location?: string;
  }): Promise<CalendarEventResult> {
    try {
      if (!this.calendarManager) {
        await this.initCalendar();
      }

      const {
        title,
        description = '',
        startTime,
        endTime = startTime + 3600000, // 默认1小时
        reminderMinutes = 30,
        location = ''
      } = options;

      // 创建事件属性
      const event: calendar.Event = {
        title,
        description,
        startTime,
        endTime,
        timeZone: 'Asia/Shanghai',
        location,
        // 事件类型：普通事件 = 0
        type: 0,
      };

      // 添加日历
      // 注意：需要日历写入权限
      const eventId = await this.calendarManager?.addEvent(event, this.calendarId ?? 0);

      if (eventId) {
        // 创建提醒
        await this.createReminderInternal(eventId, reminderMinutes);
        
        return {
          success: true,
          eventId: String(eventId),
          message: '事件已创建',
        };
      }

      return {
        success: false,
        eventId: undefined,
        message: '创建失败',
      };
    } catch (error) {
      console.error('Failed to create calendar event:', JSON.stringify(error));
      return {
        success: false,
        eventId: undefined,
        message: `创建失败: ${JSON.stringify(error)}`,
      };
    }
  }

  /**
   * 创建提醒（内部方法）
   */
  private async createReminderInternal(eventId: number, minutes: number): Promise<void> {
    try {
      // 使用reminder模块创建提醒
      // 注意：需要PUBLISH_AGENT_REMINDER权限
      const reminderRequest: reminder.ReminderRequestCalendar = {
        reminderType: reminder.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: new Date().getFullYear(),
          month: new Date().getMonth() + 1,
          day: new Date().getDate(),
          hour: new Date().getHours(),
          minute: new Date().getMinutes() + minutes,
        },
        repeatMonths: [],
        repeatDays: [],
        title: '家庭任务提醒',
        wantAgent: {
          pkgName: 'com.family.smarthub',
          abilityName: 'EntryAbility',
        },
        actionButton: [
          {
            title: '查看',
            type: reminder.ActionButtonType.ACTION_BUTTON_TYPE_CUSTOM,
          },
        ],
      };

      // 发布提醒
      reminder.publishReminder(reminderRequest);
    } catch (error) {
      console.warn('Failed to create reminder:', JSON.stringify(error));
    }
  }

  /**
   * 创建快速提醒（不需要完整日历事件）
   */
  async createQuickReminder(options: {
    title: string;
    content?: string;
    triggerTimeInMinutes: number;
  }): Promise<ReminderResult> {
    try {
      const { title, content = '', triggerTimeInMinutes } = options;

      // 计算触发时间
      const triggerTimestamp = Date.now() + triggerTimeInMinutes * 60 * 1000;
      const triggerDate = new Date(triggerTimestamp);

      const reminderRequest: reminder.ReminderRequestTimer = {
        reminderType: reminder.ReminderType.REMINDER_TYPE_TIMER,
        dateTime: {
          year: triggerDate.getFullYear(),
          month: triggerDate.getMonth() + 1,
          day: triggerDate.getDate(),
          hour: triggerDate.getHours(),
          minute: triggerDate.getMinutes(),
        },
        repeatMonths: [],
        repeatDays: [],
        title,
        content,
        wantAgent: {
          pkgName: 'com.family.smarthub',
          abilityName: 'EntryAbility',
        },
      };

      const reminderId = await reminder.publishReminder(reminderRequest);

      return {
        success: true,
        reminderId: String(reminderId),
        message: `已设置${triggerTimeInMinutes}分钟后提醒`,
      };
    } catch (error) {
      console.error('Failed to create reminder:', JSON.stringify(error));
      return {
        success: false,
        reminderId: undefined,
        message: `创建失败: ${JSON.stringify(error)}`,
      };
    }
  }

  /**
   * 删除日历事件
   */
  async deleteEvent(eventId: string): Promise<boolean> {
    try {
      if (this.calendarManager && this.calendarId) {
        await this.calendarManager.deleteEvent(parseInt(eventId), this.calendarId);
        return true;
      }
      return false;
    } catch (error) {
      console.error('Failed to delete event:', JSON.stringify(error));
      return false;
    }
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

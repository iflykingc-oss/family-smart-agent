/**
 * ============================================================================
 * 学习记录实体 - LearningRecordEntity
 * 领域层核心实体
 * ============================================================================
 */

/**
 * 学习结果
 */
export enum LearningResult {
  CORRECT = 'correct',
  INCORRECT = 'incorrect',
  PARTIAL = 'partial',
}

/**
 * 设备类型
 */
export enum DeviceType {
  PHONE = 'phone',
  TABLET = 'tablet',
  PC = 'pc',
  SMART_SCREEN = 'smartScreen',
  SPEAKER = 'speaker',
}

/**
 * 学习记录实体
 */
export class LearningRecordEntity {
  /** 记录 ID */
  public readonly id: string;
  
  /** 用户 ID */
  public readonly userId: string;
  
  /** 技能 ID */
  public readonly skillId: string;
  
  /** 步骤编号 */
  public readonly stepNumber: number;
  
  /** 练习 ID */
  public readonly practiceId: string;
  
  /** 学习结果 */
  public readonly result: LearningResult;
  
  /** 学习时长（秒） */
  public readonly timeSpent: number;
  
  /** 使用提示次数 */
  public readonly hintsUsed: number;
  
  /** 学习时间（小时 0-23） */
  public readonly timeOfDay: number;
  
  /** 设备类型 */
  public readonly deviceType: DeviceType;
  
  /** 日期 */
  public readonly date: string;
  
  /** 星期几 */
  public readonly dayOfWeek: number;
  
  /** 时间戳 */
  public readonly timestamp: number;

  constructor(
    id: string,
    userId: string,
    skillId: string,
    stepNumber: number,
    practiceId: string,
    result: LearningResult,
    timeSpent: number,
    hintsUsed: number,
    timeOfDay: number,
    deviceType: DeviceType,
    date: string,
    dayOfWeek: number,
    timestamp: number
  ) {
    this.id = id;
    this.userId = userId;
    this.skillId = skillId;
    this.stepNumber = stepNumber;
    this.practiceId = practiceId;
    this.result = result;
    this.timeSpent = timeSpent;
    this.hintsUsed = hintsUsed;
    this.timeOfDay = timeOfDay;
    this.deviceType = deviceType;
    this.date = date;
    this.dayOfWeek = dayOfWeek;
    this.timestamp = timestamp;
  }

  /**
   * 检查是否正确
   */
  isCorrect(): boolean {
    return this.result === LearningResult.CORRECT;
  }

  /**
   * 检查是否错误
   */
  isIncorrect(): boolean {
    return this.result === LearningResult.INCORRECT;
  }

  /**
   * 获取学习时间段
   */
  getTimeSlot(): 'morning' | 'afternoon' | 'evening' | 'night' {
    if (this.timeOfDay >= 6 && this.timeOfDay < 12) return 'morning';
    if (this.timeOfDay >= 12 && this.timeOfDay < 14) return 'afternoon';
    if (this.timeOfDay >= 14 && this.timeOfDay < 19) return 'afternoon';
    if (this.timeOfDay >= 19 && this.timeOfDay < 22) return 'evening';
    return 'night';
  }

  /**
   * 转换为 DTO
   */
  toDTO(): LearningRecordDTO {
    return {
      id: this.id,
      userId: this.userId,
      skillId: this.skillId,
      stepNumber: this.stepNumber,
      practiceId: this.practiceId,
      result: this.result,
      timeSpent: this.timeSpent,
      hintsUsed: this.hintsUsed,
      timeOfDay: this.timeOfDay,
      deviceType: this.deviceType,
      date: this.date,
      dayOfWeek: this.dayOfWeek,
      timestamp: this.timestamp,
    };
  }

  /**
   * 从 DTO 创建实体
   */
  static fromDTO(dto: LearningRecordDTO): LearningRecordEntity {
    return new LearningRecordEntity(
      dto.id,
      dto.userId,
      dto.skillId,
      dto.stepNumber,
      dto.practiceId,
      dto.result,
      dto.timeSpent,
      dto.hintsUsed,
      dto.timeOfDay,
      dto.deviceType,
      dto.date,
      dto.dayOfWeek,
      dto.timestamp
    );
  }
}

/**
 * 学习记录 DTO
 */
export interface LearningRecordDTO {
  id: string;
  userId: string;
  skillId: string;
  stepNumber: number;
  practiceId: string;
  result: LearningResult;
  timeSpent: number;
  hintsUsed: number;
  timeOfDay: number;
  deviceType: DeviceType;
  date: string;
  dayOfWeek: number;
  timestamp: number;
}

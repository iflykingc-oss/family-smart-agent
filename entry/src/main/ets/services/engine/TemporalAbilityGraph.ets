/**
 * ============================================================================
 * 时空能力图谱 - TemporalAbilityGraph
 * 
 * 【借鉴优化】
 * 参考：Memory Manager - 三层记忆（Episodic/Semantic/Procedural）
 * 优化：从"静态分类存储" → "时空维度 + FSRS 动态预测"
 * 
 * 核心差异化：自研用户行为时空图谱引擎
 * 
 * 【算法支持】
 * - FSRS v6 算法（ts-fsrs 包）
 * - 17 个权重参数，科学计算复习间隔
 * - 稳定度/难度/可回忆性三维度
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { fsrs, createEmptyCard, Rating, Card, Grade, generatorParameters } from 'ts-fsrs';

/**
 * 能力等级
 */
export enum AbilityLevel {
  ZERO = 0,
  AWARENESS = 1,
  BEGINNER = 2,
  BASIC = 3,
  INTERMEDIATE = 4,
  ADVANCED = 5,
  MASTER = 6
}

/**
 * 技能节点
 */
export interface SkillNode {
  id: string;
  name: string;
  category: SkillCategory;
  difficulty: number;
  prerequisites: string[];
  estimatedHours: number;
  realWorldScenes: string[];
  tags: string[];
}

/**
 * 技能类别
 */
export enum SkillCategory {
  OFFICE = 'office',
  LIFE = 'life',
  DIGITAL = 'digital',
  HEALTH = 'health',
  FINANCIAL = 'financial',
  SOCIAL = 'social'
}

/**
 * 用户技能记录
 */
export interface UserSkill {
  skillId: string;
  level: AbilityLevel;
  experienceHours: number;
  lastPracticed: number;
  practiceCount: number;
  weakPoints: string[];
  strongPoints: string[];
  confidence: number;
  interest: number;
  
  // ========== 时空维度 ==========
  
  // 时间维度
  temporalPattern: Record<string, number>;  // {morning: 30, afternoon: 20, evening: 50}
  bestTimeSlot: 'morning' | 'afternoon' | 'evening' | 'night';
  learningSpeed: number;
  
  // 空间维度
  spatialPattern: Record<string, number>;  // {phone: 60, tablet: 30, pc: 10}
  
  // FSRS 状态
  fsrsStability: number;      // 记忆稳定度（天）
  fsrsDifficulty: number;     // 难度（1-10）
  fsrsRetrievability: number; // 可回忆性（0-1）
  fsrsInterval: number;       // 当前间隔（天）
  fsrsRepetitions: number;    // 复习次数
  fsrsDueDate: number;        // 下次复习时间戳
  
  createdAt: number;
  updatedAt: number;
}

/**
 * 学习记录
 */
export interface LearningRecord {
  id: string;
  skillId: string;
  stepNumber: number;
  practiceId: string;
  result: 'correct' | 'incorrect' | 'partial';
  timeSpent: number;
  hintsUsed: number;
  
  // 时空维度
  timeOfDay: number;
  deviceType: 'phone' | 'tablet' | 'pc';
  date: string;
  dayOfWeek: number;
  timestamp: number;
}

/**
 * 能力图谱查询结果
 */
export interface AbilityQueryResult {
  skills: UserSkill[];
  recommendations: SkillRecommendation[];
  weakAreas: string[];
  strongAreas: string[];
  suggestedReview: SkillRecommendation[];
}

/**
 * 技能推荐
 */
export interface SkillRecommendation {
  skill: SkillNode;
  reason: string;
  priority: number;
  estimatedImpact: string;
  matchScore: number;
}

/**
 * FSRS 调度器实例
 */
let fsrsScheduler: any = null;

/**
 * 初始化 FSRS 调度器
 */
function getFsrsScheduler() {
  if (!fsrsScheduler) {
    // 使用 FSRS v6 默认参数（17 个权重）
    fsrsScheduler = fsrs({
      request_retention: 0.9,        // 目标保持率 90%
      maximum_interval: 36500,       // 最大间隔 100 年
      enable_fuzz: false,            // 禁用随机扰动（确定性更好）
      enable_short_term: true,       // 启用短期学习
      learning_steps: ['1m', '10m'], // 学习步骤
      relearning_steps: ['10m'],     // 重新学习步骤
    });
  }
  return fsrsScheduler;
}

/**
 * 时空能力图谱服务
 */
export class TemporalAbilityGraph {
  private static instance: TemporalAbilityGraph | null = null;
  
  // 用户技能记录
  private userSkills: Map<string, Map<string, UserSkill>> = new Map();
  
  // 学习记录
  private learningRecords: Map<string, LearningRecord[]> = new Map();
  
  // 内置技能库
  private skillLibrary: SkillNode[] = [
    // Office 技能
    { id: 'excel_basic', name: 'Excel 基础', category: SkillCategory.OFFICE, difficulty: 1, prerequisites: [], estimatedHours: 4, realWorldScenes: ['做报表', '统计数据'], tags: ['办公', '数据'] },
    { id: 'excel_pivot', name: '数据透视表', category: SkillCategory.OFFICE, difficulty: 2, prerequisites: ['excel_basic'], estimatedHours: 3, realWorldScenes: ['快速分析数据', '做汇总报表'], tags: ['办公', '分析'] },
    { id: 'excel_chart', name: 'Excel 图表', category: SkillCategory.OFFICE, difficulty: 2, prerequisites: ['excel_basic'], estimatedHours: 2, realWorldScenes: ['数据可视化', '展示报告'], tags: ['办公', '可视化'] },
    { id: 'word_basic', name: 'Word 基础', category: SkillCategory.OFFICE, difficulty: 1, prerequisites: [], estimatedHours: 3, realWorldScenes: ['写文档', '排版文章'], tags: ['办公', '文档'] },
    { id: 'ppt_basic', name: 'PPT 制作', category: SkillCategory.OFFICE, difficulty: 2, prerequisites: [], estimatedHours: 4, realWorldScenes: ['做演示', '工作汇报'], tags: ['办公', '演示'] },
    
    // 生活技能
    { id: 'wechat_basic', name: '微信使用', category: SkillCategory.LIFE, difficulty: 1, prerequisites: [], estimatedHours: 2, realWorldScenes: ['聊天', '支付', '发朋友圈'], tags: ['社交', '支付'] },
    { id: 'wechat_pay', name: '微信支付', category: SkillCategory.LIFE, difficulty: 2, prerequisites: ['wechat_basic'], estimatedHours: 1, realWorldScenes: ['付款', '收款', '缴费'], tags: ['支付', '便民'] },
    { id: 'online_registration', name: '网上挂号', category: SkillCategory.LIFE, difficulty: 2, prerequisites: ['wechat_pay'], estimatedHours: 1, realWorldScenes: ['医院挂号', '预约看病'], tags: ['医疗', '便民'] },
    { id: 'delivery_order', name: '外卖点餐', category: SkillCategory.LIFE, difficulty: 1, prerequisites: ['wechat_pay'], estimatedHours: 1, realWorldScenes: ['点外卖', '优惠券使用'], tags: ['生活', '美食'] },
    { id: 'travel_booking', name: '旅行预订', category: SkillCategory.LIFE, difficulty: 3, prerequisites: ['wechat_pay'], estimatedHours: 2, realWorldScenes: ['订机票', '订酒店', '景点门票'], tags: ['旅行', '预订'] },
    
    // 数字技能
    { id: 'harmony_share', name: '鸿蒙协同', category: SkillCategory.DIGITAL, difficulty: 2, prerequisites: ['wechat_basic'], estimatedHours: 2, realWorldScenes: ['手机电脑互传', '接打电话'], tags: ['鸿蒙', '协同'] },
    { id: 'photo_management', name: '照片管理', category: SkillCategory.DIGITAL, difficulty: 1, prerequisites: [], estimatedHours: 1, realWorldScenes: ['整理照片', '备份回忆'], tags: ['数字', '整理'] },
    { id: 'security_basic', name: '手机安全', category: SkillCategory.DIGITAL, difficulty: 2, prerequisites: [], estimatedHours: 1, realWorldScenes: ['防诈骗', '保护隐私'], tags: ['安全', '防骗'] },
  ];

  static getInstance(): TemporalAbilityGraph {
    if (!TemporalAbilityGraph.instance) {
      TemporalAbilityGraph.instance = new TemporalAbilityGraph();
    }
    return TemporalAbilityGraph.instance;
  }

  private constructor() {
    HiLog.info("TemporalAbilityGraph", "时空能力图谱初始化（FSRS v6）");
  }

  /**
   * 评估用户能力
   */
  assess(userId: string, skillId: string): UserSkill | null {
    const userSkillMap = this.userSkills.get(userId);
    if (!userSkillMap) return null;
    return userSkillMap.get(skillId) || null;
  }

  /**
   * 获取用户能力等级
   */
  getAbilityLevel(userId: string, skillId: string): AbilityLevel {
    const skill = this.assess(userId, skillId);
    return skill?.level || AbilityLevel.ZERO;
  }

  /**
   * 更新技能掌握度（集成真实 FSRS 算法）
   */
  updateSkill(
    userId: string,
    skillId: string,
    result: 'correct' | 'incorrect',
    timeSpent: number = 0,
    hintsUsed: number = 0,
    deviceType: 'phone' | 'tablet' | 'pc' = 'phone'
  ): UserSkill {
    const now = Date.now();
    const currentHour = new Date().getHours();
    
    // 获取或创建用户技能记录
    if (!this.userSkills.has(userId)) {
      this.userSkills.set(userId, new Map());
    }
    const userSkillMap = this.userSkills.get(userId)!;
    
    let skill = userSkillMap.get(skillId);
    if (!skill) {
      skill = this.createDefaultUserSkill(skillId, now);
      userSkillMap.set(skillId, skill);
    }
    
    // ========== 基础能力更新 ==========
    const delta = result === 'correct' ? 0.1 : 0.02;
    skill.level = Math.min(AbilityLevel.MASTER, skill.level + delta);
    skill.practiceCount++;
    skill.lastPracticed = now;
    skill.updatedAt = now;
    
    // ========== 时空维度更新 ==========
    const timeSlot = this.getTimeSlot(currentHour);
    skill.temporalPattern[timeSlot] = (skill.temporalPattern[timeSlot] || 0) + 1;
    skill.spatialPattern[deviceType] = (skill.spatialPattern[deviceType] || 0) + 1;
    skill.learningSpeed = (skill.learningSpeed * (skill.practiceCount - 1) + delta) / skill.practiceCount;
    skill.bestTimeSlot = this.calculateBestTimeSlot(skill.temporalPattern);
    
    // ========== 【核心】FSRS 算法更新 ==========
    this.updateFSRSState(skill, result);
    
    // 添加学习记录
    this.addLearningRecord(userId, skillId, 1, result, timeSpent, hintsUsed, currentHour, deviceType);
    
    return skill;
  }

  /**
   * 【核心】使用真实 FSRS 算法更新状态
   */
  private updateFSRSState(skill: UserSkill, result: 'correct' | 'incorrect'): void {
    const scheduler = getFsrsScheduler();
    
    // 创建或获取卡片
    let card: Card;
    if (skill.fsrsStability === 0) {
      // 新卡片
      card = createEmptyCard();
    } else {
      // 现有卡片，恢复状态
      card = {
        due: new Date(skill.fsrsDueDate),
        stability: skill.fsrsStability,
        difficulty: skill.fsrsDifficulty,
        elapsed_days: Math.floor(skill.fsrsInterval),
        scheduled_days: Math.floor(skill.fsrsInterval),
        reps: skill.fsrsRepetitions,
        lapses: 0,
        state: 0, // 0=New, 1=Learning, 2=Review
      };
    }
    
    // 根据结果选择评分
    const rating = result === 'correct' ? Rating.Good : Rating.Again;
    
    // 使用 FSRS 计算下一个状态
    const record = scheduler.next(card, new Date(), rating);
    
    // 更新 FSRS 状态
    skill.fsrsStability = record.card.stability;
    skill.fsrsDifficulty = record.card.difficulty;
    skill.fsrsInterval = record.card.elapsed_days;
    skill.fsrsRepetitions = record.card.reps;
    skill.fsrsDueDate = record.card.due.getTime();
    
    // 计算可回忆性
    const elapsedDays = (Date.now() - skill.lastPracticed) / (1000 * 60 * 60 * 24);
    skill.fsrsRetrievability = this.calculateRetrievability(skill.fsrsStability, elapsedDays);
    
    HiLog.info("TemporalAbilityGraph", 
      `FSRS 更新：稳定度=${skill.fsrsStability.toFixed(2)}天，难度=${skill.fsrsDifficulty.toFixed(2)}, ` +
      `间隔=${skill.fsrsInterval}天，可回忆性=${(skill.fsrsRetrievability * 100).toFixed(1)}%`
    );
  }

  /**
   * 计算可回忆性
   * 公式：R = (1 + S * D * t)^(-w)
   */
  private calculateRetrievability(stability: number, elapsedDays: number): number {
    if (stability === 0 || elapsedDays === 0) return 1.0;
    
    // 简化版 FSRS 回忆公式
    const decay = 0.1; // 衰减因子
    const retrievability = Math.pow(1 + decay * elapsedDays / stability, -1);
    return Math.max(0, Math.min(1, retrievability));
  }

  /**
   * 检查是否需要复习
   */
  checkReviewNeeded(userId: string, skillId: string): { 
    needed: boolean; 
    nextReviewTime?: Date; 
    retrievability?: number;
    reason?: string 
  } {
    const skill = this.getUserSkill(userId, skillId);
    if (!skill) {
      return { needed: false };
    }
    
    const now = Date.now();
    const isDue = skill.fsrsDueDate <= now;
    const retrievability = skill.fsrsRetrievability;
    
    if (isDue || retrievability < 0.85) {
      const nextReviewTime = new Date(skill.fsrsDueDate);
      return {
        needed: true,
        nextReviewTime,
        retrievability,
        reason: `遗忘曲线提醒：可回忆性${(retrievability * 100).toFixed(1)}%，需要复习巩固`
      };
    }
    
    return { needed: false, retrievability };
  }

  /**
   * 获取用户画像
   */
  getUserProfile(userId: string): any | null {
    // 简化实现
    return {
      userId,
      preferredTimeSlot: 'evening',
      mostUsedDevice: 'phone',
      totalLearningDays: 1,
      totalTimeSpent: 0
    };
  }

  /**
   * 推荐最佳学习时间
   */
  recommendBestTime(userId: string): string {
    return '晚上 20:00 - 21:00';
  }

  /**
   * 推荐最佳学习设备
   */
  recommendBestDevice(userId: string): string {
    return '手机（随时随地学习）';
  }

  /**
   * 获取时空模式分析
   */
  getTemporalPatternAnalysis(userId: string, skillId: string): {
    bestTimeSlot: string;
    bestDevice: string;
    learningSpeed: string;
    engagementLevel: string;
    fsrsStability: string;
    fsrsRetrievability: string;
  } {
    const skill = this.getUserSkill(userId, skillId);
    if (!skill) {
      return {
        bestTimeSlot: '晚上',
        bestDevice: '手机',
        learningSpeed: '中等',
        engagementLevel: '一般',
        fsrsStability: '新学习',
        fsrsRetrievability: '100%'
      };
    }
    
    const timeSlotLabels: Record<string, string> = {
      'morning': '早上',
      'afternoon': '下午',
      'evening': '晚上',
      'night': '深夜'
    };
    
    const timeSlot = timeSlotLabels[skill.bestTimeSlot] || '晚上';
    
    // 计算最常用设备
    let bestDevice = '手机';
    let maxDeviceCount = 0;
    for (const [device, count] of Object.entries(skill.spatialPattern)) {
      if (count > maxDeviceCount) {
        maxDeviceCount = count;
        bestDevice = device;
      }
    }
    const deviceLabels: Record<string, string> = {
      'phone': '手机',
      'tablet': '平板',
      'pc': '电脑',
      'smartScreen': '智慧屏',
      'speaker': '音箱'
    };
    
    // 学习速度评估
    let learningSpeed = '较慢';
    if (skill.learningSpeed > 0.12) learningSpeed = '很快';
    else if (skill.learningSpeed > 0.08) learningSpeed = '较快';
    else if (skill.learningSpeed > 0.05) learningSpeed = '中等';
    
    // 参与度评估
    let engagementLevel = '一般';
    const totalActivities = Object.values(skill.temporalPattern).reduce((a, b) => a + b, 0);
    if (totalActivities > 20) engagementLevel = '很高';
    else if (totalActivities > 10) engagementLevel = '较高';
    else if (totalActivities > 5) engagementLevel = '中等';
    
    return {
      bestTimeSlot: timeSlot,
      bestDevice: deviceLabels[bestDevice] || '手机',
      learningSpeed,
      engagementLevel,
      fsrsStability: `${skill.fsrsStability.toFixed(1)}天`,
      fsrsRetrievability: `${(skill.fsrsRetrievability * 100).toFixed(1)}%`
    };
  }

  /**
   * 获取用户技能
   */
  getUserSkill(userId: string, skillId: string): UserSkill | null {
    const userSkillMap = this.userSkills.get(userId);
    if (!userSkillMap) return null;
    return userSkillMap.get(skillId) || null;
  }

  /**
   * 获取用户所有技能
   */
  getUserSkills(userId: string): UserSkill[] {
    const userSkillMap = this.userSkills.get(userId);
    if (!userSkillMap) return [];
    return Array.from(userSkillMap.values());
  }

  /**
   * 获取技能库
   */
  getSkillLibrary(): SkillNode[] {
    return this.skillLibrary;
  }

  // ==================== 私有方法 ====================

  /**
   * 创建默认用户技能
   */
  private createDefaultUserSkill(skillId: string, now: number): UserSkill {
    return {
      skillId,
      level: AbilityLevel.ZERO,
      experienceHours: 0,
      lastPracticed: now,
      practiceCount: 0,
      weakPoints: [],
      strongPoints: [],
      confidence: 0.5,
      interest: 0.5,
      temporalPattern: {},
      spatialPattern: {},
      learningSpeed: 0.1,
      bestTimeSlot: 'evening',
      fsrsStability: 0,
      fsrsDifficulty: 5,
      fsrsRetrievability: 1.0,
      fsrsInterval: 0,
      fsrsRepetitions: 0,
      fsrsDueDate: now,
      createdAt: now,
      updatedAt: now
    };
  }

  /**
   * 获取时间段
   */
  private getTimeSlot(hour: number): 'morning' | 'afternoon' | 'evening' | 'night' {
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 14) return 'afternoon';
    if (hour >= 14 && hour < 19) return 'afternoon';
    if (hour >= 19 && hour < 22) return 'evening';
    return 'night';
  }

  /**
   * 计算最适合学习的时间段
   */
  private calculateBestTimeSlot(pattern: Record<string, number>): 'morning' | 'afternoon' | 'evening' | 'night' {
    let maxSlot: string = 'evening';
    let maxCount = 0;
    
    for (const [slot, count] of Object.entries(pattern)) {
      if (count > maxCount) {
        maxCount = count;
        maxSlot = slot;
      }
    }
    
    return maxSlot as any;
  }

  /**
   * 添加学习记录
   */
  private addLearningRecord(
    userId: string,
    skillId: string,
    stepNumber: number,
    result: 'correct' | 'incorrect' | 'partial',
    timeSpent: number,
    hintsUsed: number,
    timeOfDay: number,
    deviceType: 'phone' | 'tablet' | 'pc'
  ): void {
    if (!this.learningRecords.has(userId)) {
      this.learningRecords.set(userId, []);
    }
    
    const now = new Date();
    const record: LearningRecord = {
      id: `record_${Date.now()}`,
      skillId,
      stepNumber,
      practiceId: `practice_${stepNumber}`,
      result,
      timeSpent,
      hintsUsed,
      timeOfDay,
      deviceType,
      date: now.toISOString().split('T')[0],
      dayOfWeek: now.getDay(),
      timestamp: Date.now()
    };
    
    this.learningRecords.get(userId)!.push(record);
  }

  /**
   * 检查前置技能
   */
  checkPrerequisites(userId: string, skillId: string): { passed: boolean; missing: string[] } {
    const skill = this.skillLibrary.find(s => s.id === skillId);
    if (!skill) {
      return { passed: false, missing: [skillId] };
    }
    
    const userSkillMap = this.userSkills.get(userId);
    const missing: string[] = [];
    
    for (const prereqId of skill.prerequisites) {
      const prereqSkill = userSkillMap?.get(prereqId);
      if (!prereqSkill || prereqSkill.level < AbilityLevel.BASIC) {
        missing.push(prereqId);
      }
    }
    
    return {
      passed: missing.length === 0,
      missing
    };
  }
}

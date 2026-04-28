/**
 * ============================================================================
 * 时空能力图谱 - TemporalAbilityGraph
 * 
 * v2.0 重构：
 * 1. 新增职业素养技能节点（8 个）
 * 2. 对接 Rdb 数据库（替代内存 Map）
 * 3. FSRS v6 算法集成
 * 
 * 核心差异化：自研用户行为时空图谱引擎
 * 
 * 算法支持：
 * - FSRS v6 算法（ts-fsrs 包）
 * - 17 个权重参数，科学计算复习间隔
 * - 稳定度/难度/可回忆性三维度
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { fsrs, createEmptyCard, Rating, Card } from 'ts-fsrs';
import { LearningDataStore, UserSkillRecord } from '../storage/LearningDataStore';

const TAG = 'TemporalAbilityGraph';

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
  PROFESSIONAL = 'professional',  // 职业素养（新增）
  OFFICE = 'office',
  LIFE = 'life',
  DIGITAL = 'digital'
}

/**
 * 用户技能记录（对接数据库）
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
  
  // 时空维度
  temporalPattern: Record<string, number>;
  bestTimeSlot: 'morning' | 'afternoon' | 'evening' | 'night';
  learningSpeed: number;
  
  // 空间维度
  spatialPattern: Record<string, number>;
  
  // FSRS 状态
  fsrsStability: number;
  fsrsDifficulty: number;
  fsrsRetrievability: number;
  fsrsInterval: number;
  fsrsRepetitions: number;
  fsrsDueDate: number;
  
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
  timeOfDay: number;
  deviceType: 'phone' | 'tablet' | 'pc';
  date: string;
  dayOfWeek: number;
  timestamp: number;
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

function getFsrsScheduler() {
  if (!fsrsScheduler) {
    fsrsScheduler = fsrs({
      request_retention: 0.9,
      maximum_interval: 36500,
      enable_fuzz: false,
      enable_short_term: true,
      learning_steps: ['1m', '10m'],
      relearning_steps: ['10m'],
    });
  }
  return fsrsScheduler;
}

/**
 * 时空能力图谱服务
 */
export class TemporalAbilityGraph {
  private static instance: TemporalAbilityGraph | null = null;
  
  // 用户技能记录（缓存层，实际数据在数据库）
  private userSkills: Map<string, Map<string, UserSkill>> = new Map();
  
  // 学习记录（缓存层）
  private learningRecords: Map<string, LearningRecord[]> = new Map();
  
  // 数据存储层（新增）
  private dataStore: LearningDataStore;
  
  // 内置技能库
  private skillLibrary: SkillNode[] = [
    // ========== 职业素养技能（新增 8 个）==========
    { id: 'comm_basic', name: '沟通技巧基础', category: SkillCategory.PROFESSIONAL, difficulty: 1, prerequisites: [], estimatedHours: 2, realWorldScenes: ['工作汇报', '团队协作', '客户沟通'], tags: ['沟通', '职场'] },
    { id: 'comm_advanced', name: '高级沟通技巧', category: SkillCategory.PROFESSIONAL, difficulty: 2, prerequisites: ['comm_basic'], estimatedHours: 3, realWorldScenes: ['跨部门协调', '冲突处理', '商务谈判'], tags: ['沟通', '谈判'] },
    { id: 'time_mgmt', name: '时间管理', category: SkillCategory.PROFESSIONAL, difficulty: 1, prerequisites: [], estimatedHours: 2, realWorldScenes: ['多任务处理', '项目 deadline', '个人效率'], tags: ['效率', '管理'] },
    { id: 'workplace_etiquette', name: '职场礼仪', category: SkillCategory.PROFESSIONAL, difficulty: 1, prerequisites: [], estimatedHours: 2, realWorldScenes: ['面试', '商务会议', '客户接待'], tags: ['礼仪', '职场'] },
    { id: 'resume_interview', name: '简历与面试', category: SkillCategory.PROFESSIONAL, difficulty: 2, prerequisites: [], estimatedHours: 3, realWorldScenes: ['求职', '跳槽', '晋升答辩'], tags: ['求职', '面试'] },
    { id: 'email_writing', name: '职场邮件写作', category: SkillCategory.PROFESSIONAL, difficulty: 1, prerequisites: [], estimatedHours: 2, realWorldScenes: ['工作汇报', '会议邀请', '客户跟进'], tags: ['邮件', '写作'] },
    { id: 'team_collab', name: '团队协作', category: SkillCategory.PROFESSIONAL, difficulty: 2, prerequisites: ['comm_basic'], estimatedHours: 2, realWorldScenes: ['敏捷开发', '项目协作', '远程办公'], tags: ['协作', '团队'] },
    { id: 'problem_solving', name: '问题解决能力', category: SkillCategory.PROFESSIONAL, difficulty: 2, prerequisites: [], estimatedHours: 3, realWorldScenes: ['故障排查', '流程优化', '决策制定'], tags: ['分析', '决策'] },
    
    // ========== 办公技能 ==========
    { id: 'excel_basic', name: 'Excel 基础', category: SkillCategory.OFFICE, difficulty: 1, prerequisites: [], estimatedHours: 4, realWorldScenes: ['做报表', '统计数据'], tags: ['办公', '数据'] },
    { id: 'excel_pivot', name: '数据透视表', category: SkillCategory.OFFICE, difficulty: 2, prerequisites: ['excel_basic'], estimatedHours: 3, realWorldScenes: ['快速分析数据', '做汇总报表'], tags: ['办公', '分析'] },
    { id: 'excel_chart', name: 'Excel 图表', category: SkillCategory.OFFICE, difficulty: 2, prerequisites: ['excel_basic'], estimatedHours: 2, realWorldScenes: ['数据可视化', '展示报告'], tags: ['办公', '可视化'] },
    
    // ========== 生活技能 ==========
    { id: 'wechat_basic', name: '微信使用', category: SkillCategory.LIFE, difficulty: 1, prerequisites: [], estimatedHours: 2, realWorldScenes: ['聊天', '支付', '发朋友圈'], tags: ['社交', '支付'] },
    { id: 'wechat_pay', name: '微信支付', category: SkillCategory.LIFE, difficulty: 2, prerequisites: ['wechat_basic'], estimatedHours: 1, realWorldScenes: ['付款', '收款', '缴费'], tags: ['支付', '便民'] },
    { id: 'online_registration', name: '网上挂号', category: SkillCategory.LIFE, difficulty: 2, prerequisites: ['wechat_pay'], estimatedHours: 1, realWorldScenes: ['医院挂号', '预约看病'], tags: ['医疗', '便民'] },
    
    // ========== 数字技能 ==========
    { id: 'harmony_share', name: '鸿蒙协同', category: SkillCategory.DIGITAL, difficulty: 2, prerequisites: ['wechat_basic'], estimatedHours: 2, realWorldScenes: ['手机电脑互传', '接打电话'], tags: ['鸿蒙', '协同'] },
    { id: 'security_basic', name: '手机安全', category: SkillCategory.DIGITAL, difficulty: 2, prerequisites: [], estimatedHours: 1, realWorldScenes: ['防诈骗', '保护隐私'], tags: ['安全', '防骗'] },
  ];

  static getInstance(): TemporalAbilityGraph {
    if (!TemporalAbilityGraph.instance) {
      TemporalAbilityGraph.instance = new TemporalAbilityGraph();
    }
    return TemporalAbilityGraph.instance;
  }

  private constructor() {
    this.dataStore = LearningDataStore.getInstance();
    HiLog.info(TAG, '时空能力图谱初始化 v2.0（FSRS v6 + Rdb）');
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
   * 更新技能掌握度（集成真实 FSRS 算法 + 持久化）
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
    
    // 基础能力更新
    const delta = result === 'correct' ? 0.1 : 0.02;
    skill.level = Math.min(AbilityLevel.MASTER, skill.level + delta);
    skill.practiceCount++;
    skill.lastPracticed = now;
    skill.updatedAt = now;
    
    // 时空维度更新
    const timeSlot = this.getTimeSlot(currentHour);
    skill.temporalPattern[timeSlot] = (skill.temporalPattern[timeSlot] || 0) + 1;
    skill.spatialPattern[deviceType] = (skill.spatialPattern[deviceType] || 0) + 1;
    skill.learningSpeed = (skill.learningSpeed * (skill.practiceCount - 1) + delta) / skill.practiceCount;
    skill.bestTimeSlot = this.calculateBestTimeSlot(skill.temporalPattern);
    
    // FSRS 算法更新
    this.updateFSRSState(skill, result);
    
    // 添加学习记录
    this.addLearningRecord(userId, skillId, 1, result, timeSpent, hintsUsed, currentHour, deviceType);
    
    // 持久化到数据库（新增）
    this.persistUserSkill(userId, skill);
    
    return skill;
  }

  /**
   * 持久化用户技能到数据库
   */
  private async persistUserSkill(userId: string, skill: UserSkill): Promise<void> {
    try {
      const record: UserSkillRecord = {
        userId,
        skillId: skill.skillId,
        level: skill.level,
        practiceCount: skill.practiceCount,
        lastPracticed: skill.lastPracticed,
        weakPoints: skill.weakPoints,
        strongPoints: skill.strongPoints,
        confidence: skill.confidence,
        fsrsStability: skill.fsrsStability,
        fsrsDifficulty: skill.fsrsDifficulty,
        fsrsRetrievability: skill.fsrsRetrievability,
        fsrsInterval: skill.fsrsInterval,
        fsrsRepetitions: skill.fsrsRepetitions,
        fsrsDueDate: skill.fsrsDueDate,
        createdAt: skill.createdAt,
        updatedAt: skill.updatedAt
      };
      
      await this.dataStore.saveUserSkill(record);
      HiLog.info(TAG, `技能已持久化: ${userId}/${skill.skillId}`);
    } catch (error) {
      HiLog.error(TAG, `持久化失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 从数据库加载用户技能
   */
  async loadUserSkillFromDB(userId: string, skillId: string): Promise<UserSkill | null> {
    try {
      const record = await this.dataStore.getUserSkill(userId, skillId);
      if (!record) return null;
      
      const skill: UserSkill = {
        skillId: record.skillId,
        level: record.level as AbilityLevel,
        experienceHours: 0,
        lastPracticed: record.lastPracticed,
        practiceCount: record.practiceCount,
        weakPoints: record.weakPoints,
        strongPoints: record.strongPoints,
        confidence: record.confidence,
        interest: 0.5,
        temporalPattern: {},
        spatialPattern: {},
        learningSpeed: 0.1,
        bestTimeSlot: 'evening',
        fsrsStability: record.fsrsStability,
        fsrsDifficulty: record.fsrsDifficulty,
        fsrsRetrievability: record.fsrsRetrievability,
        fsrsInterval: record.fsrsInterval,
        fsrsRepetitions: record.fsrsRepetitions,
        fsrsDueDate: record.fsrsDueDate,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt
      };
      
      // 更新缓存
      if (!this.userSkills.has(userId)) {
        this.userSkills.set(userId, new Map());
      }
      this.userSkills.get(userId)!.set(skillId, skill);
      
      HiLog.info(TAG, `技能已从数据库加载: ${userId}/${skillId}`);
      return skill;
    } catch (error) {
      HiLog.error(TAG, `从数据库加载失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * FSRS 算法更新状态
   */
  private updateFSRSState(skill: UserSkill, result: 'correct' | 'incorrect'): void {
    const scheduler = getFsrsScheduler();
    
    let card: Card;
    if (skill.fsrsStability === 0) {
      card = createEmptyCard();
    } else {
      card = {
        due: new Date(skill.fsrsDueDate),
        stability: skill.fsrsStability,
        difficulty: skill.fsrsDifficulty,
        elapsed_days: Math.floor(skill.fsrsInterval),
        scheduled_days: Math.floor(skill.fsrsInterval),
        reps: skill.fsrsRepetitions,
        lapses: 0,
        state: 0,
      };
    }
    
    const rating = result === 'correct' ? Rating.Good : Rating.Again;
    const record = scheduler.next(card, new Date(), rating);
    
    skill.fsrsStability = record.card.stability;
    skill.fsrsDifficulty = record.card.difficulty;
    skill.fsrsInterval = record.card.elapsed_days;
    skill.fsrsRepetitions = record.card.reps;
    skill.fsrsDueDate = record.card.due.getTime();
    
    const elapsedDays = (Date.now() - skill.lastPracticed) / (1000 * 60 * 60 * 24);
    skill.fsrsRetrievability = this.calculateRetrievability(skill.fsrsStability, elapsedDays);
    
    HiLog.info(TAG, 
      `FSRS 更新：稳定度=${skill.fsrsStability.toFixed(2)}天，难度=${skill.fsrsDifficulty.toFixed(2)}, ` +
      `间隔=${skill.fsrsInterval}天，可回忆性=${(skill.fsrsRetrievability * 100).toFixed(1)}%`
    );
  }

  /**
   * 计算可回忆性
   */
  private calculateRetrievability(stability: number, elapsedDays: number): number {
    if (stability === 0 || elapsedDays === 0) return 1.0;
    const decay = 0.1;
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
   * 获取需要复习的技能列表
   */
  async getDueReviewSkills(userId: string): Promise<UserSkill[]> {
    try {
      const records = await this.dataStore.getDueReviewSkills(userId);
      return records.map(r => ({
        skillId: r.skillId,
        level: r.level as AbilityLevel,
        experienceHours: 0,
        lastPracticed: r.lastPracticed,
        practiceCount: r.practiceCount,
        weakPoints: r.weakPoints,
        strongPoints: r.strongPoints,
        confidence: r.confidence,
        interest: 0.5,
        temporalPattern: {},
        spatialPattern: {},
        learningSpeed: 0.1,
        bestTimeSlot: 'evening',
        fsrsStability: r.fsrsStability,
        fsrsDifficulty: r.fsrsDifficulty,
        fsrsRetrievability: r.fsrsRetrievability,
        fsrsInterval: r.fsrsInterval,
        fsrsRepetitions: r.fsrsRepetitions,
        fsrsDueDate: r.fsrsDueDate,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt
      }));
    } catch (error) {
      HiLog.error(TAG, `获取复习技能失败: ${JSON.stringify(error)}`);
      return [];
    }
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

  /**
   * 按分类获取技能
   */
  getSkillsByCategory(category: SkillCategory): SkillNode[] {
    return this.skillLibrary.filter(s => s.category === category);
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

  // ==================== 私有方法 ====================

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

  private getTimeSlot(hour: number): 'morning' | 'afternoon' | 'evening' | 'night' {
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 14) return 'afternoon';
    if (hour >= 14 && hour < 19) return 'afternoon';
    if (hour >= 19 && hour < 22) return 'evening';
    return 'night';
  }

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
}

/**
 * ============================================================================
 * 能力图谱服务
 * 自研三层记忆系统重构：从"家庭成员"到"用户技能"
 * 
 * 核心能力：
 * - 存储用户的技能掌握度
 * - 追踪学习历史和薄弱点
 * - 跨任务理解用户能力水平
 * - 与华为AI协作：华为理解内容，我们管理能力图谱
 * ============================================================================
 */

/**
 * 技能节点
 */
export interface SkillNode {
  id: string;
  name: string;                    // "Excel数据分析"
  category: SkillCategory;        // "office" | "life" | "digital"
  difficulty: number;             // 1-5
  prerequisites: string[];        // 前置技能ID
  estimatedHours: number;         // 预估学习时长
  realWorldScenes: string[];      // 真实应用场景
  tags: string[];                 // 标签
}

/**
 * 技能类别
 */
export enum SkillCategory {
  OFFICE = 'office',           // 办公技能
  LIFE = 'life',               // 生活技能
  DIGITAL = 'digital',         // 数字技能
  HEALTH = 'health',           // 健康技能
  FINANCIAL = 'financial',     // 财务技能
  SOCIAL = 'social'             // 社交技能
}

/**
 * 用户技能记录
 */
export interface UserSkill {
  skillId: string;
  level: AbilityLevel;
  experienceHours: number;       // 实际学习时长
  lastPracticed: number;         // 上次练习时间
  practiceCount: number;          // 练习次数
  weakPoints: string[];           // 薄弱点
  strongPoints: string[];        // 强项
  confidence: number;            // 自信心 0-1
  interest: number;              // 兴趣度 0-1
  createdAt: number;
  updatedAt: number;
}

/**
 * 能力等级
 */
export enum AbilityLevel {
  ZERO = 0,          // 完全不会
  AWARENESS = 1,    // 听说过
  BEGINNER = 2,     // 入门
  BASIC = 3,        // 基础
  INTERMEDIATE = 4, // 中级
  ADVANCED = 5,     // 高级
  MASTER = 6       // 精通
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
  timeSpent: number;            // 用时（秒）
  hintsUsed: number;            // 使用提示次数
  timestamp: number;
}

/**
 * 能力图谱查询结果
 */
export interface AbilityQueryResult {
  skills: UserSkill[];
  recommendations: SkillRecommendation[];
  weakAreas: string[];          // 需要加强的领域
  strongAreas: string[];        // 强项领域
  suggestedReview: SkillRecommendation[];
}

/**
 * 技能推荐
 */
export interface SkillRecommendation {
  skill: SkillNode;
  reason: string;                // 推荐原因
  priority: number;             // 优先级 1-5
  estimatedImpact: string;      // 预估收益
  matchScore: number;           // 匹配度 0-1
}

/**
 * 能力图谱服务
 */
export class AbilityGraph {
  private static instance: AbilityGraph | null = null;
  
  // 用户技能记录
  private userSkills: Map<string, Map<string, UserSkill>> = new Map();
  
  // 学习记录
  private learningRecords: Map<string, LearningRecord[]> = new Map();
  
  // 内置技能库
  private skillLibrary: SkillNode[] = [
    // Office技能
    { id: 'excel_basic', name: 'Excel基础', category: SkillCategory.OFFICE, difficulty: 1, prerequisites: [], estimatedHours: 4, realWorldScenes: ['做报表', '统计数据'], tags: ['办公', '数据'] },
    { id: 'excel_pivot', name: '数据透视表', category: SkillCategory.OFFICE, difficulty: 2, prerequisites: ['excel_basic'], estimatedHours: 3, realWorldScenes: ['快速分析数据', '做汇总报表'], tags: ['办公', '分析'] },
    { id: 'excel_chart', name: 'Excel图表', category: SkillCategory.OFFICE, difficulty: 2, prerequisites: ['excel_basic'], estimatedHours: 2, realWorldScenes: ['数据可视化', '展示报告'], tags: ['办公', '可视化'] },
    { id: 'word_basic', name: 'Word基础', category: SkillCategory.OFFICE, difficulty: 1, prerequisites: [], estimatedHours: 3, realWorldScenes: ['写文档', '排版文章'], tags: ['办公', '文档'] },
    { id: 'ppt_basic', name: 'PPT制作', category: SkillCategory.OFFICE, difficulty: 2, prerequisites: [], estimatedHours: 4, realWorldScenes: ['做演示', '工作汇报'], tags: ['办公', '演示'] },
    
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

  static getInstance(): AbilityGraph {
    if (!AbilityGraph.instance) {
      AbilityGraph.instance = new AbilityGraph();
    }
    return AbilityGraph.instance;
  }

  private constructor() {}

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
   * 更新技能掌握度
   */
  updateSkill(
    userId: string,
    skillId: string,
    result: 'correct' | 'incorrect',
    timeSpent: number = 0,
    hintsUsed: number = 0
  ): UserSkill {
    // 获取或创建用户技能记录
    if (!this.userSkills.has(userId)) {
      this.userSkills.set(userId, new Map());
    }
    const userSkillMap = this.userSkills.get(userId)!;
    
    let skill = userSkillMap.get(skillId);
    if (!skill) {
      const skillNode = this.skillLibrary.find(s => s.id === skillId);
      skill = {
        skillId,
        level: AbilityLevel.ZERO,
        experienceHours: 0,
        lastPracticed: Date.now(),
        practiceCount: 0,
        weakPoints: [],
        strongPoints: [],
        confidence: 0.5,
        interest: 0.5,
        createdAt: Date.now(),
        updatedAt: Date.now()
      };
      userSkillMap.set(skillId, skill);
    }
    
    // 更新数据
    const delta = result === 'correct' ? 0.1 : 0.02;
    skill.level = Math.min(AbilityLevel.MASTER, skill.level + delta);
    skill.experienceHours += timeSpent / 3600;
    skill.lastPracticed = Date.now();
    skill.practiceCount++;
    skill.updatedAt = Date.now();
    
    // 记录学习结果
    this.addLearningRecord(userId, skillId, 1, result, timeSpent, hintsUsed);
    
    return skill;
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
    hintsUsed: number
  ): void {
    if (!this.learningRecords.has(userId)) {
      this.learningRecords.set(userId, []);
    }
    
    const record: LearningRecord = {
      id: `record_${Date.now()}`,
      skillId,
      stepNumber,
      practiceId: `practice_${stepNumber}`,
      result,
      timeSpent,
      hintsUsed,
      timestamp: Date.now()
    };
    
    this.learningRecords.get(userId)!.push(record);
  }

  /**
   * 获取薄弱点
   */
  getWeakPoints(userId: string): string[] {
    const userSkillMap = this.userSkills.get(userId);
    if (!userSkillMap) return [];
    
    const weakPoints: string[] = [];
    userSkillMap.forEach((skill, skillId) => {
      if (skill.level < AbilityLevel.INTERMEDIATE) {
        weakPoints.push(skillId);
      }
    });
    
    return weakPoints;
  }

  /**
   * 获取推荐技能
   */
  recommend(userId: string, limit: number = 3): SkillRecommendation[] {
    const recommendations: SkillRecommendation[] = [];
    const userSkillMap = this.userSkills.get(userId);
    
    for (const skill of this.skillLibrary) {
      // 跳过已掌握的技能
      const userSkill = userSkillMap?.get(skill.id);
      if (userSkill && userSkill.level >= AbilityLevel.INTERMEDIATE) continue;
      
      // 检查前置技能是否满足
      const prereqsMet = skill.prerequisites.every(prereq => {
        const prereqSkill = userSkillMap?.get(prereq);
        return !prereqSkill || prereqSkill.level >= AbilityLevel.BASIC;
      });
      
      if (!prereqsMet) continue;
      
      // 计算推荐度
      const matchScore = this.calculateMatchScore(userId, skill);
      
      recommendations.push({
        skill,
        reason: this.generateReason(skill, userSkill),
        priority: skill.difficulty <= 2 ? 5 : 3,
        estimatedImpact: `学会后可以${skill.realWorldScenes[0]}`,
        matchScore
      });
    }
    
    // 按匹配度排序
    recommendations.sort((a, b) => b.matchScore - a.matchScore);
    
    return recommendations.slice(0, limit);
  }

  /**
   * 获取技能依赖图
   */
  getDependencyGraph(skillId: string): SkillNode[] {
    const skill = this.skillLibrary.find(s => s.id === skillId);
    if (!skill) return [];
    
    const graph: SkillNode[] = [skill];
    
    // 递归添加前置技能
    for (const prereqId of skill.prerequisites) {
      const prereqSkills = this.getDependencyGraph(prereqId);
      graph.push(...prereqSkills);
    }
    
    return graph;
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

  /**
   * 计算匹配度
   */
  private calculateMatchScore(userId: string, skill: SkillNode): number {
    const userSkillMap = this.userSkills.get(userId);
    let score = 0.5;  // 基础分
    
    // 难度适中加分
    if (skill.difficulty <= 2) score += 0.2;
    
    // 有前置技能基础加分
    const hasPrereq = skill.prerequisites.some(p => {
      const s = userSkillMap?.get(p);
      return s && s.level >= AbilityLevel.BASIC;
    });
    if (hasPrereq) score += 0.2;
    
    return Math.min(1, score);
  }

  /**
   * 生成推荐原因
   */
  private generateReason(skill: SkillNode, userSkill: UserSkill | undefined): string {
    if (!userSkill) {
      return '还没有学习过，推荐从这门课开始';
    }
    
    if (skill.difficulty <= 2) {
      return '难度适中，适合巩固基础';
    }
    
    return `当前水平可以开始学习`;
  }

  /**
   * 获取技能库
   */
  getSkillLibrary(): SkillNode[] {
    return this.skillLibrary;
  }

  /**
   * 获取用户所有技能
   */
  getUserSkills(userId: string): UserSkill[] {
    const userSkillMap = this.userSkills.get(userId);
    if (!userSkillMap) return [];
    return Array.from(userSkillMap.values());
  }
}

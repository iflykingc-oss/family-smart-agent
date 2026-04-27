/**
 * ============================================================================
 * 项目驱动学习服务 - ProjectBasedLearning
 * 核心：通过实际项目学习，边做边学，产出实际成果
 * 
 * 输入：学习路径 + 用户场景
 * 输出：
 *   - 项目任务拆解
 *   - 分步指导
 *   - 成果评估
 *   - 作品展示
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { LearningPath } from '../core/LearningPathPlanner';

/**
 * 项目模板
 */
export interface ProjectTemplate {
  id: string;
  name: string;
  description: string;
  scenarioType: string;
  
  // 项目要求
  objectives: string[];
  deliverables: string[]; // 交付物
  
  // 技能要求
  requiredSkills: string[];
  
  // 难度和时间
  difficulty: number; // 1-5
  estimatedTime: number; // 分钟
  
  // 项目步骤
  steps: ProjectStep[];
  
  // 评估标准
  rubric: AssessmentRubric;
  
  // 示例作品
  examples?: ProjectExample[];
}

/**
 * 项目步骤
 */
export interface ProjectStep {
  order: number;
  title: string;
  description: string;
  
  // 指导
  guidance: string;
  tips: string[];
  
  // 检查点
  checkpoints: Checkpoint[];
  
  // 预计时间
  estimatedTime: number;
}

/**
 * 检查点
 */
export interface Checkpoint {
  description: string;
  type: 'auto' | 'manual' | 'ai';
  criteria: string;
}

/**
 * 评估标准
 */
export interface AssessmentRubric {
  criteria: RubricCriterion[];
  totalScore: number;
}

/**
 * 评估标准项
 */
export interface RubricCriterion {
  name: string;
  description: string;
  weight: number; // 权重 0-1
  score: number;  // 得分 0-100
}

/**
 * 项目示例
 */
export interface ProjectExample {
  title: string;
  description: string;
  imageUrl?: string;
  downloadUrl?: string;
}

/**
 * 用户项目进度
 */
export interface UserProjectProgress {
  projectId: string;
  userId: string;
  templateId: string;
  
  // 进度
  currentStep: number;
  completedSteps: number[];
  overallProgress: number; // 0-100
  
  // 交付物
  deliverables: UserDeliverable[];
  
  // 时间
  startTime: number;
  lastUpdateTime: number;
  timeSpent: number; // 已用时间（分钟）
  
  // 评估
  finalScore?: number;
  feedback?: string;
  
  // 状态
  status: 'not_started' | 'in_progress' | 'completed' | 'abandoned';
}

/**
 * 用户交付物
 */
export interface UserDeliverable {
  name: string;
  type: 'file' | 'text' | 'image' | 'video';
  content?: string;
  filePath?: string;
  submittedAt?: number;
  score?: number;
  feedback?: string;
}

/**
 * 项目驱动学习服务
 */
export class ProjectBasedLearning {
  private static instance: ProjectBasedLearning | null = null;
  
  // 项目模板库
  private projectTemplates: Map<string, ProjectTemplate> = new Map();
  
  // 用户项目进度
  private userProjects: Map<string, UserProjectProgress> = new Map();

  static getInstance(): ProjectBasedLearning {
    if (!ProjectBasedLearning.instance) {
      ProjectBasedLearning.instance = new ProjectBasedLearning();
    }
    return ProjectBasedLearning.instance;
  }

  private constructor() {
    this.initProjectTemplates();
    HiLog.info("ProjectBasedLearning", "项目驱动学习服务初始化");
  }

  /**
   * 初始化项目模板库
   */
  private initProjectTemplates(): void {
    // Excel - 家庭开支管理
    this.projectTemplates.set('excel_finance', {
      id: 'excel_finance',
      name: '家庭开支管理系统',
      description: '用 Excel 制作一个家庭开支管理表格，记录和分析日常开支',
      scenarioType: 'life_finance',
      
      objectives: [
        '掌握 Excel 基础操作',
        '学会使用公式计算',
        '能够制作数据图表',
        '实现开支自动分类统计'
      ],
      
      deliverables: [
        '家庭开支记录表',
        '月度开支统计图表',
        '预算超支预警公式'
      ],
      
      requiredSkills: ['excel_basic', 'excel_formula', 'excel_chart'],
      
      difficulty: 3,
      estimatedTime: 120,
      
      steps: [
        {
          order: 1,
          title: '创建开支记录表',
          description: '设计表格结构，包含日期、类别、金额、备注等字段',
          guidance: '打开 Excel，创建一个新的工作表，设置以下列：日期、类别、金额、支付方式、备注',
          tips: ['类别可以包括：餐饮、交通、购物、娱乐、其他', '日期格式设置为 YYYY-MM-DD'],
          checkpoints: [
            { description: '表格包含所有必需列', type: 'manual', criteria: '5 列完整' },
            { description: '日期格式正确', type: 'auto', criteria: '日期格式验证' }
          ],
          estimatedTime: 20
        },
        {
          order: 2,
          title: '输入示例数据',
          description: '输入至少 10 条示例开支记录',
          guidance: '根据实际或假设的开支情况，输入 10 条以上的记录',
          tips: ['数据要真实或接近真实', '类别要多样化'],
          checkpoints: [
            { description: '至少 10 条记录', type: 'auto', criteria: '行数>=10' },
            { description: '类别多样化', type: 'manual', criteria: '至少 5 个不同类别' }
          ],
          estimatedTime: 15
        },
        {
          order: 3,
          title: '使用公式计算',
          description: '用 SUM 公式计算总开支，用 SUMIF 按类别统计',
          guidance: '在表格下方添加汇总行，使用=SUM()计算总额，使用=SUMIF()按类别统计',
          tips: ['SUM 公式：=SUM(C2:C100)', 'SUMIF 公式：=SUMIF(B:B,"餐饮",C:C)'],
          checkpoints: [
            { description: '总开支计算正确', type: 'ai', criteria: '公式验证' },
            { description: '分类统计正确', type: 'ai', criteria: 'SUMIF 公式验证' }
          ],
          estimatedTime: 25
        },
        {
          order: 4,
          title: '制作统计图表',
          description: '用饼图或柱状图展示各类别开支占比',
          guidance: '选中分类统计数据，插入→图表，选择饼图或柱状图',
          tips: ['饼图适合展示占比', '柱状图适合对比大小'],
          checkpoints: [
            { description: '图表类型合适', type: 'manual', criteria: '饼图或柱状图' },
            { description: '数据源正确', type: 'ai', criteria: '图表数据验证' }
          ],
          estimatedTime: 20
        },
        {
          order: 5,
          title: '添加预算预警',
          description: '使用 IF 公式实现超支预警',
          guidance: '添加预算列，使用=IF()公式判断是否超支，超支时显示红色',
          tips: ['IF 公式：=IF(C2>预算，"超支","正常")', '条件格式可以自动变色'],
          checkpoints: [
            { description: '预警公式正确', type: 'ai', criteria: 'IF 公式验证' },
            { description: '超支显示明显', type: 'manual', criteria: '颜色或文字标识' }
          ],
          estimatedTime: 25
        },
        {
          order: 6,
          title: '美化与完善',
          description: '美化表格格式，添加标题和说明',
          guidance: '设置表格样式，添加标题行，调整列宽，添加边框',
          tips: ['使用表格样式快速美化', '标题行可以加粗和居中'],
          checkpoints: [
            { description: '表格美观', type: 'manual', criteria: '格式整齐' },
            { description: '有标题说明', type: 'manual', criteria: '包含标题' }
          ],
          estimatedTime: 15
        }
      ],
      
      rubric: {
        criteria: [
          { name: '表格结构', description: '列设置合理，格式规范', weight: 0.2, score: 0 },
          { name: '数据完整性', description: '数据记录完整，至少 10 条', weight: 0.2, score: 0 },
          { name: '公式应用', description: '正确使用 SUM、SUMIF、IF 公式', weight: 0.3, score: 0 },
          { name: '图表制作', description: '图表类型合适，数据准确', weight: 0.2, score: 0 },
          { name: '美观度', description: '表格整洁美观', weight: 0.1, score: 0 }
        ],
        totalScore: 100
      },
      
      examples: [
        {
          title: '优秀示例：张家开支表',
          description: '包含完整的开支记录、分类统计、饼图展示和超支预警'
        }
      ]
    });
    
    // 微信 - 朋友圈营销
    this.projectTemplates.set('wechat_marketing', {
      id: 'wechat_marketing',
      name: '微信朋友圈营销',
      description: '学习如何有效使用微信朋友圈进行个人或产品推广',
      scenarioType: 'social_networking',
      
      objectives: [
        '掌握朋友圈发布技巧',
        '学会文案撰写',
        '了解发布时间策略',
        '能够设计吸引人的内容'
      ],
      
      deliverables: [
        '3 条朋友圈文案',
        '发布时间计划表',
        '互动数据分析'
      ],
      
      requiredSkills: ['wechat_basic', 'copywriting'],
      
      difficulty: 2,
      estimatedTime: 60,
      
      steps: [
        {
          order: 1,
          title: '分析目标受众',
          description: '明确朋友圈的目标受众是谁，他们关心什么',
          guidance: '列出你的好友构成，分析他们的年龄、职业、兴趣',
          tips: ['可以用 Excel 简单统计', '找出共同关注点'],
          checkpoints: [
            { description: '受众分析清晰', type: 'manual', criteria: '有明确受众画像' }
          ],
          estimatedTime: 15
        },
        {
          order: 2,
          title: '撰写朋友圈文案',
          description: '撰写 3 条不同类型的朋友圈文案',
          guidance: '分别撰写：生活分享型、知识分享型、产品推广型',
          tips: ['文案要真实自然', '避免硬广', '配图很重要'],
          checkpoints: [
            { description: '3 条文案完成', type: 'manual', criteria: '数量达标' },
            { description: '类型多样化', type: 'manual', criteria: '3 种类型' }
          ],
          estimatedTime: 25
        },
        {
          order: 3,
          title: '制定发布计划',
          description: '规划最佳发布时间和频率',
          guidance: '根据受众活跃时间，制定一周发布计划',
          tips: ['早上 8-9 点、中午 12-1 点、晚上 8-10 点是高峰', '每天 1-3 条为宜'],
          checkpoints: [
            { description: '发布计划合理', type: 'manual', criteria: '有时间规划' }
          ],
          estimatedTime: 10
        },
        {
          order: 4,
          title: '发布与跟踪',
          description: '实际发布并跟踪互动数据',
          guidance: '按计划发布，记录点赞、评论数',
          tips: ['用表格记录数据', '分析哪种类型更受欢迎'],
          checkpoints: [
            { description: '有发布记录', type: 'manual', criteria: '发布截图' },
            { description: '有数据分析', type: 'manual', criteria: '互动统计' }
          ],
          estimatedTime: 10
        }
      ],
      
      rubric: {
        criteria: [
          { name: '受众分析', description: '目标受众明确', weight: 0.2, score: 0 },
          { name: '文案质量', description: '文案真实自然，有吸引力', weight: 0.4, score: 0 },
          { name: '发布计划', description: '时间安排合理', weight: 0.2, score: 0 },
          { name: '数据分析', description: '有跟踪和反思', weight: 0.2, score: 0 }
        ],
        totalScore: 100
      }
    });
    
    // 烹饪 - 家常菜
    this.projectTemplates.set('cooking_basic', {
      id: 'cooking_basic',
      name: '学会做一道家常菜',
      description: '从零开始学会做一道家常菜，如红烧肉、番茄炒蛋等',
      scenarioType: 'life_cooking',
      
      objectives: [
        '掌握基础刀工',
        '学会火候控制',
        '理解调味原理',
        '独立完成一道菜'
      ],
      
      deliverables: [
        '菜品成品照片',
        '制作过程记录',
        '心得体会'
      ],
      
      requiredSkills: ['cooking_basic', 'cooking_recipe'],
      
      difficulty: 2,
      estimatedTime: 90,
      
      steps: [
        {
          order: 1,
          title: '选择菜品',
          description: '选择一道想学的家常菜',
          guidance: '选择难度适中、食材易得的菜品，如番茄炒蛋、红烧肉',
          tips: ['初学者建议从简单的开始', '准备所需食材清单'],
          checkpoints: [
            { description: '菜品选择合适', type: 'manual', criteria: '难度适中' }
          ],
          estimatedTime: 10
        },
        {
          order: 2,
          title: '准备食材',
          description: '购买并处理食材',
          guidance: '按照菜谱准备食材，学习基础刀工',
          tips: ['注意安全用刀', '食材洗净切好备用'],
          checkpoints: [
            { description: '食材齐全', type: 'manual', criteria: '对照清单' },
            { description: '处理得当', type: 'manual', criteria: '切配整齐' }
          ],
          estimatedTime: 20
        },
        {
          order: 3,
          title: '学习烹饪步骤',
          description: '按照菜谱学习烹饪步骤',
          guidance: '仔细阅读菜谱，理解每一步的目的',
          tips: ['先通读一遍再开始', '准备好调料'],
          checkpoints: [
            { description: '理解步骤', type: 'manual', criteria: '能复述步骤' }
          ],
          estimatedTime: 15
        },
        {
          order: 4,
          title: '实际烹饪',
          description: '动手做菜',
          guidance: '按照步骤烹饪，注意火候和时间',
          tips: ['火不要太大', '及时搅拌防止粘锅'],
          checkpoints: [
            { description: '完成烹饪', type: 'manual', criteria: '成品完成' }
          ],
          estimatedTime: 30
        },
        {
          order: 5,
          title: '品尝与反思',
          description: '品尝成品，记录心得',
          guidance: '品尝自己的作品，记录成功和不足之处',
          tips: ['可以请家人品尝给反馈', '记录下次改进点'],
          checkpoints: [
            { description: '有成品照片', type: 'manual', criteria: '照片上传' },
            { description: '有心得体会', type: 'manual', criteria: '文字记录' }
          ],
          estimatedTime: 15
        }
      ],
      
      rubric: {
        criteria: [
          { name: '食材准备', description: '食材新鲜，处理得当', weight: 0.2, score: 0 },
          { name: '烹饪技巧', description: '火候控制得当，步骤正确', weight: 0.4, score: 0 },
          { name: '成品质量', description: '色香味俱佳', weight: 0.3, score: 0 },
          { name: '学习反思', description: '有总结和改进计划', weight: 0.1, score: 0 }
        ],
        totalScore: 100
      }
    });
  }

  /**
   * 根据场景推荐项目
   */
  recommendProject(scenarioType: string, difficulty?: number): ProjectTemplate[] {
    const templates: ProjectTemplate[] = [];
    
    for (const template of this.projectTemplates.values()) {
      if (template.scenarioType === scenarioType) {
        if (!difficulty || template.difficulty <= difficulty + 1) {
          templates.push(template);
        }
      }
    }
    
    // 按难度排序
    templates.sort((a, b) => a.difficulty - b.difficulty);
    
    return templates.slice(0, 3); // 返回最多 3 个
  }

  /**
   * 开始项目
   */
  startProject(userId: string, templateId: string): UserProjectProgress {
    const template = this.projectTemplates.get(templateId);
    if (!template) {
      throw new Error(`项目模板不存在：${templateId}`);
    }
    
    const progress: UserProjectProgress = {
      projectId: `project_${Date.now()}`,
      userId,
      templateId,
      currentStep: 1,
      completedSteps: [],
      overallProgress: 0,
      deliverables: [],
      startTime: Date.now(),
      lastUpdateTime: Date.now(),
      timeSpent: 0,
      status: 'in_progress'
    };
    
    this.userProjects.set(progress.projectId, progress);
    
    HiLog.info("ProjectBasedLearning", `开始项目：${userId}/${template.name}`);
    
    return progress;
  }

  /**
   * 完成项目步骤
   */
  completeStep(
    projectId: string,
    stepOrder: number,
    deliverable?: UserDeliverable
  ): boolean {
    const progress = this.userProjects.get(projectId);
    if (!progress) return false;
    
    // 添加交付物
    if (deliverable) {
      deliverable.submittedAt = Date.now();
      progress.deliverables.push(deliverable);
    }
    
    // 标记步骤完成
    if (!progress.completedSteps.includes(stepOrder)) {
      progress.completedSteps.push(stepOrder);
    }
    
    // 更新当前步骤
    progress.currentStep = stepOrder + 1;
    
    // 计算进度
    const template = this.projectTemplates.get(progress.templateId);
    if (template) {
      progress.overallProgress = Math.round(
        (progress.completedSteps.length / template.steps.length) * 100
      );
    }
    
    progress.lastUpdateTime = Date.now();
    
    HiLog.info("ProjectBasedLearning", `完成步骤：${projectId}/步骤${stepOrder}, 进度${progress.overallProgress}%`);
    
    return true;
  }

  /**
   * 评估项目
   */
  evaluateProject(projectId: string): { score: number; feedback: string } {
    const progress = this.userProjects.get(projectId);
    if (!progress) {
      return { score: 0, feedback: '项目不存在' };
    }
    
    const template = this.projectTemplates.get(progress.templateId);
    if (!template) {
      return { score: 0, feedback: '模板不存在' };
    }
    
    // 检查是否完成所有步骤
    if (progress.completedSteps.length < template.steps.length) {
      return {
        score: 0,
        feedback: `项目未完成，已完成${progress.completedSteps.length}/${template.steps.length}步`
      };
    }
    
    // 评估交付物
    let totalScore = 0;
    const rubricScores: string[] = [];
    
    for (const criterion of template.rubric.criteria) {
      // 简化评估：根据交付物数量给分
      const criterionScore = Math.min(100, progress.deliverables.length * 20);
      criterion.score = criterionScore;
      totalScore += criterionScore * criterion.weight;
      
      rubricScores.push(`${criterion.name}: ${criterionScore}分`);
    }
    
    const feedback = `项目完成！总分：${Math.round(totalScore)}分\n\n评估详情：\n${rubricScores.join('\n')}`;
    
    progress.finalScore = totalScore;
    progress.feedback = feedback;
    progress.status = 'completed';
    
    HiLog.info("ProjectBasedLearning", `项目评估完成：${projectId}, 得分${totalScore}`);
    
    return { score: totalScore, feedback };
  }

  /**
   * 获取项目进度
   */
  getProjectProgress(projectId: string): UserProjectProgress | null {
    return this.userProjects.get(projectId) || null;
  }

  /**
   * 获取用户所有项目
   */
  getUserProjects(userId: string): UserProjectProgress[] {
    const projects: UserProjectProgress[] = [];
    
    for (const progress of this.userProjects.values()) {
      if (progress.userId === userId) {
        projects.push(progress);
      }
    }
    
    return projects;
  }

  /**
   * 获取项目模板
   */
  getProjectTemplate(templateId: string): ProjectTemplate | undefined {
    return this.projectTemplates.get(templateId);
  }

  /**
   * 获取所有项目模板
   */
  getAllTemplates(): ProjectTemplate[] {
    return Array.from(this.projectTemplates.values());
  }
}

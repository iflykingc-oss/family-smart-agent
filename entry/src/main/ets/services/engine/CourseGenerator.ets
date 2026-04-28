/**
 * ============================================================================
 * 课程生成器 - CourseGenerator
 * 借鉴 OpenMAIC 一键生成课程逻辑
 * 
 * 功能：
 * 1. 输入主题 → 自动生成完整课程
 * 2. 课程结构：大纲 → 幻灯片 → 测验 → 实践项目
 * 3. 自适应难度（根据用户水平）
 * 4. 课程模板库
 * 
 * 借鉴 OpenMAIC：
 * - 课程生成 Pipeline（主题分析 → 大纲生成 → 内容填充 → 测验生成）
 * - 多模态内容（文本 + 图示 + 视频）
 * - 课程模板系统
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { SkillEntity, SkillCategory, SkillDifficulty, SkillStep } from './LearningEngine';

const TAG = 'CourseGenerator';

/**
 * 课程结构（借鉴 OpenMAIC）
 */
export interface Course {
  /** 课程 ID */
  id: string;
  
  /** 课程标题 */
  title: string;
  
  /** 课程描述 */
  description: string;
  
  /** 课程类别 */
  category: SkillCategory;
  
  /** 课程难度 */
  difficulty: SkillDifficulty;
  
  /** 预计时长（分钟） */
  estimatedMinutes: number;
  
  /** 课程大纲 */
  outline: CourseOutline[];
  
  /** 幻灯片列表 */
  slides: Slide[];
  
  /** 测验列表 */
  quizzes: Quiz[];
  
  /** 实践项目 */
  projects: Project[];
  
  /** 课程标签 */
  tags: string[];
  
  /** 创建时间 */
  createdAt: number;
}

/**
 * 课程大纲
 */
export interface CourseOutline {
  /** 章节序号 */
  order: number;
  
  /** 章节标题 */
  title: string;
  
  /** 章节描述 */
  description: string;
  
  /** 预计时长（分钟） */
  estimatedMinutes: number;
  
  /** 子章节 */
  subsections: Subsection[];
}

/**
 * 子章节
 */
export interface Subsection {
  /** 子章节标题 */
  title: string;
  
  /** 内容要点 */
  keyPoints: string[];
  
  /** 教学方法 */
  teachingMethod: 'lecture' | 'demo' | 'practice' | 'discussion' | 'project';
}

/**
 * 幻灯片（借鉴 OpenMAIC）
 */
export interface Slide {
  /** 幻灯片序号 */
  order: number;
  
  /** 幻灯片标题 */
  title: string;
  
  /** 幻灯片内容 */
  content: string;
  
  /** 配图描述 */
  imageDescription?: string;
  
  /** 讲解备注 */
  speakerNotes?: string;
  
  /** 动画效果 */
  animation?: 'none' | 'fade' | 'slide' | 'zoom';
}

/**
 * 测验（借鉴 OpenMAIC）
 */
export interface Quiz {
  /** 测验序号 */
  order: number;
  
  /** 测验类型 */
  type: 'multiple_choice' | 'true_false' | 'fill_blank' | 'short_answer' | 'practical';
  
  /** 问题 */
  question: string;
  
  /** 选项（选择题） */
  options?: string[];
  
  /** 正确答案 */
  answer: string;
  
  /** 解析 */
  explanation: string;
  
  /** 难度 */
  difficulty: number;
}

/**
 * 实践项目（借鉴 OpenMAIC）
 */
export interface Project {
  /** 项目序号 */
  order: number;
  
  /** 项目标题 */
  title: string;
  
  /** 项目描述 */
  description: string;
  
  /** 项目要求 */
  requirements: string[];
  
  /** 评分标准 */
  rubric: RubricItem[];
  
  /** 预计时长（分钟） */
  estimatedMinutes: number;
}

/**
 * 评分标准
 */
export interface RubricItem {
  /** 评分项 */
  criterion: string;
  
  /** 权重 */
  weight: number;
  
  /** 优秀标准 */
  excellent: string;
  
  /** 合格标准 */
  passing: string;
}

/**
 * 课程模板
 */
export interface CourseTemplate {
  /** 模板 ID */
  id: string;
  
  /** 模板名称 */
  name: string;
  
  /** 适用类别 */
  category: SkillCategory;
  
  /** 大纲模板 */
  outlineTemplate: string[];
  
  /** 幻灯片模板 */
  slideTemplates: string[];
  
  /** 测验模板 */
  quizTemplates: string[];
}

/**
 * 课程生成器
 */
export class CourseGenerator {
  private static instance: CourseGenerator | null = null;
  
  // 课程模板库
  private templates: Map<string, CourseTemplate>;
  
  // 已生成的课程
  private generatedCourses: Map<string, Course>;

  static getInstance(): CourseGenerator {
    if (!CourseGenerator.instance) {
      CourseGenerator.instance = new CourseGenerator();
    }
    return CourseGenerator.instance;
  }

  private constructor() {
    this.templates = new Map();
    this.generatedCourses = new Map();
    this.initTemplates();
    HiLog.info(TAG, '课程生成器初始化（借鉴 OpenMAIC）');
  }

  /**
   * 初始化课程模板库
   */
  private initTemplates(): void {
    // 职业素养模板
    this.templates.set('professional', {
      id: 'professional',
      name: '职业素养课程模板',
      category: SkillCategory.PROFESSIONAL,
      outlineTemplate: [
        '概念理解：{topic}的基本概念和重要性',
        '核心技巧：{topic}的关键技巧和方法',
        '实战演练：{topic}的实际应用场景',
        '进阶提升：{topic}的高级技巧和注意事项',
        '总结复习：{topic}的核心要点回顾'
      ],
      slideTemplates: [
        '封面：{topic} - 职业素养提升',
        '目录：{topic}学习内容概览',
        '概念：{topic}是什么？为什么重要？',
        '技巧：{topic}的 3 个核心技巧',
        '案例：{topic}的实际案例',
        '练习：{topic}的实战练习',
        '总结：{topic}的核心要点'
      ],
      quizTemplates: [
        '选择题：关于{topic}，以下说法正确的是？',
        '判断题：{topic}的关键是 XXX（对/错）',
        '简答题：请描述{topic}的应用场景',
        '实践题：模拟{topic}的实际场景'
      ]
    });

    // 办公技能模板
    this.templates.set('office', {
      id: 'office',
      name: '办公技能课程模板',
      category: SkillCategory.OFFICE,
      outlineTemplate: [
        '基础操作：{topic}的基本操作方法',
        '核心功能：{topic}的主要功能使用',
        '实战案例：{topic}的实际应用案例',
        '进阶技巧：{topic}的高级技巧',
        '综合练习：{topic}的综合应用'
      ],
      slideTemplates: [
        '封面：{topic} - 办公技能提升',
        '目录：{topic}学习内容',
        '界面：{topic}的界面介绍',
        '操作：{topic}的基本操作',
        '案例：{topic}的实际案例',
        '练习：{topic}的练习任务',
        '总结：{topic}的要点回顾'
      ],
      quizTemplates: [
        '选择题：{topic}的 XXX 功能是？',
        '操作题：请使用{topic}完成 XXX',
        '案例分析：分析{topic}的使用场景'
      ]
    });

    // 生活技能模板
    this.templates.set('life', {
      id: 'life',
      name: '生活技能课程模板',
      category: SkillCategory.LIFE,
      outlineTemplate: [
        '认识功能：{topic}的基本功能介绍',
        '操作步骤：{topic}的详细操作步骤',
        '注意事项：{topic}的安全和注意事项',
        '常见问题：{topic}的常见问题解答',
        '实践练习：{topic}的实际操作练习'
      ],
      slideTemplates: [
        '封面：{topic} - 生活技能学习',
        '目录：{topic}学习内容',
        '功能：{topic}有哪些功能？',
        '步骤：{topic}的操作步骤',
        '注意：{topic}的注意事项',
        '问答：{topic}的常见问题',
        '练习：{topic}的实际操作'
      ],
      quizTemplates: [
        '选择题：{topic}的正确操作是？',
        '判断题：使用{topic}需要注意 XXX（对/错）',
        '操作题：请演示{topic}的使用'
      ]
    });
  }

  /**
   * 一键生成课程（借鉴 OpenMAIC）
   * @param topic 主题
   * @param category 类别
   * @param difficulty 难度
   * @param userLevel 用户水平（0-5）
   */
  generateCourse(
    topic: string,
    category: SkillCategory = SkillCategory.PROFESSIONAL,
    difficulty: SkillDifficulty = SkillDifficulty.BEGINNER,
    userLevel: number = 0
  ): Course {
    const startTime = Date.now();
    HiLog.info(TAG, `开始生成课程：${topic}`);
    
    try {
      // 1. 选择模板
      const template = this.selectTemplate(category);
      
      // 2. 生成大纲
      const outline = this.generateOutline(topic, template, difficulty);
      
      // 3. 生成幻灯片
      const slides = this.generateSlides(topic, template, outline);
      
      // 4. 生成测验
      const quizzes = this.generateQuizzes(topic, template, difficulty);
      
      // 5. 生成实践项目
      const projects = this.generateProjects(topic, difficulty, userLevel);
      
      // 6. 组装课程
      const course: Course = {
        id: `course_${Date.now()}`,
        title: `${topic}`,
        description: `学习${topic}，提升${category === SkillCategory.PROFESSIONAL ? '职业素养' : category === SkillCategory.OFFICE ? '办公技能' : '生活技能'}`,
        category,
        difficulty,
        estimatedMinutes: this.calculateEstimatedTime(outline),
        outline,
        slides,
        quizzes,
        projects,
        tags: [topic, category, difficulty.toString()],
        createdAt: Date.now()
      };
      
      // 7. 缓存课程
      this.generatedCourses.set(course.id, course);
      
      const elapsed = Date.now() - startTime;
      HiLog.info(TAG, `课程生成完成：${topic}，耗时${elapsed}ms，${outline.length}章，${slides.length}页，${quizzes.length}题`);
      
      return course;
    } catch (error) {
      HiLog.error(TAG, `课程生成失败：${topic}, ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 选择模板
   */
  private selectTemplate(category: SkillCategory): CourseTemplate {
    const templateId = category === SkillCategory.PROFESSIONAL ? 'professional' 
      : category === SkillCategory.OFFICE ? 'office' 
      : 'life';
    
    return this.templates.get(templateId)!;
  }

  /**
   * 生成大纲（借鉴 OpenMAIC 的课程结构）
   */
  private generateOutline(
    topic: string,
    template: CourseTemplate,
    difficulty: SkillDifficulty
  ): CourseOutline[] {
    const outlines: CourseOutline[] = [];
    
    template.outlineTemplate.forEach((template, index) => {
      const title = template.replace('{topic}', topic);
      
      // 根据难度调整子章节
      const subsections = this.generateSubsections(topic, index, difficulty);
      
      outlines.push({
        order: index + 1,
        title,
        description: `学习${title}的核心内容`,
        estimatedMinutes: this.estimateSubsectionTime(subsections),
        subsections
      });
    });
    
    return outlines;
  }

  /**
   * 生成子章节
   */
  private generateSubsections(
    topic: string,
    chapterIndex: number,
    difficulty: SkillDifficulty
  ): Subsection[] {
    const subsections: Subsection[] = [];
    
    // 基础章节：概念 + 技巧
    if (chapterIndex === 0) {
      subsections.push(
        { title: `${topic}是什么`, keyPoints: ['定义', '重要性', '应用场景'], teachingMethod: 'lecture' },
        { title: `为什么学习${topic}`, keyPoints: ['职业价值', '个人成长', '实际需求'], teachingMethod: 'lecture' }
      );
    }
    
    // 核心章节：技巧 + 演示
    if (chapterIndex === 1) {
      subsections.push(
        { title: `${topic}的核心技巧`, keyPoints: ['技巧 1', '技巧 2', '技巧 3'], teachingMethod: 'demo' },
        { title: `${topic}的常见误区`, keyPoints: ['误区 1', '误区 2', '避免方法'], teachingMethod: 'lecture' }
      );
    }
    
    // 实战章节：案例 + 练习
    if (chapterIndex === 2) {
      subsections.push(
        { title: `${topic}的实际案例`, keyPoints: ['案例 1', '案例 2', '分析'], teachingMethod: 'discussion' },
        { title: `${topic}的实战练习`, keyPoints: ['练习 1', '练习 2', '反馈'], teachingMethod: 'practice' }
      );
    }
    
    // 进阶章节：高级技巧
    if (chapterIndex === 3 && difficulty >= SkillDifficulty.INTERMEDIATE) {
      subsections.push(
        { title: `${topic}的高级技巧`, keyPoints: ['技巧 A', '技巧 B', '技巧 C'], teachingMethod: 'lecture' },
        { title: `${topic}的最佳实践`, keyPoints: ['实践 1', '实践 2', '总结'], teachingMethod: 'project' }
      );
    }
    
    // 总结章节
    if (chapterIndex === 4) {
      subsections.push(
        { title: `${topic}的核心要点`, keyPoints: ['要点 1', '要点 2', '要点 3'], teachingMethod: 'lecture' },
        { title: `${topic}的复习计划`, keyPoints: ['复习 1', '复习 2', '巩固'], teachingMethod: 'practice' }
      );
    }
    
    return subsections;
  }

  /**
   * 生成幻灯片（借鉴 OpenMAIC）
   */
  private generateSlides(
    topic: string,
    template: CourseTemplate,
    outline: CourseOutline[]
  ): Slide[] {
    const slides: Slide[] = [];
    let order = 1;
    
    // 封面
    slides.push({
      order: order++,
      title: topic,
      content: `${topic} - 轻量化职业素养智能导学`,
      animation: 'fade'
    });
    
    // 目录
    slides.push({
      order: order++,
      title: '课程目录',
      content: outline.map(o => `${o.order}. ${o.title}`).join('\n'),
      animation: 'slide'
    });
    
    // 每个章节的幻灯片
    outline.forEach((section, sectionIndex) => {
      // 章节标题页
      slides.push({
        order: order++,
        title: section.title,
        content: section.description,
        animation: 'fade'
      });
      
      // 每个子章节的幻灯片
      section.subsections.forEach((subsection, subIndex) => {
        const content = subsection.keyPoints.map((point, i) => `${i + 1}. ${point}`).join('\n');
        
        slides.push({
          order: order++,
          title: subsection.title,
          content,
          imageDescription: `${topic} - ${subsection.title}的示意图`,
          speakerNotes: `讲解要点：${subsection.keyPoints.join('、')}`,
          animation: subIndex > 0 ? 'slide' : 'none'
        });
      });
    });
    
    // 总结页
    slides.push({
      order: order++,
      title: '课程总结',
      content: `恭喜完成${topic}的学习！\n核心要点：\n${outline.map(s => `• ${s.title}`).join('\n')}`,
      animation: 'zoom'
    });
    
    return slides;
  }

  /**
   * 生成测验（借鉴 OpenMAIC）
   */
  private generateQuizzes(
    topic: string,
    template: CourseTemplate,
    difficulty: SkillDifficulty
  ): Quiz[] {
    const quizzes: Quiz[] = [];
    let order = 1;
    
    // 选择题
    quizzes.push({
      order: order++,
      type: 'multiple_choice',
      question: `关于"${topic}"，以下说法正确的是？`,
      options: [
        'A. 是职业素养的重要组成部分',
        'B. 只在特定场景下使用',
        'C. 不需要系统学习',
        'D. 只对管理者重要'
      ],
      answer: 'A',
      explanation: `${topic}是职业素养的重要组成部分，适用于所有职场人士。`,
      difficulty: 1
    });
    
    // 判断题
    quizzes.push({
      order: order++,
      type: 'true_false',
      question: `掌握"${topic}"只需要理论学习，不需要实践练习。（判断对错）`,
      answer: '错',
      explanation: `掌握${topic}需要理论学习 + 实践练习相结合。`,
      difficulty: 1
    });
    
    // 简答题
    quizzes.push({
      order: order++,
      type: 'short_answer',
      question: `请描述"${topic}"在你的工作/生活中的应用场景。`,
      answer: '（开放题，根据用户回答评估）',
      explanation: `${topic}可以应用于多个场景，关键是要结合实际。`,
      difficulty: 2
    });
    
    // 实践题（中高级难度）
    if (difficulty >= SkillDifficulty.INTERMEDIATE) {
      quizzes.push({
        order: order++,
        type: 'practical',
        question: `模拟场景：你正在使用"${topic}"解决实际问题，请描述你的操作步骤。`,
        answer: '（实践题，根据操作评估）',
        explanation: `实践是检验学习成果的最佳方式。`,
        difficulty: 3
      });
    }
    
    return quizzes;
  }

  /**
   * 生成实践项目（借鉴 OpenMAIC 的 PBL）
   */
  private generateProjects(
    topic: string,
    difficulty: SkillDifficulty,
    userLevel: number
  ): Project[] {
    const projects: Project[] = [];
    
    // 基础项目
    projects.push({
      order: 1,
      title: `${topic}基础实践`,
      description: `运用${topic}的基本知识完成一个简单任务`,
      requirements: [
        '理解${topic}的基本概念',
        '能够描述${topic}的应用场景',
        '完成一个与${topic}相关的简单任务'
      ],
      rubric: [
        { criterion: '概念理解', weight: 0.3, excellent: '准确理解核心概念', passing: '基本理解概念' },
        { criterion: '应用能力', weight: 0.4, excellent: '能独立应用', passing: '在指导下能应用' },
        { criterion: '完成质量', weight: 0.3, excellent: '任务完成度高', passing: '任务基本完成' }
      ],
      estimatedMinutes: 30
    });
    
    // 进阶项目（中高级难度）
    if (difficulty >= SkillDifficulty.INTERMEDIATE) {
      projects.push({
        order: 2,
        title: `${topic}进阶项目`,
        description: `综合运用${topic}解决一个复杂问题`,
        requirements: [
          '综合运用${topic}的多项技能',
          '分析实际场景并制定方案',
          '完成一个完整的项目'
        ],
        rubric: [
          { criterion: '方案设计', weight: 0.3, excellent: '方案完整可行', passing: '方案基本可行' },
          { criterion: '技能应用', weight: 0.4, excellent: '熟练应用多项技能', passing: '能应用基本技能' },
          { criterion: '成果质量', weight: 0.3, excellent: '成果优秀', passing: '成果合格' }
        ],
        estimatedMinutes: 60
      });
    }
    
    return projects;
  }

  /**
   * 估算子章节时间
   */
  private estimateSubsectionTime(subsections: Subsection[]): number {
    return subsections.length * 10; // 每个子章节约 10 分钟
  }

  /**
   * 计算课程总时长
   */
  private calculateEstimatedTime(outline: CourseOutline[]): number {
    return outline.reduce((sum, section) => sum + section.estimatedMinutes, 0);
  }

  /**
   * 获取已生成的课程
   */
  getCourse(courseId: string): Course | null {
    return this.generatedCourses.get(courseId) || null;
  }

  /**
   * 获取所有已生成的课程
   */
  getAllCourses(): Course[] {
    return Array.from(this.generatedCourses.values());
  }

  /**
   * 清除缓存
   */
  clearCache(): void {
    this.generatedCourses.clear();
    HiLog.info(TAG, '课程缓存已清除');
  }
}

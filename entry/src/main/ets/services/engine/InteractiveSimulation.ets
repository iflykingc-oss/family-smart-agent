/**
 * ============================================================================
 * 交互式模拟引擎 - InteractiveSimulation
 * 借鉴 OpenMAIC 交互式模拟和场景化学习
 * 
 * 功能：
 * 1. 场景模拟（面试/汇报/谈判等真实场景）
 * 2. 角色扮演（用户扮演角色，AI 扮演对手）
 * 3. 实时反馈（操作评估 + 建议）
 * 4. 模拟评分（多维度评分）
 * 
 * 借鉴 OpenMAIC：
 * - 交互式模拟（用户操作 + AI 反馈）
 * - 场景化学习（真实场景模拟）
 * - 游戏化学习（积分 + 评级）
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

const TAG = 'InteractiveSimulation';

/**
 * 模拟类型
 */
export enum SimulationType {
  /** 面试模拟 */
  INTERVIEW = 'interview',
  
  /** 汇报模拟 */
  REPORT = 'report',
  
  /** 谈判模拟 */
  NEGOTIATION = 'negotiation',
  
  /** 冲突处理模拟 */
  CONFLICT = 'conflict',
  
  /** 邮件写作模拟 */
  EMAIL = 'email',
  
  /** 会议发言模拟 */
  MEETING = 'meeting',
}

/**
 * 模拟场景
 */
export interface SimulationScenario {
  /** 场景 ID */
  id: string;
  
  /** 场景名称 */
  name: string;
  
  /** 场景类型 */
  type: SimulationType;
  
  /** 场景描述 */
  description: string;
  
  /** 背景信息 */
  background: string;
  
  /** 角色列表 */
  roles: SimulationRole[];
  
  /** 对话轮次 */
  rounds: SimulationRound[];
  
  /** 评分标准 */
  scoringCriteria: ScoringCriterion[];
  
  /** 难度 */
  difficulty: number;
}

/**
 * 模拟角色
 */
export interface SimulationRole {
  /** 角色 ID */
  id: string;
  
  /** 角色名称 */
  name: string;
  
  /** 角色描述 */
  description: string;
  
  /** 性格特征 */
  personality: string;
  
  /** 目标 */
  goal: string;
}

/**
 * 模拟轮次
 */
export interface SimulationRound {
  /** 轮次序号 */
  round: number;
  
  /** AI 发言 */
  aiMessage: string;
  
  /** 用户可选回复 */
  userOptions: UserOption[];
  
  /** 最佳回复 */
  bestOptionIndex: number;
  
  /** 反馈 */
  feedback: string;
}

/**
 * 用户选项
 */
export interface UserOption {
  /** 选项文本 */
  text: string;
  
  /** 得分 */
  score: number;
  
  /** 反馈 */
  feedback: string;
}

/**
 * 评分标准
 */
export interface ScoringCriterion {
  /** 评分项 */
  criterion: string;
  
  /** 权重 */
  weight: number;
  
  /** 评分说明 */
  description: string;
}

/**
 * 模拟结果
 */
export interface SimulationResult {
  /** 场景 ID */
  scenarioId: string;
  
  /** 总得分 */
  totalScore: number;
  
  /** 各维度得分 */
  dimensionScores: Record<string, number>;
  
  /** 评级 */
  rating: 'S' | 'A' | 'B' | 'C' | 'D';
  
  /** 评价 */
  feedback: string;
  
  /** 改进建议 */
  suggestions: string[];
}

/**
 * 交互式模拟引擎
 */
export class InteractiveSimulation {
  private static instance: InteractiveSimulation | null = null;
  
  // 场景库
  private scenarios: Map<string, SimulationScenario>;
  
  // 当前模拟
  private currentSimulation: {
    scenario: SimulationScenario;
    currentRound: number;
    userScores: number[];
    userChoices: number[];
  } | null;

  static getInstance(): InteractiveSimulation {
    if (!InteractiveSimulation.instance) {
      InteractiveSimulation.instance = new InteractiveSimulation();
    }
    return InteractiveSimulation.instance;
  }

  private constructor() {
    this.scenarios = new Map();
    this.currentSimulation = null;
    this.initScenarios();
    HiLog.info(TAG, '交互式模拟引擎初始化（借鉴 OpenMAIC）');
  }

  /**
   * 初始化场景库
   */
  private initScenarios(): void {
    // 面试模拟
    this.scenarios.set('interview_salary', {
      id: 'interview_salary',
      name: '面试谈薪模拟',
      type: SimulationType.INTERVIEW,
      description: '模拟面试中 HR 问期望薪资的场景',
      background: '你正在参加一家公司的面试，最后一轮面试中 HR 问你期望薪资。',
      roles: [
        { id: 'hr', name: 'HR', description: '人力资源经理，专业、友善但有压力', personality: '温和但坚持原则', goal: '在预算内招到合适的人才' },
        { id: 'user', name: '候选人', description: '求职者，需要谈判薪资', personality: '自信但不傲慢', goal: '获得合理的薪资' }
      ],
      rounds: [
        {
          round: 1,
          aiMessage: '你好！感谢你参加我们的面试。最后一个问题，你期望的薪资是多少？',
          userOptions: [
            { text: '我期望 15-20K，具体看整体 package', score: 90, feedback: '很好！给出范围而不是具体数字，同时考虑整体 package。' },
            { text: '我期望 25K', score: 60, feedback: '说具体数字可能被压价或淘汰。' },
            { text: '无所谓，看公司规定', score: 30, feedback: '显得没有自信，可能影响议价能力。' },
            { text: '我前公司薪资是 12K', score: 40, feedback: '前公司薪资与新工作无关，应该关注市场价值。' }
          ],
          bestOptionIndex: 0,
          feedback: '谈薪时要给出范围，了解市场行情，考虑整体 package。'
        },
        {
          round: 2,
          aiMessage: '你的期望薪资在我们的预算范围内。你能说说为什么值这个价吗？',
          userOptions: [
            { text: '我有 3 年经验，主导过 2 个成功项目，数据表明我能带来 XXX 价值', score: 95, feedback: '很好！用数据和成果说话，展示价值。' },
            { text: '我觉得我应该值这个价', score: 40, feedback: '缺乏具体依据，说服力不足。' },
            { text: '我的朋友都拿这个数', score: 20, feedback: '用别人对比不专业，应该关注自身价值。' }
          ],
          bestOptionIndex: 0,
          feedback: '用数据和成果展示你的价值，而不是主观感觉。'
        },
        {
          round: 3,
          aiMessage: '我们最多能给到 18K，你能接受吗？',
          userOptions: [
            { text: '18K 可以接受，请问年终奖和晋升机制是怎样的？', score: 90, feedback: '好！接受的同时了解其他福利和晋升机会。' },
            { text: '可以，谢谢！', score: 60, feedback: '可以接受，但没有争取更多。' },
            { text: '太低了，我不接受', score: 30, feedback: '直接拒绝可能失去机会，可以协商。' }
          ],
          bestOptionIndex: 0,
          feedback: '接受薪资的同时，了解年终奖、晋升、福利等整体 package。'
        }
      ],
      scoringCriteria: [
        { criterion: '自信度', weight: 0.3, description: '表现出自信但不傲慢' },
        { criterion: '数据支撑', weight: 0.3, description: '用数据和成果说话' },
        { criterion: '谈判技巧', weight: 0.2, description: '灵活应对，不轻易放弃' },
        { criterion: '整体思维', weight: 0.2, description: '考虑整体 package，不只是底薪' }
      ],
      difficulty: 3
    });

    // 汇报模拟
    this.scenarios.set('report_delay', {
      id: 'report_delay',
      name: '项目延期汇报模拟',
      type: SimulationType.REPORT,
      description: '模拟向领导汇报项目延期的场景',
      background: '你负责的项目可能延期，需要向领导汇报。',
      roles: [
        { id: 'leader', name: '领导', description: '部门经理，关注进度和结果', personality: '严格但讲理', goal: '确保项目按时完成' },
        { id: 'user', name: '项目负责人', description: '需要汇报延期风险', personality: '专业但面临压力', goal: '透明沟通，寻求支持' }
      ],
      rounds: [
        {
          round: 1,
          aiMessage: '项目进度怎么样了？能按时交付吗？',
          userOptions: [
            { text: '领导，项目可能需要延期 3 天。原因是第三方接口延迟交付。我已经协调了备用方案，预计本周三可以完成。', score: 95, feedback: '很好！提前汇报 + 说明原因 + 给出解决方案。' },
            { text: '应该能按时完成', score: 40, feedback: '隐瞒风险，如果真延期会更严重。' },
            { text: '可能会延期，但我不确定', score: 50, feedback: '汇报了但不确定，缺乏具体信息。' }
          ],
          bestOptionIndex: 0,
          feedback: '汇报延期要提前、具体、有方案。'
        },
        {
          round: 2,
          aiMessage: '延期 3 天影响很大，你能保证周三完成吗？',
          userOptions: [
            { text: '我保证周三完成核心功能，非核心功能放到下一期。每天向您汇报进度。', score: 90, feedback: '好！调整范围 + 承诺 + 定期汇报。' },
            { text: '我尽量', score: 40, feedback: '缺乏信心，领导不会满意。' },
            { text: '不能保证，要看情况', score: 20, feedback: '太消极，显得不专业。' }
          ],
          bestOptionIndex: 0,
          feedback: '调整范围、承诺具体目标、定期汇报进度。'
        }
      ],
      scoringCriteria: [
        { criterion: '透明度', weight: 0.3, description: '及时、真实地汇报' },
        { criterion: '解决方案', weight: 0.3, description: '带着方案汇报，不是只提问题' },
        { criterion: '沟通能力', weight: 0.2, description: '清晰、有条理' },
        { criterion: '责任心', weight: 0.2, description: '主动承担责任' }
      ],
      difficulty: 2
    });

    // 冲突处理模拟
    this.scenarios.set('conflict_colleague', {
      id: 'conflict_colleague',
      name: '与同事意见不合模拟',
      type: SimulationType.CONFLICT,
      description: '模拟与同事在方案上有分歧的场景',
      background: '你和同事在一个方案上有分歧，需要沟通解决。',
      roles: [
        { id: 'colleague', name: '同事', description: '技术骨干，坚持自己的方案', personality: '固执但有理', goal: '推行自己的方案' },
        { id: 'user', name: '你', description: '有不同意见，需要沟通', personality: '理性但坚持', goal: '找到最佳方案' }
      ],
      rounds: [
        {
          round: 1,
          aiMessage: '我觉得我的方案更好，你的方案有这些问题...',
          userOptions: [
            { text: '我理解你的顾虑。你的方案在 XX 方面确实更好。不过从用户数据来看，我的方案转化率更高。要不我们做个 A/B 测试？', score: 95, feedback: '很好！先理解对方 + 用数据说话 + 提出折中方案。' },
            { text: '你的方案不行，我的更好', score: 30, feedback: '直接否定，伤和气。' },
            { text: '好吧，听你的', score: 50, feedback: '放弃自己的观点，可能不是最佳方案。' }
          ],
          bestOptionIndex: 0,
          feedback: '处理冲突要理解对方、用数据说话、寻找双赢。'
        }
      ],
      scoringCriteria: [
        { criterion: '理解对方', weight: 0.3, description: '先理解对方观点' },
        { criterion: '数据支撑', weight: 0.3, description: '用数据说话' },
        { criterion: '沟通能力', weight: 0.2, description: '友好、理性' },
        { criterion: '双赢思维', weight: 0.2, description: '寻找最佳方案，不是争输赢' }
      ],
      difficulty: 2
    });
  }

  /**
   * 开始模拟
   */
  startSimulation(scenarioId: string): SimulationScenario | null {
    const scenario = this.scenarios.get(scenarioId);
    if (!scenario) {
      HiLog.error(TAG, `场景不存在：${scenarioId}`);
      return null;
    }
    
    this.currentSimulation = {
      scenario,
      currentRound: 0,
      userScores: [],
      userChoices: []
    };
    
    HiLog.info(TAG, `模拟开始：${scenario.name}`);
    return scenario;
  }

  /**
   * 获取当前轮次
   */
  getCurrentRound(): SimulationRound | null {
    if (!this.currentSimulation) return null;
    
    const round = this.currentSimulation.currentRound;
    if (round >= this.currentSimulation.scenario.rounds.length) {
      return null;
    }
    
    return this.currentSimulation.scenario.rounds[round];
  }

  /**
   * 用户选择
   */
  userSelect(optionIndex: number): { feedback: string; score: number; isLast: boolean } {
    if (!this.currentSimulation) {
      return { feedback: '模拟未开始', score: 0, isLast: true };
    }
    
    const round = this.getCurrentRound();
    if (!round) {
      return { feedback: '没有更多轮次', score: 0, isLast: true };
    }
    
    const option = round.userOptions[optionIndex];
    if (!option) {
      return { feedback: '选项不存在', score: 0, isLast: true };
    }
    
    // 记录分数
    this.currentSimulation.userScores.push(option.score);
    this.currentSimulation.userChoices.push(optionIndex);
    
    // 进入下一轮
    this.currentSimulation.currentRound++;
    
    const isLast = this.currentSimulation.currentRound >= this.currentSimulation.scenario.rounds.length;
    
    HiLog.info(TAG, `用户选择: 选项${optionIndex}, 得分${option.score}`);
    
    return {
      feedback: option.feedback,
      score: option.score,
      isLast
    };
  }

  /**
   * 获取模拟结果
   */
  getSimulationResult(): SimulationResult | null {
    if (!this.currentSimulation) return null;
    
    const scenario = this.currentSimulation.scenario;
    const scores = this.currentSimulation.userScores;
    
    if (scores.length === 0) return null;
    
    // 计算总分
    const totalScore = scores.reduce((sum, score) => sum + score, 0) / scores.length;
    
    // 计算各维度得分
    const dimensionScores: Record<string, number> = {};
    scenario.scoringCriteria.forEach(criterion => {
      dimensionScores[criterion.criterion] = totalScore * criterion.weight;
    });
    
    // 评级
    let rating: 'S' | 'A' | 'B' | 'C' | 'D';
    if (totalScore >= 90) rating = 'S';
    else if (totalScore >= 80) rating = 'A';
    else if (totalScore >= 70) rating = 'B';
    else if (totalScore >= 60) rating = 'C';
    else rating = 'D';
    
    // 评价
    const feedback = this.generateFeedback(totalScore, rating);
    
    // 改进建议
    const suggestions = this.generateSuggestions(scores, scenario);
    
    return {
      scenarioId: scenario.id,
      totalScore,
      dimensionScores,
      rating,
      feedback,
      suggestions
    };
  }

  /**
   * 生成反馈
   */
  private generateFeedback(totalScore: number, rating: string): string {
    const feedbacks: Record<string, string> = {
      'S': '太棒了！你的表现非常优秀，已经掌握了这个场景的核心技巧！',
      'A': '很好！你的表现很出色，只有少量需要改进的地方。',
      'B': '不错！你的表现良好，有一些地方可以进一步提升。',
      'C': '还可以，但需要更多练习来提升。',
      'D': '需要加强练习，建议重新学习相关技巧。'
    };
    return feedbacks[rating] || '继续努力！';
  }

  /**
   * 生成改进建议
   */
  private generateSuggestions(scores: number[], scenario: SimulationScenario): string[] {
    const suggestions: string[] = [];
    
    // 分析低分轮次
    scores.forEach((score, index) => {
      if (score < 70) {
        const round = scenario.rounds[index];
        if (round) {
          suggestions.push(`第${index + 1}轮需要改进：${round.feedback}`);
        }
      }
    });
    
    if (suggestions.length === 0) {
      suggestions.push('你的表现很好，继续保持！');
    }
    
    return suggestions;
  }

  /**
   * 获取所有场景
   */
  getAllScenarios(): SimulationScenario[] {
    return Array.from(this.scenarios.values());
  }

  /**
   * 按类型获取场景
   */
  getScenariosByType(type: SimulationType): SimulationScenario[] {
    return Array.from(this.scenarios.values()).filter(s => s.type === type);
  }

  /**
   * 获取场景详情
   */
  getScenario(id: string): SimulationScenario | null {
    return this.scenarios.get(id) || null;
  }

  /**
   * 获取场景类型名称
   */
  getTypeName(type: SimulationType): string {
    const names: Record<SimulationType, string> = {
      [SimulationType.INTERVIEW]: '面试模拟',
      [SimulationType.REPORT]: '汇报模拟',
      [SimulationType.NEGOTIATION]: '谈判模拟',
      [SimulationType.CONFLICT]: '冲突处理模拟',
      [SimulationType.EMAIL]: '邮件写作模拟',
      [SimulationType.MEETING]: '会议发言模拟'
    };
    return names[type] || '其他';
  }

  /**
   * 重置模拟
   */
  resetSimulation(): void {
    this.currentSimulation = null;
    HiLog.info(TAG, '模拟已重置');
  }
}

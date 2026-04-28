/**
 * ============================================================================
 * 多智能体课堂 - MultiAgentClassroom
 * 借鉴 OpenMAIC 多智能体互动设计
 * 
 * 功能：
 * 1. AI 老师 - 讲解概念、出题、评估
 * 2. AI 同学 - 讨论、提问、竞争
 * 3. 三角色互动 - 老师讲解 + 同学讨论 + 用户参与
 * 4. 实时互动 - 文字 + 语音 + 白板
 * 
 * 借鉴 OpenMAIC：
 * - 多智能体编排（老师 + 同学 + 用户）
 * - 实时互动（文字讨论 + 语音讲解）
 * - 白板协作（画图 + 公式）
 * - 沉浸式模式（全屏幕学习）
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';

const TAG = 'MultiAgentClassroom';

/**
 * 智能体角色
 */
export enum AgentRole {
  /** AI 老师 */
  TEACHER = 'teacher',
  
  /** AI 同学 */
  CLASSMATE = 'classmate',
  
  /** 用户 */
  USER = 'user',
}

/**
 * 智能体
 */
export interface Agent {
  /** 智能体 ID */
  id: string;
  
  /** 角色 */
  role: AgentRole;
  
  /** 名称 */
  name: string;
  
  /** 头像 */
  avatar?: string;
  
  /** 性格特征 */
  personality: string;
  
  /** 当前状态 */
  state: 'idle' | 'speaking' | 'listening' | 'thinking';
}

/**
 * 消息
 */
export interface ClassroomMessage {
  /** 消息 ID */
  id: string;
  
  /** 发送者 */
  sender: Agent;
  
  /** 消息内容 */
  content: string;
  
  /** 消息类型 */
  type: 'text' | 'voice' | 'whiteboard' | 'quiz' | 'system';
  
  /** 时间戳 */
  timestamp: number;
  
  /** 是否已读 */
  read: boolean;
}

/**
 * 白板元素
 */
export interface WhiteboardElement {
  /** 元素 ID */
  id: string;
  
  /** 元素类型 */
  type: 'text' | 'shape' | 'image' | 'formula';
  
  /** 内容 */
  content: string;
  
  /** 位置 */
  x: number;
  y: number;
  
  /** 颜色 */
  color: string;
  
  /** 大小 */
  size: number;
}

/**
 * 课堂状态
 */
export enum ClassroomState {
  /** 未开始 */
  NOT_STARTED = 'not_started',
  
  /** 进行中 */
  IN_PROGRESS = 'in_progress',
  
  /** 讨论中 */
  DISCUSSING = 'discussing',
  
  /** 测验中 */
  QUIZZING = 'quizzing',
  
  /** 实践中 */
  PRACTICING = 'practicing',
  
  /** 已结束 */
  ENDED = 'ended',
}

/**
 * 多智能体课堂
 */
export class MultiAgentClassroom {
  private static instance: MultiAgentClassroom | null = null;
  
  // 智能体列表
  private agents: Agent[];
  
  // 消息列表
  private messages: ClassroomMessage[];
  
  // 白板元素
  private whiteboardElements: WhiteboardElement[];
  
  // 课堂状态
  private state: ClassroomState;
  
  // 当前发言者
  private currentSpeaker: Agent | null;
  
  // 课堂 ID
  private classroomId: string;

  static getInstance(): MultiAgentClassroom {
    if (!MultiAgentClassroom.instance) {
      MultiAgentClassroom.instance = new MultiAgentClassroom();
    }
    return MultiAgentClassroom.instance;
  }

  private constructor() {
    this.agents = [];
    this.messages = [];
    this.whiteboardElements = [];
    this.state = ClassroomState.NOT_STARTED;
    this.currentSpeaker = null;
    this.classroomId = `classroom_${Date.now()}`;
    
    HiLog.info(TAG, '多智能体课堂初始化（借鉴 OpenMAIC）');
  }

  /**
   * 创建课堂
   */
  createClassroom(topic: string): void {
    this.state = ClassroomState.NOT_STARTED;
    this.messages = [];
    this.whiteboardElements = [];
    
    // 创建 AI 老师
    const teacher: Agent = {
      id: 'teacher_001',
      role: AgentRole.TEACHER,
      name: '小 e 老师',
      personality: '温柔、耐心、专业',
      state: 'idle'
    };
    
    // 创建 AI 同学
    const classmate: Agent = {
      id: 'classmate_001',
      role: AgentRole.CLASSMATE,
      name: '学习伙伴',
      personality: '积极、好奇、友好',
      state: 'idle'
    };
    
    this.agents = [teacher, classmate];
    
    // 发送系统消息
    this.addSystemMessage(`🎓 欢迎来到"${topic}"课堂！今天我们将一起学习${topic}。`);
    
    HiLog.info(TAG, `课堂创建成功：${topic}`);
  }

  /**
   * 开始课堂
   */
  startClassroom(): void {
    this.state = ClassroomState.IN_PROGRESS;
    
    // AI 老师开场
    this.agentSpeak(AgentRole.TEACHER, 
      '大家好！我是小 e 老师。今天我们来学习一个新技能。让我们开始吧！'
    );
    
    // AI 同学打招呼
    this.agentSpeak(AgentRole.CLASSMATE,
      '你好！我是你的学习伙伴，我会一直陪着你学习的～'
    );
    
    HiLog.info(TAG, '课堂开始');
  }

  /**
   * AI 发言（借鉴 OpenMAIC）
   */
  agentSpeak(role: AgentRole, content: string): ClassroomMessage {
    const agent = this.agents.find(a => a.role === role);
    if (!agent) {
      throw new Error(`未找到智能体：${role}`);
    }
    
    agent.state = 'speaking';
    
    const message: ClassroomMessage = {
      id: `msg_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      sender: agent,
      content,
      type: 'text',
      timestamp: Date.now(),
      read: false
    };
    
    this.messages.push(message);
    this.currentSpeaker = agent;
    
    // 3 秒后恢复 idle
    setTimeout(() => {
      agent.state = 'idle';
      this.currentSpeaker = null;
    }, 3000);
    
    HiLog.info(TAG, `${agent.name}: ${content.slice(0, 50)}...`);
    return message;
  }

  /**
   * 用户发言
   */
  userSpeak(content: string): ClassroomMessage {
    const userAgent: Agent = {
      id: 'user',
      role: AgentRole.USER,
      name: '我',
      personality: '学习者',
      state: 'speaking'
    };
    
    const message: ClassroomMessage = {
      id: `msg_${Date.now()}`,
      sender: userAgent,
      content,
      type: 'text',
      timestamp: Date.now(),
      read: false
    };
    
    this.messages.push(message);
    
    // 触发 AI 回复
    this.triggerAgentResponse(content);
    
    return message;
  }

  /**
   * 触发 AI 回复（借鉴 OpenMAIC 的对话逻辑）
   */
  private triggerAgentResponse(userMessage: string): void {
    const lowerMessage = userMessage.toLowerCase();
    
    // AI 老师回复
    if (lowerMessage.includes('问题') || lowerMessage.includes('怎么') || lowerMessage.includes('如何')) {
      setTimeout(() => {
        this.agentSpeak(AgentRole.TEACHER, 
          '好问题！让我来解释一下...'
        );
      }, 1000);
    }
    
    // AI 同学回复
    if (lowerMessage.includes('同意') || lowerMessage.includes('觉得') || lowerMessage.includes('认为')) {
      setTimeout(() => {
        this.agentSpeak(AgentRole.CLASSMATE,
          '我也这么觉得！你觉得还有什么需要注意的吗？'
        );
      }, 1500);
    }
    
    // 默认回复
    setTimeout(() => {
      this.agentSpeak(AgentRole.TEACHER,
        '很好！你的理解很到位。我们继续往下看～'
      );
    }, 2000);
  }

  /**
   * 白板操作（借鉴 OpenMAIC）
   */
  drawOnWhiteboard(element: WhiteboardElement): void {
    this.whiteboardElements.push(element);
    
    const teacher = this.agents.find(a => a.role === AgentRole.TEACHER);
    if (teacher) {
      this.addSystemMessage(`🎨 老师在白板上画了：${element.content}`);
    }
    
    HiLog.info(TAG, `白板操作：${element.type} - ${element.content}`);
  }

  /**
   * 添加系统消息
   */
  private addSystemMessage(content: string): void {
    const systemAgent: Agent = {
      id: 'system',
      role: AgentRole.TEACHER,
      name: '系统',
      personality: '',
      state: 'idle'
    };
    
    const message: ClassroomMessage = {
      id: `msg_${Date.now()}`,
      sender: systemAgent,
      content,
      type: 'system',
      timestamp: Date.now(),
      read: false
    };
    
    this.messages.push(message);
  }

  /**
   * 获取消息列表
   */
  getMessages(limit: number = 50): ClassroomMessage[] {
    return this.messages.slice(-limit);
  }

  /**
   * 获取白板元素
   */
  getWhiteboardElements(): WhiteboardElement[] {
    return this.whiteboardElements;
  }

  /**
   * 获取智能体列表
   */
  getAgents(): Agent[] {
    return this.agents;
  }

  /**
   * 获取课堂状态
   */
  getState(): ClassroomState {
    return this.state;
  }

  /**
   * 设置课堂状态
   */
  setState(state: ClassroomState): void {
    this.state = state;
    HiLog.info(TAG, `课堂状态变更: ${state}`);
  }

  /**
   * 结束课堂
   */
  endClassroom(): void {
    this.state = ClassroomState.ENDED;
    
    this.agentSpeak(AgentRole.TEACHER,
      '今天的课程就到这里！你学得很棒，记得复习哦～'
    );
    
    this.agentSpeak(AgentRole.CLASSMATE,
      '下次再见！一起加油！'
    );
    
    HiLog.info(TAG, '课堂结束');
  }

  /**
   * 清除课堂
   */
  clearClassroom(): void {
    this.agents = [];
    this.messages = [];
    this.whiteboardElements = [];
    this.state = ClassroomState.NOT_STARTED;
    this.currentSpeaker = null;
    this.classroomId = `classroom_${Date.now()}`;
    
    HiLog.info(TAG, '课堂已清除');
  }
}

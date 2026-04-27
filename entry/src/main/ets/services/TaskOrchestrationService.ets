import { Intent, SubTask, TaskType } from '../model/Intent';
import { Task, createTask, ExecutableTaskType, ExecutableTaskStatus, TaskPriority } from '../model/Task';
import { FamilyMember } from '../model/FamilyMember';
import { MemoryService } from './MemoryService';

/**
 * 任务编排服务
 * 负责将结构化意图转换为可执行的任务列表
 * 应用家庭记忆约束，智能分配任务
 */
export class TaskOrchestrationService {
  private memoryService: MemoryService;
  private static instance: TaskOrchestrationService | null = null;

  static getInstance(): TaskOrchestrationService {
    if (!TaskOrchestrationService.instance) {
      TaskOrchestrationService.instance = new TaskOrchestrationService();
    }
    return TaskOrchestrationService.instance;
  }

  private constructor() {
    this.memoryService = MemoryService.getInstance();
  }

  /**
   * 将意图编排为可执行任务
   * 核心方法：结合记忆图谱，生成智能任务分配
   */
  async orchestrate(intent: Intent): Promise<Task[]> {
    const tasks: Task[] = [];

    // 1. 处理每个子任务
    for (const subTask of intent.subTasks) {
      const task = await this.createExecutableTask(subTask, intent);
      tasks.push(task);
    }

    // 2. 根据场景创建关联任务
    if (intent.sceneId) {
      const sceneTask = this.createSceneTask(intent);
      if (sceneTask) tasks.push(sceneTask);
    }

    // 3. 推送通知任务
    const notificationTask = this.createNotificationTask(intent);
    if (notificationTask) tasks.push(notificationTask);

    return tasks;
  }

  /**
   * 将子任务转换为可执行任务
   */
  private async createExecutableTask(subTask: SubTask, intent: Intent): Promise<Task> {
    // 确定任务类型映射
    const taskTypeMap: Record<TaskType, ExecutableTaskType> = {
      'reminder': 'reminder',
      'shopping': 'shopping',
      'care': 'care',
      'schedule': 'calendar',
      'notification': 'notification',
    };

    const executableType = taskTypeMap[subTask.type] ?? 'custom';
    
    // 获取分配者信息
    let assigneeName: string | undefined;
    if (subTask.assigneeId) {
      const member = this.memoryService.getMemberById(subTask.assigneeId);
      assigneeName = member?.name;
    }

    // 确定优先级
    const priority = this.determinePriority(subTask, intent);

    // 创建任务
    const task = createTask(subTask.description, executableType, {
      assigneeId: subTask.assigneeId,
      assigneeName,
      dueTime: subTask.dueTime,
      deviceIds: subTask.deviceIds,
      priority,
      relatedIntentId: `${intent.createdAt}`,
      status: 'pending',
    });

    return task;
  }

  /**
   * 确定任务优先级
   */
  private determinePriority(subTask: SubTask, intent: Intent): TaskPriority {
    // 健康/照料相关优先
    if (intent.intentType === 'health' || intent.intentType === 'care') {
      return 'high';
    }

    // 有明确时间限制的优先
    if (subTask.dueTime) {
      const hoursUntilDue = (subTask.dueTime - Date.now()) / (1000 * 60 * 60);
      if (hoursUntilDue < 24) return 'high';
      if (hoursUntilDue < 72) return 'medium';
    }

    // 照料类任务默认高优
    if (subTask.type === 'care') return 'high';

    return 'medium';
  }

  /**
   * 创建场景任务（如果是新场景）
   */
  private createSceneTask(intent: Intent): Task | null {
    if (!intent.sceneId) return null;

    const scene = this.memoryService.getAllScenes().find(s => s.id === intent.sceneId);
    if (!scene) return null;

    return createTask(`【场景】${scene.name}`, 'custom', {
      assigneeName: undefined,
      deviceIds: scene.defaultDevices,
      priority: 'low',
      relatedSceneId: intent.sceneId,
      status: 'pending',
    });
  }

  /**
   * 创建统一推送通知任务
   */
  private createNotificationTask(intent: Intent): Task | null {
    // 如果有明确需要推送的成员，创建通知任务
    if (intent.relatedMembers.length === 0) return null;

    const memberNames = intent.relatedMembers
      .map(id => this.memoryService.getMemberById(id)?.name ?? '家人')
      .join('、');

    return createTask(`通知${memberNames}查看任务`, 'notification', {
      assigneeId: intent.relatedMembers[0],
      assigneeName: memberNames,
      deviceIds: intent.relatedMembers.length > 0 ? ['smart_phone'] : [],
      priority: 'low',
      status: 'pending',
    });
  }

  /**
   * 应用家庭约束，重新分配任务
   * 这是"记忆"能力的关键体现
   */
  async applyConstraintsAndReassign(task: Task): Promise<Task> {
    if (!task.assigneeId) return task;

    // 获取成员的所有约束
    const constraints = this.memoryService.getMemberConstraints(task.assigneeId);
    
    // 检查任务描述是否违反约束
    const taskDescLower = task.description.toLowerCase();
    let shouldReassign = false;
    let reassignReason = '';

    for (const constraint of constraints) {
      // 腰不好 → 不能提重物
      if (constraint.includes('腰不好') && taskDescLower.includes('提重物')) {
        shouldReassign = true;
        reassignReason = `根据记忆，${this.memoryService.getMemberById(task.assigneeId)?.name}腰不好，不适合提重物`;
        break;
      }
      
      // 高血压 → 不能剧烈运动
      if (constraint.includes('高血压') && taskDescLower.includes('运动')) {
        shouldReassign = true;
        reassignReason = `根据记忆，${this.memoryService.getMemberById(task.assigneeId)?.name}有高血压，不适合剧烈运动`;
        break;
      }
    }

    if (shouldReassign) {
      // 找到其他可分配的成员
      const allMembers = this.memoryService.getAllMembers();
      const otherMembers = allMembers.filter(m => m.id !== task.assigneeId);
      
      if (otherMembers.length > 0) {
        const newAssignee = otherMembers[0];
        return createTask(task.title, task.type, {
          ...task,
          assigneeId: newAssignee.id,
          assigneeName: newAssignee.name,
          description: `${task.description}\n[自动调整] ${reassignReason}，已调整为${newAssignee.name}`,
        });
      }
    }

    return task;
  }

  /**
   * 生成任务摘要（用于展示）
   */
  generateTaskSummary(tasks: Task[]): string {
    if (tasks.length === 0) return '暂无任务';

    const lines: string[] = [];
    
    for (const task of tasks) {
      const assignee = task.assigneeName ? ` @${task.assigneeName}` : '';
      const status = task.status === 'pending' ? '📋' : task.status === 'completed' ? '✅' : '🔄';
      lines.push(`${status} ${task.title}${assignee}`);
    }

    return lines.join('\n');
  }
}

import { FamilyMember, createFamilyMember, MemberRole } from '../model/FamilyMember';
import { FamilyScene, createFamilyScene } from '../model/FamilyScene';
import { MemoryTask, createMemoryTask, MemoryEntityType } from '../model/MemoryTask';
import { DistributedDataService, DataStoreKeys } from './DistributedDataService';

/**
 * 家庭记忆服务
 * 负责家庭成员、场景、记忆的存取管理
 * 使用分布式数据实现跨设备同步
 */
export class MemoryService {
  private dataService: DistributedDataService;
  
  // 内存缓存
  private membersCache: FamilyMember[] = [];
  private scenesCache: FamilyScene[] = [];
  private memoryTasksCache: MemoryTask[] = [];
  private isDataLoaded: boolean = false;

  // 单例模式
  private static instance: MemoryService | null = null;

  static getInstance(): MemoryService {
    if (!MemoryService.instance) {
      MemoryService.instance = new MemoryService();
    }
    return MemoryService.instance;
  }

  private constructor() {
    this.dataService = DistributedDataService.getInstance();
    // 延迟加载数据
    this.loadFromStorage();
  }

  /**
   * 从分布式存储加载数据
   */
  private async loadFromStorage(): Promise<void> {
    try {
      await this.dataService.initialize();
      
      const [members, scenes, tasks] = await Promise.all([
        this.dataService.getObject<FamilyMember[]>(DataStoreKeys.FAMILY_MEMBERS),
        this.dataService.getObject<FamilyScene[]>(DataStoreKeys.FAMILY_SCENES),
        this.dataService.getObject<MemoryTask[]>(DataStoreKeys.MEMORY_TASKS),
      ]);

      this.membersCache = members ?? this.getDefaultMembers();
      this.scenesCache = scenes ?? [];
      this.memoryTasksCache = tasks ?? [];
      this.isDataLoaded = true;

      // 如果缓存为空，初始化默认数据
      if (this.membersCache.length === 0) {
        this.initDefaultMembers();
      }
      
      console.info('Memory data loaded from storage');
    } catch (error) {
      console.error('Failed to load memory data:', error);
      this.initDefaultMembers();
    }
  }

  /**
   * 初始化默认成员
   */
  private initDefaultMembers(): void {
    const mom = createFamilyMember('妈妈', '母亲', 'elder');
    mom.healthNotes.push('腰不好');
    mom.constraints.push('避免提重物');
    this.membersCache.push(mom);

    const dad = createFamilyMember('爸爸', '父亲', 'elder');
    dad.healthNotes.push('高血压');
    this.membersCache.push(dad);

    const spouse = createFamilyMember('老公', '配偶', 'adult');
    this.membersCache.push(spouse);

    this.saveMembers();
  }

  /**
   * 保存到分布式存储
   */
  private async saveMembers(): Promise<void> {
    await this.dataService.putObject(DataStoreKeys.FAMILY_MEMBERS, this.membersCache);
  }

  private async saveScenes(): Promise<void> {
    await this.dataService.putObject(DataStoreKeys.FAMILY_SCENES, this.scenesCache);
  }

  private async saveMemoryTasks(): Promise<void> {
    await this.dataService.putObject(DataStoreKeys.MEMORY_TASKS, this.memoryTasksCache);
  }

  // ==================== 家庭成员操作 ====================

  /**
   * 获取所有家庭成员（异步）
   */
  async getAllMembers(): Promise<FamilyMember[]> {
    if (!this.isDataLoaded) {
      await this.loadFromStorage();
    }
    return [...this.membersCache];
  }

  /**
   * 获取所有家庭成员（同步，缓存）
   */
  getAllMembersSync(): FamilyMember[] {
    return [...this.membersCache];
  }

  /**
   * 根据ID获取成员
   */
  getMemberById(id: string): FamilyMember | undefined {
    return this.membersCache.find(m => m.id === id);
  }

  /**
   * 根据名称查找成员
   */
  getMemberByName(name: string): FamilyMember | undefined {
    return this.membersCache.find(
      m => m.name === name || m.name.includes(name)
    );
  }

  /**
   * 添加或更新家庭成员
   */
  async saveMember(member: FamilyMember): Promise<void> {
    member.updatedAt = Date.now();
    member.lastMentioned = Date.now();
    
    const index = this.membersCache.findIndex(m => m.id === member.id);
    if (index >= 0) {
      this.membersCache[index] = member;
    } else {
      this.membersCache.push(member);
    }
    
    await this.saveMembers();
  }

  /**
   * 从文本中提取并保存成员
   */
  async saveMemberFromText(name: string, relation?: string, role?: MemberRole): Promise<FamilyMember> {
    let member = this.getMemberByName(name);
    if (!member) {
      member = createFamilyMember(name, relation ?? '未知关系', role ?? 'other');
      this.membersCache.push(member);
    }
    await this.saveMember(member);
    return member;
  }

  /**
   * 为成员添加健康备注
   */
  async addHealthNote(memberId: string, note: string): Promise<boolean> {
    const member = this.getMemberById(memberId);
    if (member) {
      if (!member.healthNotes.includes(note)) {
        member.healthNotes.push(note);
        member.updatedAt = Date.now();
        await this.saveMembers();
      }
      return true;
    }
    return false;
  }

  /**
   * 为成员添加照料约束
   */
  async addConstraint(memberId: string, constraint: string): Promise<boolean> {
    const member = this.getMemberById(memberId);
    if (member) {
      if (!member.constraints.includes(constraint)) {
        member.constraints.push(constraint);
        member.updatedAt = Date.now();
        await this.saveMembers();
      }
      return true;
    }
    return false;
  }

  /**
   * 删除家庭成员
   */
  async removeMember(memberId: string): Promise<boolean> {
    const index = this.membersCache.findIndex(m => m.id === memberId);
    if (index >= 0) {
      this.membersCache.splice(index, 1);
      await this.saveMembers();
      return true;
    }
    return false;
  }

  // ==================== 家庭场景操作 ====================

  /**
   * 获取所有场景
   */
  getAllScenes(): FamilyScene[] {
    return [...this.scenesCache];
  }

  /**
   * 获取或创建场景
   */
  async getOrCreateScene(name: string, participants: string[] = []): Promise<FamilyScene> {
    let scene = this.scenesCache.find(s => s.name === name);
    if (!scene) {
      scene = createFamilyScene(name, participants);
      this.scenesCache.push(scene);
      await this.saveScenes();
    }
    return scene;
  }

  // ==================== 记忆任务操作 ====================

  /**
   * 获取所有记忆任务
   */
  getAllMemoryTasks(): MemoryTask[] {
    return [...this.memoryTasksCache];
  }

  /**
   * 保存记忆任务
   */
  async saveMemoryTask(task: MemoryTask): Promise<void> {
    const index = this.memoryTasksCache.findIndex(t => t.id === task.id);
    if (index >= 0) {
      this.memoryTasksCache[index] = task;
    } else {
      this.memoryTasksCache.push(task);
    }
    await this.saveMemoryTasks();
  }

  /**
   * 从文本中识别并保存记忆
   * 核心方法：从用户指令中提取需要记忆的内容
   */
  async recognizeAndSave(
    text: string,
    sourceMemberId?: string
  ): Promise<MemoryTask | null> {
    const lowerText = text.toLowerCase();
    
    // 健康类关键词
    const healthKeywords = ['腰不好', '高血压', '心脏病', '糖尿病', '腿脚不便', '视力不好'];
    const healthMatch = healthKeywords.find(k => lowerText.includes(k));
    
    // 约束类关键词
    const constraintKeywords = ['避免提重物', '不能剧烈运动', '需要休息', '别让她', '别让他'];
    const constraintMatch = constraintKeywords.find(k => lowerText.includes(k));
    
    // 偏好类关键词
    const preferenceKeywords = ['喜欢吃', '喜欢喝', '不喜欢', '讨厌'];
    const preferenceMatch = preferenceKeywords.find(k => lowerText.includes(k));

    let entityType: MemoryEntityType = 'other';
    let summary = text;

    if (healthMatch) {
      entityType = 'health';
      summary = healthMatch;
    } else if (constraintMatch) {
      entityType = 'constraint';
      summary = constraintMatch;
    } else if (preferenceMatch) {
      entityType = 'preference';
    }

    const task = createMemoryTask(text, sourceMemberId ?? 'system', entityType, summary);
    task.remembered = true;
    await this.saveMemoryTask(task);
    return task;
  }

  /**
   * 查询相关记忆
   * 根据成员ID或关键词查找相关记忆
   */
  queryRelatedMemories(
    memberId?: string,
    keywords?: string[]
  ): MemoryTask[] {
    let tasks = [...this.memoryTasksCache];

    if (memberId) {
      tasks = tasks.filter(t => 
        t.sourceMemberId === memberId || 
        t.relatedMembers.includes(memberId)
      );
    }

    if (keywords && keywords.length > 0) {
      tasks = tasks.filter(t => {
        const searchText = (t.content + ' ' + t.summary + ' ' + t.tags.join(' ')).toLowerCase();
        return keywords.some(k => searchText.includes(k.toLowerCase()));
      });
    }

    return tasks;
  }

  /**
   * 获取成员的特殊约束（用于任务分配时规避）
   */
  getMemberConstraints(memberId: string): string[] {
    const member = this.getMemberById(memberId);
    return member ? [...(member.healthNotes ?? []), ...(member.constraints ?? [])] : [];
  }

  /**
   * 清空所有数据（测试用）
   */
  async clearAll(): Promise<void> {
    this.membersCache = [];
    this.scenesCache = [];
    this.memoryTasksCache = [];
    
    await Promise.all([
      this.saveMembers(),
      this.saveScenes(),
      this.saveMemoryTasks(),
    ]);
  }
}

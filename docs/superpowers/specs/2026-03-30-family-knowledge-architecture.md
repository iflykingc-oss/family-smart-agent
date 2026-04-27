# 家庭智能中枢 · 自研知识架构

> 版本：v1.0  
> 日期：2026-03-30  
> 定位：完全自研，不依赖华为 AI 的记忆和学习能力

---

## 1. 架构分层

```
┌─────────────────────────────────────────────────┐
│              对话接口层（Chat Interface）          │
└──────────────────┬────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│              家庭大脑层（Family Brain）            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │ 知识图谱    │  │ 模式学习器  │  │ 场景引擎 │ │
│  │ Knowledge   │  │ Pattern     │  │ Scene    │ │
│  │ Graph       │  │ Learner     │  │ Engine   │ │
│  └─────────────┘  └─────────────┘  └─────────┘ │
└──────────────────┬────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│              约束推理层（Constraint Engine）       │
│         健康约束 + 照料规则 + 任务分配            │
└──────────────────┬────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────┐
│              华为对接层（Harmony Adapter）         │
│     小艺意图 / Calendar / Push / 设备管理          │
└─────────────────────────────────────────────────┘
```

---

## 2. 核心模块设计

### 2.1 知识图谱（KnowledgeGraph）

**职责：** 存储家庭成员、健康、偏好、关系

**三层记忆（借鉴 ByteRover）：**

| 类型 | 内容 | 示例 |
|------|------|------|
| **Semantic** | 事实性知识 | "妈妈腰不好" |
| **Procedural** | 行为模式 | "爸爸喜欢下午做事" |
| **Episodic** | 历史事件 | "2026-03-30 组织了野餐" |

**数据结构：**
```typescript
// 语义记忆
interface SemanticMemory {
  id: string;
  type: 'health' | 'preference' | 'constraint' | 'relation';
  subjectId: string;      // 关联成员
  content: string;        // "腰不好"
  summary: string;        // AI 摘要
  confidence: number;     // 置信度
  sourceTaskId?: string;  // 来源任务
  usageCount: number;     // 被调用次数
  createdAt: number;
  updatedAt: number;
}

// 程序记忆（行为模式）
interface ProceduralMemory {
  id: string;
  pattern: string;        // "爸爸的任务安排在下午"
  trigger: string[];      // 触发词
  action: string;         // 动作
  confidence: number;
  evidence: string[];      // 来源任务ID列表
  usageCount: number;
  autoApply: boolean;     // 是否自动应用
}

// 情景记忆（历史）
interface EpisodicMemory {
  id: string;
  type: 'event' | 'task' | 'decision';
  content: string;
  timestamp: number;
  relatedMembers: string[];
  relatedScene?: string;
}
```

---

### 2.2 模式学习器（PatternLearner）

**职责：** 从任务执行历史中自动发现规律

**学习流程：**
```
1. 观察：用户完成了一个任务
2. 提取：这次任务的关键特征（谁、什么时间、分配给谁）
3. 对比：和历史模式是否相似
4. 匹配：是否有现有模式匹配？
   → 有：模式使用次数 +1
   → 无：创建新模式候选
5. 验证：连续3次相同模式 → 提升为高置信度规则
```

**核心算法：**
```typescript
// 模式发现
interface PatternDiscovery {
  // 从任务历史中发现规律
  discoverFromHistory(tasks: Task[]): Pattern[];
  
  // 模式匹配
  matchPattern(intent: Intent): Pattern | null;
  
  // 模式验证
  validatePattern(pattern: Pattern): boolean;
  
  // 模式应用
  applyPattern(pattern: Pattern, task: Task): Task;
}

// 规则蒸馏（借鉴 self-improving-agent）
interface RuleDistillation {
  // 观察行为
  observe(action: AgentAction): void;
  
  // 识别重复
  findRecurring(): Pattern[];
  
  // 蒸馏规则
  distill(pattern: Pattern): LearnedRule;
  
  // 规则优先级
  prioritize(rules: LearnedRule[]): LearnedRule[];
}
```

---

### 2.3 场景引擎（SceneEngine）

**职责：** 管理场景模板（Combo），识别场景关联

**Floatboat Combo 对应设计：**
```typescript
interface FamilyScene {
  id: string;
  name: string;           // "野餐"
  description: string;
  
  // 参与成员
  participants: string[];
  
  // 典型任务流程
  typicalTasks: TaskTemplate[];
  
  // 默认设备
  defaultDevices: string[];
  
  // 关联资源
  resources: string[];     // 采购清单模板等
  
  // 使用统计
  usageCount: number;
  lastUsed: number;
  
  // 自动推荐阈值
  autoRecommendThreshold: number;  // 使用3次以上自动推荐
}

// 场景识别
interface SceneRecognition {
  // 从意图中识别场景
  recognizeFromIntent(intent: Intent): FamilyScene | null;
  
  // 场景补全
  completeScene(scene: FamilyScene, intent: Intent): FamilyScene;
  
  // 场景推荐
  recommendScene(currentIntent: Intent): FamilyScene[];
}
```

---

### 2.4 约束推理引擎（ConstraintEngine）

**职责：** 健康约束自动传导到任务分配

**约束传递逻辑：**
```
输入：任务"搬运物资"
     成员"妈妈"（有约束：腰不好 → 避免提重物）
     
推理：
1. 识别任务特征：体力型、需要提重物
2. 匹配约束：妈妈有"腰不好"约束
3. 触发规则：腰不好 → 避免提重物
4. 执行动作：自动规避分配给妈妈

输出：任务不分配给妈妈，建议分配给爸爸
```

**约束类型：**
```typescript
interface Constraint {
  id: string;
  type: 'health' | 'schedule' | 'preference' | 'relationship';
  
  // 约束主体
  subjectId: string;      // 谁
  subjectType: 'member' | 'scene';
  
  // 约束内容
  condition: string;       // "腰不好"
  forbiddenActions: string[];  // 禁止的动作
  allowedActions: string[];     // 允许的动作（可选）
  
  // 推理规则
  rules: ConstraintRule[];
}

interface ConstraintRule {
  // IF: 任务包含这些特征
  if: TaskFeature[];
  // THEN: 执行这个动作
  then: Action;
  // 置信度
  confidence: number;
}
```

---

## 3. 数据流设计

```
用户输入："妈妈腰不好，帮我安排家务"
    ↓
┌─────────────────────────────────────┐
│         知识图谱查询                 │
│  查找"妈妈"相关语义记忆              │
│  → 发现：腰不好 → 禁止提重物          │
└──────────────────┬──────────────────┘
                   ↓
┌─────────────────────────────────────┐
│         约束推理引擎                 │
│  任务"安排家务" → 需要分配          │
│  识别约束：妈妈禁止提重物            │
│  推理结果：家务中的体力活不分配给妈妈 │
└──────────────────┬──────────────────┘
                   ↓
┌─────────────────────────────────────┐
│         模式学习器（可选）           │
│  检查是否有相关行为模式              │
│  → 无历史模式，无需学习              │
└──────────────────┬──────────────────┘
                   ↓
┌─────────────────────────────────────┐
│         场景引擎（可选）             │
│  暂无相关场景模板                    │
│  → 不推荐 Combo                      │
└──────────────────┬──────────────────┘
                   ↓
┌─────────────────────────────────────┐
│         输出结果                     │
│  生成任务：                          │
│  - 扫地/擦桌子（轻活）→ 分配给妈妈  │
│  - 搬运杂物（重活）→ 分配给爸爸     │
│  记忆更新：                          │
│  - 存储"妈妈腰不好"语义记忆         │
└─────────────────────────────────────┘
```

---

## 4. 与华为 AI 的协作模式

**华为 AI（输入层）：**
- 语音识别 → 文本
- 文本意图分类
- 实体提取

**我们自研（大脑层）：**
- 知识图谱查询
- 约束推理
- 模式学习
- 场景推荐

**华为 AI（输出层）：**
- 自然语言生成回复
- 设备控制指令

**核心原则：华为做"理解"，我们做"记忆"和"推理"**

---

## 5. 优先级排序

| 优先级 | 模块 | 价值 |
|--------|------|------|
| P0 | 知识图谱（Semantic + 约束）| 评委直接看到"记住"效果 |
| P0 | 约束推理引擎 | 差异化核心 |
| P1 | 模式学习器 | 越用越聪明 |
| P1 | 场景引擎 | Combo 推荐 |
| P2 | 情景记忆 | 历史追溯 |

---

*架构设计完成，代码实现见后续文档。*

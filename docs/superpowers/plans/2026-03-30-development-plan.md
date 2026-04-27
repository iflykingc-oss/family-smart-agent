# 家庭智联事务中枢 · 开发任务计划

> 版本：v1.0  
> 日期：2026-03-30  
> 状态：待执行

---

## 项目概述

**目标：** 基于鸿蒙生态的小艺智能体，实现家庭级记忆 + 意图理解 + 协同推送

**技术栈：**
- 框架：HarmonyOS ArkUI
- 语言：ArkTS
- AI层：小艺MCP + Gemini（赛后）
- 存储：鸿蒙分布式数据管理
- 部署：华为应用市场

**参赛截止：** 2026-05-15（提交）| 2026-06-12（决赛）

---

## MVP 功能范围

| 场景 | 功能 | 优先级 |
|------|------|--------|
| 意图理解 | 复杂口语指令 → 结构化意图 + 实体提取 | P0 |
| 家庭记忆 | 成员角色/健康特征/照料约束 存取 | P0 |
| 任务编排 | 意图 → 分类 → 绑定成员 → 生成任务 | P0 |
| 协同推送 | 任务 → 鸿蒙日历/Push → 多设备推送 | P0 |
| 设备选择 | UI选择推送设备（手机/平板/智慧屏/音箱） | P1 |

**不含：** 多轮对话追问、每周复盘归纳（赛后做）

---

## 任务拆解

### 阶段一：项目初始化（Day 1）

---

**Task 1: 创建鸿蒙项目骨架**

- [ ] 创建 `entry/src/main/` 目录结构
- [ ] 配置 `module.json5` 权限（日历、通知、分布式）
- [ ] 配置小艺MCP接入
- [ ] 配置 ArkUI 页面路由

**文件：**
- 创建：`entry/src/main/module.json5`
- 创建：`entry/src/main/ets/pages/Index.ets`
- 创建：`entry/src/main/ets/pages/Memory.ets`
- 创建：`entry/src/main/ets/pages/Devices.ets`

---

**Task 2: 创建应用入口页面**

- [ ] 首页：语音/文本输入框 + 对话展示
- [ ] TabBar：首页 / 记忆 / 设备

**文件：**
- 修改：`entry/src/main/ets/pages/Index.ets`
- 创建：`entry/src/main/ets/components/ChatBubble.ets`

---

### 阶段二：核心能力开发（Day 2-3）

---

**Task 3: 意图理解层**

- [ ] 调用小艺MCP意图识别
- [ ] 解析结构化意图（事件类型、成员、时间、动作）
- [ ] 测试指令："下周三代家人去公园野餐..."

**文件：**
- 创建：`entry/src/main/ets/services/IntentService.ets`
- 创建：`entry/src/main/ets/model/Intent.ets`

---

**Task 4: 家庭记忆图谱**

- [ ] 定义数据模型（FamilyMember、FamilyScene、MemoryTask）
- [ ] 实现分布式数据存储
- [ ] 实现记忆存取 API
- [ ] 测试："妈妈腰不好" → 记住 → "安排家务"自动规避

**文件：**
- 创建：`entry/src/main/ets/model/FamilyMember.ets`
- 创建：`entry/src/main/ets/model/FamilyScene.ets`
- 创建：`entry/src/main/ets/model/MemoryTask.ets`
- 创建：`entry/src/main/ets/services/MemoryService.ets`

---

**Task 5: 任务编排引擎**

- [ ] 意图 → 任务拆分逻辑
- [ ] 成员绑定（根据角色/约束分配）
- [ ] 生成可执行任务列表
- [ ] 任务状态管理

**文件：**
- 创建：`entry/src/main/ets/model/Task.ets`
- 创建：`entry/src/main/ets/services/TaskOrchestrationService.ets`

---

### 阶段三：协同推送（Day 4）

---

**Task 6: 鸿蒙日历集成**

- [ ] 调用日历能力创建提醒
- [ ] 设置时间、重复、提醒方式
- [ ] 关联到指定成员

**文件：**
- 创建：`entry/src/main/ets/services/CalendarService.ets`

---

**Task 7: Push Kit 推送**

- [ ] 接入华为 Push Kit
- [ ] 实现多设备推送（手机/平板/智慧屏/音箱）
- [ ] 推送卡片展示

**文件：**
- 创建：`entry/src/main/ets/services/PushService.ets`
- 修改：`entry/src/main/ets/pages/Devices.ets`

---

**Task 8: 设备选择UI**

- [ ] 获取可用设备列表
- [ ] 设备选择组件
- [ ] 多选/单选切换

**文件：**
- 修改：`entry/src/main/ets/pages/Devices.ets`
- 创建：`entry/src/main/ets/components/DeviceCard.ets`

---

### 阶段四：集成与演示（Day 5）

---

**Task 9: 端到端串联**

- [ ] 首页输入 → 意图解析 → 记忆查询 → 任务生成 → 推送执行
- [ ] 全流程打通测试

**文件：**
- 修改：`entry/src/main/ets/pages/Index.ets`

---

**Task 10: 演示场景打磨**

- [ ] 场景1："下周三代家人去公园野餐..."
- [ ] 场景2："妈妈腰不好，帮我安排家务"
- [ ] 优化展示效果，3分钟内完成演示

---

**Task 11: 作品提交**

- [ ] 检查所有权限配置
- [ ] 编译签名
- [ ] 提交 HarmonyOS 应用市场 / 比赛系统

---

## 任务依赖关系

```
Task1 → Task2 → Task3 ──┐
                         ├── Task5 → Task9 → Task10 → Task11
Task4 ───────────────────┤
                         │
Task6 ── Task7 ── Task8 ─┘
```

---

## 时间估算

| 阶段 | 任务 | 预计时间 |
|------|------|---------|
| Day 1 | 初始化 + 入口页面 | 2-3h |
| Day 2 | 意图理解 + 记忆图谱 | 3-4h |
| Day 3 | 任务编排引擎 | 2-3h |
| Day 4 | 日历 + 推送 + 设备选择 | 3-4h |
| Day 5 | 集成 + 演示打磨 + 提交 | 2-3h |

**总计：约 12-17 小时**

---

## 关键检查点

1. **Day 1 结束：** 项目能跑起来，有基础 UI
2. **Day 3 结束：** 意图理解和记忆图谱核心完成
3. **Day 4 结束：** 全流程跑通
4. **Day 5：** 打磨 + 提交

---

## 潜在风险

| 风险 | 影响 | 缓解方案 |
|------|------|---------|
| 小艺MCP调试环境缺失 | 无法本地测试意图识别 | 使用华为云调试环境 |
| 分布式数据同步问题 | 多设备协同失败 | 先做单设备推送，协同赛后补 |
| 决赛现场网络不稳定 | 云端能力失效 | 核心流程支持弱网降级 |

---

*计划完成，等待执行。*

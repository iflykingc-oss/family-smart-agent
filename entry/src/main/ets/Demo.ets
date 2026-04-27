/**
 * ============================================================================
 * 家庭认知管家·使用示例
 * 演示核心功能
 * ============================================================================
 */

import { FamilyEngine, FamilyRole, FamilyDevice } from './services/engine/FamilyEngine';

// ===== 创建引擎 =====
const engine = new FamilyEngine();

// ===== 初始化 =====
async function initDemo() {
  await engine.init();

  // 添加成员（带设备和约束）
  engine.addMember(
    'mom001',
    '妈妈',
    FamilyRole.MOTHER,
    ['妈妈', '老妈', '妈'],
    [
      { deviceId: 'watch_mom', deviceName: '妈妈手表', deviceType: 'watch', isOnline: true, priority: 100 },
      { deviceId: 'phone_mom', deviceName: '妈妈手机', deviceType: 'phone', isOnline: true, priority: 90 }
    ],
    ['喜欢温柔提醒'],  // 情感标签
    ['腰不好', '胃寒']   // 约束
  );

  engine.addMember(
    'dad001',
    '爸爸',
    FamilyRole.FATHER,
    ['爸爸', '老爸', '爸'],
    [
      { deviceId: 'phone_dad', deviceName: '爸爸手机', deviceType: 'phone', isOnline: true, priority: 90 }
    ],
    ['喜欢简洁提醒'],
    ['高血压']  // 约束
  );

  engine.addMember(
    'son001',
    '儿子',
    FamilyRole.SON,
    ['儿子', '娃', '孩子'],
    [
      { deviceId: 'pad_son', deviceName: '学习平板', deviceType: 'tablet', isOnline: true, priority: 100 }
    ],
    ['喜欢鼓励']
    // 无约束
  );
}

// ===== 场景演示 =====

/**
 * 场景1：随口叮嘱，AI记住
 */
function scene1_RememberConstraint() {
  console.log('========== 场景1：随口叮嘱 ==========');

  const result = engine.parseCommand('妈妈腰不好，帮我安排家务');

  console.log('识别成员:', result.memberName);
  console.log('生成任务:', result.tasks.length, '个');
  console.log('约束警告:', result.constraintWarnings);
  console.log('温情确认:', result.warmConfirmations);

  // 约束自动记录
  const constraints = engine.getMemberConstraints('mom001');
  console.log('妈妈现有约束:', constraints);
}

/**
 * 场景2：定时提醒，自动生成
 */
function scene2_TimedReminder() {
  console.log('========== 场景2：定时提醒 ==========');

  const result = engine.parseCommand('每天早上8点提醒妈妈吃药');

  console.log('识别成员:', result.memberName);
  console.log('生成任务:', result.tasks[0]?.content);
  console.log('触发时间:', result.tasks[0]?.triggerTime);
  console.log('生成规则:', result.rules[0]?.cronExpression);
}

/**
 * 场景3：智能分配，规避约束
 */
function scene3_SmartAssign() {
  console.log('========== 场景3：智能分配 ==========');

  // 询问安排搬运物资
  const assign = engine.smartAssign('搬运物资');

  console.log('分配给:', assign.memberName);
  console.log('原因:', assign.reason);
  // 妈妈有腰伤约束 → 分配给爸爸或儿子
}

/**
 * 场景4：温情推送
 */
function scene4_WarmPush() {
  console.log('========== 场景4：温情推送 ==========');

  const push = engine.generateWarmPush('mom001', '妈妈该吃药了');

  console.log('原始内容:', '妈妈该吃药了');
  console.log('温情内容:', push.warmMessage);
  console.log('场景类型:', push.scene);
}

/**
 * 场景5：儿童照料
 */
function scene5_ChildCare() {
  console.log('========== 场景5：育儿提醒 ==========');

  const result = engine.parseCommand('晚上6点提醒儿子写作业');

  console.log('识别成员:', result.memberName);
  console.log('生成任务:', result.tasks[0]?.content);
  console.log('温情确认:', result.warmConfirmations);
}

// ===== 运行演示 =====

async function runDemo() {
  await initDemo();

  scene1_RememberConstraint();
  scene2_TimedReminder();
  scene3_SmartAssign();
  scene4_WarmPush();
  scene5_ChildCare();

  // 查看所有成员
  console.log('========== 家庭成员 ==========');
  const members = engine.getMembers();
  for (const m of members) {
    const constraints = engine.getMemberConstraints(m.memberId);
    console.log(`${m.name}: ${m.devices.length}台设备, ${constraints.length}个约束`);
  }
}

runDemo().catch(console.error);

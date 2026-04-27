/**
 * ============================================================================
 * 演示数据预置 - DemoData
 * 用于演示和测试的预置数据
 * ============================================================================
 */

import { HiLog } from '@kit.BasicServicesKit';
import { UserEntity } from '../../domain/entities/UserEntity';
import { SkillEntity, SkillCategory, SkillDifficulty } from '../../domain/entities/SkillEntity';
import { UserRepository } from '../../data/repositories/impl/UserRepository';
import { SkillRepository } from '../../data/repositories/impl/SkillRepository';

/**
 * 演示数据预置
 */
export class DemoData {
  private static instance: DemoData | null = null;
  
  private userRepository: UserRepository;
  private skillRepository: SkillRepository;

  /**
   * 获取单例实例
   */
  static getInstance(): DemoData {
    if (!DemoData.instance) {
      DemoData.instance = new DemoData();
    }
    return DemoData.instance;
  }

  private constructor() {
    this.userRepository = UserRepository.getInstance();
    this.skillRepository = SkillRepository.getInstance();
    HiLog.info("DemoData", "初始化");
  }

  /**
   * 预置演示数据
   */
  async seed(): Promise<void> {
    HiLog.info("DemoData", "开始预置演示数据");
    
    // 预置用户
    await this.seedUsers();
    
    // 预置技能
    await this.seedSkills();
    
    HiLog.info("DemoData", "演示数据预置完成");
  }

  /**
   * 预置用户
   */
  private async seedUsers(): Promise<void> {
    const users = [
      new UserEntity('demo_user_001', '演示用户'),
      new UserEntity('test_user_001', '测试用户'),
    ];
    
    for (const user of users) {
      try {
        await this.userRepository.save(user);
        HiLog.info("DemoData", `预置用户：${user.name}`);
      } catch (error: any) {
        HiLog.warn("DemoData", `用户已存在：${user.name}`);
      }
    }
  }

  /**
   * 预置技能
   */
  private async seedSkills(): Promise<void> {
    const skills = [
      // Excel 技能
      new SkillEntity(
        'excel_basic',
        'Excel 基础',
        SkillCategory.OFFICE,
        SkillDifficulty.BEGINNER,
        [
          { stepNumber: 1, title: '认识 Excel 界面', content: 'Excel 是一个表格软件，由行和列组成。每一格叫做"单元格"。', keyPoint: '行是横的（1,2,3...），列是竖的（A,B,C...）', estimatedTime: 5 },
          { stepNumber: 2, title: '单元格操作', content: '点击单元格就能输入内容，输入完按回车确认。', keyPoint: '双击单元格可以直接编辑', estimatedTime: 8 },
          { stepNumber: 3, title: '简单公式', content: '公式用等号"="开头。比如"=A1+B1"就是把 A1 和 B1 的数加起来。', keyPoint: '公式要用等号开头，否则会当作文本', estimatedTime: 10 },
          { stepNumber: 4, title: '格式设置', content: '可以设置单元格的字体、颜色、边框。', keyPoint: '选中后右键设置单元格格式', estimatedTime: 5 },
        ],
        [],
        ['做报表', '统计数据'],
        ['办公', '数据', 'Excel'],
        28
      ),
      
      // 微信技能
      new SkillEntity(
        'wechat_basic',
        '微信使用',
        SkillCategory.LIFE,
        SkillDifficulty.BEGINNER,
        [
          { stepNumber: 1, title: '添加好友', content: '点击右上角"+"号，选择"添加朋友"。可以扫码添加、搜索手机号添加。', keyPoint: '扫码是最快的方式', estimatedTime: 5 },
          { stepNumber: 2, title: '发送消息', content: '在聊天框输入文字，点击发送按钮或按回车。', keyPoint: '2 分钟内可撤回', estimatedTime: 3 },
          { stepNumber: 3, title: '发朋友圈', content: '点击朋友圈入口，点击右上角相机发布。', keyPoint: '可以设置谁可以看', estimatedTime: 5 },
          { stepNumber: 4, title: '使用支付', content: '我->支付，可以付款、收款、缴费。', keyPoint: '支付密码要保密', estimatedTime: 8 },
        ],
        [],
        ['聊天', '支付', '发朋友圈'],
        ['社交', '支付', '微信'],
        21
      ),
      
      // 鸿蒙协同技能
      new SkillEntity(
        'harmony_share',
        '鸿蒙设备协同',
        SkillCategory.DIGITAL,
        SkillDifficulty.INTERMEDIATE,
        [
          { stepNumber: 1, title: '登录同一个华为账号', content: '确保手机、平板、电脑都登录了同一个华为账号。', keyPoint: '在设置->华为账号里登录', estimatedTime: 3 },
          { stepNumber: 2, title: '开启跨设备权限', content: '在手机设置里，找到"跨设备协同"选项，开启需要的权限。', keyPoint: '跨设备剪贴板、文件互传', estimatedTime: 5 },
          { stepNumber: 3, title: '多屏协同', content: '打开电脑的"华为电脑管家"，用手机碰一碰电脑的 NFC 标签。', keyPoint: 'NFC 标签通常在电脑触控板附近', estimatedTime: 10 },
        ],
        ['wechat_basic'],
        ['手机电脑互传', '接打电话'],
        ['鸿蒙', '协同', '多屏'],
        18
      ),
    ];
    
    for (const skill of skills) {
      try {
        await this.skillRepository.save(skill);
        HiLog.info("DemoData", `预置技能：${skill.name}`);
      } catch (error: any) {
        HiLog.warn("DemoData", `技能已存在：${skill.name}`);
      }
    }
  }

  /**
   * 清空演示数据
   */
  async clear(): Promise<void> {
    HiLog.info("DemoData", "清空演示数据");
    
    // TODO: 实现清空逻辑
  }

  /**
   * 检查是否已预置
   */
  async isSeeded(): Promise<boolean> {
    try {
      const users = await this.userRepository.findAll();
      return users.length > 0;
    } catch (error) {
      return false;
    }
  }
}

/**
 * 便捷函数
 */
export async function seedDemoData(): Promise<void> {
  const demoData = DemoData.getInstance();
  const isSeeded = await demoData.isSeeded();
  
  if (!isSeeded) {
    await demoData.seed();
  }
}

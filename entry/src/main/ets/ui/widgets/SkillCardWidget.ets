/**
 * ============================================================================
 * 技能卡片组件 - SkillCardWidget
 * 纯 UI 组件，可复用
 * ============================================================================
 */

import { SkillEntity, SkillCategory, SkillDifficulty } from '../../domain/entities/SkillEntity';

/**
 * 技能卡片属性
 */
export interface SkillCardProps {
  skill: SkillEntity;
  progress?: number;
  onClick?: () => void;
}

@Component
export struct SkillCardWidget {
  @Prop skill: SkillEntity = new SkillEntity(
    'demo',
    '演示技能',
    SkillCategory.LIFE,
    SkillDifficulty.BEGINNER,
    []
  );
  @Prop progress: number = 0;
  @Prop onClick?: () => void = undefined;

  build() {
    Column() {
      // 标题和难度
      Row() {
        Text(this.skill.name)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        // 难度标签
        Text(this.getDifficultyText())
          .fontSize(10)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.getDifficultyColor())
          .borderRadius(12)
          .fontColor('#FFFFFF')
      }
      .width('100%')

      // 类别标签
      Row() {
        Text(this.getCategoryText())
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ top: 8 })

      // 进度条
      if (this.progress > 0) {
        Column() {
          Row() {
            Text(`进度：${this.progress}%`)
              .fontSize(12)
              .fontColor('#007AFF')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Progress({
            value: this.progress,
            total: 100,
            type: ProgressType.Linear
          })
            .color('#007AFF')
            .width('100%')
            .height(4)
            .margin({ top: 8 })
        }
        .width('100%')
        .margin({ top: 12 })
      }

      // 标签
      if (this.skill.tags.length > 0) {
        Row() {
          ForEach(this.skill.tags.slice(0, 3), (tag: string) => {
            Text(`#${tag}`)
              .fontSize(10)
              .fontColor('#007AFF')
              .margin({ right: 8 })
          })
        }
        .width('100%')
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .onClick(() => {
      if (this.onClick) {
        this.onClick();
      }
    })
    .animation({
      duration: 200,
      curve: Curve.EaseInOut,
    })
  }

  /**
   * 获取难度文本
   */
  private getDifficultyText(): string {
    switch (this.skill.difficulty) {
      case SkillDifficulty.BEGINNER:
        return '⭐ 入门';
      case SkillDifficulty.INTERMEDIATE:
        return '⭐⭐ 进阶';
      case SkillDifficulty.ADVANCED:
        return '⭐⭐⭐ 高级';
      default:
        return '未知';
    }
  }

  /**
   * 获取难度颜色
   */
  private getDifficultyColor(): string {
    switch (this.skill.difficulty) {
      case SkillDifficulty.BEGINNER:
        return '#34C759';
      case SkillDifficulty.INTERMEDIATE:
        return '#FF9500';
      case SkillDifficulty.ADVANCED:
        return '#FF3B30';
      default:
        return '#999999';
    }
  }

  /**
   * 获取类别文本
   */
  private getCategoryText(): string {
    const categoryMap: Record<SkillCategory, string> = {
      [SkillCategory.OFFICE]: '📊 办公技能',
      [SkillCategory.LIFE]: '🏠 生活技能',
      [SkillCategory.DIGITAL]: '📱 数字技能',
      [SkillCategory.HEALTH]: '💪 健康技能',
      [SkillCategory.FINANCIAL]: '💰 财务技能',
      [SkillCategory.SOCIAL]: '💬 社交技能',
    };
    return categoryMap[this.skill.category] || '其他';
  }
}

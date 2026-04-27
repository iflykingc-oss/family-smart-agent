/**
 * ============================================================================
 * 技能库 UI - SkillsPage
 * ============================================================================
 */

import { SkillEntity, SkillCategory, SkillDifficulty } from '../../domain/entities/SkillEntity';
import { SkillCardWidget } from '../widgets/SkillCardWidget';

@Entry
@Component
struct SkillsPage {
  @State skills: SkillEntity[] = [];
  @State selectedCategory: string = '全部';
  @State isSearching: boolean = false;
  @State searchText: string = '';
  
  private categories: string[] = ['全部', '办公', '生活', '数字', '健康', '财务', '社交'];

  build() {
    Column() {
      // 标题栏
      this.TitleBar()
      
      // 搜索框
      this.SearchBar()
      
      // 分类筛选
      this.CategoryFilter()
      
      // 技能列表
      Scroll() {
        Column() {
          if (this.skills.length === 0) {
            this.EmptyView()
          } else {
            this.SkillsList()
          }
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  TitleBar() {
    Row() {
      Text('🎯 技能库')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
      
      Blank()
      
      // 统计
      Text(`共${this.skills.length}个技能`)
        .fontSize(14)
        .fontColor('#666666')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  SearchBar() {
    Row() {
      Image('🔍')
        .width(16)
        .height(16)
      
      TextInput({ placeholder: '搜索技能...', text: this.searchText })
        .layoutWeight(1)
        .fontSize(14)
        .margin({ left: 8 })
        .onChange((value: string) => {
          this.searchText = value;
          this.filterSkills();
        })
      
      if (this.searchText) {
        Image('❌')
          .width(16)
          .height(16)
          .onClick(() => {
            this.searchText = '';
            this.filterSkills();
          })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .margin({ bottom: 8 })
  }

  @Builder
  CategoryFilter() {
    Scroll() {
      Row() {
        ForEach(this.categories, (category: string) => {
          Text(category)
            .fontSize(14)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor(this.selectedCategory === category ? '#007AFF' : '#E5E5EA')
            .fontColor(this.selectedCategory === category ? '#FFFFFF' : '#333333')
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.selectedCategory = category;
              this.filterSkills();
            })
        })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
    .scrollBar(BarState.Off)
  }

  @Builder
  SkillsList() {
    ForEach(this.skills, (skill: SkillEntity) => {
      SkillCardWidget({
        skill: skill,
        onClick: () => {
          this.startLearning(skill);
        }
      })
      .margin({ bottom: 12 })
    })
  }

  @Builder
  EmptyView() {
    Column() {
      Text('📚')
        .fontSize(48)
      
      Text('暂无技能')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16 })
      
      Text('技能库正在建设中...')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })
    }
    .width('100%')
    .height(300)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 筛选技能
   */
  filterSkills() {
    // TODO: 调用 SkillRepository 查询
    // 根据分类和搜索文本筛选
  }

  /**
   * 开始学习
   */
  startLearning(skill: SkillEntity) {
    // TODO: 跳转到 TeachingPage
  }
}

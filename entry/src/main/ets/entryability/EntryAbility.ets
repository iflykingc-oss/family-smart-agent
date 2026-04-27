import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';

const TAG = 'EntryAbility';
const DOMAIN = 0x0001;

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    hilog.info(DOMAIN, TAG, 'EntryAbility onCreate');
    
    // 初始化家庭记忆服务
    // 正式项目：在这里初始化分布式数据管理
  }

  onDestroy() {
    hilog.info(DOMAIN, TAG, 'EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    // 加载主页面
    hilog.info(DOMAIN, TAG, 'EntryAbility onWindowStageCreate');
    
    windowStage.loadContent('pages/MainPage', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content. Data: %{public}s', JSON.stringify(data));
    });
  }

  onWindowStageDestroy() {
    hilog.info(DOMAIN, TAG, 'EntryAbility onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(DOMAIN, TAG, 'EntryAbility onForeground');
  }

  onBackground() {
    hilog.info(DOMAIN, TAG, 'EntryAbility onBackground');
  }
}

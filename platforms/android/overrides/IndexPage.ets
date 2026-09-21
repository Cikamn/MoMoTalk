import { CommonConstants, EventHubUtils } from 'lib_common';
import { IndexPageViewModel } from '../viewmodels/IndexPageVM';
import { ChatPage } from './chat/ChatPage';
import { CharacterPage } from './character/CharacterPage';
import { MinePageBuilder } from 'business_mine';
import { window } from '@kit.ArkUI';
import { PhoneConstants } from '../common/Constants';
import { OPEN_CHARACTER_CHAT } from '../common/CharacterStore';

@Builder
export function IndexPageBuilder() {
  IndexPage()
}

@ComponentV2
struct IndexPage {
  @Local vm: IndexPageViewModel = new IndexPageViewModel();
  @Provider() selectedIndex: number = 0;
  @Local keyboardHeight : number = 0;
  private currentWindow?: window.Window;
  private keyboardHeightCallback: (data: window.AvoidAreaOptions) => void = (data: window.AvoidAreaOptions) => {
    if (data.type === window.AvoidAreaType.TYPE_KEYBOARD) {
      this.keyboardHeight = this.getUIContext().px2vp(data.area.bottomRect.height);
    }
  };
  private openCharacterChatCallback: () => void = () => {
    this.selectedIndex = 0;
  };

  aboutToAppear(): void {
    this.vm.refreshUserInfo();
    EventHubUtils.getInstance().on(OPEN_CHARACTER_CHAT, this.openCharacterChatCallback);
    window.getLastWindow(this.getUIContext().getHostContext()).then(currentWindow => {
      this.currentWindow = currentWindow;
      currentWindow.on('avoidAreaChange', this.keyboardHeightCallback)
    })
  }

  aboutToDisappear(): void {
    this.currentWindow?.off('avoidAreaChange', this.keyboardHeightCallback);
    EventHubUtils.getInstance().off(OPEN_CHARACTER_CHAT, this.openCharacterChatCallback);
  }

  @Monitor('selectedIndex')
  onChangeTabIndex() {
    this.vm.tabModel.selectedIndex = this.selectedIndex;
  }

  build() {
    NavDestination() {
      Column() {
        Tabs({ index: $$this.selectedIndex, barPosition: BarPosition.End }) {
          TabContent() {
            ChatPage()
          }.tabBar(this.tabBarBuilder(0, 'AI对话', $r('app.media.icon_ai_dialog_on'), $r('app.media.icon_ai_dialog_off')))

          TabContent() {
            CharacterPage()
          }
          .tabBar(this.tabBarBuilder(1, '角色', $r('app.media.icon_ai_office_on'),
            $r('app.media.icon_ai_office_off')))

          TabContent() {
            MinePageBuilder()
          }.tabBar(this.tabBarBuilder(2, '我的', $r('app.media.icon_my_on'), $r('app.media.icon_my_off')))
        }
        .scrollable(false)
        .barHeight(this.keyboardHeight > 0 ? 0 : PhoneConstants.BOTTOM_TAB_BAR_HEIGHT)
        .layoutWeight(1)
        .animationDuration(0)
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          this.selectedIndex = index;
        })
      }
      .height(CommonConstants.FULL_PERCENT)
      .width(CommonConstants.FULL_PERCENT)
      .padding({
        bottom: this.keyboardHeight > 0 ? 0 : this.vm.paddingBottom,
      })
    }
    .onBackPressed(() => {
      return this.vm.onBackPressed();
    })
  }

  @Builder
  tabBarBuilder(index: number, name: string, iconCheck: Resource, iconDefault: Resource) {
    Column() {
      Image(this.selectedIndex === index ? iconCheck : iconDefault)
        .width(24)
        .height(24);
      Text(name)
        .fontColor(this.selectedIndex === index ? $r('sys.color.icon_emphasize') : $r('sys.color.icon_secondary'))
        .fontWeight(FontWeight.Medium)
        .fontSize('10')
        .margin({ top: 4 });
    }
    .width('100%');
  }
}

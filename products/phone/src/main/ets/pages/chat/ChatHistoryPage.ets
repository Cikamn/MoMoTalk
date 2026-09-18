import { RouterMap, RouterUtils } from 'lib_common';
import { NavHeaderBar } from 'lib_widget';
import { CopilotHistory } from '../../components/CopilotHistory';

@Builder
export function ChatHistoryPageBuilder() {
  ChatHistoryPage()
}

@ComponentV2
export struct ChatHistoryPage {
  @Local isDeleted: boolean = false;
  @Local storeId: string = 'Chat';

  aboutToAppear(): void {
    this.storeId = RouterUtils.getParamByName<string>(RouterMap.CHAT_HISTORY_PAGE) ?? 'Chat';
  }

  build() {
    NavDestination() {
      Column() {
        NavHeaderBar({
          title: '历史对话'
        }) {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize($r('sys.float.Title_M'))
            .fontColor([$r('sys.color.icon_primary')])
            .padding(8)
            .borderRadius(40)
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .onClick(() => {
              this.isDeleted = !this.isDeleted;
            })
        }
        CopilotHistory({
          isDeleted: this.isDeleted,
          storeId: this.storeId,
          onClickEvent: (threadId) => {
            if (!this.isDeleted) {
              RouterUtils.pop(threadId);
            }
          }
        }).padding({ left: 16, right: 16, bottom: 16 })
          .layoutWeight(1)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .height('100%')
    }.hideTitleBar(true)
  }
}

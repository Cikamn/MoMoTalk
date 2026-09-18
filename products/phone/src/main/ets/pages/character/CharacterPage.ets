import { EventHubUtils, RouterMap, RouterUtils } from 'lib_common';
import { NavHeaderBar } from 'lib_widget';
import {
  CHARACTER_CHANGED,
  CharacterProfile,
  CharacterStore,
  OPEN_CHARACTER_CHAT
} from '../../common/CharacterStore';

@ComponentV2
export struct CharacterPage {
  @Local profiles: CharacterProfile[] = [];
  @Local activeId: string = '';
  private characterChangedCallback: () => void = () => {
    this.load();
  };

  aboutToAppear(): void {
    this.load();
    EventHubUtils.getInstance().on(CHARACTER_CHANGED, this.characterChangedCallback);
  }

  aboutToDisappear(): void {
    EventHubUtils.getInstance().off(CHARACTER_CHANGED, this.characterChangedCallback);
  }

  build() {
    Column() {
      NavHeaderBar({
        title: '角色',
        isSubTitle: false,
        showBackBtn: false,
        rightPartBuilder: () => {
          this.addCharacterButton()
        }
      })

      List({ space: 12 }) {
        ForEach(this.profiles, (profile: CharacterProfile) => {
          ListItem() {
            this.characterCard(profile)
          }
        }, (profile: CharacterProfile): string => profile.id)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }

  @Builder
  addCharacterButton() {
    Button('+ 新增')
      .height(36)
      .onClick(() => {
        this.openEditor();
      })
  }

  @Builder
  characterCard(profile: CharacterProfile) {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        if (profile.avatarUri) {
          Image(profile.avatarUri)
            .width(56)
            .height(56)
            .objectFit(ImageFit.Cover)
            .borderRadius(28)
            .border({ width: 1, color: $r('sys.color.icon_emphasize') })
        } else if (profile.id === 'arona') {
          Image($r('app.media.arona_avatar_circle'))
            .width(56)
            .height(56)
            .objectFit(ImageFit.Cover)
            .borderRadius(28)
        } else {
          Stack() {
            Circle()
              .width(56)
              .height(56)
              .fill($r('sys.color.comp_background_emphasize'))
            Text(profile.displayName.slice(0, 1))
              .fontSize($r('sys.float.Title_L'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_on_primary'))
          }
          .width(56)
          .height(56)
        }

        Column({ space: 5 }) {
          Row({ space: 8 }) {
            Text(profile.displayName)
              .fontSize($r('sys.float.Subtitle_L'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
            if (profile.id === this.activeId) {
              Text('使用中')
                .fontSize($r('sys.float.Caption_M'))
                .fontColor($r('sys.color.font_emphasize'))
            }
          }
          Text(profile.description)
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: 10 }) {
        Button('编辑设定')
          .layoutWeight(1)
          .height(38)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .fontColor($r('sys.color.font_primary'))
          .onClick(() => {
            this.openEditor(profile.id);
          })
        Button(profile.id === this.activeId ? '继续聊天' : '选择并聊天')
          .layoutWeight(1)
          .height(38)
          .onClick(() => {
            CharacterStore.setActive(profile.id);
            this.load();
            EventHubUtils.getInstance().emit(CHARACTER_CHANGED);
            EventHubUtils.getInstance().emit(OPEN_CHARACTER_CHAT);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor($r('sys.color.comp_background_tertiary'))
  }

  private load(): void {
    this.profiles = CharacterStore.loadAll();
    this.activeId = CharacterStore.getActive().id;
  }

  private openEditor(id?: string): void {
    RouterUtils.pushPathByName(RouterMap.CHARACTER_SETTINGS_PAGE, id ?? null, () => {
      this.load();
    });
  }
}

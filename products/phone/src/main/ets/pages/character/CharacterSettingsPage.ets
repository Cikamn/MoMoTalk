import { promptAction } from '@kit.ArkUI';
import { EventHubUtils, RouterMap, RouterUtils } from 'lib_common';
import { NavHeaderBar } from 'lib_widget';
import { DEFAULT_ROLE_PROMPT } from '../../common/AIConfig';
import {
  ARONA_DEFAULT_DESCRIPTION,
  CHARACTER_CHANGED,
  CharacterProfile,
  CharacterStore
} from '../../common/CharacterStore';
import { LoreRetriever } from '../../common/LoreRetriever';
import { AvatarCropSession, AvatarService } from '../../common/AvatarService';

@Builder
export function CharacterSettingsPageBuilder() {
  CharacterSettingsPage()
}

@ComponentV2
struct CharacterSettingsPage {
  @Local profile: CharacterProfile = CharacterStore.createCustom();
  @Local displayName: string = '';
  @Local description: string = '';
  @Local systemPrompt: string = '';
  @Local loreEnabled: boolean = false;
  @Local loreEntryCount: number = 0;
  @Local isNew: boolean = true;
  @Local avatarUri: string = '';

  aboutToAppear(): void {
    const id = RouterUtils.getParamByName<string>(RouterMap.CHARACTER_SETTINGS_PAGE);
    const saved = id ? CharacterStore.getById(id) : undefined;
    this.profile = saved ?? CharacterStore.createCustom();
    this.isNew = !saved;
    this.displayName = this.profile.displayName;
    this.description = this.profile.description;
    this.systemPrompt = this.profile.systemPrompt;
    this.loreEnabled = this.profile.loreEnabled;
    this.avatarUri = this.profile.avatarUri;
    this.loreEntryCount = LoreRetriever.getInstance().getEntryCount(this.profile.knowledgeBaseFile);
  }

  build() {
    NavDestination() {
      Column() {
        NavHeaderBar({ title: this.isNew ? '新增角色' : '编辑角色' })

        Scroll() {
          Column({ space: 12 }) {
            Text('角色头像')
              .fontSize($r('sys.float.Subtitle_L'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
            Row({ space: 16 }) {
              this.avatarPreview()
              Column({ space: 8 }) {
                Button(this.avatarUri ? '重新选择' : '选择图片')
                  .height(38)
                  .onClick(() => {
                    this.selectAvatar();
                  })
                if (this.avatarUri) {
                  Button('恢复默认头像')
                    .height(38)
                    .fontColor($r('sys.color.font_primary'))
                    .backgroundColor($r('sys.color.comp_background_tertiary'))
                    .onClick(() => {
                      this.avatarUri = '';
                    })
                }
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')

            Text('角色名称')
              .fontSize($r('sys.float.Subtitle_L'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
            TextInput({ placeholder: '请输入角色名称', text: $$this.displayName })
              .height(48)
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_primary'))
              .placeholderColor($r('sys.color.font_secondary'))
              .backgroundColor($r('sys.color.comp_background_tertiary'))

            Text('角色简介')
              .fontSize($r('sys.float.Subtitle_L'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
            TextInput({ placeholder: '用一句话介绍这个角色', text: $$this.description })
              .height(48)
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_primary'))
              .placeholderColor($r('sys.color.font_secondary'))
              .backgroundColor($r('sys.color.comp_background_tertiary'))

            Text('角色提示词')
              .fontSize($r('sys.float.Subtitle_L'))
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
              .margin({ top: 8 })
            Text('描述角色身份、对用户的称呼、性格、语气和回答边界。')
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_secondary'))
            TextArea({ placeholder: '请输入角色设定', text: $$this.systemPrompt })
              .constraintSize({ minHeight: 300 })
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_primary'))
              .placeholderColor($r('sys.color.font_secondary'))
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .padding(12)

            if (this.profile.id === 'arona') {
              Button('恢复阿罗娜默认设定')
                .height(36)
                .onClick(() => {
                  this.displayName = '阿罗娜';
                  this.description = ARONA_DEFAULT_DESCRIPTION;
                  this.systemPrompt = DEFAULT_ROLE_PROMPT;
                })

              Row() {
                Column({ space: 4 }) {
                  Text('阿罗娜本地知识库')
                    .fontSize($r('sys.float.Body_L'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('sys.color.font_primary'))
                  Text(`共 ${this.loreEntryCount} 条本地知识，按当前问题自动检索`)
                    .fontSize($r('sys.float.Caption_M'))
                    .fontColor($r('sys.color.font_secondary'))
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Toggle({ type: ToggleType.Switch, isOn: this.loreEnabled })
                  .onChange((isOn: boolean) => {
                    this.loreEnabled = isOn;
                  })
              }
              .width('100%')
            }

            Button('保存角色')
              .width('100%')
              .height(44)
              .margin({ top: 12, bottom: 24 })
              .onClick(() => {
                this.save();
              })

            if (!this.isNew && !this.profile.builtIn) {
              Button('删除角色')
                .width('100%')
                .height(44)
                .fontColor('#FFF44336')
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .margin({ bottom: 24 })
                .onClick(() => {
                  this.confirmDelete();
                })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 16, right: 16, top: 16 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .expandSafeArea([SafeAreaType.KEYBOARD])
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  @Builder
  avatarPreview() {
    if (this.avatarUri) {
      Image(this.avatarUri)
        .width(88)
        .height(88)
        .objectFit(ImageFit.Cover)
        .borderRadius(44)
        .border({ width: 1, color: $r('sys.color.icon_emphasize') })
    } else if (this.profile.id === 'arona') {
      Image($r('app.media.arona_avatar_circle'))
        .width(88)
        .height(88)
        .objectFit(ImageFit.Cover)
        .borderRadius(44)
    } else {
      Stack() {
        Circle()
          .width(88)
          .height(88)
          .fill($r('sys.color.comp_background_emphasize'))
        Text((this.displayName || '新').slice(0, 1))
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_on_primary'))
      }
      .width(88)
      .height(88)
    }
  }

  private selectAvatar(): void {
    AvatarService.selectImage()
      .then((sourceUri: string) => {
        if (!sourceUri) {
          return;
        }
        AvatarCropSession.begin(sourceUri, this.profile.id);
        RouterUtils.pushPathByName(RouterMap.AVATAR_CROP_PAGE, null, (popInfo) => {
          if (typeof popInfo.result !== 'string' || !popInfo.result) {
            return;
          }
          if (this.avatarUri && this.avatarUri !== this.profile.avatarUri) {
            AvatarService.removeAvatar(this.avatarUri);
          }
          this.avatarUri = popInfo.result;
        });
      })
      .catch(() => {
        promptAction.showToast({ message: '图片选择失败' });
      });
  }

  private save(): void {
    if (!this.displayName.trim() || !this.systemPrompt.trim()) {
      promptAction.showToast({ message: '请填写角色名称和角色提示词' });
      return;
    }
    this.profile.displayName = this.displayName;
    this.profile.description = this.description;
    this.profile.systemPrompt = this.systemPrompt;
    this.profile.loreEnabled = this.profile.id === 'arona' && this.loreEnabled;
    const oldAvatarUri = this.profile.avatarUri;
    this.profile.avatarUri = this.avatarUri;
    CharacterStore.save(this.profile);
    if (oldAvatarUri && oldAvatarUri !== this.avatarUri) {
      AvatarService.removeAvatar(oldAvatarUri);
    }
    EventHubUtils.getInstance().emit(CHARACTER_CHANGED);
    promptAction.showToast({ message: '角色已保存' });
    RouterUtils.pop('saved');
  }

  private confirmDelete(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: '删除角色',
      message: `确定删除“${this.displayName}”吗？角色设定和本地头像将被移除。`,
      buttons: [
        { text: '取消', color: $r('sys.color.font_primary') },
        { text: '删除', color: '#FFF44336' }
      ]
    }).then((result) => {
      if (result.index !== 1) {
        return;
      }
      const removed = CharacterStore.delete(this.profile.id);
      if (!removed) {
        promptAction.showToast({ message: '该角色不能删除' });
        return;
      }
      AvatarService.removeAvatar(removed.avatarUri);
      EventHubUtils.getInstance().emit(CHARACTER_CHANGED);
      promptAction.showToast({ message: '角色已删除' });
      RouterUtils.pop('deleted');
    });
  }
}

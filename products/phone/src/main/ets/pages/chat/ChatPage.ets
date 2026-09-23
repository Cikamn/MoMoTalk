import { CopilotChat, CopilotController, MessageRole, TextMessage } from '@hw-agconnect/copilot';
import { markConfig, MarkdownV2 } from '@lidary/markdown';
import { EventHubUtils, RouterMap, RouterUtils } from 'lib_common';
import { NavHeaderBar } from 'lib_widget';
import { HistoryButton } from '../../components/HistoryButton';
import { AI_CONFIG_CHANGED, AIConfig, AIConfigStore } from '../../common/AIConfig';
import { CHARACTER_CHANGED, CharacterProfile, CharacterStore } from '../../common/CharacterStore';
import { LoreRetriever } from '../../common/LoreRetriever';
import { ImmersionGuard, RolePromptBuilder } from '../../common/RolePrompt';
import { ProviderRequestPatch } from '../../common/ProviderRequestPatch';

@ComponentV2
export struct ChatPage {
  @Local controller?: CopilotController;
  @Local isConfigured: boolean = false;
  @Local assistantName: string = 'AI 助手';
  @Local draft: string = '';
  private activeProfile: CharacterProfile = new CharacterProfile();
  private configChangedCallback: () => void = () => {
    this.reloadConfig();
  };

  aboutToAppear(): void {
    this.reloadConfig();
    EventHubUtils.getInstance().on(AI_CONFIG_CHANGED, this.configChangedCallback);
    EventHubUtils.getInstance().on(CHARACTER_CHANGED, this.configChangedCallback);

    markConfig.registerLinkClick = (url? : string) => {
      this.getUIContext().getPromptAction().showToast({
        message: `超链接被点击----url:${url}`,
        duration: 1500,
        bottom: 'center',
      })
    }
  }

  aboutToDisappear(): void {
    this.controller?.cancel();
    EventHubUtils.getInstance().off(AI_CONFIG_CHANGED, this.configChangedCallback);
    EventHubUtils.getInstance().off(CHARACTER_CHANGED, this.configChangedCallback);
  }

  build() {
    Column() {
      NavHeaderBar({
        title: '什亭之箱',
        isSubTitle: false,
        showBackBtn: false,
        rightPartBuilder: () => {
          this.menusBuilder()
        }
      }).expandSafeArea([SafeAreaType.KEYBOARD])

      if (this.isConfigured && this.controller) {
        CopilotChat({
          controller: this.controller,
          options: {
            labels: {
              introduce: `你好，我是${this.assistantName}。想聊些什么？`,
              initial: '我已经准备好了。',
              suggestions: [],
              placeholder: '请输入你的问题'
            },
            icons: {
              assistant: this.activeProfile.id === 'arona' ? $r('app.media.arona_avatar_circle') :
                $r('app.media.icon_foreground')
            },
            isShowDefaultActionCard: true
          },
          markdownRender: (content: string) => {
            this.markdownRender(content)
          }
        }).layoutWeight(1)
      } else {
        Column() {
          Column({ space: 12 }) {
            Image(this.activeProfile.id === 'arona' ? $r('app.media.arona_avatar_circle') :
              $r('app.media.icon_foreground'))
              .width(64)
              .height(64)
              .borderRadius(32)
            Text(`你好，我是${this.assistantName}`)
              .fontSize($r('sys.float.Title_M'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
            Text('今天想聊些什么？')
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_secondary'))
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Row({ space: 8 }) {
            TextArea({ placeholder: '请输入你的问题', text: $$this.draft })
              .layoutWeight(1)
              .height(56)
              .maxLength(4000)
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_primary'))
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .borderRadius(20)
            Button('发送')
              .height(40)
              .enabled(this.draft.trim().length > 0)
              .onClick(() => {
                this.getUIContext().getPromptAction().showToast({
                  message: '对话服务尚未就绪，请稍后再试。'
                });
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 12 })
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .height('100%')
  }

  @Builder
  markdownRender(content: string) {
    MarkdownV2({
      content: ImmersionGuard.sanitize(content, AIConfigStore.load(), this.activeProfile),
      lineSpace: 4,
      fontStyle: {
        fontSize: $r('sys.float.Body_M'),
        fontColor: $r('sys.color.font_primary')
      }
    })
  }

  @Builder
  menusBuilder() {
    Row({ space: 16 }) {
      Button('配置')
        .height(36)
        .fontColor($r('sys.color.font_secondary'))
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .fontSize($r('sys.float.Body_M'))
        .onClick(() => {
          RouterUtils.pushPathByName(RouterMap.MODEL_SETTINGS_PAGE);
        })
      HistoryButton({
        onEvent: () => {
          RouterUtils.pushPathByName(RouterMap.CHAT_HISTORY_PAGE, this.activeProfile.storeId, (popInfo) => {
            if (typeof popInfo.result !== 'string' || !popInfo.result) {
              return;
            }
            const threadId = popInfo.result;
            if (this.controller && this.controller.context.threadId !== threadId) {
              this.controller.reload(threadId);
            }
          })
        }
      })
    }
  }

  private reloadConfig(): void {
    const config = AIConfigStore.load();
    this.activeProfile = CharacterStore.getActive();
    this.controller?.cancel();
    this.assistantName = this.activeProfile.displayName;
    this.isConfigured = !!config.apiKey && !!config.baseUrl && !!config.model;
    if (this.isConfigured) {
      this.controller = this.createController(config, this.activeProfile);
    } else {
      this.controller = undefined;
    }
  }

  private createController(config: AIConfig, profile: CharacterProfile): CopilotController {
    const controller = new CopilotController({
      llm: {
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
        model: config.model,
        forwardedParameters: {
          temperature: config.temperature,
          maxTokens: config.maxTokens
        }
      },
      storeId: profile.storeId,
      systemPrompt: () => this.buildRuntimePrompt(profile)
    });
    ProviderRequestPatch.apply(controller, config);
    controller.latestCallback = (content: string) => {
      const safeContent = ImmersionGuard.sanitize(content, config, profile);
      const messages = controller.context.visibleMessages;
      for (let index = messages.length - 1; index >= 0; index--) {
        const message = messages[index];
        if (message.isTextMessage() && (message as TextMessage).role === MessageRole.ASSISTANT) {
          (message as TextMessage).content = safeContent;
          break;
        }
      }
    };
    return controller;
  }

  private buildRuntimePrompt(profile: CharacterProfile): string {
    let loreContext = '';
    if (profile.loreEnabled) {
      loreContext = LoreRetriever.getInstance().search(this.getLastUserInput(), profile.knowledgeBaseFile).context;
    }
    return RolePromptBuilder.build(profile, loreContext);
  }

  private getLastUserInput(): string {
    const messages = this.controller?.context.visibleMessages ?? [];
    for (let index = messages.length - 1; index >= 0; index--) {
      const message = messages[index];
      if (message.isTextMessage()) {
        const textMessage = message as TextMessage;
        if (textMessage.role === MessageRole.USER) {
          return textMessage.content;
        }
      }
    }
    return '';
  }
}

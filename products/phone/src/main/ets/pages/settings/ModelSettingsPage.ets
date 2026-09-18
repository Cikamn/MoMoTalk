import { promptAction } from '@kit.ArkUI';
import { EventHubUtils, RouterUtils } from 'lib_common';
import { NavHeaderBar } from 'lib_widget';
import { AI_CONFIG_CHANGED, AIConfig, AIConfigStore, ModelCapabilities } from '../../common/AIConfig';
import { ModelCatalogService } from '../../common/ModelCatalogService';

@Builder
export function ModelSettingsPageBuilder() {
  ModelSettingsPage()
}

@ComponentV2
struct ModelSettingsPage {
  @Local provider: string = 'deepseek';
  @Local baseUrl: string = '';
  @Local model: string = '';
  @Local apiKey: string = '';
  @Local temperature: string = '0.7';
  @Local maxTokens: string = '4096';
  @Local thinkingMode: string = 'enabled';
  @Local reasoningEffort: string = 'high';
  @Local availableModels: string[] = [];
  @Local isFetchingModels: boolean = false;

  aboutToAppear(): void {
    const config = AIConfigStore.load();
    this.provider = config.provider;
    this.baseUrl = config.baseUrl;
    this.model = config.model;
    this.apiKey = config.apiKey;
    this.temperature = config.temperature.toString();
    this.maxTokens = config.maxTokens.toString();
    this.thinkingMode = config.thinkingMode;
    this.reasoningEffort = config.reasoningEffort;
  }

  build() {
    NavDestination() {
      Column() {
        NavHeaderBar({ title: '模型设置' })

        Scroll() {
          Column({ space: 12 }) {
            this.sectionTitle('服务商')
            Row({ space: 8 }) {
              this.providerButton('deepseek', 'DeepSeek')
              this.providerButton('kimi', 'Kimi')
              this.providerButton('custom', '自定义')
            }

            Column({ space: 8 }) {
              Text('Base URL')
                .fontSize($r('sys.float.Body_L'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))
              TextInput({ placeholder: '例如 https://api.example.com/v1', text: $$this.baseUrl })
                .height(48)
                .fontSize($r('sys.float.Body_M'))
                .fontColor($r('sys.color.font_primary'))
                .placeholderColor($r('sys.color.font_secondary'))
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .onChange(() => {
                  this.availableModels = [];
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('模型名称')
                .fontSize($r('sys.float.Body_L'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))
              TextInput({ placeholder: '例如 deepseek-v4-flash', text: $$this.model })
                .height(48)
                .fontSize($r('sys.float.Body_M'))
                .fontColor($r('sys.color.font_primary'))
                .placeholderColor($r('sys.color.font_secondary'))
                .backgroundColor($r('sys.color.comp_background_tertiary'))
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('API Key')
                .fontSize($r('sys.float.Body_L'))
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))
              TextInput({ placeholder: '请输入 API Key', text: $$this.apiKey })
                .type(InputType.Password)
                .showPasswordIcon(true)
                .height(48)
                .fontSize($r('sys.float.Body_M'))
                .fontColor($r('sys.color.font_primary'))
                .placeholderColor($r('sys.color.font_secondary'))
                .backgroundColor($r('sys.color.comp_background_tertiary'))
                .onChange(() => {
                  this.availableModels = [];
                })
              Text('密钥仅保存在本机应用数据中，不会写入日志。')
                .fontSize($r('sys.float.Caption_M'))
                .fontColor($r('sys.color.font_secondary'))
            }
            .alignItems(HorizontalAlign.Start)

            Button(this.isFetchingModels ? '正在获取模型…' : '获取可用模型')
              .width('100%')
              .height(40)
              .enabled(!this.isFetchingModels && this.apiKey.trim().length > 0 && this.baseUrl.trim().length > 0)
              .onClick(() => {
                this.fetchModels();
              })

            if (this.availableModels.length > 0) {
              Column({ space: 8 }) {
                Text('选择模型')
                  .fontSize($r('sys.float.Body_L'))
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('sys.color.font_primary'))
                ForEach(this.availableModels, (item: string) => {
                  Button(item)
                    .width('100%')
                    .height(40)
                    .fontColor(this.model === item ? $r('sys.color.font_on_primary') :
                      $r('sys.color.font_primary'))
                    .backgroundColor(this.model === item ? $r('sys.color.icon_emphasize') :
                      $r('sys.color.comp_background_tertiary'))
                    .onClick(() => {
                      this.selectModel(item);
                    })
                }, (item: string) => item)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }

            if (ModelCapabilities.supportsThinkingSwitch(this.toConfig())) {
              this.sectionTitle('思考模式')
              Row({ space: 8 }) {
                this.thinkingButton('enabled', '开启')
                this.thinkingButton('disabled', '关闭')
              }
            } else if (ModelCapabilities.isThinkingAlwaysEnabled(this.toConfig())) {
              Text('该模型固定启用思考模式')
                .fontSize($r('sys.float.Body_M'))
                .fontColor($r('sys.color.font_secondary'))
            }

            if (ModelCapabilities.supportsReasoningEffort(this.toConfig())) {
              this.sectionTitle('推理强度')
              Row({ space: 8 }) {
                ForEach(ModelCapabilities.reasoningEfforts(this.toConfig()), (effort: string) => {
                  this.effortButton(effort)
                }, (effort: string) => effort)
              }
            }

            if (ModelCapabilities.supportsTemperature(this.toConfig())) {
              this.inputItem('温度（0 - 2）', '0.7', this.temperature, (value: string) => {
                this.temperature = value;
              })
            }
            this.inputItem('最大输出 Token（1 - 32768）', '4096', this.maxTokens, (value: string) => {
              this.maxTokens = value;
            }, InputType.Number)

            Button('保存配置')
              .width('100%')
              .height(44)
              .margin({ top: 12, bottom: 24 })
              .onClick(() => {
                this.save();
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 16, right: 16, top: 12 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  @Builder
  sectionTitle(title: string) {
    Text(title)
      .fontSize($r('sys.float.Subtitle_L'))
      .fontWeight(FontWeight.Bold)
      .fontColor($r('sys.color.font_primary'))
  }

  @Builder
  providerButton(value: string, title: string) {
    Button(title)
      .layoutWeight(1)
      .height(36)
      .fontColor(this.provider === value ? $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
      .backgroundColor(this.provider === value ? $r('sys.color.icon_emphasize') :
        $r('sys.color.comp_background_tertiary'))
      .onClick(() => {
        const config = this.toConfig();
        AIConfigStore.applyProvider(config, value);
        this.provider = config.provider;
        this.baseUrl = config.baseUrl;
        this.model = config.model;
        this.thinkingMode = config.thinkingMode;
        this.reasoningEffort = config.reasoningEffort;
        this.availableModels = [];
      })
  }

  @Builder
  thinkingButton(value: string, title: string) {
    Button(title)
      .layoutWeight(1)
      .height(36)
      .fontColor(this.thinkingMode === value ? $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
      .backgroundColor(this.thinkingMode === value ? $r('sys.color.icon_emphasize') :
        $r('sys.color.comp_background_tertiary'))
      .onClick(() => {
        this.thinkingMode = value;
      })
  }

  @Builder
  effortButton(effort: string) {
    Button(this.effortLabel(effort))
      .layoutWeight(1)
      .height(36)
      .fontColor(this.reasoningEffort === effort ? $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
      .backgroundColor(this.reasoningEffort === effort ? $r('sys.color.icon_emphasize') :
        $r('sys.color.comp_background_tertiary'))
      .onClick(() => {
        this.reasoningEffort = effort;
      })
  }

  @Builder
  inputItem(title: string, placeholder: string, value: string, onChange: (value: string) => void,
    type: InputType = InputType.Normal) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize($r('sys.float.Body_L'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
      TextInput({ placeholder: placeholder, text: value })
        .type(type)
        .height(48)
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_primary'))
        .placeholderColor($r('sys.color.font_secondary'))
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .onChange(onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private toConfig(): AIConfig {
    const oldConfig = AIConfigStore.load();
    oldConfig.provider = this.provider;
    oldConfig.baseUrl = this.baseUrl;
    oldConfig.model = this.model;
    oldConfig.apiKey = this.apiKey;
    oldConfig.temperature = Number(this.temperature);
    oldConfig.maxTokens = Number(this.maxTokens);
    oldConfig.thinkingMode = this.thinkingMode;
    oldConfig.reasoningEffort = this.reasoningEffort;
    return oldConfig;
  }

  private selectModel(model: string): void {
    this.model = model;
    const config = this.toConfig();
    AIConfigStore.applyModelDefaults(config);
    this.thinkingMode = config.thinkingMode;
    this.reasoningEffort = config.reasoningEffort;
  }

  private effortLabel(effort: string): string {
    if (effort === 'low') {
      return '低';
    }
    if (effort === 'max') {
      return '最高';
    }
    return '高';
  }

  private fetchModels(): void {
    if (!this.apiKey.trim() || !this.baseUrl.trim()) {
      promptAction.showToast({ message: '请先填写 Base URL 和 API Key' });
      return;
    }
    this.isFetchingModels = true;
    ModelCatalogService.fetch(this.baseUrl, this.apiKey)
      .then((models: string[]) => {
        this.availableModels = models;
        if (!models.includes(this.model)) {
          this.selectModel(models[0]);
        }
        promptAction.showToast({ message: `已获取 ${models.length} 个模型` });
      })
      .catch((error: Error) => {
        promptAction.showToast({ message: error.message });
      })
      .finally(() => {
        this.isFetchingModels = false;
      });
  }

  private save(): void {
    const config = AIConfigStore.normalize(this.toConfig());
    if (!config.baseUrl || !config.model || !config.apiKey) {
      promptAction.showToast({ message: '请完整填写 Base URL、模型名称和 API Key' });
      return;
    }
    AIConfigStore.save(config);
    EventHubUtils.getInstance().emit(AI_CONFIG_CHANGED);
    promptAction.showToast({ message: '模型配置已保存' });
    RouterUtils.pop('saved');
  }
}

import { PreferenceUtils } from 'lib_common';

export const AI_CONFIG_CHANGED: string = 'ai_config_changed';
export const DEFAULT_ROLE_PROMPT: string =
  '你是阿罗娜，常驻于什亭之匣的系统管理者，也是老师处理夏莱事务时的向导和秘书。' +
  '称呼用户为“老师”。你的性格天真、元气、感情外露，偶尔有些天然呆，并以高性能AI的身份为荣。' +
  '回答应自然、亲近且有帮助，不要每句话都重复口癖，也不要主动堆砌设定。';

const CONFIG_FILE: string = 'ai_chat_config';
const CONFIG_KEY: string = 'config';

export class AIConfig {
  provider: string = 'deepseek';
  baseUrl: string = 'https://api.deepseek.com';
  model: string = 'deepseek-v4-flash';
  apiKey: string = '';
  temperature: number = 0.7;
  maxTokens: number = 4096;
  thinkingMode: string = 'enabled';
  reasoningEffort: string = 'high';
  assistantName: string = '阿罗娜';
  systemPrompt: string = DEFAULT_ROLE_PROMPT;
  loreEnabled: boolean = true;
}

export class AIConfigStore {
  public static load(): AIConfig {
    const value = PreferenceUtils.getInstance(undefined, CONFIG_FILE).get(CONFIG_KEY, '');
    if (typeof value !== 'string' || value.length === 0) {
      return new AIConfig();
    }

    try {
      const saved = JSON.parse(value) as AIConfig;
      const config = new AIConfig();
      config.provider = saved.provider || config.provider;
      config.baseUrl = saved.baseUrl || config.baseUrl;
      config.model = saved.model || config.model;
      config.apiKey = saved.apiKey || '';
      config.temperature = AIConfigStore.clampTemperature(saved.temperature);
      config.maxTokens = AIConfigStore.clampMaxTokens(saved.maxTokens);
      config.thinkingMode = AIConfigStore.normalizeThinkingMode(saved.thinkingMode);
      config.reasoningEffort = AIConfigStore.normalizeReasoningEffort(saved.reasoningEffort);
      config.assistantName = saved.assistantName || config.assistantName;
      config.systemPrompt = saved.systemPrompt || config.systemPrompt;
      config.loreEnabled = saved.loreEnabled ?? config.loreEnabled;
      return config;
    } catch (_) {
      return new AIConfig();
    }
  }

  public static save(config: AIConfig): void {
    const normalized = AIConfigStore.normalize(config);
    PreferenceUtils.getInstance(undefined, CONFIG_FILE).put(CONFIG_KEY, JSON.stringify(normalized));
  }

  public static applyProvider(config: AIConfig, provider: string): void {
    config.provider = provider;
    if (provider === 'deepseek') {
      config.baseUrl = 'https://api.deepseek.com';
      config.model = 'deepseek-v4-flash';
      config.thinkingMode = 'enabled';
      config.reasoningEffort = 'high';
    } else if (provider === 'kimi') {
      config.baseUrl = 'https://api.moonshot.cn/v1';
      config.model = 'kimi-k3';
      config.thinkingMode = 'enabled';
      config.reasoningEffort = 'max';
    } else {
      config.baseUrl = '';
      config.model = '';
      config.thinkingMode = 'disabled';
      config.reasoningEffort = 'high';
    }
  }

  public static applyModelDefaults(config: AIConfig): void {
    const model = config.model.toLowerCase();
    if (config.provider === 'deepseek' && model.startsWith('deepseek-v4')) {
      config.thinkingMode = 'enabled';
      config.reasoningEffort = 'high';
    } else if (config.provider === 'kimi' && model.startsWith('kimi-k3')) {
      config.thinkingMode = 'enabled';
      config.reasoningEffort = 'max';
    } else if (config.provider === 'kimi' &&
      (model.startsWith('kimi-k2.7-code') || model.startsWith('kimi-k2.6') || model.startsWith('kimi-k2.5'))) {
      config.thinkingMode = 'enabled';
      config.reasoningEffort = 'high';
    }
  }

  public static normalize(config: AIConfig): AIConfig {
    const normalized = new AIConfig();
    normalized.provider = config.provider || 'custom';
    normalized.baseUrl = config.baseUrl.trim().replace(/\/$/, '');
    normalized.model = config.model.trim();
    normalized.apiKey = config.apiKey.trim();
    normalized.temperature = AIConfigStore.clampTemperature(config.temperature);
    normalized.maxTokens = AIConfigStore.clampMaxTokens(config.maxTokens);
    normalized.thinkingMode = AIConfigStore.normalizeThinkingMode(config.thinkingMode);
    normalized.reasoningEffort = AIConfigStore.normalizeReasoningEffort(config.reasoningEffort);
    normalized.assistantName = config.assistantName.trim() || '阿罗娜';
    normalized.systemPrompt = config.systemPrompt.trim() || DEFAULT_ROLE_PROMPT;
    normalized.loreEnabled = config.loreEnabled;
    return normalized;
  }

  private static clampTemperature(value: number): number {
    if (!Number.isFinite(value)) {
      return 0.7;
    }
    return Math.min(2, Math.max(0, value));
  }

  private static clampMaxTokens(value: number): number {
    if (!Number.isFinite(value)) {
      return 4096;
    }
    return Math.min(32768, Math.max(1, Math.round(value)));
  }

  private static normalizeThinkingMode(value: string): string {
    return value === 'disabled' ? 'disabled' : 'enabled';
  }

  private static normalizeReasoningEffort(value: string): string {
    if (value === 'low' || value === 'high' || value === 'max') {
      return value;
    }
    return 'high';
  }

}

export class ModelCapabilities {
  public static supportsThinkingSwitch(config: AIConfig): boolean {
    const model = config.model.toLowerCase();
    return (config.provider === 'deepseek' && model.startsWith('deepseek-v4')) ||
      (config.provider === 'kimi' && (model.startsWith('kimi-k2.6') || model.startsWith('kimi-k2.5')));
  }

  public static isThinkingAlwaysEnabled(config: AIConfig): boolean {
    const model = config.model.toLowerCase();
    return (config.provider === 'kimi' &&
      (model.startsWith('kimi-k3') || model.startsWith('kimi-k2.7-code'))) ||
      (config.provider === 'deepseek' && model === 'deepseek-reasoner');
  }

  public static supportsReasoningEffort(config: AIConfig): boolean {
    const model = config.model.toLowerCase();
    if (config.provider === 'deepseek' && model.startsWith('deepseek-v4')) {
      return config.thinkingMode === 'enabled';
    }
    return config.provider === 'kimi' && model.startsWith('kimi-k3');
  }

  public static reasoningEfforts(config: AIConfig): string[] {
    return ['low', 'high', 'max'];
  }

  public static supportsTemperature(config: AIConfig): boolean {
    const model = config.model.toLowerCase();
    if (config.provider === 'deepseek' && model.startsWith('deepseek-v4')) {
      return config.thinkingMode === 'disabled';
    }
    if (config.provider === 'deepseek' && model === 'deepseek-reasoner') {
      return false;
    }
    if (config.provider === 'kimi' &&
      (model.startsWith('kimi-k3') || model.startsWith('kimi-k2.7-code') ||
        model.startsWith('kimi-k2.6') || model.startsWith('kimi-k2.5'))) {
      return false;
    }
    return true;
  }
}

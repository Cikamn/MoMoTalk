import { CopilotController } from '@hw-agconnect/copilot';
import { AIConfig, ModelCapabilities } from './AIConfig';

export class ProviderRequestPatch {
  public static apply(controller: CopilotController, config: AIConfig): void {
    const dynamicController: ESObject = controller as ESObject;
    const client: ESObject = dynamicController.client;
    const originalConverter: ESObject = client.convertToOpenAIRequest;

    client.convertToOpenAIRequest = (request: ESObject): ESObject => {
      const body: ESObject = originalConverter.call(client, request);
      if (ModelCapabilities.supportsThinkingSwitch(config)) {
        body.thinking = { type: config.thinkingMode };
      }
      if (ModelCapabilities.supportsReasoningEffort(config)) {
        body.reasoning_effort = config.reasoningEffort;
      }
      if (!ModelCapabilities.supportsTemperature(config)) {
        body.temperature = undefined;
      }
      return body;
    };
  }
}

import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface ModelItem {
  id?: string;
}

interface ModelListPayload {
  data?: ModelItem[];
}

export class ModelCatalogService {
  public static fetch(baseUrl: string, apiKey: string): Promise<string[]> {
    const endpoint = `${baseUrl.trim().replace(/\/$/, '')}/models`;
    const request = http.createHttp();
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      header: {
        'Authorization': `Bearer ${apiKey.trim()}`,
        'Accept': 'application/json'
      },
      connectTimeout: 15000,
      readTimeout: 15000
    };

    return new Promise<string[]>((resolve: (models: string[]) => void,
      reject: (error: Error) => void) => {
      request.request(endpoint, options, (error: BusinessError, response: http.HttpResponse) => {
        try {
          if (error) {
            reject(new Error(`网络请求失败（${error.code}）`));
            return;
          }
          if (response.responseCode < 200 || response.responseCode >= 300) {
            reject(new Error(`服务商返回 ${response.responseCode}，请检查 API Key 和 Base URL`));
            return;
          }

          const text = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);
          const payload = JSON.parse(text) as ModelListPayload;
          const ids: string[] = [];
          (payload.data ?? []).forEach((item: ModelItem) => {
            const id = item.id?.trim() ?? '';
            if (id && !ids.includes(id)) {
              ids.push(id);
            }
          });
          if (ids.length === 0) {
            reject(new Error('服务商没有返回可用模型'));
            return;
          }
          ids.sort();
          resolve(ids);
        } catch (_) {
          reject(new Error('模型列表响应格式无法识别'));
        } finally {
          request.destroy();
        }
      });
    });
  }
}

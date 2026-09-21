import bridge from '@arkui-x.bridge';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import fs from '@ohos.file.fs';

const DOMAIN = 0x0000;
const TAG = '[MediaUtils]';

export class MediaUtils {
  /**
   * 用系统picker，拉起相册或者相机
   * @param params
   * @returns
   */
  private static picker?: bridge.BridgeObject;
  private static pending: boolean = false;
  public static selectMedia(maxSelectNumber: number): Promise<string[]> {
    if (MediaUtils.pending) { return Promise.reject(new Error('文件选择器已打开')); }
    if (!MediaUtils.picker) { MediaUtils.picker = bridge.createBridge('MoMoTalkFeedbackMedia'); }
    const picker = MediaUtils.picker;
    MediaUtils.pending = true;
    return new Promise<string[]>((resolve, reject) => {
      picker.setMessageListener((message: bridge.Message): bridge.Response => {
        MediaUtils.pending = false;
        try {
          const result = JSON.parse(message as string) as AndroidMediaResult;
          if (result.error) { reject(new Error(result.error)); } else { resolve(result.uris); }
        } catch (error) { reject(new Error('无法读取文件选择结果')); }
        return '';
      });
      picker.callMethod('selectMedia', 'image/*', maxSelectNumber).catch(() => {
        MediaUtils.pending = false;
        reject(new Error('无法打开系统文件选择器'));
      });
    });
  }

  /**
   * uri对应文件复制到沙箱
   * @param uri
   * @param suffix
   * @returns
   */
  public static handleUri(uri: string, suffix: string = 'png'): string {
    if (!uri) {
      return '';
    }
    let tempFile: fs.File | null = null;
    try {
      tempFile = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      let newPath: string = getContext().cacheDir + `/${util.generateRandomUUID(false)}.${suffix}`;
      fs.copyFileSync(tempFile.fd, newPath);
      hilog.info(DOMAIN, TAG, 'handleUri copyFileSync success, cache path: ' + newPath);
      return 'file://' + newPath;
    } finally {
      if (tempFile) {
        fs.closeSync(tempFile);
      }
    }
  }
}

interface AndroidMediaResult { uris: string[]; error: string; }

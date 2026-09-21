import bridge from '@arkui-x.bridge';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import fs from '@ohos.file.fs';
import { MediaParams } from '../models/MediaModel';
import { util } from '@kit.ArkTS';

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
  public static selectMedia(params: MediaParams): Promise<string[]> {
    if (MediaUtils.pending) { return Promise.reject(new Error('文件选择器已打开')); }
    if (!MediaUtils.picker) { MediaUtils.picker = bridge.createBridge('MoMoTalkMedia'); }
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
      picker.callMethod('selectMedia', params.type, params.maxLimit).catch(() => {
        MediaUtils.pending = false;
        reject(new Error('无法打开系统文件选择器'));
      });
    });
  }

  /**
   * pixelMap写入沙箱
   * @param pixelMap
   * @returns
   */
  public static async writePixelMap(pixelMap?: image.PixelMap): Promise<string> {
    if (!pixelMap) {
      return '';
    }
    let file: fs.File | null = null;
    try {
      const newPath: string = getContext().cacheDir + `/${util.generateRandomUUID(false)}.png`;
      file = fs.openSync(newPath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      let imagePacker: image.ImagePacker = image.createImagePacker();
      let packOpts: image.PackingOption = { format: 'image/png', quality: 100 };
      await imagePacker.packToFile(pixelMap, file.fd, packOpts);
      return 'file://' + newPath;
    } finally {
      if (file) {
        fs.closeSync(file);
      }
    }
  }
}
interface AndroidMediaResult { uris: string[]; error: string; }

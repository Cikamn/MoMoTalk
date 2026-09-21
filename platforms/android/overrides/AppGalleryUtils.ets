import { common } from '@kit.AbilityKit';

/** Android has no configured store/update service in this project. */
export class AppGalleryUtils {
  static checkAppUpdate(context: common.UIAbilityContext): Promise<boolean> {
    return Promise.reject(new Error('Android 版本暂未接入应用商店更新服务'));
  }
  static showUpdateDialog(context: common.UIAbilityContext): void {
    throw new Error('Android 版本暂未接入应用商店更新服务');
  }
}

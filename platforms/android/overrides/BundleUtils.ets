import { bundleManager, common } from '@kit.AbilityKit';
import { BundleInfo } from '../models/BundleInfo';

export class BundleUtils {
  public static async getBundleInfo(context: common.UIAbilityContext) {
    const bundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appName = context.resourceManager.getStringSync(bundleInfo.appInfo.labelId);
    let appVersionName = bundleInfo.versionName;
    let appInfo: BundleInfo = {
      appName,
      appVersionName,
    }
    AppStorage.setOrCreate('appInfo', appInfo)
  }
}

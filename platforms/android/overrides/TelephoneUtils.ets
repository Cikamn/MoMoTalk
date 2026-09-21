import bridge from '@arkui-x.bridge';
import { promptAction } from '@kit.ArkUI';

export class TelephoneUtils {
  private static bridge?: bridge.BridgeObject;

  static callPhone(tel: string): void {
    if (!TelephoneUtils.bridge) { TelephoneUtils.bridge = bridge.createBridge('MoMoTalkTelephone'); }
    TelephoneUtils.bridge.callMethod('dial', tel).catch(() => {
      promptAction.showToast({ message: '无法打开拨号应用' });
    });
  }
}

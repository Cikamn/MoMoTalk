import { promptAction, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { BaseViewModel, CommonConfirmDialog, CommonConstants, Logger, PopViewUtils, RouterMap } from 'lib_common';
import { AccountApi } from '../services/AccountApi';
import { ErrorCode } from '../constants/ErrorCode';
import { Constants } from '../constants/Constants';
import { LoginRouterParams, LoginSheetParams } from '../constants/Types';
import { getAccountErrorMsg } from '../utils/ErrorCodeHelper';

const TAG = '[LoginVM]';

@ObservedV2
export class LoginVM extends BaseViewModel {
  @Trace anonymousPhone: string = '177******96';
  @Trace isAgreePrivacy: boolean = false;
  @Trace userProtocolInfo: string = '';
  @Trace privacyInfo: string = '';
  @Trace huaweiUserProtocolInfo: string = '';
  @Trace isSheet: boolean = false;
  @Trace sheetParams: LoginSheetParams = new LoginSheetParams();
  @Trace stack: NavPathStack = new NavPathStack();
  @Trace accountInput: string = '';
  @Trace passwordInput: string = '';
  private accountInstance: AccountApi = new AccountApi();
  static instance: LoginVM | null;
  public static getInstance(reCreate: boolean = false) {
    if (!LoginVM.instance || reCreate) {
      LoginVM.instance = new LoginVM();
    }
    return LoginVM.instance;
  }

  public static clearInstance() {
    LoginVM.instance = null;
  }

  constructor() {
    super();
    this.queryAnonymousPhone();
    this.queryProtocol();
  }

  resetInput() {
    this.accountInput = '';
    this.passwordInput = '';
    this.agreePrivacyChange(false);
  }

  // The original account service is a mock; no third-party Android login is configured.
  registerOnWXRespCallback(): void {}
  unregisterOnWXRespCallback(): void {}

  simulateLogin(huawei: boolean = true): void {
    if (!this.isAgreePrivacy) {
      promptAction.showToast({ message: '请先勾选同意协议' });
      return;
    }
    if (huawei) { this.huaweiLogin(); } else { this.wechatLogin(); }
  }

  setPrivacyMode(context?: Context) {
    if (!context) {
      return;
    }
    window.getLastWindow(context).then((window) => {
      window.setWindowPrivacyMode(true);
    });
  }

  cancelPrivacyMode(context?: Context) {
    if (!context) {
      return;
    }
    window.getLastWindow(context).then((window) => {
      window.setWindowPrivacyMode(false);
    });
  }


  queryAnonymousPhone(): void {
    this.anonymousPhone = '项目演示账号';
  }

  queryProtocol() {
    this.userProtocolInfo = this.accountInstance.getUserAgreeInfo();
    this.privacyInfo = this.accountInstance.getPrivacyInfo();
    this.huaweiUserProtocolInfo = this.accountInstance.getHuaweiUserAgreeInfo();
  }

  handleClose() {
    if (this.isSheet) {
      PopViewUtils.closeSheet();
    } else {
      this.stack.pop(true);
    }
    LoginVM.clearInstance();
  }

  huaweiLogin() {
    this.accountInstance.huaweiLogin(this.anonymousPhone);
    this.handleClose();
  }

  wechatLogin() {
    this.accountInstance.wechatLogin()
    this.handleClose();
  }

  accountPasswordLogin() {
    if (!this.isAgreePrivacy) {
      promptAction.showToast({ message: '请先勾选同意协议' });
      return;
    }
    if (!this.accountInput) {
      promptAction.showToast({ message: '请输入账号' });
      return;
    }
    if (!this.passwordInput) {
      promptAction.showToast({ message: '请输入密码' });
      return;
    }
    this.accountInstance.accountPasswordLogin()
    this.handleClose();
  }

  jumpOtherLogin() {
    this.stack.replacePathByName(RouterMap.OTHER_LOGIN_PAGE, null, false);
  }

  jumpHuaweiLogin() {
    this.stack.replacePathByName(RouterMap.HUAWEI_LOGIN_PAGE, {
      keepVM: true,
    } as LoginRouterParams, false);
  }

  async jumpWX(): Promise<void> {
    if (!this.isAgreePrivacy) {
      promptAction.showToast({ message: '请先勾选同意协议' });
      return;
    }
    CommonConfirmDialog.show({
      primaryTitle: '模拟登录',
      content: '当前项目使用模拟账号，不会连接微信。是否继续？',
      confirm: () => this.wechatLogin(),
    });
  }

  agreePrivacyChange(value: boolean): void {
    this.isAgreePrivacy = value;
  }

  otherWayMarginTop() {
    if (this.isSheet) {
      return CommonConstants.PADDING_XXL;
    }
    return Constants.PADDING_40;
  }

  pageBgColor() {
    if (this.isSheet) {
      return Color.Transparent;
    }
    return $r('sys.color.background_secondary');
  }

  getPagePaddingBottom() {
    if (this.isSheet && this.sheetParams.sheetType === SheetType.CENTER) {
      return 0;
    }
    // 兼容api17以下
    if (deviceInfo.sdkApiVersion < 17) {
      return this.windowModel.windowBottomPadding + CommonConstants.PADDING_L;
    }
    return this.windowModel.windowBottomPadding;
  }
}

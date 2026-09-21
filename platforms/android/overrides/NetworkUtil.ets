import bridge from '@arkui-x.bridge';
import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { NetworkModel } from '../models/NetworkModel';
import { Logger } from './Logger';

/** Android uses the OS default network and supported ArkUI-X connectivity callbacks. */
export class NetworkUtil {
  private static instance?: NetworkUtil;
  private model: NetworkModel = NetworkModel.getInstance();
  private connection?: connection.NetConnection;
  private bridge?: bridge.BridgeObject;

  static getInstance(): NetworkUtil {
    if (!NetworkUtil.instance) { NetworkUtil.instance = new NetworkUtil(); }
    return NetworkUtil.instance;
  }

  init(): void {
    if (this.connection) { return; }
    this.connection = connection.createNetConnection();
    this.connection.on('netAvailable', () => this.refresh());
    this.connection.on('netCapabilitiesChange', (info: connection.NetCapabilityInfo) => {
      this.applyCapabilities(info.netCap);
    });
    this.connection.on('netLost', () => this.refresh());
    this.connection.register((error: BusinessError) => {
      if (error) { Logger.error('NetworkUtil', error.message); }
      this.refresh();
    });
  }

  private refresh(): void {
    if (!this.bridge) { this.bridge = bridge.createBridge('MoMoTalkNetwork'); }
    this.bridge.callMethod('networkState').then((value: bridge.ResultValue) => {
      const state = JSON.parse(value as string) as AndroidNetworkState;
      this.model.hasNet = state.connected;
      this.model.isNetworkAvailable = state.internet;
      this.model.isWiFi = state.wifi;
      this.model.isCellular = state.cellular;
    }).catch(() => {
      this.model.hasNet = false;
      this.model.isNetworkAvailable = false;
      this.model.isCellular = false;
      this.model.isWiFi = false;
    });
  }

  private applyCapabilities(capabilities: connection.NetCapabilities): void {
    this.model.hasNet = capabilities.bearerTypes.length > 0;
    this.model.isNetworkAvailable = this.model.hasNet;
    this.model.isWiFi = capabilities.bearerTypes.includes(connection.NetBearType.BEARER_WIFI);
    this.model.isCellular = capabilities.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR);
    if (this.model.hasNet) { this.model.hasOfflineTip = false; }
  }

  unregister(): void {
    if (!this.connection) { return; }
    this.connection.unregister((error: BusinessError) => {
      if (error) { Logger.error('NetworkUtil', error.message); }
    });
    this.connection = undefined;
  }
}

interface AndroidNetworkState {
  connected: boolean;
  internet: boolean;
  wifi: boolean;
  cellular: boolean;
}

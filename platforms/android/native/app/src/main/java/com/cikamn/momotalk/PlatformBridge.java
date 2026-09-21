package com.cikamn.momotalk;

import android.app.Activity;
import android.app.NotificationManager;
import android.content.Intent;
import android.net.Uri;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import org.json.JSONObject;
import android.provider.Settings;
import ohos.ace.adapter.capability.bridge.BridgePlugin;

/** Native equivalents of the existing settings and contact actions. */
public class PlatformBridge extends BridgePlugin {
    private final Activity activity;

    public PlatformBridge(Activity activity, String name) {
        super(name, BridgeType.JSON_TYPE);
        this.activity = activity;
    }

    public String networkState() throws Exception {
        ConnectivityManager manager = activity.getSystemService(ConnectivityManager.class);
        Network network = manager == null ? null : manager.getActiveNetwork();
        NetworkCapabilities caps = network == null ? null : manager.getNetworkCapabilities(network);
        return new JSONObject()
                .put("connected", caps != null)
                .put("internet", caps != null && caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED))
                .put("wifi", caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI))
                .put("cellular", caps != null && caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR))
                .toString();
    }

    public boolean notificationsEnabled() {
        NotificationManager manager = activity.getSystemService(NotificationManager.class);
        return manager != null && manager.areNotificationsEnabled();
    }

    public boolean openNotificationSettings() {
        Intent intent = new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, activity.getPackageName());
        activity.startActivity(intent);
        return true;
    }

    public boolean dial(String number) {
        if (number == null || !number.matches("[+0-9() -]{1,40}")) {
            throw new IllegalArgumentException("Invalid phone number");
        }
        activity.startActivity(new Intent(Intent.ACTION_DIAL, Uri.fromParts("tel", number, null)));
        return true;
    }
}

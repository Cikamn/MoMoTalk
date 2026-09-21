package com.cikamn.momotalk;

import android.os.Bundle;
import android.content.Intent;
import ohos.stage.ability.adapter.StageActivity;

public class PhoneEntryAbilityActivity extends StageActivity {
    private MediaBridge mediaBridge;
    private MediaBridge feedbackMediaBridge;
    private PlatformBridge platformBridge;
    private PlatformBridge networkBridge;
    private PlatformBridge telephoneBridge;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        mediaBridge = new MediaBridge(this, "MoMoTalkMedia", 2101);
        feedbackMediaBridge = new MediaBridge(this, "MoMoTalkFeedbackMedia", 2102);
        platformBridge = new PlatformBridge(this, "MoMoTalkPlatform");
        networkBridge = new PlatformBridge(this, "MoMoTalkNetwork");
        telephoneBridge = new PlatformBridge(this, "MoMoTalkTelephone");
        // The ArkTS bundle identity is preserved for shared resources and persisted data.
        setInstanceName("aibusiness.1.xxxxxx:phone:EntryAbility:");
        super.onCreate(savedInstanceState);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (mediaBridge.handleResult(requestCode, resultCode, data) ||
            feedbackMediaBridge.handleResult(requestCode, resultCode, data)) return;
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onDestroy() {
        if (mediaBridge != null) mediaBridge.release();
        if (feedbackMediaBridge != null) feedbackMediaBridge.release();
        if (platformBridge != null) { platformBridge.release(); }
        if (networkBridge != null) { networkBridge.release(); }
        if (telephoneBridge != null) { telephoneBridge.release(); }
        super.onDestroy();
    }
}

package com.cikamn.momotalk;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.net.Uri;
import android.webkit.MimeTypeMap;
import java.io.File;
import java.io.InputStream;
import java.io.FileOutputStream;
import org.json.JSONArray;
import org.json.JSONObject;
import ohos.ace.adapter.capability.bridge.BridgePlugin;

/** Reads only documents explicitly selected by the user; no storage permission. */
public final class MediaBridge extends BridgePlugin {
    private final Activity activity;
    private final int requestCode;
    private boolean pending;
    private int maxCount;

    public MediaBridge(Activity activity, String name, int requestCode) {
        super(name, BridgeType.JSON_TYPE);
        this.activity = activity;
        this.requestCode = requestCode;
    }

    public synchronized boolean selectMedia(String mime, int count) {
        if (pending) throw new IllegalStateException("A media picker is already open");
        maxCount = Math.max(1, count);
        pending = true;
        activity.runOnUiThread(() -> {
            try {
                Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT)
                    .addCategory(Intent.CATEGORY_OPENABLE)
                    .setType("video/*".equals(mime) ? "video/*" : "image/*")
                    .putExtra(Intent.EXTRA_ALLOW_MULTIPLE, maxCount > 1);
                activity.startActivityForResult(intent, requestCode);
            } catch (Exception e) { finish(new JSONArray(), "无法打开系统文件选择器"); }
        });
        return true;
    }

    public boolean handleResult(int code, int result, Intent data) {
        if (code != requestCode) return false;
        if (result != Activity.RESULT_OK || data == null) {
            finish(new JSONArray(), "");
            return true;
        }
        new Thread(() -> {
            JSONArray paths = new JSONArray();
            try {
                ClipData clips = data.getClipData();
                if (clips != null) {
                    for (int i = 0; i < Math.min(clips.getItemCount(), maxCount); i++) {
                        paths.put(copySelected(clips.getItemAt(i).getUri()));
                    }
                } else if (data.getData() != null) paths.put(copySelected(data.getData()));
                finish(paths, "");
            } catch (Exception e) { finish(new JSONArray(), "无法读取所选文件，请重新选择"); }
        }, "MoMoTalk-media-import").start();
        return true;
    }

    private String copySelected(Uri uri) throws Exception {
        String extension = MimeTypeMap.getSingleton().getExtensionFromMimeType(activity.getContentResolver().getType(uri));
        File file = File.createTempFile("momotalk_media_", "." + (extension == null ? "bin" : extension), activity.getCacheDir());
        try (InputStream input = activity.getContentResolver().openInputStream(uri);
             FileOutputStream output = new FileOutputStream(file)) {
            if (input == null) throw new IllegalStateException("Document is unavailable");
            byte[] buffer = new byte[32768];
            int size;
            while ((size = input.read(buffer)) != -1) output.write(buffer, 0, size);
        } catch (Exception e) { file.delete(); throw e; }
        return Uri.fromFile(file).toString();
    }

    private synchronized void finish(JSONArray paths, String error) {
        pending = false;
        try { sendMessage(new JSONObject().put("uris", paths).put("error", error).toString()); }
        catch (Exception e) { android.util.Log.e("MoMoTalkMedia", "Could not deliver picker result"); }
    }
}

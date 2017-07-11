package com.alinz.parkerdan.shareextension;

import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.Arguments;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.graphics.Bitmap;

import java.io.InputStream;
import java.util.HashSet;
import java.util.Set;
import java.util.ArrayList;

public class ShareModule extends ReactContextBaseJavaModule {


    public ShareModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "ReactNativeShareExtension";
    }

    @ReactMethod
    public void close() {
        getCurrentActivity().finish();
    }

    @ReactMethod
    public void data(Promise promise) {
        promise.resolve(processIntent());
    }

    public WritableArray processIntent() {
        WritableArray dataArrayMap = Arguments.createArray();
        Set<String> mediaTypesSupported = new HashSet<String>();
        mediaTypesSupported.add("video");
        mediaTypesSupported.add("audio");
        mediaTypesSupported.add("image");

        String type = "";
        String action = "";
        String typePart = "";

        Activity currentActivity = getCurrentActivity();

        if (currentActivity != null) {
            Intent intent = currentActivity.getIntent();
            action = intent.getAction();
            type = intent.getType();
            if (type == null) {
                type = "";
            } else {
                typePart = type.substring(0, type.indexOf('/'));
            }
            if (Intent.ACTION_SEND.equals(action) && "text/plain".equals(type)) {
                WritableMap dataMap = Arguments.createMap();
                dataMap.putString("type", type);
                dataMap.putString("value", intent.getStringExtra(Intent.EXTRA_TEXT));
                dataArrayMap.pushMap(dataMap);
            } else if (Intent.ACTION_SEND.equals(action) && (
                    mediaTypesSupported.contains(typePart))) {
                WritableMap dataMap = Arguments.createMap();
                dataMap.putString("type", type);
                Uri uri = (Uri) intent.getParcelableExtra(Intent.EXTRA_STREAM);
                dataMap.putString("value", "file://" + RealPathUtil.getRealPathFromURI(currentActivity, uri));
                dataArrayMap.pushMap(dataMap);
            } else if (Intent.ACTION_SEND_MULTIPLE.equals(action) && mediaTypesSupported.contains(typePart)) {
                ArrayList<Uri> uris = intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM);
                for (Uri uri : uris) {
                    WritableMap dataMap = Arguments.createMap();
                    dataMap.putString("type", type);
                    dataMap.putString("value", "file://" + RealPathUtil.getRealPathFromURI(currentActivity, uri));
                    dataArrayMap.pushMap(dataMap);
                }
            }
        }
        return dataArrayMap;
    }
}

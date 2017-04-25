package com.alinz.parkerdan.shareextension;

import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.graphics.BitmapFactory;
import android.os.Bundle;


public class ShareModule extends ReactContextBaseJavaModule {

  private String getType(Intent intent) {
      String type = intent.getType();
      return (type == null ? "" : type);
  }

  private WritableMap getImageSize(String path) {
      BitmapFactory.Options options = new BitmapFactory.Options();
      options.inJustDecodeBounds = true;

      BitmapFactory.decodeFile(path, options);

      int height = options.outHeight;
      int width = options.outWidth;

      WritableMap sizes = Arguments.createMap();
      WritableMap result = Arguments.createMap();

      sizes.putInt("height", height);
      sizes.putInt("width", width);
      result.putMap("size", sizes);

      return result;
  }

  private WritableMap getImageData(Activity currentActivity) {
      WritableMap map = Arguments.createMap();
      Intent intent = currentActivity.getIntent();

      Uri uri = intent.getParcelableExtra(Intent.EXTRA_STREAM);
      String path = RealPathUtil.getRealPathFromURI(currentActivity, uri);
      String value = "file://" + path;

      map.putString("type", this.getType(intent));
      map.putString("value", value);
      map.putString("name", uri.getLastPathSegment());
      map.putMap("image", this.getImageSize(path));

      return map;
  }

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

  @ReactMethod
  public void clear() {
      Activity currentActivity = getCurrentActivity();

      if (currentActivity != null) {
        Intent intent = currentActivity.getIntent();
        intent.replaceExtras(new Bundle());
        intent.setAction("");
        intent.setData(null);
        intent.setFlags(0);
      }
  }

  private WritableMap processIntent() {
      WritableMap map = Arguments.createMap();

      String value = "";
      String type = "";
      String action = "";

      Activity currentActivity = getCurrentActivity();

      if (currentActivity != null) {
        Intent intent = currentActivity.getIntent();
        action = intent.getAction();
        type = intent.getType();
        if (type == null) {
          type = "";
        }
        if (Intent.ACTION_SEND.equals(action) && "text/plain".equals(type)) {
          value = intent.getStringExtra(Intent.EXTRA_TEXT);
        }
        else if (Intent.ACTION_SEND.equals(action) && ("image/*".equals(type) || "image/jpeg".equals(type) || "image/png".equals(type) || "image/jpg".equals(type) ) ) {
            return getImageData(currentActivity);
       } else {
         value = "";
       }
      } else {
        value = "";
        type = "";
      }

      map.putString("type", type);
      map.putString("value",value);

      return map;
  }
}

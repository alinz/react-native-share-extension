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
  public void clear() {
    Activity currentActivity = getCurrentActivity();
    
    if (currentActivity != null) {
      Intent intent = currentActivity.getIntent();
      intent.setAction("");
      intent.removeExtra(Intent.EXTRA_TEXT);
      intent.removeExtra(Intent.EXTRA_STREAM);
    }
  }

  @ReactMethod
  public void close() {
    getCurrentActivity().finish();
  }

  @ReactMethod
  public void data(Promise promise) {
      promise.resolve(processIntent());
  }

  public WritableMap processIntent() {
      WritableMap map = Arguments.createMap();
      WritableArray images = Arguments.createArray();

      String text = "";
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
          text = intent.getStringExtra(Intent.EXTRA_TEXT);
        } else if (Intent.ACTION_SEND.equals(action) && type.startsWith("image")) {
          Uri uri = (Uri) intent.getParcelableExtra(Intent.EXTRA_STREAM);
          images.pushString("file://" + RealPathUtil.getRealPathFromURI(currentActivity, uri));
        } else if (Intent.ACTION_SEND_MULTIPLE.equals(action) && type.startsWith("image")) {
          ArrayList<Uri> uris = intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM);
          for (Uri uri : uris) {
              images.pushString("file://" + RealPathUtil.getRealPathFromURI(currentActivity, uri));
          }
        } 
      } 

      map.putString("type", type);
      map.putString("text", text);
      map.putArray("images", images);

      return map;
  }
}

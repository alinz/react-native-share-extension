package com.alinz.parkerdan.shareextension;

import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;

import android.app.Activity;
import android.content.Intent;


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

   public WritableMap processIntent() {
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
       } else {
         value = "nope";
         type = "nope";
       }

       map.putString("type", type);
       map.putString("value",value);

       return map;
   }
}

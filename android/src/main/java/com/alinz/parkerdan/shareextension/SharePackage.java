package com.alinz.parkerdan.shareextension;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.uimanager.ViewManager;
import com.facebook.react.ReactPackage;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class SharePackage implements ReactPackage {
 @Override
   public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
     return Arrays.<NativeModule>asList(new ShareModule(reactContext));
   }

   @Override
   public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
       return Collections.emptyList();
   }
}

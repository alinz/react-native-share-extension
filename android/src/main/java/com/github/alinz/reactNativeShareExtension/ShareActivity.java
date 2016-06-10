package com.github.alinz.reactNativeShareExtension;

import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;

import com.facebook.react.ReactActivity;
import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.shell.MainReactPackage;
import com.facebook.react.uimanager.ViewManager;
import com.facebook.react.bridge.ReactMethod;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class ShareActivity extends ReactActivity {

    private class InternalShare extends ReactContextBaseJavaModule {
        public InternalShare(ReactApplicationContext reactContext) {
            super(reactContext);
        }

        @Override
        public String getName() {
            return "ShareExtension";
        }

        @ReactMethod
        public void close() {
            closeShareModal();
        }

        @ReactMethod
        public void data(Promise promise) {
            promise.resolve(processIntent());
        }
    }

    private class SharePackage implements ReactPackage {
        @Override
        public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
            List<NativeModule> modules = new ArrayList<>();

            modules.add(new InternalShare(reactContext));

            return modules;
        }

        @Override
        public List<Class<? extends JavaScriptModule>> createJSModules() {
            return Collections.emptyList();
        }

        @Override
        public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
            return Collections.emptyList();
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    /**
     * Returns the name of the main component registered from JavaScript.
     * This is used to schedule rendering of the component.
     */
    @Override
    protected String getMainComponentName() {
        return "Share";
    }

    /**
     * Returns whether dev mode should be enabled.
     * This enables e.g. the dev menu.
     */
    @Override
    protected boolean getUseDeveloperSupport() {
        return com.app.BuildConfig.DEBUG;
    }

    /**
     * A list of packages used by the app. If the app uses additional views
     * or modules besides the default ones, add more packages here.
     */
    @Override
    protected List<ReactPackage> getPackages() {
        return Arrays.<ReactPackage>asList(
                new MainReactPackage(),
                new SharePackage()
        );
    }

    protected WritableMap processIntent() {
        WritableMap map = Arguments.createMap();

        Intent intent = getIntent();
        String action = intent.getAction();
        String type = intent.getType();
        String value = "";

        if (type == null) {
            type = "";
        }

        //if you want to support more, just add more things here.
        //at the moment we are only supporting browser URL
        if (Intent.ACTION_SEND.equals(action) && "text/plain".equals(type)) {
            value = intent.getStringExtra(Intent.EXTRA_TEXT);
        }

        map.putString("type", type);
        map.putString("value", value);

        return map;
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    @Override
    public void onPause() {
        super.onPause();
        // Remove the activity when its off the screen
        closeShareModal();
    }

    protected void closeShareModal() {
        finish();
    }
}

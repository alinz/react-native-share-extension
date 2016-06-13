package com.sample1.share;

import com.github.alinz.reactNativeShareExtension.ShareExActivity;
import com.sample1.BuildConfig;


public class MyShareActivity extends ShareExActivity {
    @Override
    protected String getMainComponentName() {
        return "MyShareEx";
    }

    @Override
    protected boolean getUseDeveloperSupport() {
        return BuildConfig.DEBUG;
    }
}

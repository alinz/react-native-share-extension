# React Native Share Extension

This is a helper module which brings react native as an engine to drive share extension for your app.

# Installation

installation should be very easy by just installing it from npm.

```js
npm install react-native-share-extension --save
```

# Setup

the setup requires a little bit more work. I will try to describe as detail as possible. I would love to use `rnpm` so I will welcome pull request.

## iOS

- click on your project's name
- click on `+` sign

<p align="center">
    <img src ="assets/ios_step_01.png" />
</p>

- select `Share Extension` under `iOS > Application Extension`

<p align="center">
    <img src ="assets/ios_step_02.png" />
</p>

- select a name for your new share extension, in my case I chose `MyShareEx`

<p align="center">
    <img src ="assets/ios_step_03.png" />
</p>

- delete both `ShareViewController.h` and `ShareViewController.m`. make sure to click on `Move to Trash` button during deletion.

<p align="center">
    <img src ="assets/ios_step_04.png" />
</p>

- create new file under your share extension group. in my case it was `MyShareEx`

<p align="center">
    <img src ="assets/ios_step_05.png" />
</p>

- make sure the type of that object is `Objective-c File` and name it `MyShareEx.m`

<p align="center">
    <img src ="assets/ios_step_06.png" />
</p>

<p align="center">
    <img src ="assets/ios_step_07.png" />
</p>

- since we deleted `ShareViewController.m`, we need to tell the storyboard of your share extension where the view needs to be loaded. So click on `MainInterface.storyboard` and replace the class field from `ShareViewController` to `MyShareEx`

<p align="center">
    <img src ="assets/ios_step_08.png" />
</p>

- now it's time to add our library. Right click on `Libraries` group and select `Add Files to "Sample1"...`

<p align="center">
    <img src ="assets/ios_step_09.png" />
</p>

- select `node_modules` > `react-native-share-extension` > `ios` > `ReactNativeShareExtension.xcodeproj`

<p align="center">
    <img src ="assets/ios_step_10.png" />
</p>

- now we need to tell the share extension that we want to read new header files. click on project name, in my case `Sample1` then click on `MyShareEx`. After that click on Build Settings and search for `Header Search Paths`

<p align="center">
    <img src ="assets/ios_step_11.png" />
</p>

- add the new path `$(SRCROOT)/../node_modules/react-native-share-extension/ios` with `recursive` selected.

<p align="center">
    <img src ="assets/ios_step_12.png" />
</p>

- we need to add some flags as well, so search for `Other Linker Flags` and add `-Objc` and `lc++`

<p align="center">
    <img src ="assets/ios_step_13.png" />
</p>

- we also need to add all the static libraries such as react and Share Extension. so select `General` tab and under `Linked frameworks and Libraries` click on `+` and add all of the selected static binaries there.

<p align="center">
    <img src ="assets/ios_step_14.png" />
</p>

- we need to modify `MyShareEx/Info.plist` to make sure that our share extension can connect to ineternet. This is useful if you need your share extension connects to your api server or react-native remote server dev. For doing that we need to `App Transport Security Settings` to `Info.plist`

<p align="center">
    <img src ="assets/ios_step_15.png" />
</p>

- now go back to `MyShareEx.m` and paste the following code there.

```objective-c
#import <Foundation/Foundation.h>
#import "ReactNativeShareExtension.h"
#import "RCTRootView.h"

@interface MyShareEx : ReactNativeShareExtension
@end

@implementation MyShareEx

- (UIView*) shareView {
  //this is the name of registered component that ShareExtension loads.
  NSString *myShareComponentName = @"SampleShare";

  NSURL *jsCodeLocation = [NSURL URLWithString:@"http://localhost:8081/index.ios.bundle?platform=ios&dev=true"];

  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
         moduleName:myShareComponentName
  initialProperties:nil
      launchOptions:nil];
  rootView.backgroundColor = nil;
  return rootView;
}

@end
```

- now try to build the project. it should build successfully.

## Android

- edit `android/settings.gradle` file and add the following

```
include ':app', ':react-native-share-extension'

project(':react-native-share-extension').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-share-extension/android')
```

- edit `android/app/build.gradle` and add the following line before react section in dependency

```
dependencies {
    ...
    compile project(':react-native-share-extension')
    compile "com.facebook.react:react-native:+"
}
```

- create a package called `share` under your java project and create a new Java class. in my case I call it `MyShareActivity.java`. then paste the following code there.

```java
package com.sample1.share;

import com.github.alinz.reactNativeShareExtension.ShareExActivity;
import com.sample1.BuildConfig;


public class MyShareActivity extends ShareExActivity {
    @Override
    protected String getMainComponentName() {
        return "Share";
    }

    @Override
    protected boolean getUseDeveloperSupport() {
        return BuildConfig.DEBUG;
    }
}
```

- edit `android/app/src/main/AndroidMainfest.xml` and add the new `activity` right after `devSettingActivity`.

```xml
<activity android:name="com.facebook.react.devsupport.DevSettingsActivity"/>

<activity
    android:noHistory="true"
    android:name=".share.MyShareActivity"
    android:configChanges="orientation"
    android:label="@string/title_activity_share"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.Share.Transparent" >
   <intent-filter>
     <action android:name="android.intent.action.SEND" />
     <category android:name="android.intent.category.DEFAULT" />
     <data android:mimeType="text/plain" />
   </intent-filter>
</activity>
```

in this new `activity` I have used 2 variables `@string/title_activity_share` and `@style/Theme.Share.Transparent`. you can add those in `res/values`.

so in `values/strings.xml`

```xml
<resources>
    ...
    <string name="title_activity_share">MyShareEx</string>
</resources>
```

and in `values/styles.xml`

```xml
<resources>
    ...
    <style name="Share.Window" parent="android:Theme">
        <item name="android:windowEnterAnimation">@null</item>
        <item name="android:windowExitAnimation">@null</item>
    </style>

    <style name="Theme.Share.Transparent" parent="android:Theme">
        <item name="android:windowIsTranslucent">true</item>
        <item name="android:windowBackground">@android:color/transparent</item>
        <item name="android:windowContentOverlay">@null</item>
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowIsFloating">true</item>
        <item name="android:backgroundDimEnabled">true</item>
        <item name="android:windowAnimationStyle">@style/Share.Window</item>
    </style>
</resources>
```

- now you should be able to compile the code without error.

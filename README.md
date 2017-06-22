# React Native Share Extension

This is a helper module which brings react native as an engine to drive share extension for your app.

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios-demo.gif" />
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/android-demo.gif" />
</p>

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
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_01.png" />
</p>

- select `Share Extension` under `iOS > Application Extension`

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_02.png" />
</p>

- select a name for your new share extension, in my case I chose `MyShareEx`

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_03.png" />
</p>

- delete both `ShareViewController.h` and `ShareViewController.m`. make sure to click on `Move to Trash` button during deletion.

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_04.png" />
</p>

- create new file under your share extension group. in my case it was `MyShareEx`

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_05.png" />
</p>

- make sure the type of that object is `Objective-c File`, e.g. for `MyShareEx` name it `MyShareEx.m`

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_06.png" />
</p>

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_07.png" />
</p>

- since we deleted `ShareViewController.m`, we need to tell the storyboard of your share extension where the view needs to be loaded. So click on `MainInterface.storyboard` and replace the class field from `ShareViewController` to whatever you chose above (in my case `MyShareEx`)

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_08.png" />
</p>

- now it's time to add our library. Right click on `Libraries` group and select `Add Files to "Sample1"...`

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_09.png" />
</p>

- select `node_modules` > `react-native-share-extension` > `ios` > `ReactNativeShareExtension.xcodeproj`

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_10.png" />
</p>

- now we need to tell the share extension that we want to read new header files. click on project name, in my case `Sample1` then click on your extension name (in my case `MyShareEx`). After that click on Build Settings and search for `Header Search Paths`

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_11.png" />
</p>

- add the new path `$(SRCROOT)/../node_modules/react-native-share-extension/ios` with `recursive` selected.

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_12.png" />
</p>

- we need to add some flags as well, so search for `Other Linker Flags` and add `-ObjC` and `-lc++`

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_13.png" />
</p>

- we also need to add all the static libraries such as react and Share Extension. so select `General` tab and under `Linked frameworks and Libraries` click on `+` and add all of the selected static binaries there.

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_14.png" />
</p>

- we need to modify the `Info.plist` inside the extension (e.g. `MyShareEx/Info.plist`) to make sure that our share extension can connect to internet. This is useful if you need your share extension connects to your api server or react-native remote server dev. For doing that we need to `App Transport Security Settings` to `Info.plist`

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_15.png" />
</p>

- now go back to your extension file (in my case `MyShareEx.m`) and paste the following code there **being sure to substitute `MyShareEx` in all three places for whatever you chose above**

```objective-c
#import <Foundation/Foundation.h>
#import "ReactNativeShareExtension.h"
#import "React/RCTBundleURLProvider.h"
#import "React/RCTRootView.h"

@interface MyShareEx : ReactNativeShareExtension
@end

@implementation MyShareEx

RCT_EXPORT_MODULE();

- (UIView*) shareView {
  NSURL *jsCodeLocation;

  jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios" fallbackResource:nil];

  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"MyShareEx"
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

- create a folder called `share` under your java project and create two files. Call them `ShareActivity.java` and `ShareApplication.java`....just like your main project.

- ShareActivity should look like this

```java
// define your share project, if your main project is com.sample1, then com.sample1.share makes sense....
package com.sample1.share;


// import ReactActivity
import com.facebook.react.ReactActivity;


public class ShareActivity extends ReactActivity {
    @Override
    protected String getMainComponentName() {
      // this is the name AppRegistry will use to launch the Share View
        return "MyShareEx";
    }

}
```

- ShareApplication should look like this

```java
// your package you defined in ShareActivity
package com.sample1.share;
// import build config
import com.sample1.BuildConfig;

import com.alinz.parkerdan.shareextension.SharePackage;

import android.app.Application;

import com.facebook.react.shell.MainReactPackage;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactApplication;
import com.facebook.react.ReactPackage;

import java.util.Arrays;
import java.util.List;


public class ShareApplication extends Application implements ReactApplication {
 private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {
   @Override
   protected boolean getUseDeveloperSupport() {
     return BuildConfig.DEBUG;

   }

   @Override
   protected List<ReactPackage> getPackages() {
     return Arrays.<ReactPackage>asList(
         new MainReactPackage(),
         new SharePackage()
     );
   }
 };

 @Override
 public ReactNativeHost getReactNativeHost() {
     return mReactNativeHost;
 }
}
```

- MainApplication should look like this
```java
// your package you defined in ShareActivity
package com.sample1;

import android.app.Application;
import android.util.Log;

import com.facebook.react.ReactApplication;
import com.facebook.react.ReactInstanceManager;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.react.shell.MainReactPackage;

import com.alinz.parkerdan.shareextension.SharePackage;

import java.util.Arrays;
import java.util.List;

public class MainApplication extends Application implements ReactApplication {

  private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {
    @Override
    protected boolean getUseDeveloperSupport() {
      return BuildConfig.DEBUG;
    }

    @Override
    protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
          new MainReactPackage(),
          new SharePackage()
      );
    }
  };

  @Override
  public ReactNativeHost getReactNativeHost() {
      return mReactNativeHost;
  }
}
```

- edit `android/app/src/main/AndroidMainfest.xml` and add the new `activity` right after `devSettingActivity`.

```xml
<activity android:name="com.facebook.react.devsupport.DevSettingsActivity"/>

<activity
    android:noHistory="true"
    android:name=".share.ShareActivity"
    android:configChanges="orientation"
    android:label="@string/title_activity_share"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.Share.Transparent" >
   <intent-filter>
     <action android:name="android.intent.action.SEND" />
     <category android:name="android.intent.category.DEFAULT" />
    //  for sharing links include
     <data android:mimeType="text/plain" />
    //  for sharing photos include
    <data android:mimeType="image/*" />
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

> if you need to add more packages to your share extension do not overrides
`getPackages`. instead override `getMorePackages` method under `ShareExActivity`.

# Share Component

so both share extension and main application are using the same code base, or same main.jsbundle file. So the trick to separate Share and Main App is registering 2 different Component entries with `AppRegistry.registerComponent`.

so in both iOS and android share extension we are telling react to load the extension component (in my case `MyShareEx`) from js.

so in `index.ios.js` and `index.android.js` we are writing the same code as

```js
//index.android.js
import React from 'react'
import { AppRegistry } from 'react-native'

import App from './app.android'
import Share from './share.android'

AppRegistry.registerComponent('Sample1', () => App)
AppRegistry.registerComponent('MyShareEx', () => Share) // TODO: Replace MyShareEx with my extension name
```

```js
//index.ios.js
import React from 'react'
import { AppRegistry } from 'react-native'

import App from './app.ios'
import Share from './share.ios'

AppRegistry.registerComponent('Sample1', () => App)
AppRegistry.registerComponent('MyShareEx', () => Share) // TODO: Replace MyShareEx with my extension name
```

so the `app.ios` and `app.android.js` refers to main app and `share.ios.js` and `share.android.js` refers to share extension.

# Share Extension APIs

- `data()` is a function that returns a promise. Once the promise is resolved, you get two values, `type` and `value`.


```js
import ShareExtension from 'react-native-share-extension'
...

const { type, value } = await ShareExtension.data()
```

- `close()`

it simply close the share extension and return the touch event back to application that triggers the share.

# Test on Device without dev-server

because share extension in ios devices are separate containers and the do not have access to main app folder, you have to build the script twice and package it inside the share extension container. The easiest way of doing this is create a `New Script Phase` in `Build Phases` of your share extension and copy the following line

```bash
export NODE_BINARY=node
../node_modules/react-native/packager/react-native-xcode.sh
```

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_16.png" />
</p>

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/ios_step_17.png" />
</p>

# On iOS: Set the NSExtensionActivationRule key in your Info.plist

For the time being, this package only handles sharing of urls specifically from browsers. In order to tell the system to show your extension only when sharing a url, you must set the `NSExtensionActivationRule` key (under `NSExtensionAttributes`) in the share extension's Info.plist file as follows (this is also needed to pass Apple's reveiw):

```
<key>NSExtensionAttributes</key>
<dict>
  <key>NSExtensionActivationRule</key>
  <dict>
    <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
    <integer>1</integer>
  </dict>
</dict>
```

<p align="center">
    <img src ="https://raw.githubusercontent.com/alinz/react-native-share-extension/master/assets/NSExtensionActivationRule.png" />
</p>

Note that while the above will prevent many apps from wrongly sharing using your extension, some apps (e.g., YouTube) will still allow sharing using your extension, which might cause your extension to crash. Check out [this issue](https://github.com/alinz/react-native-share-extension/issues/40) for details.

For reference about `NSExtensionActivationRule` checkout [Apple's docs](https://developer.apple.com/library/content/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html#//apple_ref/doc/uid/TP40014214-CH21-SW8)

# Final note

I have used `react-native-modalbox` module to handle the showing and hiding share extension which makes the experience more enjoyable for the user.

Cheers

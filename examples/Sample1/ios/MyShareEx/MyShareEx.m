//
//  MyShareEx.m
//  Sample1
//
//  Created by Ali Najafizadeh on 2016-06-10.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReactNativeShareExtension.h"
#import "RCTRootView.h"

@interface MyShareEx : ReactNativeShareExtension
@end

@implementation MyShareEx

RCT_EXPORT_MODULE();

- (UIView*) shareView {
  NSString *myShareComponentName = @"MyShareEx";
  NSURL *jsCodeLocation = [NSURL URLWithString:@"http://localhost:8081/index.ios.bundle?platform=ios&dev=true"];
  
  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:myShareComponentName
                                               initialProperties:nil
                                                   launchOptions:nil];
  rootView.backgroundColor = nil;
  return rootView;
}

@end
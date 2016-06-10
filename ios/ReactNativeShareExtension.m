#import "ReactNativeShareExtension.h"
#import <RCTRootView.h>

#define ITEM_IDENTIFIER @"public.url"

NSExtensionContext* extensionContext;

@implementation ReactNativeShareExtension {
  NSTimer *autoTimer;
  NSString* type;
  NSString* value;
}

- (UIView*) shareView {
  return nil;
}

RCT_EXPORT_MODULE();

- (void)viewDidLoad {
  [super viewDidLoad];
  
  //object variable for extension doesn't work for react-native. It must be assign to gloabl
  //variable extensionContext. in this way, both exported method can touch extensionContext
  extensionContext = self.extensionContext;
  
  UIView *rootView = [self shareView];
  if (rootView.backgroundColor == nil) {
    rootView.backgroundColor = [[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:0.1];
  }
  
  self.view = rootView;
}


RCT_EXPORT_METHOD(close) {
  [extensionContext completeRequestReturningItems:nil
                                completionHandler:nil];
}

RCT_REMAP_METHOD(data,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  [self extractUrlFromContext: extensionContext withCallback:^(NSURL* url, NSException* err) {
    NSDictionary *inventory = @{
      @"type": @"text/plain",
      @"value": [url absoluteString]
    };
    
    resolve(inventory);
  }];
}

- (void)extractUrlFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSURL *url, NSException *exception))callback {
  @try {
    NSExtensionItem *item = [context.inputItems firstObject];
    NSArray *attachments = item.attachments;
    __block NSItemProvider *urlProvider = nil;
    [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
      if([provider hasItemConformingToTypeIdentifier:ITEM_IDENTIFIER]) {
        urlProvider = provider;
        *stop = YES;
      }
    }];
    
    if(urlProvider) {
      [urlProvider loadItemForTypeIdentifier:ITEM_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
        NSURL *url = (NSURL *)item;
        
        if(callback) {
          callback(url, nil);
        }
      }];
    }
    else {
      if(callback) {
        callback(nil, [NSException exceptionWithName:@"provider error" reason:@"couldn't find url provider" userInfo:nil]);
      }
    }
  }
  @catch (NSException *exception) {
    if(callback) {
      callback(nil, exception);
    }
  }
}

@end

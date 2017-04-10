#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"

#define ITEM_IDENTIFIER @"public.url"
#define IMAGE_IDENTIFIER @"public.image"

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
  [self extractDataFromContext: extensionContext withCallback:^(NSArray* items ,NSException* err) {
    if (items == nil) {
      resolve(nil);
      return;
    }
    resolve(items[0]);
  }];
}

RCT_REMAP_METHOD(dataMulti,
                 resolverMulti:(RCTPromiseResolveBlock)resolve
                 rejecterMulti:(RCTPromiseRejectBlock)reject)
{
  [self extractDataFromContext: extensionContext withCallback:^(NSArray* items ,NSException* err) {
    resolve(items);
  }];
}

typedef void (^ProviderCallback)(NSURL *url, NSString *contentType, NSException *exception);

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSArray *items ,NSException *exception))callback {
  @try {
    NSExtensionItem *item = [context.inputItems firstObject];
    NSArray *attachments = item.attachments;
    NSMutableArray *items = [[NSMutableArray alloc] init];
     
    __block int attachmentIdx = 0;
    __block ProviderCallback providerCb = nil;
    providerCb = ^ void (NSURL *url, NSString *contentType, NSException *exception) {
      if (exception) {
        callback(nil, exception);
        return;
      }
    
      [items addObject:@{
                        @"type": contentType,
                        @"value": [url absoluteString]
                        }];

      ++attachmentIdx;
      if (attachmentIdx == [attachments count]) {
        callback(items, nil);
      } else {
        [self extractDataFromProvider:attachments[attachmentIdx] withCallback: providerCb];
      }
    };
    [self extractDataFromProvider:attachments[0] withCallback: providerCb];
  }
  @catch (NSException *exception) {
    callback(nil,exception);
  }
}

- (void)extractDataFromProvider:(NSItemProvider *)provider withCallback:(void(^)(NSURL* url, NSString* contentType ,NSException *exception))callback {
  NSItemProvider *urlProvider = nil;
  NSItemProvider *imageProvider = nil;
    
  if([provider hasItemConformingToTypeIdentifier:ITEM_IDENTIFIER]) {
    urlProvider = provider;
  }else if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]){
    imageProvider = provider;
  }
    
  if(urlProvider) {
    [urlProvider loadItemForTypeIdentifier:ITEM_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
      NSURL *url = (NSURL *)item;
        
      if(callback) {
        callback(url,@"text/plain" ,nil);
      }
    }];
  }else if (imageProvider){
    [imageProvider loadItemForTypeIdentifier:IMAGE_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
      NSURL *url = (NSURL *)item;
        
      if(callback) {
        callback(url,[[[url absoluteString] pathExtension] lowercaseString] ,nil);
      }
    }];
  } else {
    if(callback) {
      callback(nil, nil,[NSException exceptionWithName:@"Error" reason:@"couldn't find provider" userInfo:nil]);
    }
  }
}

@end

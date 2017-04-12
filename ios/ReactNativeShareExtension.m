#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"

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


RCT_EXPORT_METHOD(close:(NSString *)appGroupId) {
  [self cleanUpTempFiles:appGroupId];
  [extensionContext completeRequestReturningItems:nil
                                completionHandler:nil];
}

RCT_REMAP_METHOD(data,
                 appGroupId: (NSString *)appGroupId
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  [self extractDataFromContext: extensionContext withAppGroup:appGroupId andCallback:^(NSArray* items ,NSError* err) {
    if (items == nil) {
      resolve(nil);
      return;
    }
    resolve(items[0]);
  }];
}

RCT_REMAP_METHOD(dataMulti,
                 appGroupId: (NSString *)appGroupId
                 resolverMulti:(RCTPromiseResolveBlock)resolve
                 rejecterMulti:(RCTPromiseRejectBlock)reject)
{
  [self extractDataFromContext: extensionContext withAppGroup: appGroupId andCallback:^(NSArray* items ,NSError* err) {
    if (err) {
      reject(@"dataMulti", @"Failed to extract attachment content", err);
      return;
    }
    resolve(items);
  }];
}

typedef void (^ProviderCallback)(NSString *content, NSString *contentType, BOOL owner, NSError *err);

- (void)extractDataFromContext:(NSExtensionContext *)context withAppGroup:(NSString *) appGroupId andCallback:(void(^)(NSArray *items ,NSError *err))callback {
  @try {
    NSExtensionItem *item = [context.inputItems firstObject];
    NSArray *attachments = item.attachments;
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    __block int attachmentIdx = 0;
    __block ProviderCallback providerCb = nil;
    __block __weak ProviderCallback weakProviderCb = nil;
    providerCb = ^ void (NSString *content, NSString *contentType, BOOL owner, NSError *err) {
      if (err) {
        callback(nil, err);
        return;
      }
      
      if (content != nil) {
        [items addObject:@{
                           @"type": contentType,
                           @"value": content,
                           @"owner": [NSNumber numberWithBool:owner],
                           }];
      }

      ++attachmentIdx;
      if (attachmentIdx == [attachments count]) {
        callback(items, nil);
      } else {
        [self extractDataFromProvider:attachments[attachmentIdx] withAppGroup:appGroupId andCallback: weakProviderCb];
      }
    };
    weakProviderCb = providerCb;
    [self extractDataFromProvider:attachments[0] withAppGroup:appGroupId andCallback: providerCb];
  }
  @catch (NSException *exc) {
    NSError *error = [NSError errorWithDomain:@"fiftythree.paste" code:1 userInfo:@{
                                                                                    @"reason": [exc description]
                                                                                    }];
    callback(nil, error);
  }
}

- (void)extractDataFromProvider:(NSItemProvider *)provider withAppGroup:(NSString *) appGroupId andCallback:(void(^)(NSString* content, NSString* contentType, BOOL owner, NSError *err))callback {

  if([provider hasItemConformingToTypeIdentifier:@"public.image"]) {
    [provider loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:^(id<NSSecureCoding, NSObject> item, NSError *error) {
      if (error) {
        callback(nil, nil, NO, error);
        return;
      }
      
      @try {
        if ([item isKindOfClass: NSURL.class]) {
          NSURL *url = (NSURL *)item;
          return callback([url absoluteString], @"public.image", NO, nil);
        } else if ([item isKindOfClass: UIImage.class]) {
          UIImage *image = (UIImage *)item;
          NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]];
          NSURL *tempContainerURL = [ReactNativeShareExtension tempContainerURL:appGroupId];
          if (tempContainerURL == nil){
            return callback(nil, nil, NO, nil);
          }
          
          NSURL *tempFileURL = [tempContainerURL URLByAppendingPathComponent: fileName];
          BOOL created = [UIImageJPEGRepresentation(image, 0.95) writeToFile:[tempFileURL path] atomically:YES];
          if (created) {
            return callback([tempFileURL absoluteString], @"public.image", YES, nil);
          } else {
            return callback(nil, nil, NO, nil);
          }
        } else if ([item isKindOfClass: NSData.class]) {
          NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]];
          NSData *data = (NSData *)item;
          UIImage *image = [UIImage imageWithData:data];
          NSURL *tempContainerURL = [ReactNativeShareExtension tempContainerURL:appGroupId];
          if (tempContainerURL == nil){
            return callback(nil, nil, NO, nil);
          }
          NSURL *tempFileURL = [tempContainerURL URLByAppendingPathComponent: fileName];
          BOOL created = [UIImageJPEGRepresentation(image, 0.95) writeToFile:[tempFileURL path] atomically:YES];
          if (created) {
            return callback([tempFileURL absoluteString], @"public.image", YES, nil);
          } else {
            return callback(nil, nil, NO, nil);
          }
        } else {
          // Do nothing, some type we don't support.
          return callback(nil, nil, NO, nil);
        }
      }
      @catch(NSException *exc) {
        NSError *error = [NSError errorWithDomain:@"fiftythree.paste" code:2 userInfo:@{
                                                                                        @"reason": [exc description]
                                                                                        }];
        callback(nil, nil, NO, error);
      }
    }];
    return;
  }

  if([provider hasItemConformingToTypeIdentifier:@"public.file-url"]) {
    [provider loadItemForTypeIdentifier:@"public.file-url" options:nil completionHandler:^(id<NSSecureCoding, NSObject> item, NSError *error) {
      if (error) {
        callback(nil, nil, NO, error);
        return;
      }
      
      if ([item isKindOfClass:NSURL.class]) {
        return callback([(NSURL *)item absoluteString], @"public.file-url", NO, nil);
      } else if ([item isKindOfClass:NSString.class]) {
        return callback((NSString *)item, @"public.file-url", NO, nil);
      }
      callback(nil, nil, NO, nil);
    }];
    return;
  }
  
  if([provider hasItemConformingToTypeIdentifier:@"public.url"]) {
    [provider loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(id<NSSecureCoding, NSObject> item, NSError *error) {
      if (error) {
        callback(nil, nil, NO, error);
        return;
      }
      
      if ([item isKindOfClass:NSURL.class]) {
        return callback([(NSURL *)item absoluteString], @"public.url", NO, nil);
      } else if ([item isKindOfClass:NSString.class]) {
        return callback((NSString *)item, @"public.url", NO, nil);
      }
    }];
    return;
  }
  
  if([provider hasItemConformingToTypeIdentifier:@"public.plain-text"]) {
    [provider loadItemForTypeIdentifier:@"public.plain-text" options:nil completionHandler:^(id<NSSecureCoding, NSObject> item, NSError *error) {
      if (error) {
        callback(nil, nil, NO, error);
        return;
      }
      
      if ([item isKindOfClass:NSString.class]) {
        return callback((NSString *)item, @"public.plain-text", NO, nil);
      } else if ([item isKindOfClass:NSAttributedString.class]) {
        NSAttributedString *str = (NSAttributedString *)item;
        return callback([str string], @"public.plain-text", NO, nil);
      } else if ([item isKindOfClass:NSData.class]) {
        NSString *str = [[NSString alloc] initWithData:(NSData *)item encoding:NSUTF8StringEncoding];
        if (str) {
          return callback(str, @"public.plain-text", NO, nil);
        } else {
          return callback(nil, nil, NO, nil);
        }
      } else {
        return callback(nil, nil, NO, nil);
      }
    }];
    return;
  }
  
  callback(nil, nil, NO, nil);
}

+ (NSURL*) tempContainerURL: (NSString*)appGroupId {
  NSFileManager *manager = [NSFileManager defaultManager];
  NSURL *containerURL = [manager containerURLForSecurityApplicationGroupIdentifier: appGroupId];
  NSURL *tempDirectoryURL = [containerURL URLByAppendingPathComponent:@"shareTempItems"];
  if (![manager fileExistsAtPath:[tempDirectoryURL path]]) {
    NSError *err;
    [manager createDirectoryAtURL:tempDirectoryURL withIntermediateDirectories:YES attributes:nil error:&err];
    if (err) {
      return nil;
    }
  }

  return tempDirectoryURL;
}

- (void) cleanUpTempFiles:(NSString *)appGroupId {
  NSURL *tmpDirectoryURL = [ReactNativeShareExtension tempContainerURL:appGroupId];
  if (tmpDirectoryURL == nil) {
    return;
  }

  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error;
  NSArray *tmpFiles = [fileManager contentsOfDirectoryAtPath:[tmpDirectoryURL path] error:&error];
  if (error) {
    return;
  }

  for (NSString *file in tmpFiles)
  {
    error = nil;
    [fileManager removeItemAtPath:[[tmpDirectoryURL URLByAppendingPathComponent:file] path] error:&error];
  }
}

@end

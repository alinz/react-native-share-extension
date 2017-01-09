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
 [self extractDataFromContext: extensionContext withCallback:^(NSURL* url,NSString* contentType ,NSException* err) {
   NSDictionary *inventory = @{
     @"type": contentType,
     @"value": [url absoluteString]
   };

   resolve(inventory);
 }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSURL *url, NSString* contentType ,NSException *exception))callback {
 @try {
   NSExtensionItem *item = [context.inputItems firstObject];
   NSArray *attachments = item.attachments;
   __block NSItemProvider *urlProvider = nil;
   __block NSItemProvider *imageProvider = nil;
   [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
     if([provider hasItemConformingToTypeIdentifier:ITEM_IDENTIFIER]) {
       urlProvider = provider;
       *stop = YES;
     }else if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]){
         imageProvider = provider;
         *stop = YES;

     }
   }];

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


   }
   else {
     if(callback) {
       callback(nil, nil,[NSException exceptionWithName:@"Error" reason:@"couldn't find provider" userInfo:nil]);
     }
   }
 }
 @catch (NSException *exception) {
   if(callback) {
     callback(nil,nil ,exception);
   }
 }
}

@end

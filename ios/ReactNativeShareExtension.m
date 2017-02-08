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

RCT_EXPORT_METHOD(clear) {
 // Method irrelevant for iOS.
}



RCT_REMAP_METHOD(data,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
  [self extractDataFromContext: extensionContext withCallback:^(NSDictionary *inventory ,NSException* err) {
    resolve(inventory);
  }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSDictionary *dict, NSException *exception))callback {
 @try {
   NSExtensionItem *item = [context.inputItems firstObject];
   NSArray *attachments = item.attachments;
   __block NSItemProvider *urlProvider = nil;
   __block NSItemProvider *imageProvider = nil;
   
   [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
     if([provider hasItemConformingToTypeIdentifier:ITEM_IDENTIFIER]) {
       urlProvider = provider;
       *stop = YES;
     }
     else if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]) {
       imageProvider = provider;
       *stop = YES;
     }
   }];
     
   if (!callback) {
     return;
   }

   if(urlProvider) {
     [urlProvider loadItemForTypeIdentifier:ITEM_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
       NSURL *url = (NSURL *)item;
       callback([self createTypeValuePair:url contentType:@"text/plain"], nil);
     }];
   }
   else if (imageProvider){
       [imageProvider loadItemForTypeIdentifier:IMAGE_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
         callback([self createImageDataObject:item], nil);
       }];
   }
   else {
     callback(nil, [NSException exceptionWithName:@"Error" reason:@"Couldn't find provider" userInfo:nil]);
   }
 }
 @catch (NSException *exception) {
   callback(nil, exception);
 }
}


- (NSDictionary*) createTypeValuePair:(NSURL*) url
                          contentType:(NSString*) contentType
{
  return @{
           @"type": contentType,
           @"value": [url absoluteString]
           };
}

- (NSDictionary*) createImageDataObject:(NSURL*) url
{
  NSData *imageData = [NSData dataWithContentsOfURL:url];
  UIImage *image = [UIImage imageWithData:imageData];
  
  return @{
           @"type": [[[url absoluteString] pathExtension] lowercaseString],
           @"value": [url absoluteString],
           @"name": [[url absoluteString] lastPathComponent],
           @"image": @{
               @"size": @{
                   @"height": [NSNumber numberWithFloat:image.size.height],
                   @"width": [NSNumber numberWithFloat:image.size.width]
                   }
               }
           };
}

@end

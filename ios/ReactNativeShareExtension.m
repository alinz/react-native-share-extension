#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define URL_IDENTIFIER @"public.url"
#define IMAGE_IDENTIFIER @"public.image"
#define TEXT_IDENTIFIER (NSString *)kUTTypePlainText

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
    [self extractDataFromContext: extensionContext withCallback:^(NSArray* items, NSException* err) {
        if(err) {
            reject(@"error", err.description, nil);
        } else {
            resolve(items);
        }
    }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSArray *items, NSException *exception))callback {
    @try {
        __block NSMutableArray *itemArray = [NSMutableArray new];
        NSExtensionItem *item = [context.inputItems firstObject];

        NSArray *attachments = item.attachments;

        __block NSItemProvider *urlProvider = nil;
        __block NSItemProvider *imageProvider = nil;
        __block NSItemProvider *textProvider = nil;
        __block NSUInteger index = 0;

        [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
            if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]){
                imageProvider = provider;
                [imageProvider loadItemForTypeIdentifier:IMAGE_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                    /**
                     * Save the image to NSTemporaryDirectory(), which cleans itself tri-daily.
                     * This is necessary as the iOS 11 screenshot editor gives us a UIImage, while
                     * sharing from Photos and similar apps gives us a URL
                     * Therefore the solution is to save a UIImage, either way, and return the local path to that temp UIImage
                     * This path will be sent to React Native and can be processed and accessed RN side.
                     **/

                    UIImage *sharedImage;
                    NSString *filename;

                    if ([(NSObject *)item isKindOfClass:[UIImage class]]){
                        sharedImage = (UIImage *)item;
                        NSString *name = @"RNSE_TEMP_IMG_";
                        NSString *nbFiles = [NSString stringWithFormat:@"%@",  @(index)];
                        NSString *fullname = [name stringByAppendingString:(nbFiles)];
                        filename = [fullname stringByAppendingPathExtension:@"png"];
                    }else if ([(NSObject *)item isKindOfClass:[NSURL class]]){
                        NSURL* url = (NSURL *)item;
                        filename = [[url lastPathComponent] lowercaseString];
                        NSData *data = [NSData dataWithContentsOfURL:url];
                        sharedImage = [UIImage imageWithData:data];
                    }
                    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];

                    [UIImageJPEGRepresentation(sharedImage, 1.0) writeToFile:filePath atomically:YES];
                    index += 1;

                    [itemArray addObject: @{
                                            @"type": [filePath pathExtension],
                                            @"value": filePath
                                            }];
                    if (callback && (index == [attachments count])) {
                        callback(itemArray, nil);
                    }

                }];
            } else if([provider hasItemConformingToTypeIdentifier:URL_IDENTIFIER]) {
                urlProvider = provider;
                index += 1;
                [urlProvider loadItemForTypeIdentifier:URL_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                    NSURL *url = (NSURL *)item;
                    [itemArray addObject: @{
                                            @"type": @"text/plain",
                                            @"value": [url absoluteString]
                                            }];
                    if (callback && (index == [attachments count])) {
                        callback(itemArray, nil);
                    }
                }];
            } else if ([provider hasItemConformingToTypeIdentifier:TEXT_IDENTIFIER]){
                textProvider = provider;
                [textProvider loadItemForTypeIdentifier:TEXT_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                    NSString *text = (NSString *)item;
                    index += 1;
                    [itemArray addObject: @{
                                            @"type": @"text/plain",
                                            @"value": text
                                            }];
                    if (callback && (index == [attachments count])) {
                        callback(itemArray, nil);
                    }
                }];
            } else {
                index += 1;
            }
        }];
        //        }
    }
    @catch (NSException *exception) {
        if(callback) {
            callback(nil, exception);
        }
    }
}

@end

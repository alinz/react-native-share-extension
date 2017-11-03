#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define URL_IDENTIFIER @"public.url"
#define IMAGE_IDENTIFIER @"public.image"
#define TEXT_IDENTIFIER (NSString *)kUTTypePlainText
#define VIDEO_IDENTIFIER (NSString *)kUTTypeQuickTimeMovie

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



RCT_REMAP_METHOD(data, resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self extractDataFromContext: extensionContext withCallback:^(NSArray *files) {
        resolve(@{@"files": files});
    }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSArray *files))callback {
    NSArray *attachments = ((NSExtensionItem *)context.inputItems.firstObject).attachments;
    __block NSInteger itemCount = attachments.count;
    NSMutableArray *output = [[NSMutableArray alloc] initWithCapacity:itemCount];
    NSLog(@"Loaded %lu attachments: %@",itemCount, attachments);
    for (NSItemProvider *item in attachments) {
        NSLog(@"Loading item: %@",item);
        if (item) {
            [self getSharedItems:item withCallback:^(NSDictionary *data, NSException *exception) {
                if (data) [output addObject:data];
                if (--itemCount <= 0) {
                    callback([output copy]);
                }
            }];
        } else {
            --itemCount;
        }
    }
}

- (void)getSharedItems:(NSItemProvider *)item withCallback:(void(^)(NSDictionary *data, NSException *exception))callback {
    @try {
        if([item hasItemConformingToTypeIdentifier:URL_IDENTIFIER]) {
            [item loadItemForTypeIdentifier:URL_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                NSURL *url = (NSURL *)item;

                if(callback) {
                    callback(@{@"value":[url absoluteString], @"type":@"text/plain"}, nil);
                }
            }];
        } else if ([item hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]) {
            [item loadItemForTypeIdentifier:IMAGE_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                NSURL *url = (NSURL *)item;

                if(callback) {
                    callback(@{@"value":[url absoluteString], @"type":[[[url absoluteString] pathExtension] lowercaseString]}, nil);
                }
            }];
        } else if ([item hasItemConformingToTypeIdentifier:TEXT_IDENTIFIER]) {
            [item loadItemForTypeIdentifier:TEXT_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                NSString *text = (NSString *)item;

                if(callback) {
                    callback(@{@"value":text, @"type":@"text/plain"}, nil);
                }
            }];
        } else if ([item hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER]) {
            NSLog(@"[SHARE EXTENSION]: loading item for video identifier...");
            [item loadItemForTypeIdentifier:VIDEO_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                NSURL *url = (NSURL *)item;

                if(callback) {
                    callback(@{@"value":[url absoluteString], @"type":[[[url absoluteString] pathExtension] lowercaseString]}, nil);
                }
            }];
        } else {
            if(callback) {
                callback(nil, [NSException exceptionWithName:@"Error" reason:@"couldn't find provider" userInfo:nil]);
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

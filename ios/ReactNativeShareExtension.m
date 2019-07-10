#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define URL_IDENTIFIER @"public.url"
#define IMAGE_IDENTIFIER @"public.image"
#define TEXT_IDENTIFIER (NSString *)kUTTypePlainText
#define HTML_IDENTIFIER (NSString *)kUTTypePropertyList

NSExtensionContext* extensionContext;

@implementation ReactNativeShareExtension {
    NSTimer *autoTimer;
    NSString* type;
    NSString* value;
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
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



RCT_EXPORT_METHOD(openURL:(NSString *)url) {
  UIApplication *application = [UIApplication sharedApplication];
  NSURL *urlToOpen = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  [application openURL:urlToOpen options:@{} completionHandler: nil];
}



RCT_REMAP_METHOD(data,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    [self extractDataFromContext: extensionContext withCallback:^(NSString* val, NSString* contentType, NSException* err) {
        if(err) {
            reject(@"error", err.description, nil);
        } else {
            resolve(@{
                      @"type": contentType,
                      @"value": val
                      });
        }
    }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSString *value, NSString* contentType, NSException *exception))callback {
    @try {
        NSExtensionItem *item = [context.inputItems firstObject];
        NSArray *attachments = item.attachments;

        __block NSItemProvider *urlProvider = nil;
        __block NSItemProvider *imageProvider = nil;
        __block NSItemProvider *textProvider = nil;
        __block NSItemProvider *htmlProvider = nil;
        
        [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
            // Change: 04-07-2019, Jordy van den Aardweg
            // "*stop = YES;" is commented out because some apps share "text" ánd a "url".
            // If we just want the "url" in that scenario, but the "text" is the first attachment, 
            // we could never get the URL with *stop = YES; enabled. As this will stop at the "text" part.
            if([provider hasItemConformingToTypeIdentifier:URL_IDENTIFIER]) {
                urlProvider = provider;
                // *stop = YES;
            } else if ([provider hasItemConformingToTypeIdentifier:TEXT_IDENTIFIER]){
                textProvider = provider;
                // *stop = YES;
            } else if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]){
                imageProvider = provider;
                // *stop = YES;
            } else if ([provider hasItemConformingToTypeIdentifier:HTML_IDENTIFIER]){
                htmlProvider = provider;
                // *stop = YES;
            }
        }];
        
        // Change: 04-07-2019, Jordy van den Aardweg
        // In below's if else if statements we have changed the order, from:
        // urlProvider, imageProvider, textProvider
        // to
        // urlProvider, textProvider, imageProvider
        // Because our App just needs an URL. The URL could also be available als text
        // We don't really care about the image, so we placed that last.
        
        if(htmlProvider) {
            [htmlProvider loadItemForTypeIdentifier:HTML_PROVIDER options:nil completionHandler:^(NSDictionary *jsDict, NSError *error) {
                NSDictionary *jsPreprocessingResults = jsDict[NSExtensionJavaScriptPreprocessingResultsKey]

                if(callback) {
                    callback(jsPreprocessingResults, @"text/plain", nil);
                }
            }];
        } else if(urlProvider) {
            [urlProvider loadItemForTypeIdentifier:URL_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                NSURL *url = (NSURL *)item;

                if(callback) {
                    callback([url absoluteString], @"text/plain", nil);
                }
            }];
        } else if (textProvider) {
            [textProvider loadItemForTypeIdentifier:TEXT_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                NSString *text = (NSString *)item;

                if(callback) {
                    callback(text, @"text/plain", nil);
                }
            }];
        } else if (imageProvider) {
            [imageProvider loadItemForTypeIdentifier:IMAGE_IDENTIFIER options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                NSURL *url = (NSURL *)item;

                if(callback) {
                    callback([url absoluteString], [[[url absoluteString] pathExtension] lowercaseString], nil);
                }
            }];
        } else {
            if(callback) {
                callback(nil, nil, [NSException exceptionWithName:@"Error" reason:@"couldn't find provider" userInfo:nil]);
            }
        }
    }
    @catch (NSException *exception) {
        if(callback) {
            callback(nil, nil, exception);
        }
    }
}

@end

#import "ReactNativeShareExtension.h"
#import "React/RCTRootView.h"
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

#define URL_IDENTIFIER @"public.url"
#define IMAGE_IDENTIFIER @"public.image"
#define TEXT_IDENTIFIER (NSString *)kUTTypePlainText

#define VIDEO_IDENTIFIER_MPEG_4 @"public.mpeg-4"
#define VIDEO_IDENTIFIER_QUICK_TIME_MOVIE @"com.apple.quicktime-movie"

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



RCT_EXPORT_METHOD(openURL:(NSString *)url) {
  UIApplication *application = [UIApplication sharedApplication];
  NSURL *urlToOpen = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  [application openURL:urlToOpen options:@{} completionHandler: nil];
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

        __block NSItemProvider *imageProvider = nil;
        __block NSItemProvider *textProvider = nil;
        // __block NSItemProvider *videoProvider = nil;
        __block NSUInteger index = 0;
        
        // Formatter used for videos
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];

        [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
            if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER] || [provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER_MPEG_4] || [provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER_QUICK_TIME_MOVIE]){
                imageProvider = provider;
                NSString *VideoIdentifier;
                if([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]){
                    VideoIdentifier = IMAGE_IDENTIFIER;
                }else if([provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER_MPEG_4]){
                    VideoIdentifier = VIDEO_IDENTIFIER_MPEG_4;
                }else {
                    VideoIdentifier = VIDEO_IDENTIFIER_QUICK_TIME_MOVIE;
                }
                [imageProvider loadItemForTypeIdentifier:VideoIdentifier options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                    /**
                     * Save the image to NSTemporaryDirectory(), which cleans itself tri-daily.
                     * This is necessary as the iOS 11 screenshot editor gives us a UIImage, while
                     * sharing from Photos and similar apps gives us a URL
                     * Therefore the solution is to save a UIImage, either way, and return the local path to that temp UIImage
                     * This path will be sent to React Native and can be processed and accessed RN side.
                     **/
                    // CGImageSourceRef source = CGImageSourceCreateWithData((CFMutableDataRef)item, NULL);
                    // NSDictionary* metadata = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,NULL));
                    // NSLog(@"image data %@", metadata);
                    
                    UIImage *sharedImage;
                    NSString *filename;
                    NSString *type = @"";
                    NSString *orientation =@"";
                    NSString *timestamp = @"";
                    NSString *latitude = @"";
                    NSString *longitude = @"";
                    NSString *filePath = @"";
                    
                    if ([(NSObject *)item isKindOfClass:[UIImage class]]){
                        sharedImage = (UIImage *)item;
                        NSString *name = @"RNSE_TEMP_IMG_";
                        NSString *nbFiles = [NSString stringWithFormat:@"%@",  @(index)];
                        NSString *fullname = [name stringByAppendingString:(nbFiles)];
                        filename = [fullname stringByAppendingPathExtension:@"png"];
                        filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
                        [UIImageJPEGRepresentation(sharedImage, 1.0) writeToFile:filePath atomically:YES];
                        type = @"image";
                    
                    }else if(([VideoIdentifier isEqualToString:VIDEO_IDENTIFIER_MPEG_4] || [VideoIdentifier isEqualToString:VIDEO_IDENTIFIER_QUICK_TIME_MOVIE]) && [(NSObject *)item isKindOfClass:[NSURL class]]){
                        NSURL* url = (NSURL *)item;
                        filePath = [url absoluteString];
                        type = @"video";

                        // Get the timestamp from the file
                        NSDate *fileDate;
                        [url getResourceValue:&fileDate forKey:NSURLContentModificationDateKey error:&error];
                        timestamp = [dateFormatter stringFromDate:fileDate];
                        //NSLog(@"File Date:%@", timestamp);
                        
                        // Other way to get timestamp
                        //NSError *err = nil;
                        //NSDictionary *dic2 = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&err];
                        //NSLog(@"File modification Date:%@", dic2[NSFileModificationDate]);

                        // NSData *data = [NSData dataWithContentsOfURL:url];
                        //NSArray *keys = [NSArray arrayWithObjects:@"createDate",nil];
                        //NSArray *objs = [NSArray arrayWithObjects:@"createDate",nil];
                        // NSDictionary *opts = [NSDictionary
                                              // dictionaryWithObjects:objs
                        //                      forKeys:keys];
                        // AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
                        
                        // NSArray<AVMetadataItem *> *metadata = [urlAsset metadata];
                        // NSLog(@"meta data %@", metadata);
                        // AVAsset *asset = [AVAsset assetWithURL:url];
                        //AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
                        //CMTime time = CMTimeMake(1, 1);
                        //CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
                        // sharedImage = [UIImage imageWithCGImage:imageRef];
                        
                        
                    } else if ([(NSObject *)item isKindOfClass:[NSURL class]]){
                        NSURL* url = (NSURL *)item;
                        filename = [[url lastPathComponent] lowercaseString];
                        NSData *data = [NSData dataWithContentsOfURL:url];
                        sharedImage = [UIImage imageWithData:data];
                        // get meta data for files
                        CGImageSourceRef source = CGImageSourceCreateWithData((CFMutableDataRef)data, NULL);
                        NSDictionary* metadata = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,NULL));
                        // NSLog(@"image data %@", metadata);
                        if(metadata){
                            
                            timestamp = metadata[@"{Exif}"][@"DateTimeOriginal"];
                            orientation = metadata[@"Orientation"];
                            latitude = metadata[@"{GPS}"][@"Latitude"];
                            longitude =metadata[@"{GPS}"][@"Longitude"];
                        }
                        filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
                        [UIImageJPEGRepresentation(sharedImage, 1.0) writeToFile:filePath atomically:YES];
                        type = @"image";
                    }
                    
                    index += 1;
                    if(timestamp == nil){
                        timestamp = @"";
                    }
                    if(orientation == nil){
                        orientation = @"";
                    }
                    if(latitude == nil){
                        latitude = @"";
                    }
                    if(longitude == nil){
                        longitude = @"";
                    }
                    [itemArray addObject: @{
                                            @"type": type,
                                            @"value": filePath,
                                            @"timestamp" :timestamp,
                                            @"orientation" :orientation,
                                            @"latitude" :latitude,
                                            @"longitude" :longitude
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

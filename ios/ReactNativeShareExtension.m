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

+ (BOOL)requiresMainQueueSetup
{
    // only do this if your module initialization relies on calling UIKit!
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
        // NSLog(@"Log Item 1");
        // NSLog(@"context items %@", context.inputItems);
        // Formatter date is converted to for video
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSZZZZZ"];
        // Format of date in the video meta info
        NSDateFormatter *videoDateFormatter = [[NSDateFormatter alloc] init];
        [videoDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
        // latitude longitude regex
        NSError *error = NULL;
        NSString *pattern = @"([\+-][0-9\.]*)";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0
                                                                                 error:&error];
        
        [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
            if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER] || [provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER_MPEG_4] || [provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER_QUICK_TIME_MOVIE]){
                imageProvider = provider;
                // NSLog(@"Log Item 2");
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
                    //CGImageSourceRef source = CGImageSourceCreateWithData((CFMutableDataRef)item, NULL);
                    // NSDictionary* metadata = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,NULL));
                    // NSLog(@"image data %@", metadata);
                    // NSLog(@"Log Item 3");
                    UIImage *sharedImage;
                    NSString *filename;
                    NSString *type = @"";
                    NSString *orientation =@"";
                    NSString *timestamp = @"";
                    NSString *timeOriginal = @"";
                    NSString *subsecTimeOriginal = @"";
                    NSString *offsetTimeOriginal = @"";
                    NSString *latitude = @"";
                    NSString *longitude = @"";
                    NSString *filePath = @"";
                    NSURL* url;
                    if ([(NSObject *)item isKindOfClass:[UIImage class]]){
                        // NSLog(@"Log Item 4");
                        // NSLog(@"image data %@", item);
                        type = @"image";
                        sharedImage = (UIImage *)item;
                        NSString *name = @"RNSE_TEMP_IMG_";
                        NSString *nbFiles = [NSString stringWithFormat:@"%@",  @(index)];
                        NSString *fullname = [name stringByAppendingString:(nbFiles)];
                        filename = [fullname stringByAppendingPathExtension:@"png"];
                        filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
                        [UIImageJPEGRepresentation(sharedImage, 1.0) writeToFile:filePath atomically:YES];
                        
                    }else if(([VideoIdentifier isEqualToString:VIDEO_IDENTIFIER_MPEG_4] || [VideoIdentifier isEqualToString:VIDEO_IDENTIFIER_QUICK_TIME_MOVIE]) && [(NSObject *)item isKindOfClass:[NSURL class]]){
                        // shared media is a video
                        // NSLog(@"Log Item 5");
                        type = @"video";
                        url = (NSURL *)item;
                        filePath = [url absoluteString];
                        // get the create time
                        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
                        NSArray<AVMetadataItem *> *metadata = [urlAsset metadata];
                        // NSLog(@"video data %@", metadata);
                        if(metadata != nil){
                            for (AVMetadataItem *meta in metadata) {
                                // Check added because of of NSCFNumber key's found
                                // key class = __NSCFNumber, key=\U00a9too
                                // https://stackoverflow.com/questions/17127924/how-do-i-get-the-datatype-of-the-value-given-the-key-of-nsdictionary
                                if( [ [meta key] isKindOfClass:[NSString class]]) {
                                    NSString *key = (NSString *)[meta key];
                                    NSString *value = [meta stringValue];
                                    if ([key isEqualToString:@"com.apple.quicktime.creationdate"]){
                                        NSDate *videoCreationDate = [videoDateFormatter dateFromString:value];
                                        if (videoCreationDate != nil) {
                                            timestamp = [dateFormatter stringFromDate:videoCreationDate];
                                        }
                                    }else if([key isEqualToString:@"com.apple.quicktime.location.ISO6709"]){
                                        NSArray *matches = [regex matchesInString:value
                                        options:0
                                          range:NSMakeRange(0, [value length])];
                                        if(matches != nil && [matches count] > 0){
                                            NSTextCheckingResult *latMatch = [matches objectAtIndex:0];
                                            latitude = [value substringWithRange:[latMatch range]];
                                            NSTextCheckingResult *lonMatch = [matches objectAtIndex:1];
                                            longitude = [value substringWithRange:[lonMatch range]];
                                            // NSLog(@"lat = %@, long = %@", latitude, longitude);
                                        }
                                        // NSLog(@"val = %@", value);
                                    }
                                }
                                // NSLog(@"key = %@, value = %@", key, value);
                            }
                        }
                        
                    } else if ([(NSObject *)item isKindOfClass:[NSURL class]]){
                        // shared media is a photo
                        // NSLog(@"Log Item 6");
                        // NSLog(@"%@",item);
                        type = @"image";
                        url = (NSURL *)item;
                        filePath = [url absoluteString];
                        filename = [[url lastPathComponent] lowercaseString];
                        NSData *data = [NSData dataWithContentsOfURL:url];
                        // get meta data for files
                        CGImageSourceRef source = CGImageSourceCreateWithData((CFMutableDataRef)data, NULL);
                        NSDictionary* metadata = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source,0,NULL));
                        // NSLog(@"url image data %@", metadata);
                        if(metadata){
                            timeOriginal = metadata[@"{Exif}"][@"DateTimeOriginal"];
                            subsecTimeOriginal = metadata[@"{Exif}"][@"SubsecTimeOriginal"];
                            offsetTimeOriginal = metadata[@"{Exif}"][@"OffsetTimeOriginal"];
                            timestamp = [NSString stringWithFormat:@"%@.%@%@", timeOriginal, subsecTimeOriginal, offsetTimeOriginal];
                            orientation = metadata[@"Orientation"];
                            latitude = metadata[@"{GPS}"][@"Latitude"];
                            longitude =metadata[@"{GPS}"][@"Longitude"];
                        }
                        //filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
                        //[UIImageJPEGRepresentation(sharedImage, 1.0) writeToFile:filePath atomically:YES];
                        
                    }
                    // last attempt to get timestamp from file
                    if(timestamp == nil){
                        NSDate *fileDate;
                        [url getResourceValue:&fileDate forKey:NSURLCreationDateKey error:&error];
                        timestamp = [dateFormatter stringFromDate:fileDate];
                        // NSLog(@"File Date:%@", timestamp);
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
                // NSLog(@"Log Item 7");
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


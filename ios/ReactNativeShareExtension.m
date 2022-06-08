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
        
        // Formatter used for videos
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];

        NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
        [rfc3339DateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
        [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        // latitude longitude regex
        NSError *error = NULL;
        NSString *pattern = @"([\+-][0-9\.]*)";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0
                                                                                 error:&error];
        
        [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop) {
            if ([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER] || [provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER_MPEG_4] || [provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER_QUICK_TIME_MOVIE]){
                imageProvider = provider;
                NSString *mediaIdentifier;
                if([provider hasItemConformingToTypeIdentifier:IMAGE_IDENTIFIER]){
                    mediaIdentifier = IMAGE_IDENTIFIER;
                }else if([provider hasItemConformingToTypeIdentifier:VIDEO_IDENTIFIER_MPEG_4]){
                    mediaIdentifier = VIDEO_IDENTIFIER_MPEG_4;
                }else {
                    mediaIdentifier = VIDEO_IDENTIFIER_QUICK_TIME_MOVIE;
                }
                // NSLog(@"image data %@", mediaIdentifier);
                
                [imageProvider loadItemForTypeIdentifier:mediaIdentifier options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                    /**
                     * Save the image to NSTemporaryDirectory(), which cleans itself tri-daily.
                     * This is necessary as the iOS 11 screenshot editor gives us a UIImage, while
                     * sharing from Photos and similar apps gives us a URL
                     * Therefore the solution is to save a UIImage, either way, and return the local path to that temp UIImage
                     * This path will be sent to React Native and can be processed and accessed RN side.
                     **/
                    NSString *filename;
                    NSString *type = @"";
                    NSString *orientation =@"";
                    NSString *timestamp = @"";
                    NSString *latitude = @"";
                    NSString *longitude = @"";
                    NSURL* url = (NSURL *)item;
                    __block NSString *filePath = [url absoluteString];
                    
                    dispatch_group_t group = dispatch_group_create();
                    dispatch_group_enter(group);
                    [self copyAssetToFile:filePath completionHandler:^(NSString * _Nullable tempFileUrl, NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"%@",[error localizedDescription]);
                            dispatch_group_leave(group);
                            NSException *exception = [NSException exceptionWithName:@"ASSET_TMP_COPY_ERROR" reason:@"Error copying asset" userInfo:nil];
                            callback(nil, exception);
                        }
                        NSLog(@"Copy asset done...");
                        filePath = tempFileUrl;
                        dispatch_group_leave(group);
                    }];
                    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
                    
                    // Handle videos seperately so we read meta data differently
                    if(([mediaIdentifier isEqualToString:VIDEO_IDENTIFIER_MPEG_4] || [mediaIdentifier isEqualToString:VIDEO_IDENTIFIER_QUICK_TIME_MOVIE]) && [(NSObject *)item isKindOfClass:[NSURL class]]){
                        
                        type = @"video";
                        // get the create time
                        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
                        NSArray<AVMetadataItem *> *metadata = [urlAsset metadata];
                        // NSLog(@"meta data %@", metadata);
                        if(metadata != nil){
                            for (AVMetadataItem *meta in metadata) {
                                NSString *key = (NSString *)[meta key];
                                NSString *value = [meta stringValue];
                                if ([key isEqualToString:@"com.apple.quicktime.creationdate"]){
                                    NSDate *videoCretionDate = [rfc3339DateFormatter dateFromString:value];
                                    timestamp = [dateFormatter stringFromDate:videoCretionDate];
                                    // NSLog(@"timestamp = %@", timestamp);
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
                                // NSLog(@"key = %@, value = %@", key, value);
                            }
                        }
                        
                    } else if ([(NSObject *)item isKindOfClass:[NSURL class]]){
                        // shared media is a photo
                        type = @"image";
                        filename = [[url lastPathComponent] lowercaseString];
                        NSData *data = [NSData dataWithContentsOfURL:url];
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
                // we do not use this right now
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

/*
 Utility method to copy a PHAsset file into a local temp file, which can then be uploaded.
 */
- (void)copyAssetToFile: (NSString *)assetUrl completionHandler: (void(^)(NSString *__nullable tempFileUrl, NSError *__nullable error))completionHandler {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpUrl = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    NSError *error;
    // call self:filePath to get the file path without protocol prefix file://
    if([fileManager copyItemAtPath:[self filePath:assetUrl] toPath:tmpUrl error:&error]) {
        // call self:fileURI to prefix the tmpUrl with file:// as the rest of the code expects a fileURI
        completionHandler([self fileURI:tmpUrl], nil);
    } else {
        completionHandler(nil, error);
    }
    
}

- (NSString *)filePath:(NSString *)fileURI {
    if (![fileURI hasPrefix:@"file://"]) {
        return fileURI;
    }
    NSURL *url = [NSURL URLWithString: fileURI];
    NSString *path = [url path];
    return path;
}

- (NSString *)fileURI:(NSString *)filePath {
    if ([filePath hasPrefix:@"file://"]) {
        return filePath;
    }
    return [NSString stringWithFormat:@"file://%@", filePath];
}

@end


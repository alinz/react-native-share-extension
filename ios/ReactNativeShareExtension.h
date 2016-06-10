#import <UIKit/UIKit.h>
#import "RCTBridgeModule.h"

@interface ReactNativeShareExtension : UIViewController<RCTBridgeModule>
- (UIView*) shareView;
@end

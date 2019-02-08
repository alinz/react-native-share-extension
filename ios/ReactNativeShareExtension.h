#import <UIKit/UIKit.h>
#import "React/RCTBridgeModule.h"

@interface ReactNativeShareExtension : UIViewController<RCTBridgeModule>

/**
 * @deprecated This method should not be used unless you are creating
 * a shared bridge inside of shareView.
 * @note Please use @code shareViewWithRCTBridge @endcode instead.
 */
- (UIView*) shareView;

/**
 * Create a shareView using a common RCTBridge. The RCTBridge is reused
 * for each launch of the share sheet. This allows the share sheet to
 * free its resources in between launches.
 */
- (UIView*) shareViewWithRCTBridge:(RCTBridge*)sharedBridge;

@end

#import <UIKit/UIKit.h>

// Minimal declaration so the bundle compiles even if the SDK lacks Preferences headers.
// The real class is provided at link time by the private Preferences framework.
@interface PSListController : UIViewController {
    NSArray *_specifiers;
}
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)plistName target:(id)target;
@end

@interface BBPRootListController : PSListController
- (void)sendTestPush;
@end

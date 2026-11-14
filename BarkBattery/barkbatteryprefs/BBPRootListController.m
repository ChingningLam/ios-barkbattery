#import "BBPRootListController.h"
#import <notify.h>

@implementation BBPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)sendTestPush {
    [self.view endEditing:YES]; // commit any text field being edited
    notify_post("com.example.barkbattery/ReloadPrefs");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        notify_post("com.example.barkbattery/TestPush");
    });
}

@end

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <notify.h>

#define PREFS_DOMAIN @"com.example.barkbattery"
#define RELOAD_NOTIFICATION "com.example.barkbattery/ReloadPrefs"
#define TEST_NOTIFICATION "com.example.barkbattery/TestPush"

@interface SpringBoard : UIApplication
@end

static BOOL enabled = YES;
static NSString *barkKey = @"";
static NSString *serverURL = @"https://api.day.app";
static NSInteger threshold = 20;
static BOOL notifyWhileCharging = NO;
static NSString *level = @"active";
static NSString *sound = @"";
static NSString *group = @"BarkBattery";
static BOOL notified = NO;

static NSString *StringPref(NSUserDefaults *d, NSString *key, NSString *fallback) {
    id v = [d objectForKey:key];
    if ([v isKindOfClass:[NSString class]] && [(NSString *)v length] > 0) {
        return (NSString *)v;
    }
    return fallback;
}

static void LoadPreferences(void) {
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:PREFS_DOMAIN];
    [d synchronize];

    id v = [d objectForKey:@"enabled"];
    enabled = v ? [v boolValue] : YES;

    barkKey = [StringPref(d, @"barkKey", @"") stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSString *url = [StringPref(d, @"serverURL", @"https://api.day.app") stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    while ([url hasSuffix:@"/"]) {
        url = [url substringToIndex:url.length - 1];
    }
    serverURL = url.length > 0 ? url : @"https://api.day.app";

    v = [d objectForKey:@"threshold"];
    threshold = v ? (NSInteger)lround([v doubleValue]) : 20;

    v = [d objectForKey:@"notifyWhileCharging"];
    notifyWhileCharging = v ? [v boolValue] : NO;

    level = StringPref(d, @"level", @"active");
    sound = StringPref(d, @"sound", @"");
    group = StringPref(d, @"group", @"BarkBattery");

    // barkKey is intentionally never logged
    NSLog(@"[BarkBattery] Preferences loaded: enabled=%d threshold=%ld charging=%d level=%@ group=%@ keySet=%d",
          enabled, (long)threshold, notifyWhileCharging, level, group, (int)(barkKey.length > 0));
}

static void SendBarkPush(NSString *title, NSString *body) {
    if (barkKey.length == 0) {
        NSLog(@"[BarkBattery] barkKey is empty, skipping push");
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/push", serverURL]];
    if (!url) {
        NSLog(@"[BarkBattery] Invalid server URL");
        return;
    }

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"device_key"] = barkKey;
    dict[@"title"] = title;
    dict[@"body"] = body;
    dict[@"group"] = group;
    dict[@"level"] = level;
    if (sound.length > 0) {
        dict[@"sound"] = sound;
    }

    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&jsonError];
    if (jsonError || !jsonData) {
        NSLog(@"[BarkBattery] JSON serialization error: %@", jsonError);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 15;
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = jsonData;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"[BarkBattery] Push error: %@", error.localizedDescription);
                return;
            }
            NSLog(@"[BarkBattery] Push HTTP status: %ld", (long)((NSHTTPURLResponse *)response).statusCode);
        }];
    [task resume];
}

static void CheckBattery(void) {
    float raw = [UIDevice currentDevice].batteryLevel;
    if (raw < 0) {
        return; // unknown
    }

    NSInteger percent = (NSInteger)lroundf(raw * 100.0f);
    UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
    BOOL charging = (state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull);

    // Re-arm (hysteresis)
    if (notified && (percent > threshold + 5 || (charging && !notifyWhileCharging))) {
        notified = NO;
        NSLog(@"[BarkBattery] Re-armed");
    }

    if (enabled && !notified && percent <= threshold && (!charging || notifyWhileCharging)) {
        notified = YES;
        NSString *body = [NSString stringWithFormat:@"当前电量 %ld%%，请及时充电", (long)percent];
        SendBarkPush(@"电量低", body);
        NSLog(@"[BarkBattery] Low battery push sent at %ld%%", (long)percent);
    }
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        NSOperationQueue *mainQ = [NSOperationQueue mainQueue];
        [nc addObserverForName:UIDeviceBatteryLevelDidChangeNotification
                        object:nil queue:mainQ usingBlock:^(NSNotification *n) { CheckBattery(); }];
        [nc addObserverForName:UIDeviceBatteryStateDidChangeNotification
                        object:nil queue:mainQ usingBlock:^(NSNotification *n) { CheckBattery(); }];

        CheckBattery();
    });
}

%end

%ctor {
    LoadPreferences();

    static int reloadToken;
    static int testToken;

    notify_register_dispatch(RELOAD_NOTIFICATION, &reloadToken, dispatch_get_main_queue(), ^(int token) {
        LoadPreferences();
        CheckBattery();
    });

    notify_register_dispatch(TEST_NOTIFICATION, &testToken, dispatch_get_main_queue(), ^(int token) {
        LoadPreferences();
        SendBarkPush(@"BarkBattery 测试", @"这是一条测试推送");
    });
}

#import <UIKit/UIKit.h>

@interface PPadDemoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;

    IBOutlet UINavigationController *navigationController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;

@end


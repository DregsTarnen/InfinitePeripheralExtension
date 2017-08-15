#import <UIKit/UIKit.h>

@class LibraryDemoViewController;

@interface LibraryDemoAppDelegate : NSObject {
    UIWindow *window;
    UIViewController *viewController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UIViewController *viewController;

@end


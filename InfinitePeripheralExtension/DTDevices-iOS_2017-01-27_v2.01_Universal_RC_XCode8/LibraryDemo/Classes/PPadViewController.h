#import <Foundation/Foundation.h>
#import "DTDevices.h"

#import "ProgressViewController.h"
#import "EMSRCryptoViewController.h"


@interface PPadViewController : UIViewController {
    IBOutlet UITabBarController *mainTabBarController;
    IBOutlet ProgressViewController *progressViewController;
    IBOutlet EMSRCryptoViewController *emsrCryptoViewController;

    DTDevices *dtdev;
    
}

-(IBAction)onKeysInfo:(id)sender;
-(IBAction)onEnterPIN:(id)sender;

@end

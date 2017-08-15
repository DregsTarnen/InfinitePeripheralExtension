#import <Foundation/Foundation.h>
#import "DTDevices.h"
#import "ProgressViewController.h"
#import "EMSRCryptoViewController.h"

@interface EMVEmulViewController : UIViewController
{
    IBOutlet ProgressViewController *progressViewController;
    IBOutlet EMSRCryptoViewController *emsrCryptoViewController;
    
    DTDevices *dtdev;
}

-(IBAction)onEMVTransaction:(id)sender;

@end

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ScannerViewController.h"
#import "EMSRCryptoViewController.h"

#import "DTDevices.h"

@interface MainTabBarController : UITabBarController <DTDeviceDelegate> {
	IBOutlet ScannerViewController *scannerViewController;
	IBOutlet UIViewController *settingsViewController;
	IBOutlet UIViewController *cryptoViewController;
	IBOutlet UIViewController *rfViewController;
	IBOutlet EMSRCryptoViewController *emsrCryptoViewController;
	IBOutlet UIViewController *printViewController;
	IBOutlet UIViewController *printZPLViewController;
	IBOutlet UIViewController *emv2ViewController;
    IBOutlet UIViewController *emvEmulViewController;
    IBOutlet UIViewController *ppadViewController;
	
	DTDevices *dtdev;

    CGRect mainRect;
    CGRect tabRect;
}

@end

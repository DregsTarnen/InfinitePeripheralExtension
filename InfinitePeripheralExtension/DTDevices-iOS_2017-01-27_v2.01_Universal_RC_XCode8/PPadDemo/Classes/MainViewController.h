#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ProgressViewController.h"
#import "AmountViewController.h"
#import "BluetoothViewController.h"


#import "DTDevices.h"

#define notificationAmount @"NotificatonAmount"

@interface MainViewController : UIViewController <UIAccelerometerDelegate> {
	IBOutlet ProgressViewController *progressViewController;
    IBOutlet AmountViewController *amountViewController;
    IBOutlet UIViewController *signatureViewController;
    IBOutlet UINavigationController *navigationController;
    IBOutlet BluetoothViewController *bluetoothViewController;
    
	IBOutlet UITextView *displayText;
    IBOutlet UIImageView *connectedState;
    IBOutlet UIButton *amountButton;
    
    IBOutlet UILabel *batLabel;
    
    DTDevices *dtdev;

	double amount;
	int operation;
	
	NSTimer *clearTimer;
	NSTimer *mfTimer;
	NSTimer *mfLedTimer;
    
    UIAlertView *alert;
}

-(void)endOperation;
-(void)enterPin;
-(void)displayResult:(NSError *)error;

-(IBAction)onEnterAmount:(id)sender;
@end

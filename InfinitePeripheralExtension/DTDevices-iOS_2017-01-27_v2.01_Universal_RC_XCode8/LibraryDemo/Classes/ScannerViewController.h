#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "ProgressViewController.h"
#import "DTDevices.h"

#define POS_NORMAL 0
#define POS_FLIPPED 1

@interface ScannerViewController : UIViewController <DTDeviceDelegate,UIAccelerometerDelegate> {
    
    IBOutlet ProgressViewController *progressViewController;
    
	IBOutlet UIButton *scanButton;
	IBOutlet UITextView *displayText;
	IBOutlet UITextView *debugText;
	IBOutlet UIImageView *statusImage;
    IBOutlet UIButton *batteryButton;
    IBOutlet UITextField *numBarcodesField;
	IBOutlet UITabBarController *mainTabBarController;
    IBOutlet UIButton *printButton;
    IBOutlet UISegmentedControl *test;
    IBOutlet UISlider *slider;
    IBOutlet UIImageView *iOSChargingImage;
	
	NSMutableString *status;
	NSMutableString *debug;	

	DTDevices *dtdev;

    int position;
    
}

-(void)debug:(NSString *)text;

-(IBAction)scanDown:(id)sender;
-(IBAction)scanUp:(id)sender;
-(IBAction)onBattery:(id)sender;
-(IBAction)onPrint:(id)sender;
-(IBAction)onTest:(id)sender;
-(IBAction)onSliderChange:(id)sender;

+(void)playSound:(NSString *)fileName volume:(float)volume;

@property (assign) bool suspendDisplayInfo;

@end

//extern ScannerViewController *scannerViewController;

#define SHOWERR(func) func; if(error)[ScannerViewController debug:error.localizedDescription];
#define ERRMSG(title) {UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil]; [alert show];}


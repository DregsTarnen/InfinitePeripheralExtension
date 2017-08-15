#import <Foundation/Foundation.h>
#import "DTDevices.h"
#import "ProgressViewController.h"

@interface EMV2ViewController : UIViewController
{
	IBOutlet UITextView *logView;
	IBOutlet ProgressViewController *progressViewController;
    
	DTDevices *dtdev;
}

-(IBAction)onEMVTransaction:(id)sender;
+(BOOL)emv2Init;

@end

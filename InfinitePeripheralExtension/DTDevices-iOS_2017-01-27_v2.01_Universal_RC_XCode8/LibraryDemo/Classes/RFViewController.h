#import <Foundation/Foundation.h>
#import "ProgressViewController.h"

#import "DTDevices.h"


@interface RFViewController : UIViewController <UITextFieldDelegate> {
	IBOutlet UITextView *logView;
	IBOutlet ProgressViewController *progressViewController;
    
	DTDevices *dtdev;
    
    NSTimer *rfStopTimer;
}

-(IBAction)clear:(id)sender;

@end

#import <Foundation/Foundation.h>
#import "DTDevices.h"


@interface PrintViewController : UIViewController {
	DTDevices *dtdev;
    
    IBOutlet UILabel *paperStatusLabel;
    IBOutlet UITextField *tfLabelWidth;
}

-(IBAction)onFontsDemo:(id)sender;
-(IBAction)onSelfTest:(id)sender;
-(IBAction)onBarcodesDemo:(id)sender;
-(IBAction)onGraphicsDemo:(id)sender;
-(IBAction)onLoadLogo:(id)sender;
-(IBAction)onCalibrate:(id)sender;
-(IBAction)onOnFeedPaper:(id)sender;
-(IBAction)onPrintLabelDemo:(id)sender;
-(IBAction)onSetLabelWidth:(id)sender;

-(IBAction)onSCCheck:(id)sender;

@end

#import <Foundation/Foundation.h>
#import "MainViewController.h"
#import "DTDevices.h"

@interface SignatureViewController : UIViewController {
	CGPoint lastPoint;
	UIImageView *drawImage;
	BOOL mouseSwiped;	
	int mouseMoved;
    
    IBOutlet UIView *signatureImage;
    IBOutlet MainViewController *mainViewController;
    
    DTDevices *dtdev;
}
- (IBAction)onComplete:(id)sender;
- (IBAction)onClear:(id)sender;
- (IBAction)onCancel:(id)sender;
- (IBAction)onEnterPIN:(id)sender;

@end

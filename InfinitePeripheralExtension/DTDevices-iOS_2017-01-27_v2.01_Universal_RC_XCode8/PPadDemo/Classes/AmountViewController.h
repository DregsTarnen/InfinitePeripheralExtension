#import <Foundation/Foundation.h>

@interface AmountViewController : UIViewController {
    IBOutlet UIButton *amountButton;

	double amount;
	int decimalPoints;
    BOOL clear;
}

- (IBAction)onButton:(id)sender;
- (IBAction)onButtonClr:(id)sender;
- (IBAction)onButtonBack:(id)sender;
- (IBAction)onAccept:(id)sender;
- (IBAction)onCancel:(id)sender;

- (void)setAmount:(double)value;
@end

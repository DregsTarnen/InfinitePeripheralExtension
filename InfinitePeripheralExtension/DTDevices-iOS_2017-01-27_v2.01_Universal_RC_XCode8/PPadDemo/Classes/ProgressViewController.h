#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ProgressViewController : UIViewController {
	IBOutlet UIActivityIndicatorView *activityIndicator;
	IBOutlet UITextView *infoText;
    IBOutlet UILabel *phaseLabel;
    IBOutlet UIProgressView *progressProgress;
	
    IBOutlet UIImageView *imageView;
	IBOutlet UIButton *cancelButton;
    IBOutlet UINavigationController *navigationController;
}

- (IBAction)onCancel:(id)sender;

- (void)enableCancel:(BOOL)enabled;
- (void)updateImage:(UIImage *)image;
- (void)updateText:(NSString *)text;
- (void)updateProgress:(NSString *)phase progress:(int)progress;

@property int type;

@end

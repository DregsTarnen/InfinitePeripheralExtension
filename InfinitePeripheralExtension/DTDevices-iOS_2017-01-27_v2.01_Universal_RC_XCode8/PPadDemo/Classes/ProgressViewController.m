#import "ProgressViewController.h"
#import "DTDevices.h"

@implementation ProgressViewController

@synthesize type;

- (IBAction)onCancel:(id)sender
{
	[[DTDevices sharedDevice] uiStopAnimation:-1 error:nil];
    [[DTDevices sharedDevice] uiFillRectangle:0 topLeftY:0 width:0 height:0 color:[UIColor blackColor] error:nil];
    [navigationController popToRootViewControllerAnimated:TRUE];
}

- (void)viewWillAppear:(BOOL)animated
{
    [phaseLabel setHidden:TRUE];
    [progressProgress setHidden:TRUE];
    [cancelButton setHidden:FALSE];
	[activityIndicator startAnimating];
}

- (void)viewWillDisappear: (BOOL)animated
{
	[activityIndicator stopAnimating];
}

- (void)enableCancel:(BOOL)enabled
{
    [cancelButton setHidden:enabled?FALSE:TRUE];
}

- (void)updateImage:(UIImage *)image
{
    [imageView setImage:image];
}

- (void)updateText:(NSString *)text
{
    [infoText setText:text];
}

- (void)updateProgress:(NSString *)phase progress:(int)progress
{
    [phaseLabel setText:phase];
    [progressProgress setProgress:(float)progress/100];
    
    [phaseLabel setHidden:FALSE];
    [progressProgress setHidden:FALSE];
}

@end

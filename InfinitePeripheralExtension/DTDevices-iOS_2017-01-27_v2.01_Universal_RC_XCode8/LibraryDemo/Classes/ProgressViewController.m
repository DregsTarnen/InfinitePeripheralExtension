#import "ProgressViewController.h"

@implementation ProgressViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [infoText setText:@"Operation in progress, please wait..."];
    [phaseLabel setHidden:TRUE];
    [progressProgress setHidden:TRUE];
	[activityIndicator startAnimating];
}
- (void)viewWillDisappear: (BOOL)animated
{
    [super viewWillDisappear:animated];
	[activityIndicator stopAnimating];
}

- (void)updateText:(NSString *)text
{
    if([[NSThread currentThread] isMainThread])
    {
        [infoText setText:text];
    }else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [infoText setText:text];
        });
    }
}

- (void)updateProgress:(NSString *)phase progress:(int)progress
{
    [phaseLabel setText:phase];
    [progressProgress setProgress:(float)progress/100];
    
    [phaseLabel setHidden:FALSE];
    [progressProgress setHidden:FALSE];
}

@end

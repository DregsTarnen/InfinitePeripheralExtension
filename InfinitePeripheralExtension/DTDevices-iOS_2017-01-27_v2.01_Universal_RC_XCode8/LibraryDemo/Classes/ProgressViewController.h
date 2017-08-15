//
//  ProgressViewController.h
//
//  Created by Anton Rajnov on 1/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ProgressViewController : UIViewController {
	IBOutlet UIActivityIndicatorView *activityIndicator;
	IBOutlet UITextView *infoText;
    IBOutlet UILabel *phaseLabel;
    IBOutlet UIProgressView *progressProgress;
}

- (void)updateText:(NSString *)text;
- (void)updateProgress:(NSString *)phase progress:(int)progress;
@end

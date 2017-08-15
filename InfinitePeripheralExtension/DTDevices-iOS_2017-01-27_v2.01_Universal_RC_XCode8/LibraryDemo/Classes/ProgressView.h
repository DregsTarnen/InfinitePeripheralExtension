//
//  ProgressView.h
//
//  Created by Anton Rajnov on 1/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ProgressView : UIView {
	IBOutlet UIActivityIndicatorView *activityIndicator;
	IBOutlet UITextView *infoText;

}

- (void)viewDidLoad;
@end

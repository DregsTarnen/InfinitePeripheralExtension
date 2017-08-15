//
//  ProgressView.m
//
//  Created by Anton Rajnov on 1/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProgressView.h"

@implementation ProgressView

- (void)viewDidLoad
{
	[activityIndicator startAnimating];
}
- (void)viewWillDisappear: (BOOL)animated
{
	[activityIndicator stopAnimating];
}

@end

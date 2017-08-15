//
//  SignatureViewController.m
//  PPadDemo
//
//  Created by Anton Rajnov on 3/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SignatureViewController.h"

@implementation SignatureViewController

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

- (IBAction)onComplete:(id)sender {
	if(drawImage.image==nil)
	{
        [self displayAlert:@"Transaction error!" message:@"Please sign on the field below"];
	}else
    {
        [mainViewController displayResult:nil];
        [mainViewController endOperation];
    }
}

- (IBAction)onClear:(id)sender {
	mouseMoved = 0;
	drawImage.image = nil;
}

- (IBAction)onCancel:(id)sender {
    [mainViewController displayResult:[NSError errorWithDomain:@"com.datecs.errors" code:DT_EFAILED userInfo:[NSDictionary dictionaryWithObject:@"Operation cancelled" forKey:NSLocalizedDescriptionKey]]];
    [mainViewController endOperation];
}

- (IBAction)onEnterPIN:(id)sender
{
    [mainViewController endOperation];
    [mainViewController enterPin];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	mouseSwiped = NO;
	UITouch *touch = [touches anyObject];
	
	if ([touch tapCount] == 2) {
		drawImage.image = nil;
		return;
	}
	
	lastPoint = [touch locationInView:signatureImage];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	mouseSwiped = YES;
	
	UITouch *touch = [touches anyObject];	
	CGPoint currentPoint = [touch locationInView:signatureImage];
	
    NSLog(@"Line: %dx%d to %dx%d",(int)lastPoint.x,(int)lastPoint.y,(int)currentPoint.x,(int)currentPoint.y);
    
	UIGraphicsBeginImageContext(signatureImage.frame.size);
	[drawImage.image drawInRect:CGRectMake(0, 0, signatureImage.frame.size.width, signatureImage.frame.size.height)];
	CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
	CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5.0);
	CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 1.0, 1.0);
	CGContextBeginPath(UIGraphicsGetCurrentContext());
	CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
	CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
	CGContextStrokePath(UIGraphicsGetCurrentContext());
	drawImage.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	lastPoint = currentPoint;
	
	mouseMoved++;
	
	if (mouseMoved == 10) {
		mouseMoved = 0;
	}
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [touches anyObject];
	
	if ([touch tapCount] == 2) {
		drawImage.image = nil;
		return;
	}
	
	
	if(!mouseSwiped) {
		UIGraphicsBeginImageContext(signatureImage.frame.size);
		[drawImage.image drawInRect:CGRectMake(0, 0, signatureImage.frame.size.width, signatureImage.frame.size.height)];
		CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
		CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 5.0);
		CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 1.0, 0.0, 0.0, 1.0);
		CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
		CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
		CGContextStrokePath(UIGraphicsGetCurrentContext());
		CGContextFlush(UIGraphicsGetCurrentContext());
		drawImage.image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}
}

- (void)viewWillAppear:(BOOL)animated {
    [self onClear:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGAffineTransform transform = CGAffineTransformMakeRotation(3.14159/2);
    self.view.transform = transform;
    
	dtdev=[DTDevices sharedDevice];
    [dtdev addDelegate:self];
    
	drawImage = [[UIImageView alloc] initWithImage:nil];
	drawImage.frame = signatureImage.frame;
	[self.view addSubview:drawImage];
}


@end

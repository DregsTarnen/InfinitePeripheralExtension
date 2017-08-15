//
//  CryptoViewController.h
//
//  Created by Anton Rajnov on 8/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ScannerViewController.h"

@interface CryptoViewController : UIViewController <DTDeviceDelegate,UITextFieldDelegate> {
    IBOutlet UIView *cryptoView;
    
	IBOutlet UITextField *newEncryptionKey;
	IBOutlet UITextField *newEncryptionKeyVersion;
	IBOutlet UITextField *oldEncryptionKey;
	IBOutlet UITextField *newAuthenticationKey;
	IBOutlet UITextField *newAuthenticationKeyVersion;
	IBOutlet UITextField *oldAuthenticationKey;
	IBOutlet UITextField *decryptKey;
	IBOutlet UITextField *authKey;
    IBOutlet UISegmentedControl *emsrAlgorithmControl;

	DTDevices *dtdev;
}

-(IBAction)setAuthenticationKey:(id)sender;
-(IBAction)setAuthenticationKeyAndLock:(id)sender;
-(IBAction)setEncryptionKey:(id)sender;
-(IBAction)deleteEncryptionKey:(id)sender;
-(IBAction)checkAuthentication:(id)sender;
-(IBAction)getKeyInfo:(id)sender;
@end

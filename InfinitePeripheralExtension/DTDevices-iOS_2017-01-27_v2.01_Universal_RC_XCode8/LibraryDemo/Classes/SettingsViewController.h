#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ScannerViewController.h"
#import "ProgressViewController.h"

@interface SettingsViewController : UIViewController <DTDeviceDelegate,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate,UITextFieldDelegate> {
	IBOutlet UITableView *settingsTable;
	IBOutlet ProgressViewController *progressViewController;

	DTDevices *dtdev;
    
    NSMutableArray *btDevices;
    NSArray *btleDevices;
    NSArray *btConnectedDevices;
    bool btListening;
    int firmareTarget;
    NSMutableArray *firmwareFiles;
    
    UITextField *tfTCPAddress;
    UITextField *tfIdleTimeout;
    UITextField *tfDisconnectedTimeout;
}

@property(assign) int scanMode;

@end

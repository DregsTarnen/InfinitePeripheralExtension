#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ScannerViewController.h"
#import "ProgressViewController.h"

@interface iHUBViewController : UIViewController <DTDeviceDelegate,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate> {
	IBOutlet UITableView *settingsTable;
	IBOutlet ProgressViewController *progressViewController;

	DTDevices *dtdev;
    NSArray *ports;
    NSArray *configs;
}

@end

#import <UIKit/UIKit.h>
#import "ProgressViewController.h"
#import "DTDevices.h"

@interface BluetoothViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet ProgressViewController *progressViewController;
    IBOutlet UINavigationController *navigationController;
    
    IBOutlet UITableView *printersTable;
    
    DTDevices *dtdev;
}

-(IBAction)onBTDiscover:(id)sender;
-(IBAction)onClose:(id)sender;

@property(copy) NSMutableArray *btAddresses;
@property(copy) NSMutableArray *btNames;
@end

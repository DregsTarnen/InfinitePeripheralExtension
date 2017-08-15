#import "PrintZPLViewController.h"

@interface PrintZPLViewController ()
{
    IBOutlet UISegmentedControl *printMode;
    IBOutlet UIStepper *printDarkness;
    IBOutlet UILabel *darknessLabel;
}

@end

@implementation PrintZPLViewController

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

-(IBAction)onDarknessValueChanged:(id)sender
{
    int darkness=(int)printDarkness.value;
    darknessLabel.text=[NSString stringWithFormat:@"Darkness: %d",darkness];
}


#define COMMAND(operation,x) if(!x){[self displayAlert:@"Error" message:[NSString stringWithFormat:@"%@ failed with error: %@",operation,error.localizedDescription]]; return; }
-(IBAction)onCalibrate:(id)sender
{
    NSError *error;
    COMMAND(@"Calibrate",[dtdev prnWriteDataToChannel:CHANNEL_ZPL data:[@"^XA\r\n^MNM\r\n^PW832\r\n^XZ\r\n~JC\r\n^XA\r\n^PH\r\n^XZ\r\n" dataUsingEncoding:NSASCIIStringEncoding] error:&error]);
}

-(IBAction)onSetRollMode:(id)sender
{
    NSError *error;
    COMMAND(@"Set roll mode",[dtdev prnWriteDataToChannel:CHANNEL_ZPL data:[@"^XA\r\n^MNN\r\n^XZ\r\n~SD20\r\n" dataUsingEncoding:NSASCIIStringEncoding] error:&error]);
}

-(IBAction)onSetLabelMode:(id)sender
{
    NSError *error;
    COMMAND(@"Set label mode",[dtdev prnWriteDataToChannel:CHANNEL_ZPL data:[@"^XA\r\n^MNM\r\n^XZ\r\n~SD20\r\n" dataUsingEncoding:NSASCIIStringEncoding] error:&error]);
}

-(IBAction)onReadStatus:(id)sender
{
    NSError *error;

    COMMAND(@"Read Info",[dtdev prnWriteDataToChannel:CHANNEL_ZPL data:[@"~HS" dataUsingEncoding:NSASCIIStringEncoding] error:&error]);
    //read back 2 lines of info, each ending with ETX
    NSData *d1 = [dtdev prnReadDataFromChannel:CHANNEL_ZPL length:0 stopByte:0x0A timeout:2 error:&error];
    NSData *d2 = [dtdev prnReadDataFromChannel:CHANNEL_ZPL length:0 stopByte:0x0A timeout:2 error:&error];
    NSData *d3 = [dtdev prnReadDataFromChannel:CHANNEL_ZPL length:0 stopByte:0x0A timeout:2 error:&error];
    if(d1 && d2 && d3)
    {
        NSString *l1 = [[NSString alloc] initWithData:d1 encoding:NSASCIIStringEncoding];
        NSString *l2 = [[NSString alloc] initWithData:d2 encoding:NSASCIIStringEncoding];
        NSString *l3 = [[NSString alloc] initWithData:d3 encoding:NSASCIIStringEncoding];

        BOOL paperOut=[[l1 componentsSeparatedByString:@","][1] isEqualToString:@"1"];

        [self displayAlert:@"Success" message: [NSString stringWithFormat:@"L1: %@\nL2: %@\nL3: %@\nPaper: %@",l1,l2,l3,paperOut?@"Missing":@"Present"]];
    }
}

-(IBAction)onPrintDemo:(id)sender
{
    NSError *error;
    
    int darkness=(int)printDarkness.value;
    int mode=(int)printMode.selectedSegmentIndex;
    
    NSString *setup=[NSString stringWithFormat:@"^XA\r\n%@\r\n^XZ\r\n~SD%02d\r\n",(mode==0?@"^MNN":@"^MNM"),darkness];
    COMMAND(@"Setup printer",[dtdev prnWriteDataToChannel:CHANNEL_ZPL data:[setup dataUsingEncoding:NSASCIIStringEncoding] error:&error]);
    
    NSData *file=[NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"label-203.txt"]];
    COMMAND(@"Print demo",[dtdev prnWriteDataToChannel:CHANNEL_ZPL data:file error:&error]);
}


-(void)viewDidLoad
{
	dtdev=[DTDevices sharedDevice];
    [dtdev addDelegate:self];
    [super viewDidLoad];
    
    printMode.selectedSegmentIndex=0;
    printDarkness.value=20;
}

@end

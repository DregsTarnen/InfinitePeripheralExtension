#import "BluetoothViewController.h"

@implementation BluetoothViewController

@synthesize btNames;
@synthesize btAddresses;

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

-(void)bluetoothDeviceDiscovered:(NSString *)btAddress name:(NSString *)btName
{
    [btAddresses addObject:btAddress];
    [btNames addObject:btName];
}

-(void)bluetoothDiscoverComplete:(BOOL)success
{
    //stop module to not consume power
    [progressViewController.view removeFromSuperview];
    
    [printersTable reloadData];
    
    if(!success)
        [self displayAlert:@"Bluetooth error" message:@"BT Discovery failed"];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [btNames count];
}

NSString *getLogFile()
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"random.bin"];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSError *error=nil;

    //saving these for future reference
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:[btAddresses objectAtIndex:indexPath.row] forKey:@"selectedPrinterAddress"];
    [prefs setObject:[btNames objectAtIndex:indexPath.row] forKey:@"selectedPrinterName"];
    [prefs synchronize];
    
    
    [progressViewController viewWillAppear:FALSE];
    [self.view addSubview:progressViewController.view];
    //just to make progressview appear
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    [dtdev btConnectSupportedDevice:[btAddresses objectAtIndex:indexPath.row] pin:@"0000" error:&error];
    [progressViewController.view removeFromSuperview];
    if(error)
        [self displayAlert:@"Bluetooth error" message:[NSString stringWithFormat:@"Connection failed with error: %@",error.localizedDescription]];
    else
        [self onClose:self];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGRect CellFrame = CGRectMake(0, 0, 300, 60);
	UITableViewCell *cell=[[UITableViewCell alloc] initWithFrame:CellFrame];
    
    [[cell textLabel] setText:[NSString stringWithFormat:@"%@ (%@)",[btNames objectAtIndex:indexPath.row],[btAddresses objectAtIndex:indexPath.row]]];
	
	return cell;
}

-(IBAction)onBTDiscover:(id)sender
{
    [btNames removeAllObjects];
    [btAddresses removeAllObjects];
    [printersTable reloadData];
    
    NSError *error;
    if(![dtdev btDiscoverPinpadsInBackground:&error])
    {
        [self displayAlert:@"Bluetooth error" message:[NSString stringWithFormat:@"Discovery failed with error: %@",error.localizedDescription]];
    }

    [progressViewController viewWillAppear:FALSE];
    [self.view addSubview:progressViewController.view];
}

-(IBAction)onClose:(id)sender
{
    [self dismissModalViewControllerAnimated:FALSE];
}

-(void)bluetoothPrintingSupported:(BOOL)supported
{
    if(!supported)
        [self dismissModalViewControllerAnimated:FALSE];
}



-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	dtdev=[DTDevices sharedDevice];
    [dtdev addDelegate:self];
    
    btNames=[[NSMutableArray alloc] init];
    btAddresses=[[NSMutableArray alloc] init];
    
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSString *selectedPrinterAddress=[prefs objectForKey:@"selectedPrinterAddress"];
	NSString *selectedPrinterName=[prefs objectForKey:@"selectedPrinterName"];
    if(selectedPrinterAddress)
    {
        [btAddresses addObject:selectedPrinterAddress];
        [btNames addObject:selectedPrinterName];
        [printersTable reloadData];
    }
    
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end

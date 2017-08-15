#import "iHUBViewController.h"
#import "NSDataCrypto.h"

@implementation iHUBViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Number of sections is the number of region dictionaries
    return 0;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    iHUBPortInfo *port=(iHUBPortInfo *)[ports objectAtIndex:section];
    return [NSString stringWithFormat:@"Port %d (%@)",port.portIndex,port.portType==IHUB_PORT_TYPE_RS232?@"RS232":@"USB"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Number of rows is the number of names in the region dictionary for the specified section
    size_t nRows=configs.count;
	return nRows;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSError *error=nil;
    
    iHUBPortInfo *port=(iHUBPortInfo *)[ports objectAtIndex:[indexPath indexAtPosition:0]];
    
    if(![dtdev iHUBSetPortConfig:[configs objectAtIndex:indexPath.row] forPort:port.portIndex error:&error])
    {
        ERRMSG(NSLocalizedString(@"Command failed",nil));
    }
    port.portConfig=[configs objectAtIndex:indexPath.row];
    [settingsTable reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SettingsCell"];
    
    iHUBPortInfo *port=(iHUBPortInfo *)[ports objectAtIndex:[indexPath indexAtPosition:0]];
    if([port.portConfig isEqualToString:[configs objectAtIndex:indexPath.row]])
        cell.accessoryType=UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType=UITableViewCellAccessoryNone;
    cell.textLabel.text=[configs objectAtIndex:indexPath.row];

	return cell;	
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    ports=[dtdev iHUBGetPortsInfo:nil];
    [settingsTable reloadData];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
	dtdev=[DTDevices sharedDevice];
	[dtdev addDelegate:self];
    
    configs=
    @[
        kPortConfigNone,
        kPortConfigLineaOldUSBSER,
        kPortConfigLineaUSBSER,
        kPortConfigPinpadUSB,
        kPortConfigPinpadUSBSER,
        kPortConfigPrinterESCPOSUSB,
        kPortConfigPrinterFiscalUSB,
        kPortConfigPrinterFiscalOldUSB,
        ];
}

@end

#import "SettingsViewController.h"
#import "NSDataCrypto.h"
#import <ExternalAccessory/ExternalAccessory.h>

@implementation SettingsViewController

@synthesize scanMode;

static NSString *settings[]={
	@"Beep upon scan",
	@"Enable scan button",
	@"Automated charge enabled",
	@"Reset barcode engine",
	@"Enable external speaker",
    @"External speaker hardware button",
    @"External speaker auto mode",
	@"Enable pass-through sync",
    @"Enable Kiosk Mode",
	@"Vibrate on barcode scan",
    @"Turn device off",
    @"Enable Code128 barcode",
    @"Disable Code128 barcode",
};

enum SETTINGS{
	SET_BEEP=0,
	SET_ENABLE_SCAN_BUTTON,
	SET_AUTOCHARGING,
	SET_RESET_BARCODE,
	SET_ENABLE_SPEAKER,
    SET_ENABLE_SPEAKER_BUTTON,
    SET_ENABLE_SPEAKER_AUTO,
	SET_ENABLE_SYNC,
    SET_KIOSK,
    SET_VIBRATE,
    SET_POWER_OFF,
    SET_ENABLE_CODE128,
    SET_DISABLE_CODE128,
    SET_LAST
};

static int chargeCurrent=500;
static NSString *charge_currents[]={
    @"500mA charging current (default)",
    @"1A charging current (!!)",
    @"2A charging current (!!)",
    @"2.4A charging current (!!)",
};


static NSString *scan_modes[]={
	@"Single scan",
	@"Multi scan",
	@"Motion detect",
	@"Single scan on button release",
    @"Multi scan without duplicates",
};

enum SECTIONS{
    SEC_GENERAL=0,
    SEC_CHARGING,
    SEC_BARCODE_MODE,
    SEC_LEDS,
    SEC_APPLE_BT,
    SEC_BT_CLIENT,
    SEC_BT_SERVER,
    SEC_BTLE,
    SEC_TCP_DEVICES,
    SEC_FIRMWARE_UPDATE,
    SEC_VOLTAGE,
    SEC_TRANSARMOR,
    SEC_MISC,
    SEC_LAST
};


static NSString *section_names[]={
	@"General Settings",
    @"Chaging Current",
	@"Barcode Scan Mode",
	@"LED Control",
    @"Apple Bluetooth",
	@"Bluetooth Client",
	@"Bluetooth Server",
	@"Bluetooth Low Energy",
    @"TCP/IP Devices",
    @"Firmware Update",
    @"Voltage",
    @"TransArmor",
    @"Misc",
};

static NSString *misc_operations[]={
	@"ExtRS Test",
};

static NSString *voltage_settings[]={
	@"Display Info",
	@"Generate New Key",
	@"Load Config 1 (SPE)",
	@"Load Config 2 (Full Track)",
    @"Set MerchantID",
};

static NSString *ta_settings[]={
    @"Display Info",
    @"Load Certificates",
    @"Set Encrypted T1, no sentinels",
    @"Set Encrypted T2",
    @"Set Encrypted T1&T2",
    @"Set Encrypted PAN",
    @"Set MerchantID",
    @"Set BIN Ranges",
    @"Clear BIN Ranges",
    @"Set clear BIN Ranges",
};

static NSString *led_names[]={
    @"Green",
    @"Red",
    @"Orange",
    @"Blue",
};

static uint32_t led_bits[]={
    0x00000001,
    0x00000002,
    0x00000003,
    0x00000004,
};

static UIColor *led_colors[4];

enum UPDATE_TARGETS{
    TARGET_DEVICE=0,
    TARGET_BLUETOOTH,
    TARGET_BARCODE,
};

static BOOL settings_values[SET_LAST];

int beep1[]={2730,250};
int beep2[]={2730,150,65000,20,2730,150};


-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

-(bool)isDeviceModelEqual:(NSString *)model
{
    NSString *deviceModel=[dtdev.deviceModel stringByReplacingOccurrencesOfString:@"PM" withString:@"AM"];
    
    if(model.length!=deviceModel.length)
        return false;
    
    for(int i=0;i<model.length;i+=2)
    {
        NSString *feat=[model substringWithRange:NSMakeRange(i,2)];
        if([deviceModel rangeOfString:feat].length==0)
            return false;
    }
    return true;
}

-(NSString *)getFirmwareFileName
{
    NSMutableString *s=[[NSMutableString alloc] init];
	NSError *error;
	NSString *name=[[dtdev.deviceName stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
    NSString *path=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Firmware"];
	NSArray *files=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    
	int lastVer=0;
	NSString *lastPath;
	for(int i=0;i<[files count];i++)
	{
		NSString *file=[[files objectAtIndex:i] lastPathComponent];
        if([[file lowercaseString] hasSuffix:@".bin"])
        {
            if([[file lowercaseString] rangeOfString:name].location!=NSNotFound)
            {
                NSData *data=[NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:file] options:0 error:&error];
                NSDictionary *info=[dtdev getFirmwareFileInformation:data error:&error];
                if(info)
                {
                    NSLog(@"file: %@, name=%@, model=%@",file,[info objectForKey:@"deviceName"],[info objectForKey:@"deviceModel"]);
                    [s appendFormat:@"file: %@, name=%@, model=%@\n",file,[info objectForKey:@"deviceName"],[info objectForKey:@"deviceModel"]];
                }
                
                if(info && [[info objectForKey:@"deviceName"] isEqualToString:dtdev.deviceName] && [self isDeviceModelEqual:[info objectForKey:@"deviceModel"]]/*[[info objectForKey:@"deviceModel"] isEqualToString:dtdev.deviceModel] */&& [[info objectForKey:@"firmwareRevisionNumber"] intValue]>lastVer)
                {
                    lastPath=[path stringByAppendingPathComponent:file];
                    lastVer=[[info objectForKey:@"firmwareRevisionNumber"] intValue];
                }
            }
        }
	}
	if(lastVer>0)
		return lastPath;
	return nil;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)theTextField;
{
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:tfTCPAddress.text forKey:@"tcpAddress"];
    [prefs synchronize];
    
	[textField resignFirstResponder];
	return YES;
}

-(void)connectionState:(int)state {
    NSError *error;
    
	switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
			break;
		case CONN_CONNECTED:
            btListening=false;
            
            memset(settings_values,0,sizeof(settings_values));
            
			//use stored values for settings that are not readable and set that value
			settings_values[SET_BEEP]=[[NSUserDefaults standardUserDefaults] boolForKey:@"BeepOnScan"];
            
			//read settings
            int value=BUTTON_DISABLED;
			[dtdev barcodeGetScanButtonMode:&value error:&error];
            settings_values[SET_ENABLE_SCAN_BUTTON]=(value==BUTTON_ENABLED);
            
			settings_values[SET_AUTOCHARGING]=[[NSUserDefaults standardUserDefaults] boolForKey:@"AutoCharging"];

            if(![dtdev barcodeGetScanMode:&scanMode error:&error])
                scanMode=0;
            
            BOOL enabled=false;;
            [dtdev getPassThroughSync:&enabled error:&error];
            settings_values[SET_ENABLE_SYNC]=enabled;
            
            enabled=false;;
            [dtdev uiIsSpeakerEnabled:&enabled error:&error];
            settings_values[SET_ENABLE_SPEAKER]=enabled;

            enabled=false;;
            [dtdev uiIsSpeakerButtonEnabled:&enabled error:&error];
            settings_values[SET_ENABLE_SPEAKER_BUTTON]=enabled;
            
            enabled=false;;
            [dtdev uiIsSpeakerAutoControlEnabled:&enabled error:&error];
            settings_values[SET_ENABLE_SPEAKER_AUTO]=enabled;
            
            enabled=false;;
            [dtdev getKioskMode:&enabled error:&error];
            settings_values[SET_KIOSK]=enabled;
            
            [dtdev getUSBChargeCurrent:&chargeCurrent error:&error];
            
			settings_values[SET_VIBRATE]=[[NSUserDefaults standardUserDefaults] boolForKey:@"vibrateOnScan"];
            
			[settingsTable reloadData];
			break;
	}
}

-(void)bluetoothDeviceDiscovered:(NSString *)btAddress name:(NSString *)btName
{
    if(!btName || btName.length==0)
        btName=@"Unknown";
    [btDevices addObject:btAddress];
    [btDevices addObject:btName];
}

-(void)bluetoothDiscoverComplete:(BOOL)success
{
    [progressViewController.view removeFromSuperview];
    [settingsTable reloadData];
    if(!success)
        [self displayAlert:NSLocalizedString(@"Bluetooth Error",nil) message:NSLocalizedString(@"Discovery failed!",nil)];
    
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:btDevices forKey:@"bluetoothDevices"];
    [prefs synchronize];
}

-(void)deviceFeatureSupported:(int)feature value:(int)value
{
    [settingsTable reloadData];
}

-(void)firmwareUpdateEnd:(NSError *)error
{
    [progressViewController.view removeFromSuperview];
    if(error)
        [self displayAlert:NSLocalizedString(@"Firmware Update",nil) message:[NSString stringWithFormat:NSLocalizedString(@"Firmware updated failed with error:%@",nil),error.localizedDescription]];
}

-(void)firmwareUpdateProgress:(int)phase percent:(int)percent
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (phase)
        {
            case UPDATE_INIT:
                [progressViewController updateProgress:NSLocalizedString(@"Initializing update...",nil) progress:percent];
                break;
            case UPDATE_ERASE:
                [progressViewController updateProgress:NSLocalizedString(@"Erasing flash...",nil) progress:percent];
                break;
            case UPDATE_WRITE:
                [progressViewController updateProgress:NSLocalizedString(@"Writing firmware...",nil) progress:percent];
                break;
            case UPDATE_COMPLETING:
                [progressViewController updateProgress:NSLocalizedString(@"Completing operation...",nil) progress:percent];
                break;
            case UPDATE_FINISH:
                [progressViewController updateProgress:NSLocalizedString(@"Complete!",nil) progress:percent];
                break;
        }
    });
}

-(void)firmwareUpdateThread:(NSString *)file
{
	@autoreleasepool {
        NSError *error=nil;
    
        BOOL idleTimerDisabled_Old=[UIApplication sharedApplication].idleTimerDisabled;
        [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
        
        if(firmareTarget==TARGET_DEVICE)
        {
            [progressViewController updateText:@"Updating Device...\nPlease wait!"];
            
            //In case authentication key is present in Linea, we need to authenticate with it first, before firmware update is allowed
            //For the sample here I'm using the field "Authentication key" in the crypto settings as data and generally ignoring the result of the
            //authentication operation, firmware update will just fail if authentication have failed
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            //last used decryption key is stored in preferences
            NSString *authenticationKey=[prefs objectForKey:@"AuthenticationKey"];
            if(authenticationKey==nil || authenticationKey.length!=32)
                authenticationKey=@"11111111111111111111111111111111"; //sample default
            
            [dtdev cryptoAuthenticateHost:[authenticationKey dataUsingEncoding:NSASCIIStringEncoding] error:nil];
            [dtdev updateFirmwareData:[NSData dataWithContentsOfFile:file] error:&error];
        }
        if(firmareTarget==TARGET_BARCODE)
        {
            if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_OPTICON)
            {
                [progressViewController updateText:[NSString stringWithFormat:@"Updating to %@...\nPlease wait!",[file lastPathComponent]]];
                
                [dtdev barcodeOpticonUpdateFirmware:[NSData dataWithContentsOfFile:file] bootLoader:FALSE error:&error];
            }
            if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_CODE)
            {
                [progressViewController updateText:@"Updating engine...\nPlease wait!"];
                [dtdev barcodeCodeUpdateFirmware:[file lastPathComponent] data:[NSData dataWithContentsOfFile:file] error:&error];
            }
            if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_INTERMEC)
            {
                [progressViewController updateText:@"Updating engine...\nPlease wait!"];
                [dtdev barcodeIntermecUpdateFirmware:[NSData dataWithContentsOfFile:file] error:&error];
            }
            if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_NEWLAND)
            {
                [progressViewController updateText:@"Updating engine...\nPlease wait!"];
                
                [dtdev barcodeNewlandUpdateFirmware:[NSData dataWithContentsOfFile:file] error:&error];
            }
        }
        if(firmareTarget==TARGET_BLUETOOTH)
        {
            [progressViewController updateText:[NSString stringWithFormat:@"Updating to %@...\nPlease wait!",[file lastPathComponent]]];

            //additional - clear pairing info, set mode to super hidden, enable automatic retrying for connection while the pinpad is turned on
            NSData *additonalData = [@"AT+CLRPAIR\r\n\0AT+WRSEC=2,1,3\r\n\0AT+WRCONLOOP=1,0,0\r\n\0" dataUsingEncoding:NSASCIIStringEncoding];
            [dtdev btFirmwareUpdate:[NSData dataWithContentsOfFile:file] additionalData:additonalData error:&error];
        }

        [[UIApplication sharedApplication] setIdleTimerDisabled: idleTimerDisabled_Old];
        [self performSelectorOnMainThread:@selector(firmwareUpdateEnd:) withObject:error waitUntilDone:FALSE];
    
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != 0)
    {
        if(alertView.tag==0)
        {//firmware update
            //Make firmware update prettier - call it from a thread and listen to the notifications only
            [progressViewController viewWillAppear:FALSE];
            [self.view addSubview:progressViewController.view];
            
            NSString *file=[firmwareFiles objectAtIndex:0];
            
            if(firmwareFiles.count>1)
            {
                file=[firmwareFiles objectAtIndex:buttonIndex-1];
            }
            
            [NSThread detachNewThreadSelector:@selector(firmwareUpdateThread:) toTarget:self withObject:file];
        }
        if(alertView.tag==1)
        {//charging
            NSError *error;
            if(![dtdev setUSBChargeCurrent:chargeCurrent error:&error])
            {
                ERRMSG(NSLocalizedString(@"Command failed",nil));
            }
            [dtdev getUSBChargeCurrent:&chargeCurrent error:&error];
            [settingsTable reloadData];
        }
        if(alertView.tag==2)
        {//kiosk
            NSError *error;
            if(![dtdev setKioskMode:settings_values[SET_KIOSK] error:&error])
            {
                settings_values[SET_KIOSK]=FALSE;
                ERRMSG(NSLocalizedString(@"Command failed",nil));
            }
            [settingsTable reloadData];
        }
    }
}

-(void)checkForFirmwareUpdate;
{
	NSString *file=[self getFirmwareFileName];
	if(file!=nil)
	{
        NSDictionary *info=[dtdev getFirmwareFileInformation:[NSData dataWithContentsOfFile:file] error:nil];
        
        if(info)
        {
            firmwareFiles=[NSMutableArray array];
            [firmwareFiles addObject:file];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"Device ver: %@\nAvailable: %@\n\nDo you want to update firmware?\n\nDO NOT DISCONNECT DEVICE DURING FIRMWARE UPDATE!",nil),[dtdev firmwareRevision],[info objectForKey:@"firmwareRevision"]]
                                                           delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Update",nil), nil];
            [alert show];
            return;
        }
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
                                                    message:NSLocalizedString(@"No firmware for this device model present",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok",nil) otherButtonTitles:nil, nil];
    [alert show];
}

-(BOOL)getFilesWithPrefix:(NSString *)prefix orPrefix:(NSString *)otherPrefix extension:(NSString *)extension
{
    prefix=[prefix lowercaseString];
    otherPrefix=[otherPrefix lowercaseString];
    
    NSString *path=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Firmware"];
    
    NSArray *files=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    firmwareFiles=[NSMutableArray array];
    
    for(int i=0;i<[files count];i++)
    {
        NSString *file=[[files objectAtIndex:i] lastPathComponent];
        if(([[file lowercaseString] hasPrefix:prefix] || [[file lowercaseString] hasPrefix:otherPrefix]) && [[file lowercaseString] hasSuffix:extension])
        {
            [firmwareFiles addObject:[path stringByAppendingPathComponent:[files objectAtIndex:i]]];
        }
    }
    return firmwareFiles.count!=0;
}

-(void)checkForBluetoothFirmwareUpdate;
{
    NSError *error;
    NSString *ver=[dtdev btGetFirmwareVersion:&error];
    if(!ver)
    {
        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Bluetooth query failed: %@",error.localizedDescription]];
        return;
    }

    if([self getFilesWithPrefix:@"update_" orPrefix:@"" extension:@".dfu"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"BT Firmware Update",nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Current bluetooth firmware: %@\n\nDo you want to update firmware?\n\nDO NOT DISCONNECT DEVICE DURING FIRMWARE UPDATE!",nil),ver]
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:nil, nil];
        for (NSString *file in firmwareFiles)
            [alert addButtonWithTitle:[file lastPathComponent]];
        [alert show];
    }else
        [self displayAlert:@"Error" message:@"No firmware for this module present"];
}

-(void)checkForPinpadFirmwareUpdate;
{
    NSError *error;
    NSString *ver=dtdev.firmwareRevision;
    if(!ver)
    {
        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Bluetooth query failed: %@",error.localizedDescription]];
        return;
    }
    
    NSString *devName=dtdev.deviceName;
    
    if([self getFilesWithPrefix:devName orPrefix:@"pinpad_ap" extension:@".bin"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Pinpad Firmware Update",nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Current pinpad firmware: %@\n\nDo you want to update firmware?\n\nDO NOT DISCONNECT DEVICE DURING FIRMWARE UPDATE!",nil),ver]
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:nil, nil];
        for (NSString *file in firmwareFiles)
            [alert addButtonWithTitle:[file lastPathComponent]];
        [alert show];
    }else
        [self displayAlert:@"Error" message:@"No firmware for this device present"];
}


-(void)checkForOpticonFirmwareUpdate;
{
    NSError *error;
    NSString *opticonIdent=[dtdev barcodeOpticonGetIdent:&error];
    if(!opticonIdent)
    {
        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Engine query failed: %@",error.localizedDescription]];
        return;
    }
    
    if([self getFilesWithPrefix:@"opticon" orPrefix:@"" extension:@".bin"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Current engine firmware: %@\n\nDo you want to update firmware?\n\nDO NOT DISCONNECT DEVICE DURING FIRMWARE UPDATE!",nil),opticonIdent]
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:nil, nil];
        for (NSString *file in firmwareFiles)
            [alert addButtonWithTitle:[file lastPathComponent]];
        [alert show];
    }else
        [self displayAlert:@"Error" message:@"No firmware for this device model present"];
}

-(void)checkForCodeFirmwareUpdate;
{
    NSString *file=[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Firmware"] stringByAppendingPathComponent:@"C005922_0674-system-cr8000-CD_GEN.crz"];
    
	if(![[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:nil])
	{
        [self displayAlert:@"Error" message:@"No firmware for this device present"];
    }else
    {
        NSError *error;
        NSDictionary *info=[dtdev barcodeCodeGetInformation:&error];
        if(!info)
        {
            [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Engine query failed: %@",error.localizedDescription]];
        }else
        {
            firmwareFiles=[NSMutableArray array];
            [firmwareFiles addObject:file];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
                                                            message:[NSString stringWithFormat:@"Reader info:\n%@\nDo you want to update engine firmware?",info]
                                                           delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Update",nil), nil];
            [alert show];
        }
    }
}

-(void)checkForNewlandFirmwareUpdate;
{
    //engine may be dead and still able to update just fine so ignore errors trying to query the info
    NSError *error;
    NSData *r;
    
    NSString *ident=@"Engine query failed";
    NSString *engine=@"";

    r=[dtdev barcodeNewlandQuery:[@"3G" dataUsingEncoding:NSASCIIStringEncoding] error:&error];
    if(r)
    {
        NSString *ver=[[NSString alloc] initWithData:r encoding:NSASCIIStringEncoding];

        r=[dtdev barcodeNewlandQuery:[@"3H030" dataUsingEncoding:NSASCIIStringEncoding] error:&error];
        if(r)
        {
            engine=[[NSString alloc] initWithData:r encoding:NSASCIIStringEncoding];
            if([engine rangeOfString:@"EB"].location!=NSNotFound)
                engine=@"EM3070";
            if([engine rangeOfString:@"ES"].location!=NSNotFound)
                engine=@"EM3096";
            if([engine rangeOfString:@"E3"].location!=NSNotFound)
                engine=@"EM3000";
            if([engine rangeOfString:@"0300"].location!=NSNotFound)
                engine=@"EM3000";
            if([engine rangeOfString:@"EW"].location!=NSNotFound)
                engine=@"EM3090";

            ident=[NSString stringWithFormat:@"Engine: %@\nVersion: %@\n",engine,ver];
        }
    }

    if([self getFilesWithPrefix:[@"newland_" stringByAppendingString:engine] orPrefix:@"" extension:@".bin"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"%@\n\nDo you want to update firmware?\n\nDO NOT DISCONNECT DEVICE DURING FIRMWARE UPDATE!",nil),ident]
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:nil, nil];
        for (NSString *file in firmwareFiles)
            [alert addButtonWithTitle:[[file lastPathComponent] substringFromIndex:@"newland_".length]];
        [alert show];
    }else
        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"%@\n\nNo firmware for this device model present!",ident]];
}

-(void)checkForIntermecFirmwareUpdate;
{
    NSError *error;
    NSData *r;
    uint8_t cmdVer[]={0x43,0x30,0xC0};
    r=[dtdev barcodeIntermecQuery:[NSData dataWithBytes:cmdVer length:sizeof(cmdVer)] error:&error];
    NSString *barcodeIdent;
    if(r)
    {
        //reply: 53 STG FID LENHI LENLO DATA
        const UInt8 *bytes=r.bytes;
        int payloadLen=(bytes[3]<<8)|bytes[4];
        barcodeIdent=[[NSString alloc] initWithBytes:&bytes[5] length:payloadLen encoding:NSASCIIStringEncoding];
    }else
    {
        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Engine query failed: %@",error.localizedDescription]];
        return;
    }


    if([self getFilesWithPrefix:@"intermec_" orPrefix:@"" extension:@".bin"])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Firmware Update",nil)
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"Current engine firmware: %@\n\nDo you want to update firmware?\n\nDO NOT DISCONNECT DEVICE DURING FIRMWARE UPDATE!",nil),barcodeIdent]
                                                       delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:nil, nil];
        for (NSString *file in firmwareFiles)
            [alert addButtonWithTitle:[file lastPathComponent]];
        [alert show];
    }else
        [self displayAlert:@"Error" message:@"No firmware for this device model present"];
}

-(void)checkForMotorolaFirmwareUpdate;
{
    NSError *error;
    NSString *barcodeIdent=[dtdev barcodeMotorolaGetVersion:&error];
    if(barcodeIdent)
    {
        [self displayAlert:@"Success" message:[NSString stringWithFormat:@"Barcode ident:\n%@",barcodeIdent]];
    }else
    {
        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Engine query failed: %@",error.localizedDescription]];
        return;
    }
}

-(void)bluetoothDeviceConnected:(NSString *)address;
{
    NSLog(@"bluetoothDeviceConnected: addr: %@",address);
    [settingsTable reloadData];
//    const char *test="test\r\n";
//    [dtdev.btOutputStream write:test maxLength:strlen(test)];
}

-(void)bluetoothDeviceDisconnected:(NSString *)address;
{
    NSLog(@"bluetoothDeviceDisconnected: addr: %@",address);
    [settingsTable reloadData];
}

-(BOOL)bluetoothDeviceRequestedConnection:(NSString *)address name:(NSString *)name
{
    NSLog(@"bluetoothDeviceRequestedConnection: addr: %@, name: %@",address,name);
    return true;
}

-(NSString *)bluetoothDevicePINCodeRequired:(NSString *)address name:(NSString *)name;
{
    NSLog(@"bluetoothDevicePINCodeRequired: addr: %@, name: %@",address,name);
    return @"0000";
}

#ifdef BTLE_USED
-(void)bluetoothLEDeviceConnected:(CBPeripheral *)device
{
    NSLog(@"bluetoothLEDeviceConnected: device: %@",device);
    [settingsTable reloadData];
}

-(void)bluetoothLEDeviceDisconnected:(CBPeripheral *)device
{
    NSLog(@"bluetoothLEDeviceDisconnected: device: %@",device);
    [settingsTable reloadData];
}
#endif

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Number of sections is the number of region dictionaries
    return SEC_LAST;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(section_names[section],nil);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Number of rows is the number of names in the region dictionary for the specified section
    size_t nRows=0;
	switch (section)
	{
		case SEC_GENERAL:
            if(dtdev.connstate==CONN_CONNECTED)
                nRows=SET_LAST;
            break;

        case SEC_CHARGING:
            if(dtdev.connstate==CONN_CONNECTED)
                nRows=sizeof(charge_currents)/sizeof(charge_currents[0]);
            break;

		case SEC_BARCODE_MODE:
            if(dtdev.connstate==CONN_CONNECTED && [dtdev getSupportedFeature:FEAT_BARCODE error:nil]!=FEAT_UNSUPPORTED)
                nRows=5;
            break;
            
		case SEC_LEDS:
            if(dtdev.connstate==CONN_CONNECTED && [dtdev getSupportedFeature:FEAT_LEDS error:nil]!=FEAT_UNSUPPORTED)
                nRows=4;
            break;

        case SEC_APPLE_BT:
            nRows=1;

		case SEC_BT_CLIENT:
            if(dtdev.connstate==CONN_CONNECTED)
            {
                if(dtdev.connstate==CONN_CONNECTED && [dtdev getSupportedFeature:FEAT_BLUETOOTH error:nil]!=FEAT_UNSUPPORTED)
                    nRows=[btDevices count]/2+1;
            }
            break;

		case SEC_BT_SERVER:
            if(dtdev.connstate==CONN_CONNECTED)
            {
                if(dtdev.connstate==CONN_CONNECTED && [dtdev getSupportedFeature:FEAT_BLUETOOTH error:nil]&BLUETOOTH_HOST)
                    nRows=1+dtdev.btConnectedDevices.count;
                //cache the connected devices in case they change between here and the display
                btConnectedDevices=[dtdev.btConnectedDevices copy];
            }
            break;
            
#ifdef BTLE_USED
		case SEC_BTLE:
            if(btleDevices!=nil)
                nRows=btleDevices.count+1;
            else
                nRows=1;
            break;
#endif
            
		case SEC_TCP_DEVICES:
            nRows=2;
            break;
            
		case SEC_FIRMWARE_UPDATE:
            if(dtdev.connstate==CONN_CONNECTED)
                nRows=3;
            break;
            
        case SEC_VOLTAGE:
            if(dtdev.connstate==CONN_CONNECTED && [dtdev getSupportedFeature:FEAT_MSR error:nil]&MSR_VOLTAGE)
                nRows=sizeof(voltage_settings)/sizeof(voltage_settings[0]);
            break;
            
        case SEC_TRANSARMOR:
            if(dtdev.connstate==CONN_CONNECTED && [dtdev getSupportedFeature:FEAT_MSR error:nil]&MSR_TRANS_ARMOR)
                nRows=sizeof(ta_settings)/sizeof(ta_settings[0]);
            break;
            
        case SEC_MISC:
            if(dtdev.connstate==CONN_CONNECTED && [dtdev getSupportedFeature:FEAT_EXTERNAL_SERIAL_PORT error:nil]==FEAT_SUPPORTED)
                nRows=sizeof(misc_operations)/sizeof(misc_operations[0]);
            break;
	}
	return nRows;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSError *error=nil;
    
	switch ([indexPath indexAtPosition:0])
	{
		case SEC_GENERAL:
            if(settings_values[indexPath.row])
			{
				settings_values[indexPath.row]=FALSE;
			}else
			{
				settings_values[indexPath.row]=TRUE;
			}
			switch (indexPath.row)
            {
                case SET_BEEP:
                    if(settings_values[SET_BEEP])
                    {
                        [dtdev barcodeSetScanBeep:settings_values[SET_BEEP] volume:100 beepData:beep2 length:sizeof(beep2) error:nil];
                        [dtdev playSound:100 beepData:beep2 length:sizeof(beep2) error:nil];
                    }else
                    {
                        [dtdev barcodeSetScanBeep:settings_values[SET_BEEP] volume:0 beepData:nil length:0 error:nil];
                    }
                    [[NSUserDefaults standardUserDefaults] setBool:settings_values[SET_BEEP] forKey:@"BeepOnScan"];
                    break;
                case SET_ENABLE_SCAN_BUTTON:
                    [dtdev barcodeSetScanButtonMode:settings_values[SET_ENABLE_SCAN_BUTTON] error:nil];
                    break;
                case SET_AUTOCHARGING:
                    [[NSUserDefaults standardUserDefaults] setBool:settings_values[SET_AUTOCHARGING] forKey:@"AutoCharging"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    if(![dtdev setCharging:settings_values[SET_AUTOCHARGING] error:nil])
                        ERRMSG(NSLocalizedString(@"Charging could not be enabled at the moment",nil));
                    break;
                case SET_RESET_BARCODE:
                    if([dtdev barcodeEngineResetToDefaults:&error])
                        [self displayAlert:@"Success" message:@"Barcode engine was resetted"];
                    else
                        ERRMSG(NSLocalizedString(@"Command failed",nil));
                    settings_values[indexPath.row]=FALSE;
                    break;
                case SET_ENABLE_SPEAKER:
                    if(![dtdev uiEnableSpeaker:settings_values[indexPath.row] error:&error])
                    {
                        settings_values[indexPath.row]=FALSE;
                        ERRMSG(NSLocalizedString(@"Command failed",nil));
                    }
                    if(error==nil)
                        [ScannerViewController playSound:@"News_Intro-Maximilien_-1801238420.wav" volume:0.7];
                    break;
                case SET_ENABLE_SPEAKER_BUTTON:
                    if(![dtdev uiEnableSpeakerButton:settings_values[indexPath.row] error:&error])
                    {
                        settings_values[indexPath.row]=FALSE;
                        ERRMSG(NSLocalizedString(@"Command failed",nil));
                    }
                    break;
                    break;
                case SET_ENABLE_SPEAKER_AUTO:
                    if(![dtdev uiEnableSpeakerAutoControl:settings_values[indexPath.row] error:&error])
                    {
                        settings_values[indexPath.row]=FALSE;
                        ERRMSG(NSLocalizedString(@"Command failed",nil));
                    }
                    break;
                case SET_ENABLE_SYNC:
                    if(![dtdev setPassThroughSync:settings_values[indexPath.row] error:&error])
                    {
                        settings_values[indexPath.row]=FALSE;
                        ERRMSG(NSLocalizedString(@"Command failed",nil));
                    }
                    break;
                case SET_KIOSK:
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING!!!",nil)
                                                                    message:NSLocalizedString(@"When you enable kiosk mode you will be able to connect only if having 2A+ wall charger attached! Warning: Use only the charging cable part number Z05B000000 provided in this package with this product. Using any other cable may either decrease the product performance and/or cause damage to this product and will void warranty!",nil)
                                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Set Kiosk",nil), nil];
                    alert.tag=2;
                    [alert show];
                    break;
                }
                    
                case SET_VIBRATE:
                    [[NSUserDefaults standardUserDefaults] setBool:settings_values[indexPath.row] forKey:@"vibrateOnScan"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    if(settings_values[indexPath.row])
                    {
                        [dtdev uiEnableVibrationForTime:0.5 error:nil];
                        [NSThread sleepForTimeInterval:0.5];
                    }
                    break;
                case SET_POWER_OFF:
                    settings_values[indexPath.row]=FALSE;
                    if(![dtdev sysPowerOff:&error])
                    {
                        ERRMSG(NSLocalizedString(@"Command failed",nil));
                    }
                    break;
                case SET_DISABLE_CODE128:
                case SET_ENABLE_CODE128:
                {
                    bool enable=indexPath.row==SET_ENABLE_CODE128;
                    settings_values[indexPath.row]=FALSE;
                    //sample for custom command for different engines
                    //opticon
                    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_OPTICON)
                    {
                        if(![dtdev barcodeOpticonSetInitString:enable?@"B6":@"VE" error:&error])
                        {
                            ERRMSG(NSLocalizedString(@"Command failed",nil));
                        }
                    }
                    //intermec
                    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_INTERMEC)
                    {
                        const uint8_t intermecInit[]=
                        {
                            0x41, //start
                            0x43,0x40,enable?1:0,
                        };
                        
                        if(![dtdev barcodeIntermecSetInitData:[NSData dataWithBytes:intermecInit length:sizeof(intermecInit)] error:&error])
                        {
                            ERRMSG(NSLocalizedString(@"Command failed",nil));
                        }
                    }
                    //newland
                    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_NEWLAND)
                    {
                        if(![dtdev barcodeNewlandSetInitString:enable?@"NLS0400020;":@"NLS0400010;" error:&error])
                        {
                            ERRMSG(NSLocalizedString(@"Command failed",nil));
                        }
                    }
                    break;
                }
            }
			[[tableView cellForRowAtIndexPath: indexPath] setAccessoryType:settings_values[indexPath.row]?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone];
			break;
            
        case SEC_CHARGING:
        {
            int current[]={500,1000,2100,2400};
            

            chargeCurrent=current[indexPath.row];
            if(chargeCurrent>=1000)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING!!!",nil)
                                                                message:NSLocalizedString(@"Linea's own battery charge adds additional 300mA to the charging current and you can damage your adapter/port if you increase the charge current beyound its limits!!! Do not put 1A charge on 1A adapters, always use 2A+ adapter! Do not use 1A charge on PCs, unless it goes through high-power usb HUB!\nAdditional, charge currents of 2A and 2.4A are only supported in kiosk mode!",nil)
                                                               delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Set charge",nil), nil];
                alert.tag=1;
                [alert show];
            }else
            {
                if(![dtdev setUSBChargeCurrent:chargeCurrent error:&error])
                {
                    settings_values[indexPath.row]=FALSE;
                    ERRMSG(NSLocalizedString(@"Command failed",nil));
                }
                [dtdev getUSBChargeCurrent:&chargeCurrent error:&error];
                [settingsTable reloadData];
            }
            break;
        }
            
        case SEC_BARCODE_MODE:
            if([dtdev barcodeSetScanMode:(int)indexPath.row error:nil])
                scanMode=(int)indexPath.row;
            [tableView reloadData];
            break;
            
        case SEC_LEDS:
        {
            [dtdev uiControlLEDsWithBitMask:led_bits[indexPath.row] error:nil];
            [NSThread sleepForTimeInterval:2.0];
            [dtdev uiControlLEDsWithBitMask:0 error:nil];
//            for(int i=0;i<4;i++)
//            {
//                [dtdev uiControlLEDsWithBitMask:led_bits[indexPath.row] error:nil];
//                [NSThread sleepForTimeInterval:0.3];
//                [dtdev uiControlLEDsWithBitMask:0 error:nil];
//                [NSThread sleepForTimeInterval:0.2];
//            }
            break;
        }

        case SEC_APPLE_BT:
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self BEGINSWITH 'PP'"];
            [[EAAccessoryManager sharedAccessoryManager] showBluetoothAccessoryPickerWithNameFilter:predicate completion:^(NSError *error) {
                if(!error)
                    [self displayAlert:@"Acc Picker" message:@"BT Accessory picker succeeded!"];
                else
                    [self displayAlert:@"Acc Picker" message:[@"BT Accessory picker failed with message: " stringByAppendingString:error.localizedDescription]];
            }];
            break;
        }

        case SEC_BT_CLIENT:
            if(indexPath.row==0)
            {//perform discovery
                NSError *error=nil;
                [progressViewController viewWillAppear:FALSE];
                [self.view addSubview:progressViewController.view];
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
                
                [btDevices removeAllObjects];
//                if(![dtdev btDiscoverSupportedDevicesInBackground:10 maxTime:8 filter:BLUETOOTH_FILTER_ALL error:&error])
                if(![dtdev btDiscoverDevicesInBackground:10 maxTime:9 codTypes:0 error:&error])
                {
                    [progressViewController.view removeFromSuperview];
                    ERRMSG(NSLocalizedString(@"Bluetooth Error",nil));
                }
            }else
            {//connect to the device
                [progressViewController viewWillAppear:FALSE];
                [self.view addSubview:progressViewController.view];
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
                
                NSString *selectedAddress=[btDevices objectAtIndex:(indexPath.row-1)*2];
                [[NSUserDefaults standardUserDefaults] setValue:selectedAddress forKey:@"selectedPrinterAddress"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                if([dtdev.btConnectedDevices containsObject:selectedAddress])
                {
                    [dtdev btDisconnect:selectedAddress error:nil];
                }else
                {
                    NSError *error=nil;
                    if(![dtdev btConnectSupportedDevice:selectedAddress pin:@"0000" error:&error])
//                    if(![dtdev btConnect:selectedAddress pin:@"0000" error:&error])
                    {
                        ERRMSG(NSLocalizedString(@"Bluetooth Error",nil));
                    }
                }
                
                [progressViewController.view removeFromSuperview];
                [tableView reloadData];
            }
            break;

        case SEC_BT_SERVER:
            [progressViewController viewWillAppear:FALSE];
            [self.view addSubview:progressViewController.view];
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
            
            if(indexPath.row==0)
            {//init/stop server
                NSError *error=nil;
                
                if(!btListening)
                {
                    if(![dtdev btListenForDevices:TRUE discoverable:TRUE localName:@"BTDTDevices" cod:0x000000 error:&error])
                    {
                        [progressViewController.view removeFromSuperview];
                        ERRMSG(NSLocalizedString(@"Bluetooth Error",nil));
                    }else
                        btListening=true;
                }else
                {
                    [dtdev btListenForDevices:FALSE discoverable:TRUE localName:nil cod:0x000000 error:&error];
                    btListening=false;
                }
            }else
            {//disconnect from active connection
                [dtdev btDisconnect:[dtdev.btConnectedDevices objectAtIndex:indexPath.row-1] error:nil];
            }
            [progressViewController.view removeFromSuperview];
            [tableView reloadData];
            break;
            
#ifdef BTLE_USED
        case SEC_BTLE:
            if(indexPath.row==0)
            {//perform discovery
                NSError *error=nil;
                
                btleDevices=[dtdev btleDiscoverSupportedDevices:BLUETOOTH_FILTER_ALL stopOnFound:false error:&error];
                if(!btleDevices)
                {
                    ERRMSG(NSLocalizedString(@"Bluetooth Error",nil));
                }
                [tableView reloadData];
            }else
            {//connect to the device
                [progressViewController viewWillAppear:FALSE];
                [self.view addSubview:progressViewController.view];
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
                
                CBPeripheral *selectedDevice=[btleDevices objectAtIndex:indexPath.row-1];
                
                if([dtdev.btleConnectedDevices containsObject:selectedDevice])
                {
                    [dtdev btleDisconnect:selectedDevice error:nil];
                }else
                {
                    NSError *error=nil;
                    if(![dtdev btleConnectToDevice:selectedDevice error:&error])
                    {
                        ERRMSG(NSLocalizedString(@"BluetoothLE Error",nil));
                    }
                }
                
                [progressViewController.view removeFromSuperview];
                [tableView reloadData];
            }
            break;
#endif
            
        case SEC_TCP_DEVICES:
        {
            if(indexPath.row==0)
            {//connect to the specified address
                NSError *error;
                [progressViewController viewWillAppear:FALSE];
                [self.view addSubview:progressViewController.view];
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
                
                error=nil;
                
                NSString *selectedAddress=[[NSUserDefaults standardUserDefaults] objectForKey:@"tcpAddress"];
                
                if([dtdev.tcpConnectedDevices containsObject:selectedAddress])
                {
                    [dtdev tcpDisconnect:selectedAddress error:nil];
                }else
                {
                    NSError *error=nil;
                    if(![dtdev tcpConnectSupportedDevice:selectedAddress error:&error])
                    {
                        ERRMSG(NSLocalizedString(@"Connection Error",nil));
                    }
                }

                [progressViewController.view removeFromSuperview];
                [tableView reloadData];
            }
            break;
        }
            
		case SEC_FIRMWARE_UPDATE:
            firmareTarget=(int)indexPath.row;
            switch (firmareTarget)
            {
                case TARGET_DEVICE:
//                    if([dtdev getSupportedFeature:FEAT_PIN_ENTRY error:nil])
//                        [self checkForPinpadFirmwareUpdate];
//                    else
                        [self checkForFirmwareUpdate];
                    break;
                case TARGET_BLUETOOTH:
                    [self checkForBluetoothFirmwareUpdate];
                    break;
                case TARGET_BARCODE:
                    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_OPTICON)
                    {
                        [self checkForOpticonFirmwareUpdate];
                    }
                    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_CODE)
                    {
                        [self checkForCodeFirmwareUpdate];
                    }
                    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_NEWLAND)
                    {
                        [self checkForNewlandFirmwareUpdate];
                    }
                    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_INTERMEC)
                    {
                        [self checkForIntermecFirmwareUpdate];
                    }
                    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_MOTOROLA)
                    {
                        [self checkForMotorolaFirmwareUpdate];
                    }
                    break;
            }
			break;
            
        case SEC_VOLTAGE:
            if(indexPath.row==0)
            {//display info
                DTVoltageInfo *info;
                if(!(info=[dtdev voltageGetInfo:&error]))
                {
                    ERRMSG(@"Voltage error");
                }else
                {
                    [self displayAlert:@"Voltage info" message:[NSString stringWithFormat:@"Settings ver: %d\nKey present: %d\nGenerating: %d\nLast date: %@",info.settingsVersion,info.keyGenerated,info.keyGenerationInProgress,info.keyGenerationDate]];
                }
            }
            if(indexPath.row==1)
            {//regenerate key
                if(![dtdev voltageGenerateNewKey:&error])
                {
                    ERRMSG(@"Voltage error");
                }else
                    [self displayAlert:@"Success" message:@"Settings has been set and new key is currently generating, please wait for couple of minutes for generation to finish. You can always check the status"];
            }
            if(indexPath.row==2)
            {//load some defaults
                NSData *file=[NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"LINEA_VOLTAGE_PARAMS_TEST_1_S2.0.0.0.BIN"]];
                
                if([dtdev voltageLoadConfiguration:file error:&error])
                {
                    [dtdev voltageGenerateNewKey:&error];
                    [self displayAlert:@"Success" message:@"Settings has been set and new key is currently generating, please wait for couple of minutes for generation to finish. You can always check the status"];
                }else
                {
                    [self displayAlert:@"Voltage error" message:[NSString stringWithFormat:@"voltageLoadConfiguration failed: %@",error.localizedDescription]];
                }
            }
            if(indexPath.row==3)
            {//load some defaults
                NSData *file=[NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"LINEA_VOLTAGE_PARAMS_TEST_2_S2.0.0.0.BIN"]];
                
                if([dtdev voltageLoadConfiguration:file error:&error])
                {
                    [dtdev voltageGenerateNewKey:&error];
                    [self displayAlert:@"Success" message:@"Settings has been set and new key is currently generating, please wait for couple of minutes for generation to finish. You can always check the status"];
                }else
                {
                    [self displayAlert:@"Voltage error" message:[NSString stringWithFormat:@"voltageLoadConfiguration failed: %@",error.localizedDescription]];
                }
            }
            if(indexPath.row==4)
            {//set MID
                if([dtdev voltageSetMerchantID:@"12345" error:&error])
                {
                    [self displayAlert:@"Success" message:@"Merchant ID successfully set"];
                }else
                {
                    [self displayAlert:@"Voltage error" message:[NSString stringWithFormat:@"voltageSetMerchantID failed: %@",error.localizedDescription]];
                }
            }
            break;
            
        case SEC_TRANSARMOR:
            if(indexPath.row==0)
            {//get info
                NSArray *certificates=[dtdev cryptoGetCertificatesInfo:&error];
                if(certificates)
                {
                    NSMutableString *display=[NSMutableString string];
                    for (DTCertificateInfo *info in certificates) {
                        [display appendFormat:@"Slot: %d, version:%08X\n",info.slot,info.version];
                    }
                    [self displayAlert:@"Loaded certificates" message:display];
                }else
                {
                    [self displayAlert:@"Certificates error" message:[NSString stringWithFormat:@"cryptoGetCertificatesInfo failed: %@",error.localizedDescription]];
                }
            }
            if(indexPath.row==1)
            {//load certificates
//                NSString *file=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"root.pem"];
//                NSString *pem=[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:file] encoding:NSASCIIStringEncoding];
//                if(![dtdev cryptoLoadCertificate:pem version:0x01 position:CERT_SLOT_DATA_ROOT rootPosition:CERT_SLOT_DATA_ROOT error:&error])
//                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Root certificate loading failed with error: %@",error.localizedDescription]];
//                
//                file=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"mid.pem"];
//                pem=[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:file] encoding:NSASCIIStringEncoding];
//                if(![dtdev cryptoLoadCertificate:pem version:0x01 position:CERT_SLOT_DATA_INTERMEDIATE rootPosition:CERT_SLOT_DATA_ROOT error:&error])
//                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Intermediate certificate loading failed with error: %@",error.localizedDescription]];
//                
//                file=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"data.pem"];
//                pem=[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:file] encoding:NSASCIIStringEncoding];
//                if(![dtdev cryptoLoadCertificate:pem version:0x01 position:CERT_SLOT_DATA_KEY rootPosition:CERT_SLOT_DATA_INTERMEDIATE error:&error])
//                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Key certificate loading failed with error: %@",error.localizedDescription]];
                
                NSString *file=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TACA.PEM"];
                NSString *pem=[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:file] encoding:NSASCIIStringEncoding];
                if(![dtdev cryptoLoadCertificate:pem version:0x01 position:CERT_SLOT_DATA_ROOT rootPosition:CERT_SLOT_DATA_ROOT error:&error])
                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Root certificate loading failed with error: %@",error.localizedDescription]];
                
                file=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TACAT1.pem"];
                pem=[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:file] encoding:NSASCIIStringEncoding];
                if(![dtdev cryptoLoadCertificate:pem version:0x01 position:CERT_SLOT_DATA_INTERMEDIATE rootPosition:CERT_SLOT_DATA_ROOT error:&error])
                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Intermediate certificate loading failed with error: %@",error.localizedDescription]];
                
                file=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TACAT166257982465.pem"];
                pem=[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:file] encoding:NSASCIIStringEncoding];
                if(![dtdev cryptoLoadCertificate:pem version:0x01 position:CERT_SLOT_DATA_KEY rootPosition:CERT_SLOT_DATA_INTERMEDIATE error:&error])
                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Key certificate loading failed with error: %@",error.localizedDescription]];

                file=[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"param.pem"];
                pem=[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:file] encoding:NSASCIIStringEncoding];
                if(![dtdev cryptoLoadCertificate:pem version:0x01 position:CERT_SLOT_PARAMS rootPosition:CERT_SLOT_PARAMS error:&error])
                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Params certificate loading failed with error: %@",error.localizedDescription]];

                if(!error)
                    [self displayAlert:@"Success" message:@"Certificates loaded!"];
            }
            if(indexPath.row==2) {//set Encrypted T1 only
                if([dtdev taSetEncryptionModeForCard:TA_MODE_T1_ONLY forManual:TA_MODE_PAN_ONLY includeSentinels:false error:&error]) { //TA_MODE_T1T2_SEPARATE, TA_MODE_T1_ONLY, TA_MODE_T2_ONLY
                    [self displayAlert:@"Success" message:@"T1 Only Encryption Mode successfully set"];
                }
                else {
                    [self displayAlert:@"Error" message:@"T1 Only Encryption Mode not set"];
                }
            }
            if(indexPath.row==3) {//set Encrypted T2 only
                if([dtdev taSetEncryptionModeForCard:TA_MODE_T2_ONLY forManual:TA_MODE_PAN_ONLY includeSentinels:true error:&error]) { //TA_MODE_T1T2_SEPARATE, TA_MODE_T1_ONLY, TA_MODE_T2_ONLY
                    [self displayAlert:@"Success" message:@"T2 Only Encryption Mode successfully set"];
                }
                else {
                    [self displayAlert:@"Error" message:@"T2 Only Encryption Mode not set"];
                }
            }
            if(indexPath.row==4) {//set Encrypted T3 only
                if([dtdev taSetEncryptionModeForCard:TA_MODE_T1T2_SEPARATE forManual:TA_MODE_PAN_ONLY includeSentinels:true error:&error]) { //TA_MODE_T1T2_SEPARATE, TA_MODE_T1_ONLY, TA_MODE_T2_ONLY
                    [self displayAlert:@"Success" message:@"T1&T2 Encryption Mode successfully set"];
                }
                else {
                    [self displayAlert:@"Error" message:@"T1&T2 Encryption Mode not set"];
                }
            }
            if(indexPath.row==5) {//set Encrypted PAN only
                if([dtdev taSetEncryptionModeForCard:TA_MODE_PAN_ONLY forManual:TA_MODE_PAN_ONLY includeSentinels:true error:&error]) {
                    [self displayAlert:@"Success" message:@"PAN Encryption Mode successfully set"];
                }
                else {
                    [self displayAlert:@"Error" message:@"PAN Encryption Mode not set"];
                }
            }
            if(indexPath.row==6)
            {//set MID
                if([dtdev taSetMerchantID:[@"323650320993" dataUsingEncoding:NSASCIIStringEncoding] error:&error])
                {
                    [self displayAlert:@"Success" message:@"Merchant ID successfully set"];
                }else
                {
                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"taSetMerchantID failed: %@",error.localizedDescription]];
                }
            }
            if(indexPath.row==7)
            {//set bin ranges 1
                unsigned char params[] = {
                    0x85, 0xF4, 0x0E, 0x25, 0x46, 0x0C, 0xD2, 0x16, 0xFE, 0x8E, 0x83, 0x80,
                    0x40, 0x31, 0xFE, 0xE7, 0x89, 0x22, 0xC4, 0xCA, 0x6C, 0x09, 0x36, 0x82,
                    0x2E, 0xEB, 0x04, 0x3A, 0x11, 0x66, 0xE6, 0x93, 0x2C, 0xDE, 0xBB, 0x7E,
                    0xE8, 0xD2, 0xBB, 0xE5, 0xEF, 0x76, 0x59, 0xA7, 0xFD, 0xE1, 0x41, 0x34,
                    0x8E, 0x33, 0x3D, 0x0A, 0x2D, 0x0A, 0xB1, 0xA1, 0x91, 0x62, 0x80, 0x28,
                    0x3B, 0x46, 0xD6, 0x0F, 0xB9, 0x68, 0xC0, 0x65, 0xE7, 0x78, 0x4E, 0x1D,
                    0x70, 0x1F, 0x9E, 0x3D, 0xA9, 0xD7, 0xC9, 0xF7, 0x4E, 0x21, 0x6E, 0x7B,
                    0x49, 0x71, 0xD7, 0x64, 0x9D, 0x46, 0x0F, 0x58, 0x88, 0xA0, 0x5D, 0x89,
                    0x50, 0x03, 0xA3, 0x3A, 0xDE, 0xE4, 0x98, 0x75, 0xB4, 0xE9, 0x9B, 0x06,
                    0xC3, 0x05, 0x95, 0x82, 0x3B, 0xAD, 0x05, 0x8C, 0x26, 0xCF, 0x38, 0x1E,
                    0x81, 0xF3, 0x3E, 0xAC, 0xFE, 0x7D, 0x06, 0x4B, 0x08, 0xBB, 0xD6, 0x07,
                    0xBE, 0xC8, 0x01, 0x5A, 0x31, 0x72, 0x58, 0x49, 0x31, 0x4F, 0x86, 0xAD,
                    0x1D, 0xAD, 0xE9, 0x76, 0x27, 0x2A, 0x4B, 0xE4, 0x69, 0xF9, 0x65, 0xC5,
                    0xA7, 0xFF, 0x27, 0xD6, 0xF5, 0xBC, 0xA3, 0x7A, 0x0F, 0xAD, 0x01, 0xB1,
                    0xFA, 0x8F, 0x86, 0xCC, 0x66, 0xDB, 0x12, 0x6F, 0x4E, 0xC2, 0x67, 0xC7,
                    0x17, 0xE0, 0x76, 0x67, 0x19, 0x4B, 0x6E, 0xBB, 0xB8, 0xF0, 0xD8, 0x1E,
                    0x57, 0xEA, 0x67, 0x15, 0x39, 0x49, 0xDB, 0xE7, 0x7F, 0xD5, 0x66, 0x4C,
                    0x28, 0x74, 0xC3, 0x27, 0xD6, 0xE1, 0x80, 0x1A, 0x15, 0x63, 0x99, 0x6D,
                    0xB9, 0x05, 0xF3, 0x8D, 0x26, 0xB4, 0x2F, 0x89, 0x94, 0x25, 0x73, 0x73,
                    0xD6, 0x31, 0x9F, 0x51, 0xBB, 0x35, 0x78, 0xDA, 0x1A, 0x71, 0xE4, 0x4E,
                    0x87, 0x02, 0x96, 0x23, 0xCC, 0x23, 0x0A, 0x81, 0x3F, 0x75, 0xA6, 0xAB,
                    0x9E, 0x00, 0x14, 0x15,
                    //bin ranges
                    0xB1, 0x0E, 0xB5, 0x00, 0x00, 0x0A, 0x55, 0x00, 0x00, 0xEC, 0x43, 0x33, 0x26, 0xEF
                };

                
                if([dtdev taSetBINRanges:[NSData dataWithBytes:params length:sizeof(params)] error:&error])
                {
                    [self displayAlert:@"Success" message:@"BIN ranges successfully set"];
                }else
                {
                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"taSetBINRanges failed: %@",error.localizedDescription]];
                }
            }
            if(indexPath.row==8)
            {//clear bin ranges
                unsigned char params[] = {
                    //RSA block
                    0x4C, 0x9E, 0xB5, 0x8C, 0xEB, 0xB2, 0x9D, 0x25, 0x1F, 0xA0, 0xB5, 0x5F,
                    0xAC, 0xA1, 0x68, 0x28, 0x88, 0x97, 0x1F, 0xC1, 0x84, 0x59, 0x5B, 0xEB,
                    0x46, 0xAC, 0x97, 0xD1, 0x73, 0x14, 0xAA, 0xB9, 0xC2, 0x76, 0xE5, 0x01,
                    0x1E, 0xD8, 0x06, 0x64, 0x22, 0x78, 0x41, 0x4D, 0x4E, 0x6F, 0x6C, 0x0A,
                    0x2D, 0x2A, 0xCA, 0x81, 0x92, 0x61, 0xDB, 0xEE, 0x39, 0xC6, 0xED, 0x2A,
                    0xFB, 0x02, 0xF0, 0x66, 0xF9, 0x0A, 0xBD, 0x55, 0xD3, 0xD6, 0xC6, 0x80,
                    0x3C, 0x01, 0x65, 0x0A, 0x1B, 0xCC, 0x2D, 0x9E, 0x83, 0x88, 0xB0, 0xB7,
                    0x67, 0xE1, 0x6A, 0xA9, 0x81, 0x8C, 0x0C, 0xE0, 0x76, 0x18, 0x2F, 0xCB,
                    0x0C, 0x08, 0x95, 0x59, 0x70, 0xAF, 0x8D, 0xC4, 0x8E, 0xE4, 0x5A, 0xBD,
                    0xB6, 0x8A, 0x8C, 0xF0, 0xA4, 0xD3, 0x31, 0xAE, 0x65, 0x44, 0xFE, 0x02,
                    0xF9, 0x71, 0x9C, 0x64, 0x44, 0x69, 0xEF, 0x84, 0x9E, 0x11, 0x4C, 0xBD,
                    0x53, 0x5C, 0x46, 0x03, 0x85, 0x94, 0xBB, 0xC2, 0xF9, 0x9A, 0xCD, 0x56,
                    0x70, 0xDE, 0x5A, 0x30, 0xE6, 0x97, 0x86, 0x49, 0xA2, 0x04, 0x11, 0xDD,
                    0xB0, 0xAC, 0xC9, 0x56, 0x16, 0x5D, 0xC2, 0x3F, 0xBA, 0x3B, 0x16, 0xBF,
                    0xEE, 0x96, 0x99, 0xDC, 0xF3, 0xB2, 0x24, 0xCF, 0xBB, 0xEF, 0xBA, 0x38,
                    0x2E, 0x52, 0xAD, 0x0F, 0xE6, 0x53, 0xDC, 0xFB, 0xE3, 0x9C, 0x37, 0x50,
                    0xAF, 0xB8, 0x8B, 0x34, 0x5F, 0x7B, 0xC7, 0x08, 0x62, 0x0D, 0xCA, 0x69,
                    0x0E, 0xF3, 0x48, 0xC2, 0xD9, 0x05, 0xDE, 0x62, 0x90, 0xF9, 0x77, 0x6D,
                    0xF5, 0x5D, 0xD9, 0xE0, 0x6D, 0xBF, 0xCE, 0xFB, 0xD7, 0xAE, 0xB8, 0xE8,
                    0xEA, 0xEA, 0xB2, 0xBD, 0x64, 0xD6, 0x6F, 0x08, 0xC1, 0xDC, 0xCD, 0xF5,
                    0x55, 0xB5, 0xF9, 0xDC, 0x19, 0xC5, 0xD0, 0x5D, 0xD0, 0x26, 0xF6, 0x96,
                    0x2B, 0x00, 0xF5, 0xC2,
                    //bin ranges - empty
                    0xBE
                };
                
                
                if([dtdev taSetBINRanges:[NSData dataWithBytes:params length:sizeof(params)] error:&error])
                {
                    [self displayAlert:@"Success" message:@"BIN ranges successfully set"];
                }else
                {
                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"taSetBINRanges failed: %@",error.localizedDescription]];
                }
            }
            if(indexPath.row==9)
            {//set all cards to be returned in clear
                unsigned char params[] = {
                    0x5B, 0x5B, 0x06, 0x07, 0x93, 0xFD, 0x5F, 0xA1, 0x7F, 0xD2, 0x32, 0x76,
                    0xF6, 0xC2, 0xB6, 0xC6, 0x80, 0xFA, 0xAE, 0xEF, 0xBC, 0xD6, 0x9D, 0xE7,
                    0xEC, 0xF1, 0x28, 0xB7, 0x14, 0xE4, 0xD7, 0x0F, 0x1E, 0x60, 0x67, 0x22,
                    0x73, 0xD5, 0x9C, 0x46, 0x89, 0x35, 0xDD, 0xB2, 0xEF, 0xFD, 0x67, 0xB2,
                    0x5F, 0xE3, 0x18, 0x8A, 0x53, 0xDD, 0xA9, 0x43, 0x8B, 0x1A, 0x15, 0x4E,
                    0x89, 0x76, 0xAF, 0x52, 0xA6, 0x59, 0x2D, 0xC1, 0x65, 0x32, 0xBD, 0xFD,
                    0x6C, 0x66, 0x14, 0x88, 0xC7, 0x0A, 0x16, 0x30, 0x33, 0xFC, 0x01, 0x35,
                    0x37, 0x78, 0xEC, 0xE6, 0xC6, 0xD1, 0xAF, 0xA4, 0x74, 0x84, 0x6B, 0x6D,
                    0xB5, 0x8B, 0x6B, 0x24, 0x71, 0xFB, 0xDF, 0x5D, 0xDA, 0xB3, 0x2F, 0xE0,
                    0x9D, 0x75, 0xD4, 0x49, 0xAE, 0x26, 0x71, 0x61, 0x63, 0x3F, 0x47, 0x17,
                    0xEE, 0x02, 0xB3, 0xD4, 0x4B, 0xD2, 0xDC, 0xF3, 0x17, 0x03, 0xEC, 0x77,
                    0x9B, 0xDC, 0xBA, 0x31, 0x5D, 0x1B, 0x8A, 0xA8, 0x29, 0xB8, 0x4E, 0x53,
                    0x26, 0xFB, 0x39, 0x23, 0xAE, 0x69, 0x01, 0xF8, 0x48, 0xF2, 0x8A, 0x43,
                    0x4D, 0xF7, 0x33, 0x09, 0x69, 0x1C, 0x78, 0xEC, 0x0B, 0x60, 0x08, 0x3D,
                    0x6C, 0xA5, 0x6F, 0x76, 0x6A, 0x0D, 0x79, 0xF3, 0xAE, 0x36, 0xCC, 0xD5,
                    0x49, 0x28, 0x15, 0xC0, 0xDB, 0x51, 0xD1, 0x17, 0x54, 0xF7, 0xA0, 0xC7,
                    0xB7, 0x6D, 0xAC, 0x40, 0xE0, 0x7D, 0x6B, 0x01, 0x06, 0x75, 0xE3, 0x60,
                    0x5C, 0xA3, 0x55, 0x07, 0xEF, 0x45, 0x20, 0xB8, 0x23, 0xC1, 0xFE, 0x8D,
                    0x5D, 0xC3, 0x46, 0x86, 0xA1, 0x30, 0x03, 0xA2, 0xF0, 0xA7, 0x56, 0x77,
                    0x04, 0x26, 0x36, 0x8A, 0x70, 0xA6, 0x7F, 0x0C, 0xD8, 0xFF, 0x3D, 0x90,
                    0x4C, 0x76, 0x44, 0xF9, 0x28, 0xBD, 0x57, 0xD6, 0xBB, 0xA9, 0x4E, 0x56,
                    0xB9, 0x0F, 0x22, 0x3F,
                    //all cards in clear
                    0xB1, 0xA9, 0x99, 0x99, 0x9E
                };
                
                if([dtdev taSetBINRanges:[NSData dataWithBytes:params length:sizeof(params)] error:&error])
                {
                    [self displayAlert:@"Success" message:@"BIN ranges successfully set"];
                }else
                {
                    [self displayAlert:@"Error" message:[NSString stringWithFormat:@"taSetBINRanges failed: %@",error.localizedDescription]];
                }
            }

            break;
            
        case SEC_MISC:
            if(indexPath.row==0)
            {//EXTRS test
                if([dtdev getSupportedFeature:FEAT_EXTERNAL_SERIAL_PORT error:nil]==FEAT_SUPPORTED)
                {
                    bool r;
                    r=[dtdev extOpenSerialPort:1 baudRate:9600 parity:PARITY_NONE dataBits:DATABITS_8 stopBits:STOPBITS_1 flowControl:FLOW_NONE error:&error];
                    
                    NSMutableData *toSend=[NSMutableData data];
                    for(int i=0;i<255;i++)
                    {
                        uint8_t b=0x30+i%10;
                        [toSend appendBytes:&b length:1];
                    }
                    if(r)
                    {
                        r=[dtdev extWriteSerialPort:1 data:toSend error:&error];
                        if(r)
                        {
                            NSData *rcv=[dtdev extReadSerialPort:1 length:(int)toSend.length timeout:1 error:&error];
                            if(rcv && rcv.length==toSend.length && [rcv isEqualToData:toSend])
                            {
                                NSLog(@"R(%d): %@",(int)rcv.length,rcv);
                                r=true;
                            }else
                            {
                                [self displayAlert:@"SerErr Read" message:[NSString stringWithFormat:@"Received bytes: %d",rcv?(int)rcv.length:0]];
                                r=false;
                            }
                        }else
                        {
                            [self displayAlert:@"SerErr Write" message:error.localizedDescription];
                            r=false;
                        }
                        
                        [dtdev extCloseSerialPort:1 error:&error];
                    }
                    if(r)
                        [self displayAlert:@"Success" message:@"Test complete"];
                }else
                    [self displayAlert:@"Failed" message:@"External RS unsupported"];
            }
            break;
	}
}

-(void)testVoltage
{
    NSError *error;
    
    
    if(![dtdev voltageGenerateNewKey:&error])
        [self displayAlert:@"Voltage error" message:[NSString stringWithFormat:@"voltageGenerateNewKey failed: %@",error.localizedDescription]];
    
    
}

-(UITextField *)addTextFieldToCell:(UITableViewCell *)cell width:(int)width
{
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, width, 21)];
    textField.placeholder = @"";
    textField.delegate = self;
    cell.accessoryView = textField;
    cell.accessoryType=UITableViewCellAccessoryNone;
    
    return textField;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SettingsCell"];
	
	switch ([indexPath indexAtPosition:0])
	{
		case SEC_GENERAL:
            if(settings_values[indexPath.row])
                cell.accessoryType=UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType=UITableViewCellAccessoryNone;
            [cell.textLabel setText:NSLocalizedString(settings[indexPath.row],nil)];
			break;
            
        case SEC_CHARGING:
        {
            int selected=0;
            if(chargeCurrent<=500)
                selected=0;
            else
            {
                if(chargeCurrent<=1000)
                    selected=1;
                else
                {
                    if(chargeCurrent<=2100)
                        selected=2;
                    else
                        selected=3;
                }
            }
            if(indexPath.row==selected)
                cell.accessoryType=UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType=UITableViewCellAccessoryNone;
            [cell.textLabel setText:NSLocalizedString(charge_currents[indexPath.row],nil)];
            if(indexPath.row==1)
                cell.detailTextLabel.text=@"Additional information in alert message";
            if(indexPath.row>=2)
                cell.detailTextLabel.text=@"Kiosk mode only";
            break;
        }
            
		case SEC_BARCODE_MODE:
			if(scanMode==indexPath.row)
				cell.accessoryType=UITableViewCellAccessoryCheckmark;
			else
				cell.accessoryType=UITableViewCellAccessoryNone;
			[cell.textLabel setText:NSLocalizedString(scan_modes[indexPath.row],nil)];
			break;
            
		case SEC_LEDS:
            cell.accessoryType=UITableViewCellAccessoryNone;
            [cell.textLabel setText:NSLocalizedString(led_names[indexPath.row],nil)];
            cell.textLabel.textColor=led_colors[indexPath.row];
			break;
            
        case SEC_APPLE_BT:
            cell.accessoryType=UITableViewCellAccessoryNone;
            [cell.textLabel setText:NSLocalizedString(@"Show BT Accessory Picker",nil)];
            break;
            
		case SEC_BT_CLIENT:
			if(indexPath.row==0)
            {
                [cell.textLabel setText:NSLocalizedString(@"Discover devices",nil)];
            }else
            {
                [cell.textLabel setText:[btDevices objectAtIndex:(indexPath.row-1)*2+1]];
                [cell.detailTextLabel setText:[btDevices objectAtIndex:(indexPath.row-1)*2]];
                
                NSLog(@"dtdev.btConnectedDevices: %@",dtdev.btConnectedDevices);

                if([dtdev.btConnectedDevices containsObject:[btDevices objectAtIndex:(indexPath.row-1)*2]])
                    cell.accessoryType=UITableViewCellAccessoryCheckmark;
                else
                    cell.accessoryType=UITableViewCellAccessoryNone;
            }
			break;

        case SEC_BT_SERVER:
			if(indexPath.row==0)
            {
                if(btListening)
                {
                    [cell.textLabel setText:NSLocalizedString(@"Stop Server",nil)];
                    cell.accessoryType=UITableViewCellAccessoryCheckmark;
                }else
                {
                    [cell.textLabel setText:NSLocalizedString(@"Start Server",nil)];
                    cell.accessoryType=UITableViewCellAccessoryNone;
                }
            }else
            {
                NSLog(@"dtdev.btConnectedDevices: %@",dtdev.btConnectedDevices);
                [cell.textLabel setText:[btConnectedDevices objectAtIndex:indexPath.row-1]];
                [cell.detailTextLabel setText:@"Connected"];
                
                cell.accessoryType=UITableViewCellAccessoryCheckmark;
            }
			break;

#ifdef BTLE_USED
		case SEC_BTLE:
			if(indexPath.row==0)
            {
                [cell.textLabel setText:NSLocalizedString(@"Discover devices",nil)];
            }else
            {
                CBPeripheral *device=[btleDevices objectAtIndex:indexPath.row-1];
                cell.textLabel.text=device.name;
//                cell.detailTextLabel.text=[NSString stringWithFormat:@"%@",device.identifier];
                
                NSLog(@"dtdev.btleConnectedDevices: %@",dtdev.btleConnectedDevices);
                
                if([dtdev.btleConnectedDevices containsObject:[btleDevices objectAtIndex:indexPath.row-1]])
                    cell.accessoryType=UITableViewCellAccessoryCheckmark;
                else
                    cell.accessoryType=UITableViewCellAccessoryNone;
            }
			break;
#endif
            
		case SEC_TCP_DEVICES:
			if(indexPath.row==0)
            {
                if(dtdev.tcpConnectedDevices.count>0)
                    [cell.textLabel setText:NSLocalizedString(@"Disconnect from device",nil)];
                else
                    [cell.textLabel setText:NSLocalizedString(@"Connect to device",nil)];
            }else
            {
                tfTCPAddress=[self addTextFieldToCell:cell width:200];
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                tfTCPAddress.text = [prefs objectForKey:@"tcpAddress"];
                if(tfTCPAddress.text.length==0)
                    tfTCPAddress.text=@"192.168.11.110";
                
                if(dtdev.tcpConnectedDevices.count>0)
                    cell.accessoryType=UITableViewCellAccessoryCheckmark;
                else
                    cell.accessoryType=UITableViewCellAccessoryNone;
            }
			break;
            
		case SEC_FIRMWARE_UPDATE:
            switch (indexPath.row)
            {
                case TARGET_DEVICE:
                    [[cell textLabel] setText:NSLocalizedString(@"Update device firmware",nil)];
                    break;
                case TARGET_BLUETOOTH:
                    [[cell textLabel] setText:NSLocalizedString(@"Update bluetooth firmware",nil)];
                    break;
                case TARGET_BARCODE:
                    [[cell textLabel] setText:NSLocalizedString(@"Update barcode firmware",nil)];
                    break;
            }
			break;
            
		case SEC_VOLTAGE:
            cell.accessoryType=UITableViewCellAccessoryNone;
            [cell.textLabel setText:voltage_settings[indexPath.row]];
			break;

        case SEC_TRANSARMOR:
            cell.accessoryType=UITableViewCellAccessoryNone;
            [cell.textLabel setText:ta_settings[indexPath.row]];
            break;
            
		case SEC_MISC:
            cell.accessoryType=UITableViewCellAccessoryNone;
            [cell.textLabel setText:NSLocalizedString(misc_operations[indexPath.row],nil)];
			break;
	}
	return cell;	
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
	btDevices=[[prefs arrayForKey:@"bluetoothDevices"] mutableCopy];
    if(!btDevices)
        btDevices=[[NSMutableArray alloc] init];
    [settingsTable reloadData];
    
	//update display according to current connection state
	[self connectionState:dtdev.connstate];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
	dtdev=[DTDevices sharedDevice];
	[dtdev addDelegate:self];
    
    led_colors[0]=[UIColor greenColor];
    led_colors[1]=[UIColor redColor];
    led_colors[2]=[UIColor orangeColor];
    led_colors[3]=[UIColor blueColor];
}

@end

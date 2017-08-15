#import "ScannerViewController.h"
#import "NSDataCrypto.h"
#import "dukpt.h"
#import "AVFoundation/AVFoundation.h"
#import "MercuryHelper.h"
#import <CommonCrypto/CommonDigest.h>

//#define LOG_FILE

#define IMGON @"connected.png"
#define IMGOFF @"disconnected.png"

@implementation ScannerViewController

@synthesize suspendDisplayInfo;

static ScannerViewController *scannerViewController;

bool scanActive=false;

-(NSString *)getLogFile
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"log.txt"];
}

+(void)debug:(NSString *)text
{
    [scannerViewController debug:text];
}

-(void)debug:(NSString *)text
{
	NSDateFormatter *dateFormat=[[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"HH:mm:ss:SSS"];
	NSString *timeString = [dateFormat stringFromDate:[NSDate date]];
	
	if([debug length]>10000)
		[debug setString:@""];
	[debug appendFormat:@"%@-%@\n",timeString,text];

	[debugText setText:debug];
#ifdef LOG_FILE
	[debug writeToFile:[self getLogFile]  atomically:YES];
#endif
}

-(void)debugString:(NSString *)text
{
    [self debug:text];
}

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}


-(NSString *)updateBattery
{
    NSMutableString *s=[NSMutableString string];
    
    DTBatteryInfo *info=[dtdev getBatteryInfo:nil];

	if(info)
    {
        [batteryButton setTitle:[NSString stringWithFormat:@"%d%%,%.1fv(%d)",info.capacity,info.voltage,info.charging] forState:UIControlStateNormal];
        [batteryButton setHidden:FALSE];
        if(info.capacity<10)
            [batteryButton setBackgroundImage:[UIImage imageNamed:@"0.png"] forState:UIControlStateNormal];
        else if(info.capacity<40)
            [batteryButton setBackgroundImage:[UIImage imageNamed:@"25.png"] forState:UIControlStateNormal];
        else if(info.capacity<60)
            [batteryButton setBackgroundImage:[UIImage imageNamed:@"50.png"] forState:UIControlStateNormal];
        else if(info.capacity<80)
            [batteryButton setBackgroundImage:[UIImage imageNamed:@"75.png"] forState:UIControlStateNormal];
        else
            [batteryButton setBackgroundImage:[UIImage imageNamed:@"100.png"] forState:UIControlStateNormal];
        
        [s appendFormat:@"Voltage: %.3fv\n",info.voltage];
        [s appendFormat:@"Capacity: %d%%\n",info.capacity];
        [s appendFormat:@"Maximum capacity: %dmA/h\n",info.maximumCapacity];
        if(info.health>0)
            [s appendFormat:@"Health: %d%%\n",info.health];
        [s appendFormat:@"Charging: %@\n",info.charging?@"YES":@"NO"];
        if(info.extendedInfo!=nil)
            [s appendFormat:@"Extended info: %@\n",info.extendedInfo];
    }else
    {
        [batteryButton setTitle:@"Busy" forState:UIControlStateNormal];
        [batteryButton setBackgroundImage:[UIImage imageNamed:@"0.png"] forState:UIControlStateNormal];
        [batteryButton setHidden:FALSE];
        [s appendFormat:@"Unable to get battery info!"];
    }

    return s;
}


AVAudioPlayer *audioPlayer;

+(void)playSound:(NSString *)fileName volume:(float)volume
{
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath],fileName]];
    
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    audioPlayer.volume=volume;
    audioPlayer.numberOfLoops = 0;
    
    [audioPlayer play];
}

-(IBAction)scanDown:(id)sender;
{
    NSError *error=nil;
    
	[statusImage setImage:[UIImage imageNamed:@"scanning.png"]];
	[displayText setText:@""];
	//refresh the screen
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];

//    uint8_t data[200];
//    for(int i=0;i<sizeof(data);i++)
//        data[i]=i;
//    [dtdev.btOutputStream write:data maxLength:sizeof(data)];
//
//    [dtdev ppadEnableStatusLine:false error:nil];
//    int tip=0;
//    int choice = [dtdev uiDisplayMenu:@"Select Tip Amount" choices:@[@"10%",@"25%",@"Other"] font:FONT_6X8 timeout:10 error:&error];
//    switch (choice) {
//        case -1: //error
//            [self displayAlert:@"Error" message:@"Choice failed"];
//            break;
//
//        case 0: //10%
//            tip=10;
//            break;
//
//        case 1: //25%
//            tip=25;
//            break;
//
//        case 2: //custom
//        {
//            NSString *custom=[dtdev uiDisplayDataPromptWithID:PROMPT_ENTER_BIRTH_DATE language:0 maxLength:16 initialValue:@"" font:FONT_8X16 timeout:10 error:&error];
//            if(!custom)
//            {
//                [self displayAlert:@"Error" message:@"Enter custom failed"];
//                tip=0;
//            }else
//            {
//                tip=custom.intValue;
//            }
//
//            break;
//        }
//    }
//    if(tip!=0)
//        [self displayAlert:@"Success" message:[NSString stringWithFormat:@"Tip: %d%%",tip]];
//    [dtdev ppadEnableStatusLine:true error:nil];

    int scanMode;
    
    if([dtdev barcodeGetScanMode:&scanMode error:&error] && scanMode==MODE_MOTION_DETECT)
    {
        if(scanActive)
        {
            scanActive=false;
            SHOWERR([dtdev barcodeStopScan:&error]);
        }else {
            scanActive=true;
            SHOWERR([dtdev barcodeStartScan:&error]);
        }
    }else
        SHOWERR([dtdev barcodeStartScan:&error]);
}

-(IBAction)scanUp:(id)sender;
{
    NSError *error;
    
	[statusImage setImage:[UIImage imageNamed:IMGON]];
    int scanMode;
    
//    if([dtdev barcodeGetScanMode:&scanMode error:&error] && scanMode!=MODE_MOTION_DETECT)
//        SHOWERR([dtdev barcodeStopScan:&error]);

    SHOWERR([dtdev barcodeStopScan:&error]);
}

-(IBAction)onBattery:(id)sender
{
    NSString *info=[self updateBattery];
    if(info)
        displayText.text=info;
//    NSTimeInterval time;
//    if([dtdev getTimeRemainingToPowerOff:&time error:nil])
//        displayText.text=[NSString stringWithFormat:@"Time to sleep: %.02f",time];
}

-(IBAction)onSliderChange:(id)sender;
{
    debugText.text=[NSString stringWithFormat:@"Value changed to: %d",(int)slider.value];
}


-(IBAction)onTest:(id)sender;
{
    if(test.selectedSegmentIndex==0)
    {
        NSError *error;
        SHOWERR([dtdev barcodeNewlandSetInitString:@"NLS0312000;" error:&error]); //disable scope scanning
//        [dtdev addDelegate:self];
//        [dtdev connect];
    }
    if(test.selectedSegmentIndex==1)
    {
        NSError *error;
        SHOWERR([dtdev barcodeNewlandSetInitString:@"NLS0312010;" error:&error]); //disable scope scanning
//        [dtdev disconnect];
//        [dtdev removeDelegate:self];
    }
    if(test.selectedSegmentIndex==2)
    {
        NSError *error;
        SHOWERR([dtdev barcodeNewlandSetInitString:@"NLS0312020;" error:&error]); //disable scope scanning
        //        [dtdev disconnect];
        //        [dtdev removeDelegate:self];
    }
    if(test.selectedSegmentIndex==3)
    {
        NSError *error;
        SHOWERR([dtdev barcodeNewlandSetInitString:@"NLS0312030;" error:&error]); //disable scope scanning
        //        [dtdev disconnect];
        //        [dtdev removeDelegate:self];
    }
}

static NSTimer *barCheckTimer=nil;
static NSTimer *battCheckTimer=nil;

static NSString *initString=nil;
static NSString *emsrString=nil;
-(NSString *)buildInfoString:(bool)force
{
    if(!force && initString!=nil)
        return initString;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterLongStyle];
    
    initString=[NSString stringWithFormat:@"SDK: ver %d.%d (%@)\n",dtdev.sdkVersion/100,dtdev.sdkVersion%100,[dateFormat stringFromDate:dtdev.sdkBuildDate]];
    if(dtdev.connstate==CONN_CONNECTED)
    {
        NSArray *connected=[dtdev getConnectedDevicesInfo:nil];
        for (DTDeviceInfo *info in connected)
        {
            initString = [initString stringByAppendingFormat:@"\n%@ %@ connected\nFirmware revision: %@\nHardware revision: %@\nSerial number: %@",info.name,info.model,info.firmwareRevision,info.hardwareRevision,info.serialNumber];
        }
        NSTimeInterval time;
        if([dtdev getTimeRemainingToPowerOff:&time error:nil])
            initString = [initString stringByAppendingFormat:@"\nAutoOff time: %.02f",time];
        else
            initString = [initString stringByAppendingFormat:@"\nAutoOff time: NA"];

        if([dtdev sysIsDevelopmentUnit])
            initString = [initString stringByAppendingFormat:@"\nUnit type: DEVELOPMENT"];

        if(!emsrString && [dtdev getSupportedFeature:FEAT_MSR error:nil]&MSR_ENCRYPTED)
        {
            EMSRDeviceInfo *emsrInfo=[dtdev emsrGetDeviceInfo:nil];
            if(emsrInfo)
            {
                BOOL tampered;
                [dtdev emsrIsTampered:&tampered error:nil];
                emsrString=[NSString stringWithFormat:@"\n\nEMSR FW: %@, Tampered: %@",emsrInfo.firmwareVersionString,tampered?@"TRUE":@"FALSE"];
                EMSRKeysInfo *keys=[dtdev emsrGetKeysInfo:nil];
                if(keys)
                {
                    for (EMSRKey *key in keys.keys)
                    {
                        if(key.keyVersion)
                            emsrString=[emsrString stringByAppendingFormat:@"- %@ ver: %d\n",key.keyName,key.keyVersion];
                    }
                }
            }else
                emsrString=[initString stringByAppendingString:@"\nEMSR Not Responding!"];
            
            initString=[initString stringByAppendingString:emsrString];
        }else
            emsrString=nil;

//        [dtdev uiEnableCancelButton:false error:nil];
//        [dtdev uiEnableCancelButton:true error:nil];
    }else
    {
        initString=[initString stringByAppendingString:@"Device not connected!"];
        emsrString=nil;
    }
    return initString;
}

-(void)barCheckTimerFunc
{
    BOOL ready=false;
    if(![dtdev barcodeEngineCheckReady:&ready error:nil])
    {
        scanButton.enabled=true;
        scanButton.titleLabel.text=@"SCAN BARCODE";
        [barCheckTimer invalidate];
        barCheckTimer=nil;
    }else
    {
        if(ready)
        {
            scanButton.enabled=true;
            scanButton.titleLabel.text=@"SCAN BARCODE";
            [barCheckTimer invalidate];
            barCheckTimer=nil;
        }else
        {
            scanButton.enabled=false;
            scanButton.titleLabel.text=@"INITIALIZING...";
        }
    }
}

-(void)battCheckTimerFunc
{
    displayText.text = [self updateBattery];
}

-(void)updatePinpadDisplay
{
    [dtdev ppadEnableStatusLine:true error:nil];
    
    if(![dtdev uiStopAnimation:ANIM_ALL error:nil])
        return;
    if(![dtdev uiFillRectangle:0 topLeftY:0 width:0 height:0 color:[UIColor whiteColor] error:nil])
        return;

    if(dtdev.uiDisplayHeight<64)
    {
        [dtdev uiDrawText:@"Use Smart, Magnetic\nor NFC card" topLeftX:0 topLeftY:0 font:FONT_6X8 error:nil];
    }
    if(dtdev.uiDisplayHeight==64)
    {
        [dtdev uiDrawText:@"\x01Use Smart,\nMagnetic or\nNFC card" topLeftX:25 topLeftY:3 font:FONT_6X8 error:nil];
        //magnetic card
        [dtdev uiStartAnimation:5 topLeftX:99 topLeftY:0 animated:TRUE error:nil];
        //smartcard
        [dtdev uiStartAnimation:4 topLeftX:0 topLeftY:0 animated:TRUE error:nil];
        [dtdev uiDisplayImage:38 topLeftY:30 image:[UIImage imageNamed:@"paypass_logo.bmp"] error:nil];
    }
    if(dtdev.uiDisplayHeight>64)
    {
        [dtdev uiShowInitScreen:nil];
        [dtdev uiDrawText:@"DEVICE CONNECTED" topLeftX:30 topLeftY:dtdev.uiDisplayHeight-80 font:FONT_8X16 error:nil];
    }
}


-(void)connectionState:(int)state
{
    displayText.text=[self buildInfoString:true];
    
    if(state==CONN_CONNECTED)
    {
        [debug deleteCharactersInRange:NSMakeRange(0,debug.length)];
        debugText.text=@"";
        scanActive=false;
        [statusImage setImage:[UIImage imageNamed:IMGON]];
        [scanButton setHidden:FALSE];
        if([dtdev getSupportedFeature:FEAT_BLUETOOTH error:nil]!=FEAT_UNSUPPORTED)
            [printButton setHidden:FALSE];
        
        [self updateBattery];
        
        //update pinpad display
        [self updatePinpadDisplay];
        
        if(!barCheckTimer)
            barCheckTimer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(barCheckTimerFunc) userInfo:nil repeats:true];
        if(!battCheckTimer)
            battCheckTimer=[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(battCheckTimerFunc) userInfo:nil repeats:true];
    }else
    {
        [statusImage setImage:[UIImage imageNamed:IMGOFF]];
        [batteryButton setHidden:TRUE];
        [scanButton setHidden:TRUE];
        [printButton setHidden:TRUE];
        [barCheckTimer invalidate];
        barCheckTimer=nil;
        [battCheckTimer invalidate];
        battCheckTimer=nil;
    }
}

-(void)deviceButtonPressed:(int)which {
	displayText.text = [NSString stringWithFormat:@"Button pressed: %d",which];
    [status setString:@""];
	//[self cleanPrintInfo];

    if(which==1)
    {//battery on imed, update it
        [status setString:[self updateBattery]];
        displayText.text=status;
    }
    if(which==0) //scanner usually
    {
        [displayText setText:@""];
        [statusImage setImage:[UIImage imageNamed:@"scanning.png"]];
    }
}

-(void)deviceButtonReleased:(int)which {
	[statusImage setImage:[UIImage imageNamed:IMGON]];

    if(status.length==0)
    {
        displayText.text = [NSString stringWithFormat:@"Button released: %d",which];
    }
}

-(void)barcodeData:(NSString *)barcode isotype:(NSString *)isotype
{
    mainTabBarController.selectedViewController=self;
    
	[status setString:@""];
	[status appendFormat:@"ISO Type: %@\n",isotype];
	[status appendFormat:@"Barcode: %@",barcode];
    
	[displayText setText:status];

//	[self updateBattery];
}

//-(void)barcodeNSData:(NSData *)barcode type:(int)type {
//    mainTabBarController.selectedViewController=self;
//
//	[status setString:@""];
//    
//	[status appendFormat:@"Type: %d\n",type];
//	[status appendFormat:@"Type text: %@\n",[dtdev barcodeType2Text:type]];
//	[status appendFormat:@"Barcode: %@",[self toHexString:(uint8_t *)barcode.bytes length:barcode.length space:true]];
//	[displayText setText:status];
//    
//	[self updateBattery];
//}

-(void)barcodeData:(NSString *)barcode type:(int)type
{
    mainTabBarController.selectedViewController=self;
    
	[status setString:@""];

	[status appendFormat:@"Type: %d\n",type];
	[status appendFormat:@"Type text: %@\n",[dtdev barcodeType2Text:type]];
	[status appendFormat:@"Barcode(%d): %@",(int)barcode.length,barcode];
	[displayText setText:status];
    
    if([dtdev getSupportedFeature:FEAT_PRINTING error:nil]!=FEAT_UNSUPPORTED)
    {
        [dtdev prnPrintText:[NSString stringWithFormat:@"{+B}Type: {-B}%d\n",type] error:nil];
        [dtdev prnPrintText:[NSString stringWithFormat:@"{+B}Type text: {-B}%@\n",[dtdev barcodeType2Text:type]] error:nil];
        [dtdev prnPrintText:[NSString stringWithFormat:@"{+B}Barcode(%d): {-B}%@",(int)barcode.length,barcode] error:nil];
        [dtdev prnFeedPaper:0 error:nil];
    }
    
    if([dtdev getSupportedFeature:FEAT_VIBRATION error:nil]==FEAT_SUPPORTED)
    {//Linea Medical - play the beep through the speaker and optionally - vibrate
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"vibrateOnScan"])
                [dtdev uiEnableVibrationForTime:0.5 error:nil];
            //play the sound using external speaker
//            [dtdev uiEnableSpeaker:true error:nil];
//            [self playSound:@"beep.wav" volume:1.0];
//            [NSThread sleepForTimeInterval:0.5];
//            [dtdev uiEnableSpeaker:false error:nil];
        });
    }

    //if printer mac address, use it
    if(type==BAR_CODE128 && barcode.length==12 && ([barcode hasPrefix:@"00019"] || [barcode hasPrefix:@"68AAD"]))
    {
        [[NSUserDefaults standardUserDefaults] setValue:barcode forKey:@"selectedPrinterAddress"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }


}

-(void)iHUBDeviceConnected:(iHUBDevice *)device;
{
    [displayText setText:[NSString stringWithFormat:@"iHUBDeviceConnected\nPort: %d\nConfig: %@",device.portIndex,device.portConfig]];
    device.delegate=self;
}

-(void)iHUBDeviceDisconnected:(iHUBDevice *)device;
{
    [displayText setText:[NSString stringWithFormat:@"iHUBDeviceDisconnected\nPort: %d\nConfig: %@",device.portIndex,device.portConfig]];
}

-(void)iHUBDataReceivedForDevice:(iHUBDevice *)device data:(NSData *)data;
{
}

-(void)smartCardInserted:(SC_SLOTS)slot {
//    mainTabBarController.selectedViewController=self;
    
    if(!([dtdev getSupportedFeature:FEAT_EMVL2_KERNEL error:nil]&EMV_KERNEL_UNIVERSAL))
    {
        NSData *atr=[dtdev scCardPowerOn:slot error:nil];
        if(atr)
        {
            [displayText setText:[NSString stringWithFormat:@"SmartCard Inserted\nATR: %@",[self toHexString:(void *)[atr bytes] length:[atr length] space:true]]];
            //also, if we have pinpad connected, ask for pin entry
//            if([dtdev getSupportedFeature:FEAT_EMVL2_KERNEL error:nil]|EMV_KERNEL_NECOMPLUS)
//            {
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"EMV Transaction" message:@"SmartCard Detected, do you want to perform an EMV transaction?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
//                [alert show];
//            }
            
        }else
        {
            //        [displayText setText:@"SmartCart reset failed!"];
        }
    }
}

-(void)smartCardRemoved:(SC_SLOTS)slot {
    [displayText setText:@"SmartCard Removed"];
}

-(void)magneticCardReadFailed:(int)source reason:(int)reason
{
    mainTabBarController.selectedViewController=self;

    NSString *reasonMessage=@"Unknown";
    if(reason==REASON_FAILED)
        reasonMessage=@"Operation failed";
    if(reason==REASON_CANCELED)
        reasonMessage=@"User cancelled";
    if(reason==REASON_TIMEOUT)
        reasonMessage=@"Transaction timed out";

    [status setString:[NSString stringWithFormat:@"Card read failed with reason: %@",reasonMessage]];
}

-(void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3 source:(int)source {
    mainTabBarController.selectedViewController=self;

	[status setString:@""];
	
    [status appendFormat:@"Magnetic: %d, contactless: %d\n",nMagnetic,nContactless];
    
    switch (source) {
        case CARD_TYPE_MAGNETIC:
            [status appendString:@"Card type: magnetic\n"];
            break;
        case CARD_TYPE_SMARTCARD:
            [status appendString:@"Card type: smartcard\n"];
            break;
        case CARD_TYPE_CONTACTLESS:
            [status appendString:@"Card type: contactless\n"];
            break;
        case CARD_TYPE_MANUAL:
            [status appendString:@"Card type: manual entry\n"];
            break;
    }
    
	NSDictionary *card=[dtdev msProcessFinancialCard:track1 track2:track2];
	if(card)
	{
		if([card valueForKey:@"cardholderName"])
			[status appendFormat:@"Name: %@\n",[card valueForKey:@"cardholderName"]];
		if([card valueForKey:@"accountNumber"])
        {
			//[status appendFormat:@"Number: %@\n",[card valueForKey:@"accountNumber"]];
            //mask the pan, instead of displaying in clear
            //get the first 4 and last 4, fill the rest with *
            NSMutableString *maskedPan=[NSMutableString stringWithString:[card valueForKey:@"accountNumber"]];
            for(int i=4;i<(maskedPan.length-4);i++)
                [maskedPan replaceCharactersInRange:NSMakeRange(i,1) withString:@"*"];
            [status appendFormat:@"Number: %@\n",maskedPan];
        }
        
		if([card valueForKey:@"expirationMonth"])
			[status appendFormat:@"Expiration: %@/%@\n",[card valueForKey:@"expirationMonth"],[card valueForKey:@"expirationYear"]];
        
        if([card valueForKey:@"serviceCode"])
            [status appendFormat:@"Service Code: %@\n",[card valueForKey:@"serviceCode"]];
		[status appendString:@"\n"];
	}
	
	if(track1!=NULL)
		[status appendFormat:@"Track1: %@\n",track1];
	if(track2!=NULL)
		[status appendFormat:@"Track2: %@\n",track2];
	if(track3!=NULL)
		[status appendFormat:@"Track3: %@\n",track3];
    
    [displayText setText:status];
    NSLog(@"%@",status);
	
	int sound[]={2730,150,0,30,2730,150};
	[dtdev playSound:100 beepData:sound length:sizeof(sound) error:nil];
	[self updateBattery];
    
    //also, if we have pinpad connected, ask for pin entry
//    if(card && [dtdev getSupportedFeature:FEAT_PIN_ENTRY error:nil]==FEAT_SUPPORTED)
//    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"PIN Entry" message:@"Do you want to enter PIN?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
//        [alert show];
//    }
}

-(NSString *)toHexString:(const void *)data length:(size_t)length space:(bool)space
{
	const char HEX[]="0123456789ABCDEF";
	char s[2000];
	
	int len=0;
	for(int i=0;i<length;i++)
	{
		s[len++]=HEX[((uint8_t *)data)[i]>>4];
		s[len++]=HEX[((uint8_t *)data)[i]&0x0f];
        if(space)
            s[len++]=' ';
	}
	s[len]=0;
	return [NSString stringWithCString:s encoding:NSASCIIStringEncoding];
}

-(void)magneticCardRawData:(NSData *)tracks {
    mainTabBarController.selectedViewController=self;
    
    //NSLog(@"raw data: %@",[self toHexString:(void *)[tracks bytes] length:[tracks length]]);
	[status setString:[self toHexString:(void *)[tracks bytes] length:[tracks length] space:true]];
	[displayText setText:status];
    
	int sound[]={2700,150,5400,150};
	[dtdev playSound:100 beepData:sound length:sizeof(sound) error:nil];
	[self updateBattery];
}

-(uint16_t)crc16:(const uint8_t *)data length:(int)length crc16:(uint16_t)crc16
{
	if(length==0) return 0;
	int i=0;
	while(length--)
	{
		crc16=(uint8_t)(crc16>>8)|(crc16<<8);
		crc16^=*data++;
		crc16^=(uint8_t)(crc16&0xff)>>4;
		crc16^=(crc16<<8)<<4;
		crc16^=((crc16&0xff)<<4)<<1;
		i++;
	}
	return crc16;
}

-(void)magneticJISCardData:(NSString *)data {
    [status setString:@""];
    [status appendFormat:@"JIS card data:\n\"%@\"",data];

	int sound[]={2730,150,0,30,2730,150};
	[dtdev playSound:100 beepData:sound length:sizeof(sound) error:nil];
	[self updateBattery];
    displayText.text=status;
}

//demo by sending encrypted data to tgate servers for processing
//#define POST_TGATE
//demo by sending encrypted data to mercury servers for processing
//#define POST_MERCURY
//demo by sending encrypted data to authorize.net servers for processing
//#define POST_AUTHORIZENET

-(void)httpPost:(NSString *)address data:(NSString *)data
{
    [progressViewController viewWillAppear:FALSE];
	[self.view addSubview:progressViewController.view];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	
    NSURL *url=[NSURL URLWithString:address];
    NSData *postData=[data dataUsingEncoding:NSASCIIStringEncoding];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
//    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    NSError *error;
    NSURLResponse *response;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	[progressViewController.view removeFromSuperview];
    if(urlData)
    {
        NSLog(@"HTTP POST completed: %@",[[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding]);
        [self displayAlert:@"HTTP response" message:[[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding]];
    }else {
        NSLog(@"HTTP POST failed with error: %@",[error localizedDescription]);
        [self displayAlert:@"HTTP" message:[NSString stringWithFormat:@"Connection failed with error: %@",error.localizedDescription]];
    }
}

#ifdef POST_TGATE
-(void)tgatePost:(NSString *)function data:(NSString *)data
{
    [self httpPost:[NSString stringWithFormat:@"https://gatewaystage.itstgate.com/SmartPayments/transact3.asmx/%@",function] data:data];
}
#endif
#ifdef POST_MERCURY
-(void) transactionDidFailWithError:(NSError *)error {
    [self displayAlert:@"Mercury error!" message:error.localizedDescription];
}

-(void) transactionDidFinish:(NSDictionary *)result {
    NSMutableString *message = [NSMutableString new];
    
    for (NSString *key in [result allKeys])
    {
        [message appendFormat:@"%@: %@;\n", key, [result objectForKey:key]];
    }
    
    [self displayAlert:@"Mercury complete!" message:message];
}
#endif

extern const uint8_t DUKPT_BDK[16];

-(BOOL)magneticCardPPADDUKPT:(NSData *)data source:(int)source
{
    const uint8_t *bytes=(uint8_t *)[data bytes];
    NSLog(@"Packet: %@",[self toHexString:bytes length:data.length space:true]);
    
    //calculate the key
    //get the ksn
    NSData *ksn=[data subdataWithRange:NSMakeRange(data.length-10, 10)];
    
    //try decrypting the data
    //calculate the IPEK based on the BDK and serial number
    //insert your own BDK here and calculate the IPEK, for the demo we are using predefined BDK
    uint8_t ipek[16]; //the device specific ipek, will be derived from the BDK
    //derive ipek from bdk
    NSLog(@"DUKPT BDK: %@",[self toHexString:DUKPT_BDK length:sizeof(DUKPT_BDK) space:true]);
    dukptDeriveIPEK(DUKPT_BDK, ksn.bytes, ipek);
    [status appendFormat:@"IPEK: %@\n",[self toHexString:ipek length:sizeof(ipek) space:true]];
    NSLog(@"IPEK: %@",[self toHexString:ipek length:sizeof(ipek) space:true]);
    [status appendFormat:@"KSN: %@\n",[self toHexString:ksn.bytes length:10 space:true]];
    NSLog(@"KSN: %@",[self toHexString:ksn.bytes length:10 space:true]);
    
    //calculate the key based on the serial number and IPEK
    uint8_t dataKey[16]={0};
    dukptCalculateDataKey(ksn.bytes,ipek,dataKey);
    [status appendFormat:@"DATA KEY: %@\n",[self toHexString:dataKey length:16 space:true]];
    NSLog(@"DUKPT KEY: %@",[self toHexString:dataKey length:16 space:true]);
    
    //decrypt the data with the calculated key
    size_t encLen=data.length-10;
    uint8_t decrypted[512];
    trides_crypto(kCCDecrypt,0,data.bytes,encLen,decrypted,dataKey);
    NSLog(@"Decrypted: %@",[self toHexString:decrypted length:encLen space:true]);
    
    int index=0;
    index+=4; //random
    index+=4; //id
    //payload length
    int dataLen=(decrypted[index+0]<<8)|decrypted[index+1];
    index+=2;
    const uint8_t *trackData=&decrypted[index];
    //verify payload length
    if(dataLen>(encLen-index))
    {
        [status appendFormat:@"Invalid data format, possibly key is incorrect"];
        return false;
    }
    //verify crc
    index+=dataLen;
    uint16_t crcPacket=(decrypted[index+0]<<8)|decrypted[index+1];
    uint16_t crcCalculated=[self crc16:decrypted length:index crc16:0xFFFF];
    if(crcPacket!=crcCalculated)
    {
        [status appendFormat:@"Invalid data format, possibly key is incorrect"];
        return false;
    }
    
    //parse the data;
    decrypted[index]=0;
    
    if(trackData[0]==0xF5)
    {
        NSString *data=[[NSString alloc] initWithBytes:&trackData[1] length:(dataLen-1) encoding:NSASCIIStringEncoding];
        //pass to the non-encrypted function to display JIS card
        [self magneticJISCardData:data];
    }else
    {
        int t1=-1,t2=-1,t3=-1,tend;
        NSString *track1=nil,*track2=nil,*track3=nil;
        //find the tracks offset
        for(int j=0;j<dataLen;j++)
        {
            if(trackData[j]==0xF1)
                t1=j;
            if(trackData[j]==0xF2)
                t2=j;
            if(trackData[j]==0xF3)
                t3=j;
        }
        if(t1!=-1)
        {
            if(t2!=-1)
                tend=t2;
            else
                if(t3!=-1)
                    tend=t3;
                else
                    tend=dataLen;
            track1=[[NSString alloc] initWithBytes:&trackData[t1+1] length:(tend-t1-1) encoding:NSASCIIStringEncoding];
        }
        if(t2!=-1)
        {
            if(t3!=-1)
                tend=t3;
            else
                tend=dataLen;
            track2=[[NSString alloc] initWithBytes:&trackData[t2+1] length:(tend-t2-1) encoding:NSASCIIStringEncoding];
        }
        if(t3!=-1)
        {
            tend=dataLen;
            track3=[[NSString alloc] initWithBytes:&trackData[t3+1] length:(tend-t3-1) encoding:NSASCIIStringEncoding];
        }
        
        //pass to the non-encrypted function to display tracks
        [self magneticCardData:track1 track2:track2 track3:track3 source:source];
    }
    return true;
}

-(BOOL)magneticCardPPADDUKPTSeparate:(NSData *)data source:(int)source
{
    const uint8_t *bytes=(uint8_t *)[data bytes];
    NSLog(@"Packet: %@",[self toHexString:bytes length:data.length space:true]);

    int index=0;
    //first block = KSN ident (0x00)
    index++;
    //2 more bytes - length (10)
    int ksnLen=(bytes[index+0]<<8)|(bytes[index+1]);
    index+=2;
    NSData *ksn=[NSData dataWithBytes:&bytes[index] length:ksnLen];
    index+=ksnLen;
    //blocks of data follow for the tracks read
    NSData *t1Encrypted=nil;
    NSData *t2Encrypted=nil;
    NSData *t3Encrypted=nil;
    NSData *tJISEncrypted=nil;
    while (index<data.length) {
        //get the block
        int tid=bytes[index++];
        int tlen=(bytes[index+0]<<8)|(bytes[index+1]);
        index+=2;
        NSData *tdata=[NSData dataWithBytes:&bytes[index] length:tlen];
        index+=tlen;
        //assign to the track
        switch (tid) {
            case 0x01:
                t1Encrypted=tdata;
                break;
            case 0x02:
                t2Encrypted=tdata;
                break;
            case 0x03:
                t3Encrypted=tdata;
                break;
            case 0x05:
                tJISEncrypted=tdata;
                break;
        }
    }


    //calculate the IPEK based on the BDK and serial number
    //insert your own BDK here and calculate the IPEK, for the demo we are using predefined BDK
    uint8_t ipek[16]; //the device specific ipek, will be derived from the BDK
    //derive ipek from bdk
    NSLog(@"DUKPT BDK: %@",[self toHexString:DUKPT_BDK length:sizeof(DUKPT_BDK) space:true]);
    dukptDeriveIPEK(DUKPT_BDK, ksn.bytes, ipek);
    NSLog(@"IPEK: %@",[self toHexString:ipek length:sizeof(ipek) space:true]);
    NSLog(@"KSN: %@",[self toHexString:ksn.bytes length:10 space:true]);

    //calculate the key based on the serial number and IPEK
    uint8_t dataKey[16]={0};
    dukptCalculateDataKey(ksn.bytes,ipek,dataKey);
    NSLog(@"DUKPT KEY: %@",[self toHexString:dataKey length:16 space:true]);


    //try decrypting the tracks
    uint8_t decrypted[512];
    if(t1Encrypted)
    {
        memset(decrypted, 0, sizeof(decrypted));
        trides_crypto(kCCDecrypt,0,t1Encrypted.bytes,t1Encrypted.length,decrypted,dataKey);
        [status appendFormat:@"T1: %@\n",[NSString stringWithCString:(const char *)decrypted encoding:NSASCIIStringEncoding]];
    }
    if(t2Encrypted)
    {
        memset(decrypted, 0, sizeof(decrypted));
        trides_crypto(kCCDecrypt,0,t1Encrypted.bytes,t1Encrypted.length,decrypted,dataKey);
        [status appendFormat:@"T2: %@\n",[NSString stringWithCString:(const char *)decrypted encoding:NSASCIIStringEncoding]];
    }
    if(t3Encrypted)
    {
        memset(decrypted, 0, sizeof(decrypted));
        trides_crypto(kCCDecrypt,0,t1Encrypted.bytes,t1Encrypted.length,decrypted,dataKey);
        [status appendFormat:@"T3: %@\n",[NSString stringWithCString:(const char *)decrypted encoding:NSASCIIStringEncoding]];
    }
    if(tJISEncrypted)
    {
        memset(decrypted, 0, sizeof(decrypted));
        trides_crypto(kCCDecrypt,0,t1Encrypted.bytes,t1Encrypted.length,decrypted,dataKey);
        [status appendFormat:@"JIS: %@\n",[NSString stringWithCString:(const char *)decrypted encoding:NSASCIIStringEncoding]];
    }

    return true;
}


-(void)magneticCardPPAD3DES:(NSData *)data source:(int)source
{
    const uint8_t *bytes=(uint8_t *)[data bytes];
    NSLog(@"Packet: %@",[self toHexString:bytes length:data.length space:true]);
    
    uint8_t dataKey[16]={0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31};

    uint8_t decrypted[512];
    trides_crypto(kCCDecrypt,0,data.bytes,data.length,decrypted,dataKey);
    NSLog(@"Decrypted: %@",[[NSString alloc] initWithBytes:decrypted length:data.length encoding:NSASCIIStringEncoding]);
    NSLog(@"Decrypted: %@",[self toHexString:decrypted length:data.length space:true]);

    int index=0;
    index+=4; //random
    index+=4; //id
    //payload length
    int dataLen=(decrypted[index+0]<<8)|decrypted[index+1];
    index+=2;
    const uint8_t *trackData=&decrypted[index];
    //verify payload length
    if(dataLen>(data.length-index))
    {
        [status appendFormat:@"Invalid data format, possibly key is incorrect"];
        return;
    }
    index+=dataLen;
    uint16_t crcPacket=(decrypted[index+0]<<8)|decrypted[index+1];
    uint16_t crcCalculated=[self crc16:decrypted length:index crc16:0xFFFF];
    if(crcPacket!=crcCalculated)
    {
        [status appendFormat:@"Invalid data format, possibly key is incorrect"];
        return;
    }
    
    //parse the data;
    decrypted[index]=0;
    
    if(trackData[0]==0xF5)
    {
        NSString *data=[[NSString alloc] initWithBytes:&trackData[1] length:(dataLen-1) encoding:NSASCIIStringEncoding];
        //pass to the non-encrypted function to display JIS card
        [self magneticJISCardData:data];
    }else
    {
        int t1=-1,t2=-1,t3=-1,tend;
        NSString *track1=nil,*track2=nil,*track3=nil;
        //find the tracks offset
        for(int j=0;j<dataLen;j++)
        {
            if(trackData[j]==0xF1)
                t1=j;
            if(trackData[j]==0xF2)
                t2=j;
            if(trackData[j]==0xF3)
                t3=j;
        }
        if(t1!=-1)
        {
            if(t2!=-1)
                tend=t2;
            else
                if(t3!=-1)
                    tend=t3;
                else
                    tend=dataLen;
            track1=[[NSString alloc] initWithBytes:&trackData[t1+1] length:(tend-t1-1) encoding:NSASCIIStringEncoding];
        }
        if(t2!=-1)
        {
            if(t3!=-1)
                tend=t3;
            else
                tend=dataLen;
            track2=[[NSString alloc] initWithBytes:&trackData[t2+1] length:(tend-t2-1) encoding:NSASCIIStringEncoding];
        }
        if(t3!=-1)
        {
            tend=dataLen;
            track3=[[NSString alloc] initWithBytes:&trackData[t3+1] length:(tend-t3-1) encoding:NSASCIIStringEncoding];
        }
        
        //pass to the non-encrypted function to display tracks
        [self magneticCardData:track1 track2:track2 track3:track3 source:source];
    }
}

static NSData *stringToData(NSString *text)
{
    NSMutableData *d=[NSMutableData data];
    text=[text lowercaseString];
    int count=0;
    uint8_t b=0;
    for(int i=0;i<text.length;i++)
    {
        b<<=4;
        char c=[text characterAtIndex:i];
        if(c<'0' || (c>'9' && c<'a') || c>'f')
        {
            b=0;
            count=0;
            continue;
        }
        if(c>='0' && c<='9')
            b|=c-'0';
        else
            b|=c-'a'+10;
        count++;
        if(count==2)
        {
            [d appendBytes:&b length:1];
            b=0;
            count=0;
        }
    }
    return d;
}

-(void)magneticCardIDTECH:(NSData *)data encryption:(int)encryption
{
    //find the tracks, turn to ascii hex the data
    int index=0;
    const uint8_t *bytes=(uint8_t *)[data bytes];
    NSLog(@"Packet: %@",[self toHexString:bytes length:data.length space:true]);
    
    index++; //card encoding type
    index++; //track status
    int t1Len=bytes[index++]; //track 1 unencrypted length
    int t2Len=bytes[index++]; //track 2 unencrypted length
    int t3Len=bytes[index++]; //track 3 unencrypted length
    NSString *t1masked=[[NSString alloc] initWithBytes:&bytes[index] length:t1Len encoding:NSASCIIStringEncoding];
    index+=t1Len; //track 1 masked
    NSString *t2masked=[[NSString alloc] initWithBytes:&bytes[index] length:t2Len encoding:NSASCIIStringEncoding];
    index+=t2Len; //track 2 masked
    NSString *t3masked=[[NSString alloc] initWithBytes:&bytes[index] length:t3Len encoding:NSASCIIStringEncoding];
    index+=t3Len; //track 3 masked
    const uint8_t *encrypted=&bytes[index]; //encrypted
    size_t encLen=[data length]-index-10-40;
    NSLog(@"Encrypted: %@",[self toHexString:encrypted length:encLen space:true]);
    index+=encLen;
    index+=20; //track1 sha1
    index+=20; //track2 sha1
    const uint8_t *ksn=&bytes[index]; //dukpt serial number
    
    [status appendFormat:@"IDTECH card format\n"];
    [status appendFormat:@"Track1: %@\n",t1masked];
    [status appendFormat:@"Track2: %@\n",t2masked];
    [status appendFormat:@"Track3: %@\n",t3masked];
    [status appendFormat:@"\r\nEncrypted: %@\n",[self toHexString:encrypted length:encLen space:true]];

    //try decrypting the data
    //calculate the IPEK based on the BDK and serial number
    //insert your own BDK here and calculate the IPEK, for the demo we are using predefined BDK
    uint8_t ipek[16]; //the device specific ipek, will be derived from the BDK
    //derive ipek from bdk
    dukptDeriveIPEK(DUKPT_BDK, ksn, ipek);
    [status appendFormat:@"IPEK: %@\n",[self toHexString:ipek length:sizeof(ipek) space:true]];
    NSLog(@"IPEK: %@",[self toHexString:ipek length:sizeof(ipek) space:true]);
    [status appendFormat:@"KSN: %@\n",[self toHexString:ksn length:10 space:true]];
    NSLog(@"KSN: %@",[self toHexString:ksn length:10 space:true]);

    //calculate the key based on the serial number and IPEK
    uint8_t idtechKey[16]={0};
    dukptCalculateDataKey(ksn,ipek,idtechKey);
    [status appendFormat:@"DATA KEY: %@\n",[self toHexString:idtechKey length:16 space:true]];
    NSLog(@"DUKPT KEY: %@",[self toHexString:idtechKey length:16 space:true]);
    
    
    //decrypt the data with the calculated key
    uint8_t decrypted[512];
    if(encryption==ALG_EH_IDTECH)
    {//decrypt using 3des
        trides_crypto(kCCDecrypt,0,encrypted,encLen,decrypted,idtechKey);
    }
    if(encryption==ALG_EH_IDTECH_AES128)
    {//decrypt using aes128
        NSData *d=[[NSData dataWithBytes:encrypted length:encLen] AESDecryptWithKey:[NSData dataWithBytes:idtechKey length:sizeof(idtechKey)]];
        [d getBytes:decrypted length:d.length];
    }

    int tLen=t1Len+t2Len+t3Len;
    NSLog(@"Decrypted: %@",[[NSString alloc] initWithBytes:decrypted length:tLen encoding:NSASCIIStringEncoding]);
    NSLog(@"Decryted Hex: %@",[self toHexString:decrypted length:encLen space:true]);
    [status appendFormat:@"Decrypted: %@",[self toHexString:decrypted length:encLen space:true]];
    NSString *t1=@"";
    NSString *t2=@"";
    if(t1Len)
        t1=[[NSString alloc] initWithBytes:&decrypted[0] length:t1Len encoding:NSASCIIStringEncoding];
    if(t2Len)
        t2=[[NSString alloc] initWithBytes:&decrypted[t1Len] length:t2Len encoding:NSASCIIStringEncoding];
    if([t1 hasPrefix:@"%B"])
        [status appendFormat:@"Decrypted T1: %@\n",t1];
    else
        [status appendFormat:@"Decrypting T1 failed\n"];
    if([t2 hasPrefix:@";"])
        [status appendFormat:@"Decrypted T2: %@\n",t2];
    else
        [status appendFormat:@"Decrypting T2 failed\n"];
    
    if(t1masked.length>0 && [dtdev msProcessFinancialCard:t1masked track2:t2masked])
    {//if the card is a financial card, try sending to a processor for verification
        NSLog(@"%@",[dtdev msProcessFinancialCard:t1masked track2:t2masked]);
#ifdef POST_TGATE
#define TGATE_USER @""
#define TGATE_PASS @""
        NSString *extData=[NSString stringWithFormat:@"<SecurityInfo>%@</SecurityInfo><Track1>%@</Track1><Track2></Track2><SecureFormat>SecureMag</SecureFormat>",
                           [self toHexString:ksn length:10 space:false],
                           [self toHexString:encrypted length:encLen space:false],
                           ];
        NSLog(@"Extdata: %@",extData);
        [self tgatePost:@"ProcessCreditCard" data:[NSString stringWithFormat:@"UserName=%@&Password=%@&TransType=Auth&CardNum=&ExpDate=&MagData=&NameOnCard=&Amount=1.00&InvNum=&PNRef=&Zip=&Street=&CVNum=&ExtData=%@",TGATE_USER,TGATE_PASS,extData]];
#endif

#ifdef POST_AUTHORIZENET
        //fill in the blanks
#define AUTH_USER @""
#define AUTH_PASS @""
#define AUTH_GATEWAY_ID @""
#define AUTH_API_LOGIN @""
#define AUTH_TRANSACTION_KEY @""
        
        //authorize.net expects common encrypted tracks packet, so we will have to recreate it here
    
        uint8_t buf[512];
        int index=0;
        buf[index++]=encLen+1;//encrypted tracks length (rounded to 8) + 1 for the type
        if(t1Len>0 && t2Len==0)
            buf[index++]=0x01; //type t1 only
        if(t1Len==0 && t2Len>0)
            buf[index++]=0x02; //type t2 only
        if(t1Len>0 && t2Len>0)
            buf[index++]=0x04; //type t1+t2
        memcpy(&buf[index],encrypted,encLen); //encrypted blob
        index+=encLen;
        memcpy(&buf[index],ksn,10);
        index+=10;
        uint8_t lrc=0;
        for(int i=0;i<index;i++)
            lrc^=buf[i];
        uint8_t crc=0;
        for(int i=0;i<index;i++)
            crc+=buf[i];
        buf[index++]=lrc; //lrc
        buf[index++]=crc; //crc
    
        //badass xml
        NSMutableString *transaction=[NSMutableString string];
        [transaction appendFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"];
        [transaction appendFormat:@"<createTransactionRequest xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"AnetApi/xml/v1/schema/AnetApiSchema.xsd\">\n"];
        [transaction appendFormat:@"  <merchantAuthentication>\n"];
        [transaction appendFormat:@"    <name>%@</name>\n",AUTH_API_LOGIN];
        [transaction appendFormat:@"    <transactionKey>%@</transactionKey>\n",AUTH_TRANSACTION_KEY];
        [transaction appendFormat:@"  </merchantAuthentication>\n"];
        [transaction appendFormat:@"  <transactionRequest>\n"];
        [transaction appendFormat:@"    <transactionType>authCaptureTransaction</transactionType>\n"];
        [transaction appendFormat:@"    <amount>66.72</amount>\n"];
        [transaction appendFormat:@"    <payment>\n"];
        [transaction appendFormat:@"      <encryptedTrackData>\n"];
        [transaction appendFormat:@"        <FormOfPayment>\n"];
        [transaction appendFormat:@"          <Value>\n"];
        [transaction appendFormat:@"            <Encoding>Hex</Encoding>\n"];
        [transaction appendFormat:@"            <EncryptionAlgorithm>TDES</EncryptionAlgorithm>\n"];
        [transaction appendFormat:@"            <Scheme>\n"];
        [transaction appendFormat:@"              <DUKPT>\n"];
        [transaction appendFormat:@"                <Operation>DECRYPT</Operation>\n"];
        [transaction appendFormat:@"                <Mode>\n"];
        [transaction appendFormat:@"                  <Data>1</Data>\n"];
        [transaction appendFormat:@"                </Mode>\n"];
        [transaction appendFormat:@"                <DeviceInfo>\n"];
        [transaction appendFormat:@"                  <Description>4649443D434F4D4D4F4E2E456E63727970746564547261636B732E53646B7631</Description>\n"];
        [transaction appendFormat:@"                </DeviceInfo>\n"];
        [transaction appendFormat:@"                <EncryptedData>\n"];
        [transaction appendFormat:@"                  <Value>%@</Value>\n",[self toHexString:buf length:index space:false]];
        [transaction appendFormat:@"                </EncryptedData>\n"];
        [transaction appendFormat:@"              </DUKPT>\n"];
        [transaction appendFormat:@"            </Scheme>\n"];
        [transaction appendFormat:@"          </Value>\n"];
        [transaction appendFormat:@"        </FormOfPayment>\n"];
        [transaction appendFormat:@"      </encryptedTrackData>\n"];
        [transaction appendFormat:@"    </payment>\n"];
        [transaction appendFormat:@"    <retail>\n"];
        [transaction appendFormat:@"      <deviceType>7</deviceType>\n"];
        [transaction appendFormat:@"    </retail>\n"];
        [transaction appendFormat:@"  </transactionRequest>\n"];
        [transaction appendFormat:@"</createTransactionRequest>\n"];
        
        
        NSLog(@"PostData: \n%@",transaction);
        [self httpPost:@"https://apitest.authorize.net/xml/v1/request.api" data:transaction];
#endif
    }
}

//this function converts the data to the keyboard emulation magnasafe packet
-(NSString *)composeMAGTEKPacket:(NSData *)data encryption:(int)encryption
{
    int padding=8;
    if(encryption==ALG_EH_MAGTEK_AES128)
        padding=16;
    
    //find the tracks, turn to ascii hex the data
    int index=0;
    const uint8_t *bytes=data.bytes;
    NSLog(@"Packet: %@",[self toHexString:bytes length:data.length space:true]);
    
    index++; //card encoding type
    index++; //track status
    int t1Len=bytes[index++]; //track 1 unencrypted length
    int t2Len=bytes[index++]; //track 2 unencrypted length
    int t3Len=bytes[index++]; //track 3 unencrypted length
    NSString *t1masked=[[NSString alloc] initWithBytes:&bytes[index] length:t1Len encoding:NSASCIIStringEncoding];
    index+=t1Len; //track 1 masked
    NSString *t2masked=[[NSString alloc] initWithBytes:&bytes[index] length:t2Len encoding:NSASCIIStringEncoding];
    index+=t2Len; //track 2 masked
    NSString *t3masked=[[NSString alloc] initWithBytes:&bytes[index] length:t3Len encoding:NSASCIIStringEncoding];
    index+=t3Len; //track 3 masked
    const uint8_t *t1Encrypted=&bytes[index]; //encrypted track 1
    int t1EncLen=((t1Len+(padding-1))/padding)*padding; //calculated encrypted track length as unencrypted one padded to 8/16 bytes
    index+=t1EncLen;
    const uint8_t *t2Encrypted=&bytes[index]; //encrypted track 2
    int t2EncLen=((t2Len+(padding-1))/padding)*padding; //calculated encrypted track length as unencrypted one padded to 8/16 bytes
    index+=t2EncLen;
    
    index+=20; //track1 sha1
    index+=20; //track2 sha1
    const uint8_t *ksn=&bytes[index]; //dukpt serial number
    
    NSMutableString *magtek=[NSMutableString string];
    //masked tracks
    [magtek appendString:t1masked];
    [magtek appendString:t2masked];
    [magtek appendString:t3masked];
    //reader encryption status
    [magtek appendString:@"|0600"];
    //encrypted track1 & 2
    [magtek appendFormat:@"|%@",[self toHexString:t1Encrypted length:t1EncLen space:false]];
    [magtek appendFormat:@"|%@",[self toHexString:t2Encrypted length:t2EncLen space:false]];
    [magtek appendString:@"|"]; //empty track 3
    //magneprint status
    [magtek appendString:@"|00000000"];
    //encrypted magneprint data
    [magtek appendString:@"|"];
    //reader serial
    [magtek appendFormat:@"|%@",dtdev.serialNumber];
    //encrypted session id
    [magtek appendString:@"|"]; //not sure this can be empty
    //dukpt KSN
    [magtek appendFormat:@"|%@",[self toHexString:ksn length:10 space:false]];
    //clear text crc
    UInt16 crc=[self crc16:(uint8_t *)magtek.UTF8String length:(int)magtek.length crc16:0];
    [magtek appendFormat:@"|%02X%02X",(uint8_t)crc,(uint8_t)(crc>>8)]; //not sure about crc calculation
    //encrypted crc
    [magtek appendString:@"|"];
    //format code
    [magtek appendString:@"|0000"];
    
    return magtek;
}


-(void)magneticCardMAGTEK:(NSData *)data encryption:(int)encryption
{
    
    NSLog(@"%@",[self composeMAGTEKPacket:data encryption:encryption]);
    
    int padding=8;
    if(encryption==ALG_EH_MAGTEK_AES128)
        padding=16;
    
    //find the tracks, turn to ascii hex the data
    int index=0;
    uint8_t *bytes=(uint8_t *)[data bytes];
    NSLog(@"Packet: %@",[self toHexString:bytes length:data.length space:true]);
    
    index++; //card encoding type
    index++; //track status
    int t1Len=bytes[index++]; //track 1 unencrypted length
    int t2Len=bytes[index++]; //track 2 unencrypted length
    int t3Len=bytes[index++]; //track 3 unencrypted length
    NSString *t1masked=[[NSString alloc] initWithBytes:&bytes[index] length:t1Len encoding:NSASCIIStringEncoding];
    index+=t1Len; //track 1 masked
    NSString *t2masked=[[NSString alloc] initWithBytes:&bytes[index] length:t2Len encoding:NSASCIIStringEncoding];
    index+=t2Len; //track 2 masked
    NSString *t3masked=[[NSString alloc] initWithBytes:&bytes[index] length:t3Len encoding:NSASCIIStringEncoding];
    index+=t3Len; //track 3 masked
    uint8_t *t1Encrypted=&bytes[index]; //encrypted track 1
    int t1EncLen=((t1Len+(padding-1))/padding)*padding; //calculated encrypted track length as unencrypted one padded to 8/16 bytes
    index+=t1EncLen;
    uint8_t *t2Encrypted=&bytes[index]; //encrypted track 2
    int t2EncLen=((t2Len+(padding-1))/padding)*padding; //calculated encrypted track length as unencrypted one padded to 8/16 bytes
    index+=t2EncLen;
    
    NSLog(@"Encrypted T1: %@",[self toHexString:t1Encrypted length:t1Len space:true]);
    NSLog(@"Encrypted T2: %@",[self toHexString:t2Encrypted length:t2Len space:true]);
    index+=20; //track1 sha1
    index+=20; //track2 sha1
    uint8_t *ksn=&bytes[index]; //dukpt serial number
    
//    [status appendFormat:@"MAGTEK card format\n"];
//    [status appendFormat:@"Track1: %@\n",t1masked];
//    [status appendFormat:@"Track2: %@\n",t2masked];
//    [status appendFormat:@"Track3: %@\n",t3masked];

    //try decrypting the data
    //calculate the IPEK based on the BDK and serial number
    //insert your own BDK here and calculate the IPEK, for the demo we are using predefined BDK
    uint8_t ipek[16]; //the device specific ipek, will be derived from the BDK
    //derive ipek from bdk
    dukptDeriveIPEK(DUKPT_BDK, ksn, ipek);
//    [status appendFormat:@"IPEK: %@\n",[self toHexString:ipek length:sizeof(ipek) space:true]];
    NSLog(@"IPEK: %@",[self toHexString:ipek length:sizeof(ipek) space:true]);
//    [status appendFormat:@"KSN: %@\n",[self toHexString:ksn length:10 space:true]];
    NSLog(@"KSN: %@",[self toHexString:ksn length:10 space:true]);
    
    //calculate the data key based on the serial number and IPEK (Magtek uses PIN key derivation)
    uint8_t dataKey[16];
    dukptCalculatePINKey(ksn,ipek,dataKey);
//    [status appendFormat:@"DUKPT DATA KEY: %@\n",[self toHexString:dataKey length:16 space:true]];
    NSLog(@"DUKPT DATA KEY: %@",[self toHexString:dataKey length:16 space:true]);
    
    //decrypt the data with the calculated key
    uint8_t decrypted[512]={0};
    
    
    if(t1EncLen)
    {
        if(encryption==ALG_EH_MAGTEK)
        {//decrypt using 3des
            trides_crypto(kCCDecrypt,0,t1Encrypted,t1EncLen,decrypted,dataKey);
        }
        if(encryption==ALG_EH_MAGTEK_AES128)
        {//decrypt using aes128
            NSData *d=[[NSData dataWithBytes:t1Encrypted length:t1EncLen] AESDecryptWithKey:[NSData dataWithBytes:dataKey length:sizeof(dataKey)]];
            [d getBytes:decrypted length:d.length];
        }
        if(decrypted[0]=='%' && decrypted[1]=='B')
        {
            NSString *t1=[[NSString alloc] initWithBytes:decrypted length:t1Len encoding:NSASCIIStringEncoding];
            [status appendFormat:@"Decrypted T1: %@\n",t1];
            NSLog(@"Decrypted T1: %@\n",t1);
        }else
        {
            [status appendFormat:@"Decrypting T1 failed\n"];
            NSLog(@"Decrypting T1 failed\n");
        }
    }
    if(t2EncLen)
    {
        if(encryption==ALG_EH_MAGTEK)
        {//decrypt using 3des
            trides_crypto(kCCDecrypt,0,t2Encrypted,t2EncLen,decrypted,dataKey);
        }
        if(encryption==ALG_EH_MAGTEK_AES128)
        {//decrypt using aes128
            NSData *d=[[NSData dataWithBytes:t2Encrypted length:t2EncLen] AESDecryptWithKey:[NSData dataWithBytes:dataKey length:sizeof(dataKey)]];
            [d getBytes:decrypted length:d.length];
        }
        if(decrypted[0]==';')
        {
            NSString *t2=[[NSString alloc] initWithBytes:decrypted length:t2Len encoding:NSASCIIStringEncoding];
            [status appendFormat:@"Decrypted T2 %@\n",t2];
            NSLog(@"Decrypted T2: %@\n",t2);
        }else
        {
            [status appendFormat:@"Decrypting T2 failed\n"];
            NSLog(@"Decrypting T2 failed\n");
        }
    }
    
    if(t2Len>0 && [dtdev msProcessFinancialCard:t1masked track2:t2masked])
    {//if the card is a financial card, try sending to a processor for verification
        NSLog(@"%@",[dtdev msProcessFinancialCard:t1masked track2:t2masked]);
#ifdef POST_MERCURY
        NSMutableDictionary *dictionaryReq = [NSMutableDictionary new];
        [dictionaryReq setObject:@"118725340908147" forKey:@"MerchantID"];
        [dictionaryReq setObject:@"Credit" forKey:@"TranType"];
        [dictionaryReq setObject:@"Sale" forKey:@"TranCode"];
        [dictionaryReq setObject:@"54321" forKey:@"InvoiceNo"];
        [dictionaryReq setObject:@"54321" forKey:@"RefNo"];
        [dictionaryReq setObject:@"Testing InfinitePeripherals" forKey:@"Memo"];
        // EncryptedFormat is always set to MagneSafe
        [dictionaryReq setObject:@"MagneSafe" forKey:@"EncryptedFormat"];
        // AccountSource set to Swiped if read from MSR
        [dictionaryReq setObject:@"Swiped" forKey:@"AccountSource"];
        // EncryptedBlock is the encrypted payload in 3DES DUKPT format
        [dictionaryReq setObject:[self toHexString:t2Encrypted length:t2EncLen space:false] forKey:@"EncryptedBlock"];
        // EncryptedKey is the Key Serial Number (KSN)
        [dictionaryReq setObject:[self toHexString:ksn length:10 space:false] forKey:@"EncryptedKey"];
        [dictionaryReq setObject:@"4.32" forKey:@"Purchase"];
        [dictionaryReq setObject:@"test" forKey:@"OperatorID"];
        [dictionaryReq setObject:@"OneTime" forKey:@"Frequency"];
        [dictionaryReq setObject:@"RecordNumberRequested" forKey:@"RecordNo"];
        [dictionaryReq setObject:@"Allow" forKey:@"PartialAuth"];
        
        MercuryHelper *mgh = [MercuryHelper new];
        mgh.delegate = self;
        [mgh transctionFromDictionary:dictionaryReq andPassword:@"xyz"];
#endif
    }
}

-(bool)magneticCardAES:(NSData *)data format:(int)format source:(int)source
{
	NSString *decryptionKey=@"11111111111111111111111111111111"; //sample default
    if(format==ALG_EH_AES128)
    {
        //try with aes128
        decryptionKey=@"1111111111111111";
    }
    
    NSData *decrypted=[data AESDecryptWithKey:[decryptionKey dataUsingEncoding:NSASCIIStringEncoding]];
    //basic check if the decrypted data is valid
    if(decrypted && decrypted.length>(4+16))
    {
        uint8_t *bytes=(uint8_t *)[decrypted bytes];
        [status appendFormat:@"Decrypted: %@",[self toHexString:decrypted.bytes length:decrypted.length space:true]];
        for(int i=0;i<([decrypted length]-2);i++)
        {
            if(i>(4+16) && !bytes[i])
            {
                uint16_t crc16=[self crc16:bytes length:(i+1) crc16:0];
                uint16_t crc16Data=(bytes[i+1]<<8)|bytes[i+2];
                
                if(crc16==crc16Data)
                {
                    int snLen=0;
                    for(snLen=0;snLen<16;snLen++)
                        if(!bytes[4+snLen])
                            break;
                    NSString *sn=[[NSString alloc] initWithBytes:&bytes[4] length:snLen encoding:NSASCIIStringEncoding];
                    //do something with that serial number
                    NSLog(@"Serial number in encrypted packet: %@",sn);
                    
                    //crc matches, extract the tracks then
                    int dataLen=i;
                    //check for JIS card
                    if(bytes[4+16]==0xF5)
                    {
                        NSString *data=[[NSString alloc] initWithBytes:&bytes[4+16+1] length:(dataLen-4-16-1) encoding:NSASCIIStringEncoding];
                        //pass to the non-encrypted function to display JIS card
                        [self magneticJISCardData:data];
                    }else
                    {
                        int t1=-1,t2=-1,t3=-1,tend;
                        NSString *track1=nil,*track2=nil,*track3=nil;
                        //find the tracks offset
                        for(int j=(4+16);j<dataLen;j++)
                        {
                            if(bytes[j]==0xF1)
                                t1=j;
                            if(bytes[j]==0xF2)
                                t2=j;
                            if(bytes[j]==0xF3)
                                t3=j;
                        }
                        if(t1!=-1)
                        {
                            if(t2!=-1)
                                tend=t2;
                            else
                                if(t3!=-1)
                                    tend=t3;
                                else
                                    tend=dataLen;
                            track1=[[NSString alloc] initWithBytes:&bytes[t1+1] length:(tend-t1-1) encoding:NSASCIIStringEncoding];
                        }
                        if(t2!=-1)
                        {
                            if(t3!=-1)
                                tend=t3;
                            else
                                tend=dataLen;
                            track2=[[NSString alloc] initWithBytes:&bytes[t2+1] length:(tend-t2-1) encoding:NSASCIIStringEncoding];
                        }
                        if(t3!=-1)
                        {
                            tend=dataLen;
                            track3=[[NSString alloc] initWithBytes:&bytes[t3+1] length:(tend-t3-1) encoding:NSASCIIStringEncoding];
                        }
                        
                        //pass to the non-encrypted function to display tracks
                        [self magneticCardData:track1 track2:track2 track3:track3 source:source];
                    }
                    return true;
                }
            }
        }
    }
    [status setString:NSLocalizedString(@"Card data cannot be decrypted, possibly key is invalid",nil)];
    return false;
}

-(NSString *)voltagePost:(NSString *)data
{
    [progressViewController viewWillAppear:FALSE];
	[self.view addSubview:progressViewController.view];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	
    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"http://cloudburst.voltage.com/payments/services/IbkeepResponder"]];
    NSData *postData=[data dataUsingEncoding:NSASCIIStringEncoding];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"cloudburst.voltage.com" forHTTPHeaderField:@"Host"];
    [request setValue:@"gSOAP/2.7" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"\"\"" forHTTPHeaderField:@"SOAPAction"];
    [request setHTTPBody:postData];
    
    NSError *error;
    NSURLResponse *response;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	[progressViewController.view removeFromSuperview];
    if(urlData)
    {
        NSString *response=[[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding];
        NSLog(@"HTTPS POST completed: %@",response);
        [self displayAlert:@"Voltage response" message:response];
        return response;
    }else {
        NSLog(@"HTTPS POST failed with error: %@",[error localizedDescription]);
//        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Voltage connection failed with error: %@",error.localizedDescription]];
    }
    return nil;
}

static int nMagnetic=0;
static int nContactless=0;

//notification sent when encrypted card was read, sent by 1.83+ sdk
-(void)magneticCardEncryptedData:(int)encryption tracks:(int)tracks data:(NSData *)data track1masked:(NSString *)track1masked track2masked:(NSString *)track2masked track3:(NSString *)track3 source:(int)source;
{
    if(source==CARD_TYPE_MAGNETIC)
        nMagnetic++;
    if(source==CARD_TYPE_CONTACTLESS)
        nContactless++;
    
    self.suspendDisplayInfo=true;
    mainTabBarController.selectedViewController=self;
    
	[status setString:@""];
    
    switch (source) {
        case CARD_TYPE_MAGNETIC:
            [status appendString:@"Card type: magnetic\n"];
            break;
        case CARD_TYPE_SMARTCARD:
            [status appendString:@"Card type: smartcard\n"];
            break;
        case CARD_TYPE_CONTACTLESS:
            [status appendString:@"Card type: contactless\n"];
            break;
        case CARD_TYPE_MANUAL:
            [status appendString:@"Card type: manual entry\n"];
            break;
    }
    
    NSLog(@"Encrypted card data, tracks: %d, encryption: %d",tracks,encryption);
    NSLog(@"Masked track1: %@",track1masked);
    NSLog(@"Masked track2: %@",track2masked);
    NSLog(@"Masked track3: %@",track3);
    
    if(track1masked!=nil)
        [status appendFormat:@"Masked track1: %@\n",track1masked];
    if(track2masked!=nil)
        [status appendFormat:@"Masked track2: %@\n",track2masked];
    if(track3!=nil)
        [status appendFormat:@"Masked track3: %@\n",track3];
    
    if(tracks!=0)
    {
        //you can check here which tracks are read and discard the data if the requred ones are missing
        // for example:
        //if(!(tracks&2)) return; //bail out if track 2 is not read
    }
	
    if(encryption==ALG_AES256 || encryption==ALG_EH_AES256 || encryption==ALG_EH_AES128)
    {
        if(![self magneticCardAES:data format:encryption source:source] && (track1masked || track2masked))
        {//if data can't or is not supposed to be decrypted on the device, work with masked card data to display
            //pass to the non-encrypted function to display tracks
            [self magneticCardData:track1masked track2:track2masked track3:track3 source:source];
        }
    }
    if(encryption==ALG_EH_IDTECH || encryption==ALG_EH_IDTECH_AES128)
    {
        [self magneticCardIDTECH:data encryption:encryption];
    }
    if(encryption==ALG_EH_MAGTEK || encryption==ALG_EH_MAGTEK_AES128)
    {
        [self magneticCardMAGTEK:data encryption:encryption];
    }
    if(encryption==ALG_EH_RSA_OAEP)
    {
        [status setString:[NSString stringWithFormat:@"RSA Magnetic Card Data:\n%@",[self toHexString:(uint8_t *)data.bytes length:data.length space:YES]]];
        int sound[]={2730,150,0,30,2730,150};
        [dtdev playSound:100 beepData:sound length:sizeof(sound) error:nil];
    }
    if(encryption==ALG_EH_VOLTAGE)
    {
        int sound[]={2730,150,0,30,2730,150};
        [dtdev playSound:100 beepData:sound length:sizeof(sound) error:nil];
        
        //try to extract the data and decrypt on voltage test server
#define ENABLED_APP (1<<7)
#define ENABLED_EXP (1<<6)
#define ENABLED_TR3 (1<<5)
#define ENABLED_TR2 (1<<4)
#define ENABLED_TR1 (1<<3)
#define ENABLED_MID (1<<2)
#define ENABLED_PAN (1<<1)
#define ENABLED_ETB (1<<0)
        
        NSString *voltage=[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        [status appendFormat:@"Voltage data: %@\n",voltage];
        //parse flags - 2 char hex in order to get which of the fields are present in the block
        int flags=0;
        char c=[voltage characterAtIndex:2];
        if(c>='0' && c<='9')
            flags|=(c-'0');
        else
            flags|=(c-'A')+10;
        flags<<=4;
        c=[voltage characterAtIndex:3];
        if(c>='0' && c<='9')
            flags|=(c-'0');
        else
            flags|=(c-'A')+10;
        
        //skip the initial packet start + flags to get to the fields directly and separate them by |
        voltage=[voltage substringWithRange:NSMakeRange(5, voltage.length-6)];
        NSArray *split=[voltage componentsSeparatedByString:@"|"];
        
        //prepare the xml string to send to voltage test server in order to decrypt the data, the rest will be filled according to the content of the packet
        NSMutableString *postString=[NSMutableString string];
        [postString appendFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
        [postString appendFormat:@"<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:ns1=\"payments.voltage.com\">\n"];
        [postString appendFormat:@"<SOAP-ENV:Body>\n"];
        [postString appendFormat:@"<ns1:posCardDataDecrypt>\n"];
        [postString appendFormat:@"<ns1:version></ns1:version>\n"];
        [postString appendFormat:@"<ns1:callerId>com.voltage.pos.sample.gsoap</ns1:callerId>\n"];
        [postString appendFormat:@"<ns1:referenceId></ns1:referenceId>\n"];
        
        [postString appendFormat:@"<ns1:encryptedData>\n"];
        
        //extract fields based on the flags content
        int index=0;
        //pan
        if(flags&ENABLED_PAN)
        {
            [postString appendFormat:@"<ns1:pan>%@</ns1:pan>\n",[split objectAtIndex:index]];
            [status appendFormat:@"Masked PAN: %@\n",[split objectAtIndex:index]];
            index++;
        }
        //mid
        if(flags&ENABLED_MID)
        {
            [postString appendFormat:@"<ns1:mid>%@</ns1:mid>\n",[split objectAtIndex:index]];
            [status appendFormat:@"Merchant ID: %@\n",[split objectAtIndex:index]];
            index++;
        }
        //track1
        if(flags&ENABLED_TR1)
        {
            [postString appendFormat:@"<ns1:track1>%@</ns1:track1>\n",[split objectAtIndex:index]];
            [status appendFormat:@"Encrypted track1: %@\n",[split objectAtIndex:index]];
            index++;
        }
        //track2
        if(flags&ENABLED_TR2)
        {
            [postString appendFormat:@"<ns1:track2>%@</ns1:track2>\n",[split objectAtIndex:index]];
            [status appendFormat:@"Encrypted track2: %@\n",[split objectAtIndex:index]];
            index++;
        }
        //track3
        if(flags&ENABLED_TR3)
        {
            [postString appendFormat:@"<ns1:track3>%@</ns1:track3>\n",[split objectAtIndex:index]];
            [status appendFormat:@"Encrypted track3: %@\n",[split objectAtIndex:index]];
            index++;
        }
        //expiration date
        if(flags&ENABLED_EXP)
        {
            [status appendFormat:@"Expires: %@\n",[split objectAtIndex:index]];
            index++;
        }
        //application data
        if(flags&ENABLED_APP)
        {
            [status appendFormat:@"App data: %@\n",[split objectAtIndex:index]];
            index++;
        }
        [postString appendFormat:@"</ns1:encryptedData>\n"];
        
        //ETB field is always present
        if(flags&ENABLED_ETB)
            [postString appendFormat:@"<ns1:etb>%@</ns1:etb>\n",[split objectAtIndex:index++]];
        
        [postString appendFormat:@"</ns1:posCardDataDecrypt>\n"];
        [postString appendFormat:@"</SOAP-ENV:Body>\n"];
        [postString appendFormat:@"</SOAP-ENV:Envelope>\n"];
        
        //send the data to voltage test server
        [self voltagePost:postString];
    }
    if(encryption==ALG_PPAD_DUKPT)
    {//pinpad DUKPT format
        if(![self magneticCardPPADDUKPT:data source:source])
            [self magneticCardData:track1masked track2:track2masked track3:track3 source:source];
//       s [self enterPIN:nil];
    }
    if(encryption==ALG_PPAD_DUKPT_SEPARATE_TRACKS)
    {//pinpad DUKPT format
        if(![self magneticCardPPADDUKPTSeparate:data source:source])
            [self magneticCardData:track1masked track2:track2masked track3:track3 source:source];
        //       s [self enterPIN:nil];
    }
    if(encryption==ALG_PPAD_3DES_CBC)
    {//pinpad 3DES format
        [self magneticCardPPAD3DES:data source:source];
    }
    if(encryption==ALG_TRANSARMOR)
    {
        NSArray *ta=[[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] componentsSeparatedByString:@"|"];
        int track_no = 0;
        
        [status appendString:@"TransArmor Data:\n"];
        
        for (NSString *block in ta) {
            NSArray *split=[block componentsSeparatedByString:@","];
            int ident=[[split objectAtIndex:0] intValue];
            if(ident&1)
                track_no=1;
            if(ident&2)
                track_no=2;
            if(ident&4)
                track_no=3;
            NSLog(@"Encrypted Track%d: %@", track_no, [split objectAtIndex:1]);
            [status appendFormat:@"Track %d:\n%@\n", track_no, [split objectAtIndex:1]];
        }
        
        int sound[]={2730,150,0,30,2730,150};
        [dtdev playSound:100 beepData:sound length:sizeof(sound) error:nil];
    }
    [self displayAlert:@"Card Result" message:status];
//	[displayText setText:status];
}

-(void)sdkDebug:(NSString *)logText source:(int)source
{
	displayText.text=[displayText.text stringByAppendingFormat:@"%@\n",logText];
}

-(IBAction)onPrint:(id)sender
{
    NSError *error;
    
	NSString *selectedPrinterAddress=[[NSUserDefaults standardUserDefaults] objectForKey:@"selectedPrinterAddress"];
    
    if(!selectedPrinterAddress || ![selectedPrinterAddress length])
	{
        [self displayAlert:@"Bluetooth printing" message:@"Please discover and select bluetooth printer from the settings."];
        return;
	}
	
    if(displayText.text.length<1)
	{
        [self displayAlert:@"Bluetooth printing" message:@"Nothing to print, scan barcode or magnetic card first"];
        return;
	}
	
    [progressViewController viewWillAppear:FALSE];
	[self.view addSubview:progressViewController.view];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    if([dtdev btConnectSupportedDevice:selectedPrinterAddress pin:@"0000" error:&error])
    {
        [dtdev prnPrintText:displayText.text usingEncoding:NSASCIIStringEncoding error:&error];
        [dtdev prnFeedPaper:0 error:&error];
        [dtdev prnFlushCache:&error];
        [dtdev btDisconnect:selectedPrinterAddress error:&error];
    }else
        ERRMSG(@"Bluetooth connect failed");
    
	[progressViewController.view removeFromSuperview];
}

-(void)updateiOSBatteryStatus:(NSNotification *)notification
{
    if([UIDevice currentDevice].batteryState!=UIDeviceBatteryStateUnplugged)
    {
        iOSChargingImage.hidden=false;
    }else
    {
        iOSChargingImage.hidden=true;
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	//update display according to current dtdev state
    if(!self.suspendDisplayInfo)
        [self connectionState:dtdev.connstate];
    self.suspendDisplayInfo=false;
}

- (void)viewDidLoad
{
    self.suspendDisplayInfo=false;
    scannerViewController=self;
	status=[[NSMutableString alloc] init];
	debug=[[NSMutableString alloc] init];
#ifdef LOG_FILE
	NSFileManager *fileManger = [NSFileManager defaultManager];
	if ([fileManger fileExistsAtPath:[self getLogFile]])
	{
		[debug appendString:[[NSString alloc] initWithContentsOfFile:[self getLogFile]]];
		[debugText setText:debug];
	}
#endif
	debugText.font=[debugText.font fontWithSize:8];
	dtdev=[DTDevices sharedDevice];
	[dtdev addDelegate:self];
    

    //register for device battery charge notifications
    if ([UIDevice currentDevice].batteryMonitoringEnabled == NO) {
        [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateiOSBatteryStatus:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    }
    //kick it

    [self updateiOSBatteryStatus:nil];
    
    //for the pinpad or display enabled devices, show some fancy stuff when turned around
//	UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
//	accel.delegate = self;
//	accel.updateInterval = 20.0f/60.0f;
    position=-1;

    [super viewDidLoad];
}


@end

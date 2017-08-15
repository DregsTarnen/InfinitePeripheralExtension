#import "MainViewController.h"
#import "NSDataCrypto.h"

@implementation MainViewController

#define OP_NONE 0
#define OP_PIN 1
#define OP_SIGNATURE 2
#define OP_AMOUNT 3

#define POS_NORMAL 0
#define POS_FLIPPED 1

int operation;
int position=-1;
BOOL payPassPresent=FALSE;
BOOL scPresent=FALSE;

-(UIAlertView *)displayAlert:(NSString *)title message:(NSString *)message
{
    if(alert)
    {
        [alert dismissWithClickedButtonIndex:0 animated:FALSE];
        alert=nil;
    }

	alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
    return alert;
}

-(IBAction)onEnterAmount:(id)sender
{
    operation=OP_AMOUNT;
    [amountViewController setAmount:amount];
    [navigationController presentModalViewController:amountViewController animated:TRUE];
}

-(IBAction)onUpdateBattery:(id)sender
{
    [batLabel setHidden:TRUE];
    
    int percent;
    float voltage;
    
	if([dtdev getBatteryCapacity:&percent voltage:&voltage error:nil])
    {
        [batLabel setText:[NSString stringWithFormat:@"Bat: %.2fv, %d%%",voltage,percent]];
        [batLabel setHidden:FALSE];
    }
}

-(void)ppMessage:(NSString *)caption message:(NSString *)message
{
	if(dtdev.connstate==CONN_CONNECTED)
	{
		[dtdev uiStopAnimation:-1 error:nil];
        [dtdev uiFillRectangle:0 topLeftY:0 width:0 height:0 color:[UIColor blackColor] error:nil];
        [dtdev uiDrawText:[NSString stringWithFormat:@"\x01%@",caption] topLeftX:0 topLeftY:0 font:FONT_8X16 error:nil];
		[dtdev uiDrawText:[NSString stringWithFormat:@"\x01%@",message] topLeftX:0 topLeftY:16 font:FONT_6X8 error:nil];
	}
}

-(void)displayResult:(NSError *)error
{
    if(!error)
    {
        if(dtdev.uiDisplayHeight<64)
        {
            [self ppMessage:@" TRANSACTION OK" message:@"     Thank you    "];
        }else
        {
            [self ppMessage:@" TRANSACTION OK" message:@"    Thank you for\n   shopping at the"];
            [dtdev uiDrawText:@"  Apple  Store" topLeftX:0 topLeftY:40 font:FONT_8X16 error:nil];
        }
    }else
    {
        [self ppMessage:@"     ERROR" message:error.localizedDescription];
    }
}

-(void)PINEntryCompleteWithError:(NSError *)error;
{
    [self displayResult:error];
    [self endOperation];
}

-(void)enterPin
{
//    [dtdev uiStopAnimation:-1 error:nil];
//    [dtdev uiFillRectangle:0 topLeftY:0 width:0 height:0 color:[UIColor blackColor] error:nil];
//    [dtdev uiDrawText:@"Insert smart card" topLeftX:0 topLeftY:0 font:FONT_6X8 error:nil];
//    [dtdev uiStopAnimation:-1 error:nil];
//    [dtdev uiFillRectangle:0 topLeftY:0 width:0 height:0 color:[UIColor blackColor] error:nil];
//    [dtdev uiDrawText:@"Insert smart card" topLeftX:0 topLeftY:0 font:FONT_6X8 error:nil];
//    
    operation=OP_PIN;
    [progressViewController updateText:@"Please complete operation on the PinPad"];
    [progressViewController enableCancel:FALSE];
    [self.view addSubview:progressViewController.view];

    [dtdev uiFillRectangle:0 topLeftY:0 width:0 height:0 color:[UIColor blackColor] error:nil];
    NSString *txt=[NSString stringWithFormat:@"Amount: %.2f\nEnter PIN:",amount];
    [dtdev ppadStartPINEntry:0 startY:2 timeout:30 echoChar:'*' message:txt error:nil];
}

- (void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3
{
    if(operation==OP_NONE)
    {
        NSDictionary *card=[dtdev msProcessFinancialCard:track1 track2:track2];
        if(card && [card objectForKey:@"accountNumber"]!=nil && [[card objectForKey:@"expirationYear"] intValue]!=0)
        {
            if(position==POS_FLIPPED)
            {
                [self enterPin];
            }else
            {
                operation=OP_SIGNATURE;
                if(dtdev.uiDisplayHeight<64)
                {
                    [self ppMessage:@"   PLEASE SIGN" message:@"Please sign on the\ndevice"];
                }else
                {
                    [self ppMessage:@" SIGNATURE" message:@"Sign on the device\nor turn it over to enter pin"];
                }
                [navigationController pushViewController:signatureViewController animated:TRUE];
            }
        }else
        {
            [self ppMessage:@"     ERROR" message:@"Please use valid payment card"];
            [self displayAlert:@"Magnetic Card Error" message:@"Please use valid payment card"];
        }
    }
}

-(uint16_t)crc16:(uint8_t *)data length:(int)length crc16:(uint16_t)crc16
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

-(void)magneticCardEncryptedData:(int)encryption tracks:(int)tracks data:(NSData *)data
{
    NSLog(@"Encrypted card data, tracks: %d, encryption: %d",tracks,encryption);
    
	NSString *decryptionKey=@"11111111111111111111111111111111"; //sample default
    
    if(encryption==ALG_AES256 || encryption==ALG_EH_AES256)
    {
        NSData *decrypted=[data AESDecryptWithKey:[decryptionKey dataUsingEncoding:NSASCIIStringEncoding]];
        //basic check if the decrypted data is valid
        if(decrypted && decrypted.length && decrypted.bytes)
        {
            uint8_t *bytes=(uint8_t *)decrypted.bytes;
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
                            [self magneticCardData:track1 track2:track2 track3:track3];
                        }
                        return;
                    }
                }
            }
        }else
        {
            [self displayAlert:@"MS Error" message:@"Decrypted data is null"];
        }
        [self displayAlert:@"MS Error" message:@"Card data cannot be decrypted, possibly key is invalid"];
    }
}

-(void)clearScreenTimer
{
    if(clearTimer)
    {
        [clearTimer invalidate];
        clearTimer=NULL;
    }
	if(dtdev.connstate==CONN_CONNECTED && operation==OP_NONE)
	{
//        [dtdev sysLEDControl:0 pattern:0];
//        [dtdev sysLEDControl:1 pattern:0];
//        [dtdev sysLEDControl:2 pattern:0];
//        [dtdev sysLEDControl:3 pattern:0];
        [self positionChanged:position];
	}
}

-(void)smartCardInserted:(SC_SLOTS)slot;
{
    if(operation==OP_NONE)
    {
        NSData *atr=[dtdev scCardPowerOn:slot error:nil];
        
        if(atr)
        {
            if([dtdev emvATRValidation:atr warmReset:false error:nil])
            {
                //do something with the card, like EMV transaction
                //for the demo, we ask for a fake pin
                [progressViewController updateImage:[UIImage imageNamed:@"card_smart.png"]];
                [self enterPin];
                return;
            }
        }
        //oops, wrong card
//        [self ppMessage:@"     ERROR" message:@"The SmartCard inserted is inserted the wrong way or is non-EMV SmartCard"];
//        [self displayAlert:@"SmartCard Error" message:@"The SmartCard inserted is inserted the wrong way or is non-EMV SmartCard"];
    }
}

-(void)smartCardRemoved
{
}

-(void)barcodeData:(NSString *)barcode type:(int)type
{
    [self displayAlert:@"Barcode" message:[NSString stringWithFormat:@"Type: %@\nBarcode: %@",[dtdev barcodeType2Text:type],barcode]];
}

-(void)showBTController
{
    [self presentModalViewController:bluetoothViewController animated:false];
}

//for the pinpad
-(void)connectionState:(int)state {
	switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
			[[UIApplication sharedApplication] setIdleTimerDisabled: NO];
			[displayText setText:@"PPad not connected"];
            [connectedState setImage:[UIImage imageNamed:@"disconnected.png"]];
            if(operation==OP_SIGNATURE)
            {
                [navigationController popViewControllerAnimated:FALSE];
            }
			break;
		case CONN_CONNECTED:
		{
			[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
			[displayText setText:[NSString stringWithFormat:@"PPad connected!\nSDK version: %d.%d\nHardware revision: %@\nFirmware revision: %@\nSerial number: %@",dtdev.sdkVersion/100,dtdev.sdkVersion%100,dtdev.hardwareRevision,dtdev.firmwareRevision,dtdev.serialNumber]];
            [connectedState setImage:[UIImage imageNamed:@"connected.png"]];

            scPresent=[dtdev scInit:SLOT_MAIN error:nil];
            //since we work with AES encrypted or plain card data, make sure device is sending it
            [dtdev emsrSetEncryption:ALG_EH_AES256 params:nil error:nil];
//            [ppad sysLEDControl:0 pattern:0];
//            [ppad sysLEDControl:1 pattern:0xFFFF];
//            [ppad sysLEDControl:2 pattern:0xFFFF];
//            [ppad sysLEDControl:3 pattern:0xFFFF];
            
            position=-1; //recreate images if needed
            
            [self onUpdateBattery:nil];
            
            //if we are connected to a device not supporting pin entry, but has bluetooth in, try to find something around to connect to
//            if([dtdev getSupportedFeature:FEAT_PIN_ENTRY error:nil]!=FEAT_SUPPORTED && [dtdev getSupportedFeature:FEAT_BLUETOOTH error:nil]&BLUETOOTH_CLIENT)
//                [self performSelectorOnMainThread:@selector(showBTController) withObject:nil waitUntilDone:false];
			break;
		}
	}
}
-(void)clearTimerStop
{
	if(clearTimer)
	{
		[clearTimer invalidate];
		clearTimer=NULL;
	}
	if(mfTimer)
	{
		[mfTimer invalidate];
		mfTimer=NULL;
	}
}

-(void)clearTimerStart
{
    [self clearTimerStop];
    clearTimer=[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(clearScreenTimer) userInfo:nil repeats:NO];
}

-(void)endOperation
{
    operation=OP_NONE;
    [progressViewController.view removeFromSuperview];
    [navigationController popToRootViewControllerAnimated:TRUE];
    [self clearTimerStart];
}

-(void)positionChanged:(int)newpos
{
    position=newpos;
    if(dtdev.connstate!=CONN_CONNECTED)
        return;
    
    [dtdev uiStopAnimation:-1 error:nil];
    [dtdev uiFillRectangle:0 topLeftY:0 width:0 height:0 color:[UIColor blackColor] error:nil];
    
    if(position==POS_FLIPPED)
    {
        if(operation==OP_SIGNATURE)
        {
            [navigationController popViewControllerAnimated:FALSE];
            [progressViewController updateImage:[UIImage imageNamed:@"card_ms.png"]];
            [self enterPin];
        }
        if(operation==OP_AMOUNT)
        {
            [dtdev uiDrawText:@"\x01Please turn the\nunit and enter\namount" topLeftX:0 topLeftY:5 font:FONT_8X16 error:nil];
        }
        if(operation==OP_NONE)
        {
            if(dtdev.uiDisplayHeight<64)
            {
                [dtdev uiDrawText:@"Insert smartcard\nor swipe magnetic\ncard" topLeftX:0 topLeftY:0 font:FONT_6X8 error:nil];
            }else
            {
                [dtdev uiDrawText:@"\x01Use smart,\nmagnetic or\npaypass card" topLeftX:25 topLeftY:3 font:FONT_6X8 error:nil];
                //magnetic card
                [dtdev uiStartAnimation:5 topLeftX:99 topLeftY:0 animated:TRUE error:nil];
                //smartcard
                if(scPresent)
                {
                    [dtdev uiStartAnimation:4 topLeftX:0 topLeftY:0 animated:TRUE error:nil];
                }
                if(payPassPresent)
                {
                    [dtdev uiDisplayImage:38 topLeftY:30 image:[UIImage imageNamed:@"paypass_logo.bmp"] error:nil];
                }
                [dtdev uiDisplayImage:38 topLeftY:30 image:[UIImage imageNamed:@"paypass_logo.bmp"] error:nil];
            }
        }
        [progressViewController enableCancel:FALSE];
    }else
    {
        if(operation==OP_NONE && !dtdev.uiDisplayAtBottom)
        {
            if(dtdev.uiDisplayHeight<64)
            {
                [dtdev uiDrawText:@"Insert smartcard\nor swipe magnetic\ncard" topLeftX:0 topLeftY:0 font:FONT_6X8 error:nil];
            }else
            {
                [dtdev uiDrawText:@"\x01Use smart,\nmagnetic or\npaypass card" topLeftX:25 topLeftY:3 font:FONT_6X8 error:nil];
                //magnetic card
                [dtdev uiStartAnimation:5 topLeftX:99 topLeftY:0 animated:TRUE error:nil];
                //smartcard
                if(scPresent)
                {
                    [dtdev uiStartAnimation:4 topLeftX:0 topLeftY:0 animated:TRUE error:nil];
                }
                if(payPassPresent)
                {
                    [dtdev uiDisplayImage:38 topLeftY:30 image:[UIImage imageNamed:@"paypass_logo.bmp"] error:nil];
                }
                [dtdev uiDisplayImage:38 topLeftY:30 image:[UIImage imageNamed:@"paypass_logo.bmp"] error:nil];
            }
        }
        [progressViewController enableCancel:TRUE];
    }
    
}

-(void)accelerometer:(UIAccelerometer *)acel didAccelerate:(UIAcceleration *)aceler
{
    if(position==-1)
    {
        if([aceler z]<0)
            [self positionChanged:POS_NORMAL];
        else
            [self positionChanged:POS_FLIPPED];
    }else
    {
        if(position==POS_NORMAL && [aceler z]>0.5)
            [self positionChanged:POS_FLIPPED];
        if(position==POS_FLIPPED && [aceler z]<-0.5)
            [self positionChanged:POS_NORMAL];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self onUpdateBattery:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if(operation==OP_AMOUNT)
    {
        operation=OP_NONE;
        [self positionChanged:position];
    }
}

- (void)notifyAmountChanged:(NSNotification *)notification
{
    amount=[notification.object doubleValue];
    [amountButton setTitle:[NSString stringWithFormat:@"%.2f",amount] forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
	UIAccelerometer *accel = [UIAccelerometer sharedAccelerometer];
	accel.delegate = self;
	accel.updateInterval = 20.0f/60.0f;
    
    amount=12.99;
    [amountButton setTitle:[NSString stringWithFormat:@"%.2f",amount] forState:UIControlStateNormal];
	dtdev=[DTDevices sharedDevice];
    [dtdev addDelegate:self];
	[dtdev connect];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyAmountChanged:) name:notificationAmount object:nil];
    
    [super viewDidLoad];
}

@end

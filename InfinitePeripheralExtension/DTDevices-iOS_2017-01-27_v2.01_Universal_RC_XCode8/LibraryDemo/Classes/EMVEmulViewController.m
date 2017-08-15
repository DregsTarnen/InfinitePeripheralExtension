//For America: selecting it makes for a much simplified EMV transaction, lot of stuff becomes optional
//and the data is sent as a normal encrypted magnetic card

#import <CommonCrypto/CommonDigest.h>
#import "EMVEmulViewController.h"
#import "EMV2ViewController.h"
#import "EMVTags.h"
#import "EMVPrivateTags.h"
#import "EMVProcessorHelper.h"
#import "EMVTLV.h"
#import "dukpt.h"
#import "Config.h"

@implementation EMVEmulViewController

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

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

#define RF_COMMAND(operation,c) {if(!c){[self displayAlert:@"Operatin failed!" message:[NSString stringWithFormat:@"%@ failed, error %@, code: %d",operation,error.localizedDescription,(int)error.code]]; return;} }

-(void)updateDisplay
{
    if([dtdev getSupportedFeature:FEAT_PIN_ENTRY error:nil])
    {
        [dtdev emv2Deinitialise:nil];
        if([dtdev getSupportedFeature:FEAT_PIN_ENTRY error:nil])
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
    }
}

-(void)emv2OnTransactionFinished:(NSData *)data;
{
    [progressViewController.view removeFromSuperview];
}

static int getConfigurationVesrsion(NSData *configuration)
{
    NSArray *arr=[TLV decodeTags:configuration];
    if(!arr)
        return 0;
    for (TLV *tag in arr)
    {
        if(tag.tag==0xE4)
        {
            TLV *cfgtag=[TLV findLastTag:0xC1 tags:[TLV decodeTags:tag.data]];
            
            const uint8_t *data=cfgtag.data.bytes;
            int ver=(data[0]<<24)|(data[1]<<16)|(data[2]<<8)|(data[3]<<0);
            return ver;
        }
    }
    return 0;
}

-(IBAction)onEMVTransaction:(id)sender
{
    [self PerformEMVTransactionWithType:0x00 shortEMV:false];
}

-(IBAction)onShortEMVTransaction:(id)sender
{
    [self PerformEMVTransactionWithType:0x00 shortEMV:true];
}

-(void)emv2OnOnlineProcessing:(NSData *)data;
{
    NSData *trackData=[dtdev emv2GetCardTracksEncryptedWithFormat:ALG_TRANSARMOR keyID:0 error:nil];
    if(trackData)
        NSLog(@"Track data: %@",trackData);
    
    //called when the kernel wants an approval online from the server, encapsulate the server response tags
    //in tag 0xE6 and set the server communication success or fail in tag C2
    
    //for the demo fake a successful server response (30 30)
    NSData *serverResponse=[TLV encodeTags:@[[TLV tlvWithHexString:@"30 30" tag:TAG_8A_AUTH_RESP_CODE]]];
    NSData *response=[TLV encodeTags:@[[TLV tlvWithHexString:@"01" tag:0xC2],[TLV tlvWithData:serverResponse tag:0xE6]]];
    [dtdev emv2SetOnlineResult:response error:nil];
}

-(void)PerformEMVTransactionWithType:(int)type shortEMV:(BOOL)shortEMV
{
    NSError *error=nil;

    if(![EMV2ViewController emv2Init])
    {
        [dtdev emv2Deinitialise:&error];
        return;
    }

    //process with transaction
    
    //overwrite terminal capabilities flag depending on the connected device
    NSData *initData=nil;
    TLV *tag9f33=nil;
    if([dtdev getSupportedFeature:FEAT_PIN_ENTRY error:nil]==FEAT_SUPPORTED)
    {//pinpad
        tag9f33=[TLV tlvWithHexString:@"60 B0 C8" tag:TAG_9F33_TERMINAL_CAPABILITIES];
    }else
    {//linea
        tag9f33=[TLV tlvWithHexString:@"40 28 C8" tag:TAG_9F33_TERMINAL_CAPABILITIES];
    }
    //change decimal separator to .
    TLV *tagDecimalSeparator=[TLV tlvWithString:@" " tag:TAG_C2_DECIMAL_SEPARATOR];
    
    initData=[TLV encodeTags:@[/*tag9f33, */tagDecimalSeparator]];

    //set encryption algorithm
    [emsrCryptoViewController updateEMSRAlgorithm:nil];
    //set to disable CVV and enable expiration on manual card entry
    [dtdev emv2SetManualEntryOptionsEnableCVV:false enableExpiration:false error:nil];
    //set pin to always ask
    [dtdev emv2SetPINOptions:PIN_ENTRY_DISABLED error:nil];
    //[dtdev emv2SetPINOptions:PIN_ENTRY_DISABLED forInterface:EMV_INTERFACE_MAGNETIC error:nil];
    //[dtdev emv2SetPINOptions:PIN_ENTRY_ENABLED forInterface:EMV_INTERFACE_MAGNETIC_MANUAL error:nil];
    //disable transaction complete messages

    [dtdev uiEnableCancelButton:true error:nil];
    [dtdev uiEnablePowerButton:true error:nil];

    [dtdev emv2SetMessageForID:EMV_UI_SIGN_APPROVED font:FONT_8X16 message:nil error:nil];
    [dtdev emv2SetMessageForID:EMV_UI_APPROVED font:FONT_8X16 message:nil error:nil];
    [dtdev emv2SetMessageForID:EMV_UI_DECLINED font:FONT_8X16 message:nil error:nil];
    [dtdev emv2SetMessageForID:EMV_UI_ERROR_PROCESSING font:FONT_8X16 message:nil error:nil]; //disable transaction error
    [dtdev emv2SetMessageForID:EMV_UI_ONLINE_AUTHORISATION font:FONT_8X16 message:nil error:nil];
    //set transaction options
    [dtdev emsrConfigMaskedDataShowExpiration:true showServiceCode:true showTrack3:false unmaskedDigitsAtStart:6 unmaskedDigitsAtEnd:4 unmaskedDigitsAfter:7 error:nil];
    //amount: $1.50, currency code: USD(840), according to ISO 4217
    [dtdev emv2SetTransactionType:shortEMV?20:0 amount:12346 currencyCode:840 error:nil];
    //start the transaction

    [dtdev emv2EnableDebug:true error:nil];

    int cfgIndex=shortEMV?1:0;

    [dtdev emv2StartMagneticEmulationTransactionOnInterface:EMV_INTERFACE_CONTACT|EMV_INTERFACE_CONTACTLESS|EMV_INTERFACE_MAGNETIC|EMV_INTERFACE_MAGNETIC_MANUAL initData:initData usingConfiguration:cfgIndex timeout:10 error:&error];
    
    if(error)
    {
        [dtdev emv2Deinitialise:&error];
    }else
    {
        [progressViewController viewWillAppear:FALSE];
        [self.view addSubview:progressViewController.view];
        [progressViewController updateText:@"Use payment card to complete transaction"];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dtdev=[DTDevices sharedDevice];
    [dtdev addDelegate:self];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [dtdev removeDelegate:self];
    [dtdev emv2CancelTransaction:nil];
    [dtdev emv2Deinitialise:nil];
    [progressViewController.view removeFromSuperview];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
}

@end

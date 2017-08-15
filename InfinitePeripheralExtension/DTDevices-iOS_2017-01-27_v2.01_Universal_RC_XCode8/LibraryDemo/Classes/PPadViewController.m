#import "PPadViewController.h"
#import "tr31.h"
#import "dukpt.h"
#import "NSDataCrypto.h"
#import "EMVTlv.h"
#import "EMVPrivateTags.h"

@implementation PPadViewController

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}


#define COMMAND(operation,x) if(!x){[self displayAlert:@"Error" message:[NSString stringWithFormat:@"%@ failed with error: %@",operation,err.localizedDescription]]; return; }

-(IBAction)onKeysInfo:(id)sender;
{
    NSError *err;
    
    NSMutableString *s=[NSMutableString string];
    
    [s appendFormat:@"Loaded Pinpad Keys:\n"];
    //50 3DES keys, get the info about first 10 to speed things up
    for(int i=0;i<10;i++)
    {
        DTKeyInfo *key=[dtdev ppadGetKeyInfo:i error:&err];
        COMMAND(@"Get Key",key);
        if(key.version!=0)
            [s appendFormat:@"%2d. Ver: %d, Usage: %@, KCV: %@\n",i,key.version,key.usage,key.checkValue];
    }
    //2 DUKPT keys
    [s appendFormat:@"\nDUKPT Keys:\n"];
    for(int i=0;i<8;i++)
    {
        NSData *ksn=[dtdev ppadGetDUKPTKeyKSN:i error:&err];
        if(ksn)
            [s appendFormat:@"%2d. KSN: %@\n",i,ksn];
    }
    [self displayAlert:@"Keys" message:s];
}

extern const uint8_t DUKPT_BDK[16];
extern const uint8_t DUKPT_KSN1[10];
extern const uint8_t DUKPT_KSN2[10];

static uint8_t dataKey[16]={0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10};

//load keys using known master key, this is viable on development pinpads only
-(IBAction)onSetKeysHMK:(id)sender;
{
    //load KBPK key on position 0 that can later be used to change other keys
    //the kek bdk is derived to cpu serial number to produce the device kek, which is then used to
    const uint8_t testKEKBDK[] = {0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF,0xFE,0xDC,0xBA,0x98,0x76,0x54,0x32,0x10};
    DTPinpadInfo *info=[dtdev ppadGetSystemInfo:nil];
    if(info)
    {
        NSData *bdk=[NSData dataWithBytes:testKEKBDK length:sizeof(testKEKBDK)];
        //encrypt the bdk with cpu serial number 3des/cbc mode to get the derived device kek
        NSData *deviceKEK=[info.cpuSerial DESEncryptWithKey:bdk];
        
        [self changeKeyTR31WithHMK:"K1" mode:'N' key:deviceKEK keyAddon:nil keyID:1 keyVersion:1];
    }
    
    
    //load DUKPT key on position 0
    //calculate the IPEK based on the BDK and serial number
    //insert your own BDK here and calculate the IPEK, for the demo we are using predefined BDK
    uint8_t ipek[16]; //the device specific ipek, will be derived from the BDK
    //derive ipek from bdk
    dukptDeriveIPEK(DUKPT_BDK, DUKPT_KSN1, ipek);
    [self changeKeyTR31WithHMK:"B1" mode:'X' key:[NSData dataWithBytes:ipek length:sizeof(ipek)] keyAddon:[NSData dataWithBytes:DUKPT_KSN1 length:sizeof(DUKPT_KSN1)] keyID:0 keyVersion:3];
    
    dukptDeriveIPEK(DUKPT_BDK, DUKPT_KSN2, ipek);
    [self changeKeyTR31WithHMK:"B1" mode:'X' key:[NSData dataWithBytes:ipek length:sizeof(ipek)] keyAddon:[NSData dataWithBytes:DUKPT_KSN1 length:sizeof(DUKPT_KSN1)] keyID:1 keyVersion:3];
    
    //load 3DES data encryption key on positon 2
    [self changeKeyTR31WithHMK:"D0" mode:'N' key:[NSData dataWithBytes:dataKey length:sizeof(dataKey)] keyAddon:nil keyID:2 keyVersion:3];
}

//load keys using key encryption key already preloaded
-(IBAction)onSetKeysKEK:(id)sender;
{
    //load DUKPT key on position 0
    //calculate the IPEK based on the BDK and serial number
    //insert your own BDK here and calculate the IPEK, for the demo we are using predefined BDK
    uint8_t ipek[16]; //the device specific ipek, will be derived from the BDK
    //derive ipek from bdk
    dukptDeriveIPEK(DUKPT_BDK, DUKPT_KSN1, ipek);
    [self changeKeyTR31WithKEK:"B1" mode:'X' key:[NSData dataWithBytes:ipek length:sizeof(ipek)] keyAddon:[NSData dataWithBytes:DUKPT_KSN1 length:sizeof(DUKPT_KSN1)] keyID:0 keyVersion:3];
    
    
    //load 3DES data encryption key on positon 2
    [self changeKeyTR31WithKEK:"D0" mode:'N' key:[NSData dataWithBytes:dataKey length:sizeof(dataKey)] keyAddon:nil keyID:2 keyVersion:3];
}

-(void)changeKeyTR31WithHMK:(char *)usage mode:(char)mode key:(NSData *)key keyAddon:(NSData *)keyAddon keyID:(int)keyID keyVersion:(int)keyVersion
{
    const uint8_t testHMK[] = {0x1A,0xC4,0xF2,0x34,0x79,0xCD,0x8F,0x23,0x0B,0xC4,0x9D,0x2C,0x98,0xC8,0x91,0xEA};
    [self changeKeyTR31:usage mode:mode key:key keyAddon:(NSData *)keyAddon keyID:keyID keyVersion:keyVersion encryptionKey:[NSData dataWithBytes:testHMK length:sizeof(testHMK)] encryptionKeyID:0];
}

-(void)changeKeyTR31WithKEK:(char *)usage mode:(char)mode key:(NSData *)key keyAddon:(NSData *)keyAddon keyID:(int)keyID keyVersion:(int)keyVersion
{
    //the kek bdk is derived to cpu serial number to produce the device kek, which is then used to
    const uint8_t testKEKBDK[] = {0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF,0xFE,0xDC,0xBA,0x98,0x76,0x54,0x32,0x10};
    DTPinpadInfo *info=[dtdev ppadGetSystemInfo:nil];
    if(info)
    {
        NSData *bdk=[NSData dataWithBytes:testKEKBDK length:sizeof(testKEKBDK)];
        //encrypt the bdk with cpu serial number 3des/cbc mode to get the derived device kek
        NSData *deviceKEK=[info.cpuSerial DESEncryptWithKey:bdk];
        
        [self changeKeyTR31:usage mode:mode key:key keyAddon:(NSData *)keyAddon keyID:keyID keyVersion:keyVersion encryptionKey:deviceKEK encryptionKeyID:1];
    }
}

//generate the tr31 block, take the usage/mode from the table below
/*
 TR31  TR31 descryption
 usage mode
 --------------------------------------------
 'K1' 'X' TR31 block protection key
 'P0' 'E' key for PIN encryption
 'M1' 'C' key for MAC ISO9797-1 alg. 1
 'M3' 'C' key for MAC ISO9797-1 alg. 3
 'M0' 'C' key for MAC ISO16609 alg. 1
 'D0' 'E' key for data encryption
 'D0' 'D' key for data decrypyion
 'B1' 'X' key for DUKPT
 */
-(void)changeKeyTR31:(char *)usage mode:(char)mode key:(NSData *)key keyAddon:(NSData *)keyAddon keyID:(int)keyID keyVersion:(int)keyVersion encryptionKey:(NSData *)encryptionKey encryptionKeyID:(int)encryptionKeyID
{
    NSError *error;
    
    TKeyBlock tr31;
    tr31.KeyBlockVer='B';
    tr31.usage[0]=usage[0];
    tr31.usage[1]=usage[1];
    tr31.cypher='T';
    tr31.ModeOfUse=mode;
    int ver=((keyVersion>>24)&0xff)*0x01000000;
    ver+=((keyVersion>>16)&0xff)*0x010000;
    ver+=((keyVersion>>8)&0xff)*0x0100;
    ver+=((keyVersion>>0)&0xff);
    tr31.Ver[0]=(ver%100)/10+0x30;
    tr31.Ver[1]=(ver%100)%10+0x30;
    tr31.Export='N';
    tr31.OptionBlocks=0;
    if(keyAddon)
    {//dukpt KSN
        tr31.OptionBlocks=1;
        tr31.option[0].id[0]='2';
        tr31.option[0].id[1]='0';
        tr31.option[0].len=24;
        char *ptr=(char *)tr31.option[0].data;
        const uint8_t *addonBytes=keyAddon.bytes;
        for(int i=0; i<10; i++){
            sprintf(ptr, "%02X", addonBytes[i]);
            ptr+=2;
        }
    }
    tr31.Reserved=0;
    tr31.dataLen=key.length+2;
    tr31.data[0]=(key.length*8)/256;
    tr31.data[1]=(key.length*8)%256;
    memcpy(tr31.data+2, key.bytes, key.length);
    
    uint8_t buf[1024];
    uint16_t outLen=0;
    CreateTR31Block(buf, &outLen, &tr31, (uint8_t *)encryptionKey.bytes, encryptionKey.length, TDES_CMAC);
    buf[outLen]=0;
    NSString *tr31block = [NSString stringWithCString:(char *)buf encoding:NSASCIIStringEncoding];
    
    [dtdev ppadCryptoDelete3DESKeyID:keyID error:nil];
    
    //call the command with the generated tr31 block
    //first parameter is where to load the key - 0-1 for dukpt keys, 1-49 for 3des keys
    //second parameter is the kek - 0 is the terminal hmk (used in this sample) or any other suitable kek
    //usually the pinpad will have some tr31 kek loaded (position 1), so it will be used to load every other key, because the hmk is not available on production units, only test ones
    //the common case when receiving a new production unit:
    //- it will have test tr31 kek (not derived) at position 1
    //- you will need master tr31 kek, that you derive for this device based on serial number, resulting in unique kek
    //- use the transport tr31 kek to change the load your real unique per device kek instead
    //- use the real unique kek to load any other keys
//    tr31block=@"B0104B1TX00E01002018FFFF0000000242E000001986895ECABAFD2AB71C8C2BC286E35FA8333948257AAD8836F075A0EBE5525B";
    if(![dtdev ppadCryptoTR31ExchangeKeyID:keyID kekID:encryptionKeyID tr31:tr31block error:&error])
        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Load failed with error: %@",error.localizedDescription]];
    else
        [self displayAlert:@"Success" message:@"Key loaded successfully"];
}


-(NSString *)pinExtractISO0:(NSData *)data pan:(NSData *)pan
{
    if(data==nil || data.length==0)
        return nil;
    
    const uint8_t *bytes=data.bytes;
    int pinLen=bytes[0]&0x0f;
    NSString *pin=[self toHexString:(uint8_t *)data.bytes length:data.length space:false];
    pin=[pin substringWithRange:NSMakeRange(2, pinLen)];
    NSLog(@"Decrypted pin: %@",pin);
    return pin;
}

-(NSString *)pinExtractISO1:(NSData *)data
{
    if(data==nil || data.length==0)
        return nil;
    
    const uint8_t *bytes=data.bytes;
    int pinLen=bytes[0]&0x0f;
    NSString *pin=[self toHexString:(uint8_t *)data.bytes length:data.length space:false];
    pin=[pin substringWithRange:NSMakeRange(2, pinLen)];
    NSLog(@"Decrypted pin: %@",pin);
    return pin;
}

-(NSString *)pinDecryptMasterSession:(NSError **)error
{
    //master/session assuming a trides_key is loaded at position 2
    NSData *decryptedData=nil;
    uint8_t trides_key[]={0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11};
    uint8_t random_key[]={0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22,0x22};
    uint8_t encrypted_random_key[16]={0};
    
    trides_crypto(kCCEncrypt,kCCOptionECBMode,random_key,sizeof(random_key),encrypted_random_key,trides_key);
    
    //try to get the encrypted data, it will work only if the keys are already set
    NSData *pinData=[dtdev ppadGetPINBlockUsingMasterSession:[NSData dataWithBytes:encrypted_random_key length:sizeof(encrypted_random_key)] fixedKeyID:2 pinFormat:PIN_FORMAT_ISO1 error:error];
    
    if(pinData)
    {
        uint8_t decrypted_pin_block[8]={0};
        trides_crypto(kCCDecrypt,kCCOptionECBMode,pinData.bytes,pinData.length,decrypted_pin_block,random_key);
        decryptedData=[NSData dataWithBytes:decrypted_pin_block length:sizeof(decrypted_pin_block)];
        
        return [self pinExtractISO1:decryptedData];
    }
    NSLog(@"Getting pin failed");
    return nil;
}

-(NSString *)ppadGetPINBlockUsingDUKPT:(NSError **)error
{
    extern const uint8_t DUKPT_BDK[16];
    
    //assuming a dukpt is loaded at position 0
    NSData *pinData=[dtdev ppadGetPINBlockUsingDUKPT:0 keyVariant:nil pinFormat:PIN_FORMAT_ISO0 error:error];
    
    if(pinData)
    {
        NSData *ksn=[pinData subdataWithRange:NSMakeRange(pinData.length-10, 10)];
        
        uint8_t ipek[16]; //the device specific ipek, will be derived from the BDK
        //derive ipek from bdk
        dukptDeriveIPEK(DUKPT_BDK, ksn.bytes, ipek);
        NSLog(@"IPEK: %@",[self toHexString:ipek length:sizeof(ipek) space:true]);
        NSLog(@"KSN: %@",[self toHexString:ksn.bytes length:10 space:true]);
        
        //calculate the key based on the serial number and IPEK
        uint8_t pinKey[16]={0};
        dukptCalculatePINKey(ksn.bytes,ipek,pinKey);
        NSLog(@"DUKPT KEY: %@",[self toHexString:pinKey length:16 space:true]);
        
        uint8_t decrypted[512];
        trides_crypto(kCCDecrypt,0,pinData.bytes,pinData.length-10,decrypted,pinKey);
        NSLog(@"PAN BLOCK: %@",[self toHexString:decrypted length:pinData.length-10 space:true]);
        
        //return [self pinExtractISO0:[NSData dataWithBytes:decrypted length:pinData.length-10] pan:pan];
        return [self pinExtractISO1:[NSData dataWithBytes:decrypted length:pinData.length-10]];
    }
    NSLog(@"Getting pin failed");
    return nil;
}

-(NSString *)ppadGetPINBlockUsingFixedKey:(NSError **)error
{
    //master/session assuming a trides_key is loaded at position 2
    NSData *decryptedData=nil;
    uint8_t trides_key[]={0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11};
    
    //try to get the encrypted data, it will work only if the keys are already set
    NSData *pinData=[dtdev ppadGetPINBlockUsingFixedKey:0x02 keyVariant:nil pinFormat:PIN_FORMAT_ISO1 error:error];
    
    if(pinData)
    {
        uint8_t decrypted_pin_block[8]={0};
        trides_crypto(kCCDecrypt,kCCOptionECBMode,pinData.bytes,pinData.length,decrypted_pin_block,trides_key);
        decryptedData=[NSData dataWithBytes:decrypted_pin_block length:sizeof(decrypted_pin_block)];
        
        return [self pinExtractISO1:decryptedData];
    }
    NSLog(@"Getting pin failed");
    return nil;
}

static NSData *stringToData(NSString *str)
{
    str=[str lowercaseString];
    NSMutableData *r=[NSMutableData data];

    int count = 0;
    uint8_t b = 0;
    for (int i = 0; i < str.length; i++)
    {
        b <<= 4;
        char c = [str characterAtIndex:i];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
        {
            b = 0;
            count = 0;
            continue;
        }
        if (c >= '0' && c <= '9')
            b |= (uint8_t)(c - '0');
        else
            b |= (uint8_t)(c - 'a' + 10);
        count++;
        if (count == 2)
        {
            [r appendBytes:&b length:1];
            b = 0;
            count = 0;
        }
    }
    return r;
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

-(void)PINEntryCompleteWithError:(NSError *)error
{
    [progressViewController.view removeFromSuperview];
    if(error)
    {
        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"PIN entry failed: %@",error.localizedDescription]];
    }else
    {
        NSString *pin=[self ppadGetPINBlockUsingDUKPT:&error];
        if(!pin)
            [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Getting pin data failed: %@",error.localizedDescription]];
        else
            [self displayAlert:@"Success" message:[NSString stringWithFormat:@"PIN code: %@",pin]];
    }
}

-(IBAction)onEnterPIN:(id)sender;
{
    [progressViewController viewWillAppear:FALSE];
    [progressViewController updateText:@"Please use the pinpad to complete the operation..."];
    [mainTabBarController.view addSubview:progressViewController.view];
    
    //Ask for pin, display progress dialog, the pin result will be done via notification
    NSError *error;
//    bool result=[dtdev ppadStartPINEntry:0 startY:2 timeout:100 echoChar:'!' message:[NSString stringWithFormat:@"Amount: %.2f\nEnter PIN:",12.34] error:&error];
    bool result=[dtdev ppadStartPINEntry:11 startY:1 timeout:100 echoChar:'*' minPin:-1 maxPin:-1 message:[NSString stringWithFormat:@"Amount: %.2f\nEnter PIN:",12.34] font:FONT_8X16 error:&error];
    if(!result)
    {
        [progressViewController.view removeFromSuperview];
        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"Operation failed with error: %@",error.localizedDescription]];
    }
    
    //if you want to cancel the entry...
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [NSThread sleepForTimeInterval:5.0];
//        [dtdev ppadCancelPINEntry:nil];
//    });
    
}

-(IBAction)onManualCardEntry:(id)sender
{
    NSError *error;
    //ask for card to be entered or magnetic card to be swiped. the data will come back the same way emsrSetEncryption and emsrConfigMaskedDataShowExpiration are set
    //set encryption algorithm
    [emsrCryptoViewController updateEMSRAlgorithm:nil];
    //set to disable CVV and enable expiration on manual card entry
    [dtdev emv2SetManualEntryOptionsEnableCVV:false enableExpiration:false error:nil];
    //set pin to always ask
    [dtdev emv2SetPINOptions:PIN_ENTRY_ENABLED error:nil];
    //disable transaction complete messages
    [dtdev emv2SetMessageForID:EMV_UI_APPROVED font:FONT_8X16 message:nil error:nil];
    [dtdev emv2SetMessageForID:EMV_UI_DECLINED font:FONT_8X16 message:nil error:nil];
    //set transaction options
    [dtdev emsrConfigMaskedDataShowExpiration:true showServiceCode:true showTrack3:false unmaskedDigitsAtStart:6 unmaskedDigitsAtEnd:4 unmaskedDigitsAfter:7 error:nil];
    //amount: $1.50, currency code: USD(840), according to ISO 4217
    [dtdev emv2SetTransactionType:0x00 amount:1500 currencyCode:840 error:nil];
    //start the transaction
    if([dtdev emv2StartMagneticEmulationTransactionOnInterface:EMV_INTERFACE_MAGNETIC|EMV_INTERFACE_MAGNETIC_MANUAL initData:nil timeout:10 error:&error])
    {
        [progressViewController viewWillAppear:FALSE];
        [progressViewController updateText:@"Please use the pinpad to complete the operation..."];
        [mainTabBarController.view addSubview:progressViewController.view];
    }
}

-(IBAction)onLoadLogo:(id)sender;
{
    [dtdev uiLoadLogo:[UIImage imageNamed:@"ipc1.png"] align:ALIGN_CENTER error:nil];
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
    [progressViewController.view removeFromSuperview];
}

-(void)viewDidLoad
{
    dtdev=[DTDevices sharedDevice];
    [dtdev addDelegate:self];
    [super viewDidLoad];
}


@end

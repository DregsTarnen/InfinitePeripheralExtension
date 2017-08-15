#import "EMSRCryptoViewController.h"
#import "NSDataCrypto.h"
#import <CommonCrypto/CommonDigest.h>
#import "dukpt.h"

@implementation EMSRCryptoViewController

-(BOOL)textFieldShouldEndEditing:(UITextField *)theTextField;
{
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
	[textField resignFirstResponder];
	return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    //limit the size to 32
    int limit = 32;
    return !([textField.text length]>=limit && [string length] > range.length);
}

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

-(IBAction)setActiveHead:(id)sender
{
    NSError *error;
    if(![dtdev emsrSetActiveHead:(int)emsrActiveHead.selectedSegmentIndex error:&error])
        ERRMSG(@"Operation failed!");
}

NSString *toHexString(const void *data, size_t length)
{
    const char HEX[]="0123456789ABCDEF";
    char s[2000];
    
    int len=0;
    for(int i=0;i<length;i++)
    {
        s[len++]=HEX[((uint8_t *)data)[i]>>4];
        s[len++]=HEX[((uint8_t *)data)[i]&0x0f];
        s[len++]=' ';
    }
    s[len]=0;
    return [NSString stringWithCString:s encoding:NSASCIIStringEncoding];
}

/**
 Loads initial key in plain text or changes existing key. Keys in plain text can be loaded only once,
 on every subsequent key change, they needs to be encrypted with KEY_EH_AES256_LOADING.
 
 KEY_EH_AES256_LOADING can be used to change all the keys in the head except for the TMK, and KEY_AES256_LOADING
 can be loaded in plain text the first time too.
 */
NSData *emsrGenerateKeyData(int keyID, int keyVersion, const uint8_t *keyData, size_t keyKength, const uint8_t aes256EncryptionKey[32])
{
    uint8_t data[256];
    int index=0;
	data[index++]=0x2b;
	//key to encrypt with, either KEY_AES256_LOADING or 0xff to use plain text
	data[index++]=aes256EncryptionKey?KEY_EH_AES256_LOADING:0xff;
    data[index++]=keyID; //key to set
    data[index++]=keyVersion>>24; //key version
    data[index++]=keyVersion>>16; //key version
    data[index++]=keyVersion>>8; //key version
    data[index++]=keyVersion; //key version
    int keyStart=index;
    memmove(&data[index],keyData,keyKength); //key data
    index+=keyKength;
    NSLog(@"ToHash: %@",toHexString(data,index));
    CC_SHA256(data,index,&data[index]); //calculate sha256 on the previous packet
    NSLog(@"Hash: %@",toHexString(&data[index],CC_SHA256_DIGEST_LENGTH));
	index+=CC_SHA256_DIGEST_LENGTH;
	//encrypt the data if using the encryption key
	if(aes256EncryptionKey)
	{
        NSData *encryptionKey=[NSData dataWithBytes:aes256EncryptionKey length:32];
        NSData *toEncrypt=[NSData dataWithBytes:&data[keyStart] length:index-keyStart];
        NSLog(@"Toencrypt: %@",toHexString(toEncrypt.bytes,toEncrypt.length));
        NSData *encrypted=[toEncrypt AESEncryptWithKey:encryptionKey]; //encrypt only the key, without the params before it
        
        NSLog(@"Encrypted: %@",toHexString(encrypted.bytes,encrypted.length));
        //store the encryptd data back into the packet
        [encrypted getBytes:&data[keyStart] length:encrypted.length];
	}
    return [NSData dataWithBytes:data length:index];
}

//prepares and loads a key
//NOTE!!!! There can't be a key with duplicate value, this is PCI requirement!
-(bool)loadKeyID:(int)keyID keyData:(NSData *)keyData keyVersion:(int)keyVersion
{
    [self setActiveHead:nil];
    
	NSData *kekData=([newAES256KeyEncryptionKey.text length]>0)?[newAES256KeyEncryptionKey.text dataUsingEncoding:NSASCIIStringEncoding]:nil;
    NSError *error;
    
    //check to see if keyEncryptionKey is present, in this case load encrypted with it
    int kekVer;
    [dtdev emsrGetKeyVersion:KEY_EH_AES256_LOADING keyVersion:&kekVer error:nil];
    if(kekVer<=0)
        kekData=nil;
    if(kekVer>0 && !kekData)
    {
        ERRMSG(NSLocalizedString(@"Key Encryption Key must be provided!",nil));
        return false;
    }
    
    //format the key to load it, optionally encrypt with KEK
    NSData *generatedKeyData=emsrGenerateKeyData(keyID, keyVersion, keyData.bytes, keyData.length, kekData!=nil?kekData.bytes:nil);
    //get the key name, for display purposers
    NSString *keyName=[EMSRKeysInfo keyNameByID:keyID];
    //try to load the key in the slot
    if([dtdev emsrLoadKey:generatedKeyData error:&error])
    {
        [self displayAlert:@"Success!" message:[NSString stringWithFormat:@"Key %@ loaded successfully!",keyName]];
    }else
    {
        NSString *msg=[NSString stringWithFormat:@"Key %@ failed!",keyName];
        ERRMSG(msg);
        return false;
    }
    return true;
}

-(IBAction)setAES256KeyEncryptionKey:(id)sender
{
	if([newAES256KeyEncryptionKey.text length]!=32 || ([oldAES256KeyEncryptionKey.text length]>0 && [oldAES256KeyEncryptionKey.text length]!=32))
	{
		[self displayAlert:NSLocalizedString(@"Wrong key",nil) message:NSLocalizedString(@"Key should be 32 symbols long",nil)];
		return;
	}
	NSData *newKeyData=[newAES256KeyEncryptionKey.text dataUsingEncoding:NSASCIIStringEncoding];
    
    if([self loadKeyID:KEY_EH_AES256_LOADING keyData:newKeyData keyVersion:[newAES256KeyEncryptionKeyVersion.text intValue]])
    {
        //copy the key to the "old key" so you can change easily
        oldAES256KeyEncryptionKey.text=newAES256KeyEncryptionKey.text;
    }
}

-(IBAction)setAES256EncryptionKey:(id)sender
{
	if([newAES256EncryptionKey.text length]!=32)
	{
		[self displayAlert:NSLocalizedString(@"Wrong key",nil) message:NSLocalizedString(@"Key should be 32 symbols long",nil)];
		return;
	}
	NSData *newKeyData=[newAES256EncryptionKey.text dataUsingEncoding:NSASCIIStringEncoding];
    [self loadKeyID:KEY_EH_AES256_ENCRYPTION1 keyData:newKeyData keyVersion:[newAES256EncryptionKeyVersion.text intValue]];
}

-(IBAction)setAES128EncryptionKey:(id)sender;
{
    //load a sample AES128 keys. although AES128 is 16 bytes, it needs to be padded to 32 with anything
    [self loadKeyID:KEY_EH_AES128_ENCRYPTION1 keyData:[@"11111111111111110000000000000000" dataUsingEncoding:NSASCIIStringEncoding] keyVersion:2];
    [self loadKeyID:KEY_EH_AES128_ENCRYPTION2 keyData:[@"11111111111111120000000000000000" dataUsingEncoding:NSASCIIStringEncoding] keyVersion:2];
    [self loadKeyID:KEY_EH_AES128_ENCRYPTION3 keyData:[@"11111111111111130000000000000000" dataUsingEncoding:NSASCIIStringEncoding] keyVersion:2];
}

-(bool)setDUKPTEncryptionKey:(int)keyID version:(int)version ipek:(NSData *)ipek ksn:(NSData *)ksn
{
    uint8_t dukptKey[16+10+6]={0};
    memcpy(&dukptKey[0],ipek.bytes,ipek.length);
    memcpy(&dukptKey[16],ksn.bytes,ksn.length);
    
	NSData *newKeyData=[NSData dataWithBytes:dukptKey length:sizeof(dukptKey)];
    return [self loadKeyID:keyID keyData:newKeyData keyVersion:version];
}


const uint8_t DUKPT_BDK[16]={0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF,0xFE,0xDC,0xBA,0x98,0x76,0x54,0x32,0x10};
//const uint8_t DUKPT_BDK[16]={0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F};
const uint8_t DUKPT_KSN1[10]={0xFF,0xFF,0x98,0x76,0x54,0x32,0x10,0x00,0x00,0x00};
const uint8_t DUKPT_KSN2[10]={0xFF,0xFF,0x98,0x76,0x54,0x32,0x11,0x00,0x00,0x00};
-(IBAction)setDUKPTEncryptionKey:(id)sender
{
    [self setActiveHead:nil];
    
    //load 2 same dukpt keys here, derive them given test bdk and ksn
    uint8_t ipek[16]; //the device specific ipek... that would be if the ksn changes per device based on the serial number or something else, it will generate fixed keys in this case
    dukptDeriveIPEK(DUKPT_BDK, DUKPT_KSN1, ipek);
    
    //load on position 1
    [self setDUKPTEncryptionKey:KEY_EH_DUKPT_MASTER1 version:2 ipek:[NSData dataWithBytes:ipek length:sizeof(ipek)] ksn:[NSData dataWithBytes:DUKPT_KSN1 length:sizeof(DUKPT_KSN1)]];
    EMSRDeviceInfo *emsrInfo=[dtdev emsrGetDeviceInfo:nil];
    if(emsrInfo.firmwareVersion>=230)
    {
        dukptDeriveIPEK(DUKPT_BDK, DUKPT_KSN2, ipek);
        //if the emsr has version 2.30+, then we have more slots to load dukpt keys to
        [self setDUKPTEncryptionKey:KEY_EH_DUKPT_MASTER2 version:3 ipek:[NSData dataWithBytes:ipek length:sizeof(ipek)] ksn:[NSData dataWithBytes:DUKPT_KSN2 length:sizeof(DUKPT_KSN2)]];
    }
}

-(NSString *)toHexString:(void *)data length:(int)length space:(bool)space
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

-(IBAction)getEMSRInfo:(id)sender
{
    [self setActiveHead:nil];
    
    NSError *error=nil;
    
    EMSRDeviceInfo *info=[dtdev emsrGetDeviceInfo:&error];
    if(info)
    {
        NSMutableString *log=[NSMutableString string];
        [log appendFormat:@"Ident: %@\nFW version: %02d.%02d.%02d.%02d\nSerial: %@\n",
         info.ident, info.securityVersion/100,info.securityVersion%100, info.firmwareVersion/100, info.firmwareVersion%100, info.serialNumberString];
        
        EMSRKeysInfo *keys=[dtdev emsrGetKeysInfo:&error];
        if(keys)
        {
//            [log appendFormat:@"AES enc key version: %d\n",[keys getKeyVersion:KEY_ENCRYPTION]];
//            [log appendFormat:@"AES auth key version: %d\n",[keys getKeyVersion:KEY_AUTHENTICATION]];
//            [log appendFormat:@"AES load key version: %d\n",[keys getKeyVersion:KEY_EH_AES256_LOADING]];
//            [log appendFormat:@"DUKPT key version: %d\n",[keys getKeyVersion:KEY_EH_DUKPT_MASTER]];
//            [log appendFormat:@"TMK key version: %d\n",[keys getKeyVersion:KEY_EH_TMK_AES]];
            
            [log appendFormat:@"\nTampered: %@\n",keys.tampered?@"TRUE":@"FALSE"];
            
            [log appendFormat:@"\nLoaded Keys:\n"];
            for (EMSRKey *key in keys.keys)
            {
                if(key.keyVersion)
                {
                    [log appendFormat:@"- %@ ver: %d\n",key.keyName,key.keyVersion];
                    if(key.dukptKSN)
                        [log appendFormat:@"KSN: %@\n",key.dukptKSN];
                }
            }
            
            [log appendFormat:@"\nEmpty Keys:\n"];
            for (EMSRKey *key in keys.keys)
            {
                if(key.keyVersion==0)
                    [log appendFormat:@"- %@\n",key.keyName];
            }
        }
        [self displayAlert:@"EMSR Info" message:log];
    }
    if(error)
        ERRMSG(NSLocalizedString(@"Operation failed!",nil));
}

static NSString * FORMATS[]={
    @"AES 256",
    @"IDTECH 3",
    @"RSA-OAEP",
    @"Voltage",
    @"Magtek",
    @"AES 128",
    @"PPAD DUKPT",
    @"PPAD 3DES",
    @"IDTECH 3 (AES128)",
    @"Magtek (AES128)",
    @"TransArmor",
    @"PPAD DUKPT (Separate)",
};

static int FORMAT_IDS[]={
    ALG_EH_AES256,
    ALG_EH_IDTECH,
    ALG_EH_RSA_OAEP,
    ALG_EH_VOLTAGE,
    ALG_EH_MAGTEK,
    ALG_EH_AES128,
    ALG_PPAD_DUKPT,
    ALG_PPAD_3DES_CBC,
    ALG_EH_IDTECH_AES128,
    ALG_EH_MAGTEK_AES128,
    ALG_TRANSARMOR,
    ALG_PPAD_DUKPT_SEPARATE_TRACKS,
};

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	return NSLocalizedString(@"MS Encryption Format",nil);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return sizeof(FORMATS)/sizeof(NSString *);
}

-(bool)updateEMSRAlgorithm:(NSError **)error
{
    [self setActiveHead:nil];
    
    int emsrAlgorithm=[[[NSUserDefaults standardUserDefaults] objectForKey:@"emsrAlgorithm"] intValue];
    if(emsrAlgorithm<=ALG_EH_AES256)
        emsrAlgorithm=ALG_EH_AES256;
    
    NSDictionary *params=nil;
    int keyID=-1; //if -1, automatically selects the first available key for the specified algorithm
    
    if(emsrAlgorithm==ALG_EH_VOLTAGE)
    {
        params=[NSDictionary dictionaryWithObjectsAndKeys:@"SPE",@"encryption",@"0123456",@"merchantID", nil];
    }
    if(emsrAlgorithm==ALG_EH_IDTECH)
    {//Just a demo how to select key
        keyID=KEY_EH_DUKPT_MASTER1;
    }
    if(emsrAlgorithm==ALG_EH_MAGTEK)
    {//Just a demo how to select key
        keyID=KEY_EH_DUKPT_MASTER1;
    }
    if(emsrAlgorithm==ALG_EH_AES128)
    {//Just a demo how to select key
        keyID=KEY_EH_AES128_ENCRYPTION1;
    }
    if(emsrAlgorithm==ALG_EH_AES256)
    {//Just a demo how to select key
        keyID=KEY_EH_AES256_ENCRYPTION1;
    }
    if(emsrAlgorithm==ALG_PPAD_DUKPT)
    {//Just a demo how to select key, in the pinpad, the dukpt keys are 0 and 1
        keyID=0;
        params=@{@"uniqueID": [NSNumber numberWithInt:0xDDCCBBAA]};
    }
    if(emsrAlgorithm==ALG_PPAD_3DES_CBC)
    {//Just a demo how to select key, in the pinpad, the 3des keys are from 1 to 49, key 1 is automatically selected if you pass 0
        //the key loaded needs to be data encryption 3des type, or card will not read. Assuming such is loaded on position 2:
        keyID=2;
    }
    if(emsrAlgorithm==ALG_EH_IDTECH_AES128)
    {//Just a demo how to select key
        keyID=KEY_EH_DUKPT_MASTER1;
    }
    if(emsrAlgorithm==ALG_EH_MAGTEK_AES128)
    {//Just a demo how to select key
        keyID=KEY_EH_DUKPT_MASTER1;
    }
    
    if(dtdev.connstate==CONN_CONNECTED && ![dtdev emsrSetEncryption:emsrAlgorithm keyID:keyID params:params error:error])
        return false;
    return true;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSError *error;
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:FORMAT_IDS[indexPath.row]] forKey:@"emsrAlgorithm"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if(![self updateEMSRAlgorithm:&error])
    {
        ERRMSG(NSLocalizedString(@"Operation failed!",nil));
    }
    
    [emsrAlgorithmTable reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"CryptoCell"];
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    int emsrAlgorithm=[[prefs objectForKey:@"emsrAlgorithm"] intValue];
    
    cell.accessoryType=UITableViewCellAccessoryNone;
    for(int i=0;i<sizeof(FORMAT_IDS)/sizeof(FORMAT_IDS[0]);i++)
        if(FORMAT_IDS[indexPath.row]==emsrAlgorithm)
        {
            cell.accessoryType=UITableViewCellAccessoryCheckmark;
            break;
        }
    
    [cell.textLabel setText:FORMATS[indexPath.row]];
	return cell;
}

-(void)viewDidLayoutSubviews
{
    ((UIScrollView *)self.view).contentSize=CGSizeMake(self.view.frame.size.width, cryptoView.frame.size.height);
}

-(void)viewDidLoad
{
    [self.view addSubview:cryptoView];

	//we don't care about dtdev notifications here, so won't add the delegate
	dtdev=[DTDevices sharedDevice];
    [super viewDidLoad];
}



@end

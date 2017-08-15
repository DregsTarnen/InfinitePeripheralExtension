#import "CryptoViewController.h"
#import "NSDataCrypto.h"
#import <CommonCrypto/CommonDigest.h>

@implementation CryptoViewController

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

-(void)setAuthKeyAndFlags:(uint32_t)flags
{
	if([newAuthenticationKey.text length]!=32 || ([oldAuthenticationKey.text length]>0 && [oldAuthenticationKey.text length]!=32))
	{
		[self displayAlert:NSLocalizedString(@"Wrong key",nil) message:NSLocalizedString(@"Key should be 32 symbols long",nil)];
		return;
	}
	NSData *newKeyData=[newAuthenticationKey.text dataUsingEncoding:NSASCIIStringEncoding];
	NSData *oldKeyData=([oldAuthenticationKey.text length]>0)?[oldAuthenticationKey.text dataUsingEncoding:NSASCIIStringEncoding]:nil;
    NSError *error;
    
    if([dtdev cryptoSetKey:KEY_AUTHENTICATION key:newKeyData oldKey:oldKeyData keyVersion:[newAuthenticationKeyVersion.text intValue] keyFlags:flags error:&error])
    {
        [self displayAlert:NSLocalizedString(@"Operation successful!",nil) message:NSLocalizedString(@"Key successfully set",nil)];
        //setting key okay, modify the authentication program uses so we can easily authenticate with dtdev
        [authKey setText:newAuthenticationKey.text];
    }else
        ERRMSG(NSLocalizedString(@"Operation failed!",nil));
}

-(IBAction)setAuthenticationKey:(id)sender
{
    [self setAuthKeyAndFlags:0];
}

static const uint8_t KEY_AES256_EMPTY[32]={0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF};

-(IBAction)deleteAuthenticationKey:(id)sender
{
	if([oldAuthenticationKey.text length]!=32)
	{
		[self displayAlert:NSLocalizedString(@"Wrong key",nil) message:NSLocalizedString(@"Old key should be 32 symbols long",nil)];
		return;
	}
	NSData *newKeyData=[NSData dataWithBytes:KEY_AES256_EMPTY length:sizeof(KEY_AES256_EMPTY)];
	NSData *oldKeyData=[oldAuthenticationKey.text dataUsingEncoding:NSASCIIStringEncoding];
    NSError *error;
    
	if([dtdev cryptoSetKey:KEY_AUTHENTICATION key:newKeyData oldKey:oldKeyData keyVersion:0 keyFlags:0 error:&error])
    {
        [self displayAlert:NSLocalizedString(@"Operation successful!",nil) message:NSLocalizedString(@"Key successfully deleted",nil)];
    }else
        ERRMSG(NSLocalizedString(@"Operation failed!",nil));
}



-(IBAction)setAuthenticationKeyAndLock:(id)sender
{
    [self setAuthKeyAndFlags:KEY_AUTH_FLAG_LOCK];
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


-(IBAction)setEncryptionKey:(id)sender
{
    NSError *error;
    
	if([newEncryptionKey.text length]!=32 || ([oldEncryptionKey.text length]>0 && [oldEncryptionKey.text length]!=32))
	{
		[self displayAlert:NSLocalizedString(@"Wrong key",nil) message:NSLocalizedString(@"Key should be 32 symbols long",nil)];
		return;
	}
	NSData *newKeyData=[newEncryptionKey.text dataUsingEncoding:NSASCIIStringEncoding];
	NSData *oldKeyData=([oldEncryptionKey.text length]>0)?[oldEncryptionKey.text dataUsingEncoding:NSASCIIStringEncoding]:nil;
    
	if([dtdev cryptoSetKey:KEY_ENCRYPTION key:newKeyData oldKey:oldKeyData keyVersion:[newEncryptionKeyVersion.text intValue] keyFlags:0 error:&error])
    {
        //setting key okay, modify the decryption key to match the encryption, so we can actually decrypt the data received
        [decryptKey setText:newEncryptionKey.text];
        [self displayAlert:NSLocalizedString(@"Operation successful!",nil) message:NSLocalizedString(@"Key successfully set",nil)];
    }else
        ERRMSG(NSLocalizedString(@"Operation failed!",nil));
}

-(IBAction)deleteEncryptionKey:(id)sender
{
	if([oldEncryptionKey.text length]!=32)
	{
		[self displayAlert:NSLocalizedString(@"Wrong key",nil) message:NSLocalizedString(@"Old key should be 32 symbols long",nil)];
		return;
	}
	NSData *newKeyData=[NSData dataWithBytes:KEY_AES256_EMPTY length:sizeof(KEY_AES256_EMPTY)];
	NSData *oldKeyData=[oldEncryptionKey.text dataUsingEncoding:NSASCIIStringEncoding];
    NSError *error;
    
	if([dtdev cryptoSetKey:KEY_ENCRYPTION key:newKeyData oldKey:oldKeyData keyVersion:0 keyFlags:0 error:&error])
    {
        [self displayAlert:NSLocalizedString(@"Operation successful!",nil) message:NSLocalizedString(@"Key successfully deleted",nil)];
    }else
        ERRMSG(NSLocalizedString(@"Operation failed!",nil));
}

-(IBAction)checkAuthentication:(id)sender
{
    NSError *error;
    
	NSData *lockedKeyData=[authKey.text dataUsingEncoding:NSASCIIStringEncoding];
	if([dtdev cryptoAuthenticateDevice:lockedKeyData error:&error])
    {		
		[self displayAlert:@"dtdev Pro" message:NSLocalizedString(@"Correct Device - UnLocked...",nil)];
	}
	else
    {
		[self displayAlert:@"dtdev Pro" message:NSLocalizedString(@"Wrong Device - Locked...",nil)];
	}
}

-(IBAction)unlockLinea:(id)sender
{
    NSError *error;
    
	NSData *lockedKeyData=[authKey.text dataUsingEncoding:NSASCIIStringEncoding];
	if([dtdev cryptoAuthenticateHost:lockedKeyData error:&error])
    {		
		[self displayAlert:@"dtdev Pro" message:NSLocalizedString(@"Unlock successful",nil)];
	}else
    {
		[self displayAlert:@"dtdev Pro" message:NSLocalizedString(@"Unlock failed",nil)];
	}
}

-(IBAction)getKeyInfo:(id)sender
{
    NSError *error;
    if([dtdev getSupportedFeature:FEAT_PIN_ENTRY error:nil]==FEAT_SUPPORTED)
    {
        NSMutableString *keys=[[NSMutableString alloc] init];
        for(int i=0;i<50;i++)
        {
            DTKeyInfo *key=[dtdev ppadGetKeyInfo:i error:nil];
            if(key && key.version>0)
            {
                [keys appendFormat:@"%d: ver=%d, usage=%@, type=%c\n",i,key.version,key.usage,key.mode];
            }
        }
        [self displayAlert:@"Key Info" message:keys];
    }else
    {
        uint32_t encKeyVersion=-1,authKeyVersion=-1;
        if([dtdev cryptoGetKeyVersion:KEY_ENCRYPTION keyVersion:&encKeyVersion error:&error] || [dtdev cryptoGetKeyVersion:KEY_AUTHENTICATION keyVersion:&authKeyVersion error:&error])
            [self displayAlert:@"Key Info" message:[NSString stringWithFormat:@"AES enc key version: %d\nAES auth key version: %d",encKeyVersion,authKeyVersion]];
        else
            ERRMSG(NSLocalizedString(@"Operation failed!",nil));
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	//store the current decryption key
    NSLog(@"key: %@, len=%d",decryptKey.text,(int)[decryptKey.text length]);
	if([decryptKey.text length]==32)
	{
		NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
		[prefs setObject:decryptKey.text forKey:@"DecryptionKey"];
		[prefs setObject:authKey.text forKey:@"AuthenticationKey"];
		[prefs synchronize];
	}
}

-(void)viewDidLoad
{
    [self.view addSubview:cryptoView];
    ((UIScrollView *)self.view).contentSize=CGSizeMake(cryptoView.frame.size.width, cryptoView.frame.size.height);
	
	//last used decryption key is stored in preferences
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	NSString *decryptionKey=[prefs objectForKey:@"DecryptionKey"];
	if(decryptionKey==nil || decryptionKey.length!=32)
		decryptionKey=@"11111111111111111111111111111111"; //sample default
	[decryptKey setText:decryptionKey];

	NSString *authenticationKey=[prefs objectForKey:@"AuthenticationKey"];
	if(authenticationKey==nil || authenticationKey.length!=32)
		authenticationKey=@"11111111111111111111111111111111"; //sample default
	[authKey setText:authenticationKey];
    
	//we don't care about dtdev notifications here, so won't add the delegate
	dtdev=[DTDevices sharedDevice];
    [super viewDidLoad];
}



@end

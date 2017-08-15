static int nRFCards=0;
static int nRFCardSuccess=0;


#import <CommonCrypto/CommonDigest.h>
#import "EMV2ViewController.h"
#import "EMVTags.h"
#import "EMVPrivateTags.h"
#import "EMVProcessorHelper.h"
#import "EMVTLV.h"
#import "dukpt.h"
#import "Config.h"

@implementation EMV2ViewController

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

void displayAlert(NSString *title, NSString *message)
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

#define RF_COMMAND(operation,c) {if(!c){displayAlert(@"Operatin failed!", [NSString stringWithFormat:@"%@ failed, error %@, code: %d",operation,error.localizedDescription,(int)error.code]); return false;} }

-(IBAction)clear:(id)sender
{
    [logView setText:@""];
}

-(void)updateDisplay
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

-(void)emv2OnTransactionFinished:(NSData *)data;
{
    [progressViewController.view removeFromSuperview];
    
    NSLog(@"emv2OnTransactionFinished: %@",data);
    
    //try to get some encrypted tags and decrypt them
    [self encryptedTagsDemo];
    
    [self performSelector:@selector(updateDisplay) withObject:nil afterDelay:1.5];
    if(!data)
    {
        [dtdev emv2Deinitialise:nil];
        displayAlert(@"Error", @"Transaction could not be completed!");
        return;
    }
    
    //emv2OnTransactionFinished is used to get the final response from the transaction in non-emulation mode
    //data is extracted from the returned tags or manually asked for before calling emv2Deinitialise
    
    //parse data to display, send the rest to server
    
    //find and get Track1 masked and Track2 masked tags for display purposes
    NSString *t1Masked=nil;
    NSString *t2Masked=nil;
    
    NSArray *tags=[TLV decodeTags:data];
    logView.text=[NSString stringWithFormat:@"Final tags:\n%@",tags];
    
    TLV *t;
    
    NSMutableString *receipt=[NSMutableString string];
    NSLog(@"Tags: %@",tags);
    
    [receipt appendFormat:@"* Datecs Ltd *\n"];
    [receipt appendFormat:@"\n"];
    
    
    [receipt appendFormat:@"Terminal ID: %@\n",[EMVProcessorHelper decodeNib:[TLV findLastTag:TAG_9F1C_TERMINAL_ID tags:tags].data]];
    [receipt appendFormat:@"\n"];
    
    [receipt appendFormat:@"Date: %@ %@\n",
     [EMVProcessorHelper decodeDateString:[TLV findLastTag:TAG_9A_TRANSACTION_DATE tags:tags].data],
     [EMVProcessorHelper decodeTimeString:[TLV findLastTag:TAG_9F21_TRANSACTION_TIME tags:tags].data]
     ];
    //    [receipt appendFormat:@"Transaction Sequence: %d\n",[EMVProcessorHelper decodeInt:[TLV findLastTag:TAG_9F41_TRANSACTION_SEQ_COUNTER tags:tags].data]];
    //    [receipt appendFormat:@"\n"];
    //
    //    if([cardInfo valueForKey:@"cardholderName"])
    //        [receipt appendFormat:@"Name: %@\n",[cardInfo valueForKey:@"cardholderName"]];
    //    if([cardInfo valueForKey:@"accountNumber"])
    //        [receipt appendFormat:@"PAN: %@\n",[cardInfo valueForKey:@"accountNumber"]];
    //    if([TLV findLastTag:TAG_5F34_PAN_SEQUENCE_NUMBER tags:tags])
    //    {
    //        [receipt appendFormat:@"PAN-SEQ: %@\n",[EMVProcessorHelper decodeNib:[TLV findLastTag:TAG_5F34_PAN_SEQUENCE_NUMBER tags:tags].data]];
    //    }
    //    [receipt appendFormat:@"AID: %@\n",[EMVProcessorHelper decodeHexString:[TLV findLastTag:TAG_84_DF_NAME tags:tags].data]];
    //    [receipt appendFormat:@"\n"];
    
    [receipt appendFormat:@"* Payment *\n"];
    
    
    int transactionResult=[EMVProcessorHelper decodeInt:[TLV findLastTag:TAG_C1_TRANSACTION_RESULT tags:tags].data];
    
    nRFCards++;
    NSString *transactionResultString=nil;
    switch (transactionResult)
    {
        case EMV_RESULT_APPROVED:
            transactionResultString=@"APPROVED";
            nRFCardSuccess++;
            break;
        case EMV_RESULT_DECLINED:
            nRFCardSuccess++;
            transactionResultString=@"DECLINED";
            break;
        case EMV_RESULT_TRY_ANOTHER_INTERFACE:
            transactionResultString=@"TRY ANOTHER INTERFACE";
            break;
        case EMV_RESULT_TRY_AGAIN:
            transactionResultString=@"TRY AGAIN";
            break;
        case EMV_RESULT_END_APPLICATION:
            transactionResultString=@"END APPLICATION";
            break;
    }
    [receipt appendFormat:@"Transaction Result:\n"];
    [receipt appendFormat:@"%@\n",transactionResultString];
    [receipt appendFormat:@"\n"];


    t=[TLV findLastTag:TAG_C3_TRANSACTION_INTERFACE tags:tags];
    if(t)
    {
        const uint8_t *bytes=t.data.bytes;
        switch (bytes[0]) {
            case EMV_INTERFACE_CONTACT:
                [receipt appendString:@"Interface: contact\n"];
                break;
            case EMV_INTERFACE_CONTACTLESS:
                [receipt appendString:@"Interface: contactless\n"];
                break;
            case EMV_INTERFACE_MAGNETIC:
                [receipt appendString:@"Interface: magnetic\n"];
                break;
            case EMV_INTERFACE_MAGNETIC_MANUAL:
                [receipt appendString:@"Interface: manual entry\n"];
                break;
        }
    }

    t=[TLV findLastTag:TAG_C5_TRANSACTION_INFO tags:tags];
    if(t)
    {
        [receipt appendFormat:@"CL Card Scheme: %d\n",t.bytes[0]];
        [receipt appendFormat:@"Transaction Type: %@\n",((t.bytes[1]&EMV_CL_TRANS_TYPE_MSD)?@"MSD":@"EMV")];
    }

    NSData *trackData=[dtdev emv2GetCardTracksEncryptedWithFormat:ALG_TRANSARMOR keyID:0 error:nil];
    if(trackData)
        [receipt appendFormat:@"Encrypted track data: %@\n",trackData];
    
    if(transactionResult==EMV_RESULT_APPROVED)
    {
        t=[TLV findLastTag:TAG_D3_TRACK1_MASKED tags:tags];
        if(t)
            t1Masked=[[NSString alloc] initWithData:t.data encoding:NSASCIIStringEncoding];
        t=[TLV findLastTag:TAG_D4_TRACK2_MASKED tags:tags];
        if(t)
            t2Masked=[[NSString alloc] initWithData:t.data encoding:NSASCIIStringEncoding];
        
        NSDictionary *card=[dtdev msProcessFinancialCard:t1Masked track2:t2Masked];
        if(card)
        {
            if([card valueForKey:@"cardholderName"])
                [receipt appendFormat:@"Name: %@\n",[card valueForKey:@"cardholderName"]];
            if([card valueForKey:@"accountNumber"])
                [receipt appendFormat:@"Number: %@\n",[card valueForKey:@"accountNumber"]];
            
            if([card valueForKey:@"expirationMonth"])
                [receipt appendFormat:@"Expiration: %@/%@\n",[card valueForKey:@"expirationMonth"],[card valueForKey:@"expirationYear"]];
            [receipt appendString:@"\n"];
        }
        
        //try to get some encrypted tags and decrypt them
        [self encryptedTagsDemo];
    
        //    [receipt appendFormat:@"TVR: %@\n",[EMVProcessorHelper decodeHexString:[TLV findLastTag:TAG_95_TVR tags:tags].data]];
        //    [receipt appendFormat:@"TSI: %@\n",[EMVProcessorHelper decodeHexString:[TLV findLastTag:TAG_9B_TSI tags:tags].data]];
        //    [receipt appendFormat:@"\n"];
        //
        //    NSString *issuerScriptResults=[EMVProcessorHelper decodeHexString:[TLV findLastTag:TAG_C8_ISSUER_SCRIPT_RESULTS tags:tags].data];
        //    if(issuerScriptResults)
        //        [receipt appendFormat:@"%@\n",issuerScriptResults];
        
        if([dtdev getSupportedFeature:FEAT_PRINTING error:nil])
        {
            [dtdev prnPrintText:@"{+B}{=C}TRANSACTION COMPLETE" error:nil];
            [dtdev prnPrintText:receipt error:nil];
            [dtdev prnFeedPaper:0 error:nil];
        }
        
        [receipt insertString:[NSString stringWithFormat:@"nEMVCards: %d, success: %d, failed: %d\n",nRFCards,nRFCardSuccess,nRFCards-nRFCardSuccess] atIndex:0];
        
        
        displayAlert(@"Transaction complete!", receipt);
    }else
    {
        NSString *reasonMessage=@"Terminal declined";
        t=[TLV findLastTag:TAG_C4_TRANSACTION_FAILED_REASON tags:tags];
        if(t)
        {
            const uint8_t *bytes=t.data.bytes;
            int reason=bytes[0];
            if(reason==REASON_CANCELED)
                reasonMessage=@"User cancelled";
            if(reason==REASON_TIMEOUT)
                reasonMessage=@"Transaction timed out";
        }
        displayAlert(@"Transaction failed!", reasonMessage);
    }
}
-(void)emv2OnOnlineProcessing:(NSData *)data;
{
    [self encryptedTagsDemo];

    //called when the kernel wants an approval online from the server, encapsulate the server response tags
    //in tag 0xE6 and set the server communication success or fail in tag C2
    
    //for the demo fake a successful server response (30 30)
    NSData *serverResponse=[TLV encodeTags:@[[TLV tlvWithHexString:@"30 30" tag:TAG_8A_AUTH_RESP_CODE]]];
    NSData *response=[TLV encodeTags:@[[TLV tlvWithHexString:@"01" tag:0xC2],[TLV tlvWithData:serverResponse tag:0xE6]]];
    [dtdev emv2SetOnlineResult:response error:nil];
}

-(void)emv2OnApplicationSelection:(NSData *)applicationTags
{
    //parse apps, multiples of 6F templates
    NSArray<TLV *> *applications=[TLV decodeTags:applicationTags];

    //now decide what to do with the list, there are 2 ways - select some app right away, or, sort the list any way you want, filter it, etc, and send it back
    //a demo of parsing some app name, then showing back the list
    NSMutableArray<NSString *> *appNames=[NSMutableArray array];

    for (TLV *tag6F in applications) {
        NSArray<TLV *> *tag6FTags = [TLV decodeTags:tag6F.data];
        //the aid is here in 84, but we don't care for it now, rather than FCI
        TLV *tagA5 = [TLV findLastTag:0xA5 tags:tag6FTags];
        if(tagA5)
        {
            NSArray<TLV *> *tagA5Tags = [TLV decodeTags:tagA5.data];
            TLV *tag50 = [TLV findLastTag:0x50 tags:tagA5Tags];
            if(tag50)
                [appNames addObject:[[NSString alloc] initWithData:tag50.data encoding:NSASCIIStringEncoding]];
        }
    }
    //anyway when done, send the result way, in this case we flip the apps backwards for the sake of it
    NSMutableArray<NSNumber *> *appList=[NSMutableArray array];
    for(int i=0;i<applications.count;i++)
    {
        [appList insertObject:[NSNumber numberWithInteger:i] atIndex:0];
    }
    [dtdev emv2ShowApplicationList:appList error:nil];
    //or if you want to directly select some app...
//    [dtdev emv2SelectApplication:0 error:nil];
}

-(void)encryptedTagsDemo
{
    NSError *error;
    
    NSData *tagList = [TLV encodeTagList:@[
                                           [NSNumber numberWithInt:0x56], //track1
                                           [NSNumber numberWithInt:0x57], //track2
                                           [NSNumber numberWithInt:0x5A], //pan
                                           [NSNumber numberWithInt:0x5F24], //expiration date
                                           [NSNumber numberWithInt:0x5F20], //account name
                                           ]];
    
    //get the tags encrypted with 3DES CBC and key loaded at positon 2
    NSData *packetData=[dtdev emv2GetTagsEncrypted:tagList format:TAGS_FORMAT_DATECS keyType:KEY_TYPE_3DES_CBC keyIndex:2 packetID:0x12345678 error:&error];
//    packetData=[dtdev emv2GetTagsPlain:tagListData error:nil];
    if(!packetData || packetData.length==0)
        return; //no data
    const uint8_t *packet=packetData.bytes;
    
    int index=0;
    int format = (packet[index + 0] << 24) | (packet[index + 1] << 16) | (packet[index + 2] << 8) | (packet[index + 3]);
    if(format!=TAGS_FORMAT_DATECS)
        return; //wrong format
    index += 4;
    
    //try to decrypt the packet
    NSData *encrypted=[NSData dataWithBytes:&packet[index] length:packetData.length-index];
    
    static uint8_t tridesKey[16]={0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10};
//    uint8_t tridesKey[16]={0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31};

    uint8_t decrypted[1024];
    trides_crypto(kCCDecrypt,0,encrypted.bytes,encrypted.length,decrypted,tridesKey);

    
    //parse and verify the data
    index = 0;
    
    format = (decrypted[index + 0] << 24) | (decrypted[index + 1] << 16) | (decrypted[index + 2] << 8) | (decrypted[index + 3]);
    index += 4;
    
    int dataLen = (decrypted[index + 0] << 8) | (decrypted[index + 1]) - 4 - 4 - 16;
    if(dataLen<0 || dataLen>encrypted.length)
        return; //invalid length
    index += 2;
    int hashStart = index;
    
    int packetID = (decrypted[index + 0] << 24) | (decrypted[index + 1] << 16) | (decrypted[index + 2] << 8) | (decrypted[index + 3]);
    index += 4;
    
    index += 4;
    
    NSData *sn=[NSData dataWithBytes:&decrypted[index] length:16];
    index += sn.length;
    
    NSData *tags=[NSData dataWithBytes:&decrypted[index] length:dataLen];
    index += tags.length;
    int hashEnd = index;
  
    NSData *hashPacket=[NSData dataWithBytes:&decrypted[index] length:32];
    index += hashPacket.length;
    
    uint8_t hash[32];
    CC_SHA256(&decrypted[hashStart],hashEnd-hashStart,hash);
    index+=CC_SHA256_DIGEST_LENGTH;
    
    NSData *hashComputed=[NSData dataWithBytes:hash length:sizeof(hash)];
    
    if(![hashPacket isEqualToData:hashComputed])
        return; //invalid packet checksum
    
    //everything is valid, parse the tags now
    NSLog(@"TLV: %@",tags);
    NSArray *t=[TLV decodeTags:tags];
    NSLog(@"Tags: %@",t);
}

-(void)emv2OnUserInterfaceCode:(int)code status:(int)status holdTime:(NSTimeInterval)holdTime;
{
    NSString *ui=@"";
    NSString *uistatus=@"not provided";
    switch (code)
    {
        case EMV_UI_NOT_WORKING:
            ui = @"Not working";
            break;
        case EMV_UI_APPROVED:
            ui = @"Approved";
            break;
        case EMV_UI_DECLINED:
            ui = @"Declined";
            break;
        case EMV_UI_PLEASE_ENTER_PIN:
            ui = @"Please enter PIN";
            break;
        case EMV_UI_ERROR_PROCESSING:
            ui = @"Error processing";
            break;
        case EMV_UI_REMOVE_CARD:
            ui = @"Please remove card";
            break;
        case EMV_UI_IDLE:
            ui = @"Idle";
            break;
        case EMV_UI_PRESENT_CARD:
            ui = @"Please present card";
            break;
        case EMV_UI_PROCESSING:
            ui = @"Processing...";
            break;
        case EMV_UI_CARD_READ_OK_REMOVE:
            ui = @"It is okay to remove card";
            break;
        case EMV_UI_TRY_OTHER_INTERFACE:
            ui = @"Try another interface";
            break;
        case EMV_UI_CARD_COLLISION:
            ui = @"Card collision";
            break;
        case EMV_UI_SIGN_APPROVED:
            ui = @"Signature approved";
            break;
        case EMV_UI_ONLINE_AUTHORISATION:
            ui = @"Online authorization";
            break;
        case EMV_UI_TRY_OTHER_CARD:
            ui = @"Try another card";
            break;
        case EMV_UI_INSERT_CARD:
            ui = @"Please insert card";
            break;
        case EMV_UI_CLEAR_DISPLAY:
            ui = @"Clear display";
            break;
        case EMV_UI_SEE_PHONE:
            ui = @"See phone";
            break;
        case EMV_UI_PRESENT_CARD_AGAIN:
            ui = @"Please present card again";
            break;
        case EMV_UI_SELECT_APPLICAITON:
            ui = @"Select application on device";
            break;
        case EMV_UI_MANUAL_ENTRY:
            ui = @"Enter card on device";
            break;
        case EMV_UI_NA:
            ui = @"N/A";
            break;
    }
    switch (status)
    {
        case EMV_UI_STATUS_NOT_READY:
            uistatus = @"Status Not Ready";
            break;
        case EMV_UI_STATUS_IDLE:
            uistatus = @"Status Idle";
            break;
        case EMV_UI_STATUS_READY_TO_READ:
            uistatus = @"Status Ready To Read";
            break;
        case EMV_UI_STATUS_PROCESSING:
            uistatus = @"Status Processing";
            break;
        case EMV_UI_STATUS_CARD_READ_SUCCESS:
            uistatus = @"Status Card Read Success";
            break;
        case EMV_UI_STATUS_ERROR_PROCESSING:
            uistatus = @"Status Processing";
            break;
    }
    [progressViewController updateText:ui];
}

-(NSData *)parseXMLTag:(NSDictionary *)config
{
    id subtags=[config objectForKey:@"TAG"];
    NSString *tag=[config objectForKey:@"Tag"];
    NSString *tagdata=[config objectForKey:@"Value"];
    
    NSMutableData *data=[NSMutableData data];
    if(subtags!=nil)
    {
        if([subtags isKindOfClass:[NSArray class]])
        {
            for(NSDictionary *subtag in subtags)
            {
                NSData *tagValue=[self parseXMLTag:subtag];
                [data appendData:tagValue];
            }
        }else
        {
            NSData *tagValue=[self parseXMLTag:subtags];
            [data appendData:tagValue];
        }
    }else
    {
        [data appendData:stringToData(tagdata)];
    }
    TLV *tlv=[TLV tlvWithData:data tag:(int)strtoull(tag.UTF8String, NULL, 16)];
    return [TLV encodeTags:@[tlv]];
}

-(NSData *)parseXMLConfiguration:(NSDictionary *)config
{
    NSMutableData *data=[NSMutableData data];
    NSDictionary *root=[config objectForKey:@"TLVConfiguration"];
    
    for(NSDictionary *tags in [root objectForKey:@"TAG"])
    {
        NSData *tag=[self parseXMLTag:tags];
        [data appendData:tag];
    }
    return data;
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

+(BOOL)emv2Init
{
    NSError *error=nil;

    DTDevices *dtdev=[DTDevices sharedDevice];

    RF_COMMAND(@"EMV Initialize",[dtdev emv2Initialise:&error]);

    //try loading configuration, if it is not there already
    DTEMV2Info *info=[dtdev emv2GetInfo:&error];
    if(info)
    {
        //load contactless configuration
        NSData *configContactless=[Config paymentGetConfigurationFromXML:@"contactless.xml"];

        if(info.contactlessConfigurationVersion!=getConfigurationVesrsion(configContactless))
        {
            RF_COMMAND(@"EMV Load Contactless Configuration",[dtdev emv2LoadContactlessConfiguration:configContactless error:&error]);
            configContactless=[dtdev emv2CreatePANConfiguration:configContactless error:nil];
            [dtdev emv2LoadContactlessConfiguration:configContactless configurationIndex:1 error:nil];  //don't check for failure, in order to work on older firmwares
        }

        if([dtdev getSupportedFeature:FEAT_EMVL2_KERNEL error:nil]&EMV_KERNEL_UNIVERSAL)
        {
            //in case of universal kernel supporting contact/contactless and magnetic payments load contact configuration too
            NSData *configContact=[Config paymentGetConfigurationFromXML:@"contact.xml"];

            if(info.contactConfigurationVersion!=getConfigurationVesrsion(configContact))
            {
                RF_COMMAND(@"EMV Load Contact Configuration",[dtdev emv2LoadContactConfiguration:configContact error:&error]);
                configContact=[dtdev emv2CreatePANConfiguration:configContact error:nil];
                [dtdev emv2LoadContactConfiguration:configContact configurationIndex:1 error:nil]; //don't check for failure, in order to work on older firmwares
            }


            NSData *capkContact=[Config paymentGetConfigurationFromXML:@"contact_capk.xml"];
            if(info.contactCAPKVersion!=getConfigurationVesrsion(capkContact))
                RF_COMMAND(@"EMV Load Contact CAPK",[dtdev emv2LoadContactCAPK:capkContact error:&error]);

            NSData *capkContactless=[Config paymentGetConfigurationFromXML:@"contactless_capk.xml"];
            if(info.contactlessCAPKVersion!=getConfigurationVesrsion(capkContactless))
                RF_COMMAND(@"EMV Load Contactless CAPK",[dtdev emv2LoadContactlessCAPK:capkContactless error:&error]);
            
        }

            //            change some messages in the config
            //            NSMutableArray *uiTags=[NSMutableArray array];
            //            [uiTags addObject:[self emvMakeUITag:EMV_UI_PRESENT_CARD message:@"Present Card" font:FONT_8X16]];
            //            TLV *tagE6=[TLV tlvWithData:[TLV encodeTags:uiTags] tag:0xE6];
            //            NSData *uiConfig=[TLV encodeTags:@[tagE6]];
            //            RF_COMMAND(@"EMV Load Generic Config",[dtdev emv2LoadGenericConfiguration:uiConfig error:&error]);
    }
    return true;
}

-(BOOL)emv2StartTransaction
{
    NSError *error=nil;

    //overwrite terminal capabilities flag depending on the connected device
    NSData *initData=nil;
    TLV *tag9f33=nil;
    if([dtdev getSupportedFeature:FEAT_PIN_ENTRY error:nil]==FEAT_SUPPORTED)
    {//pinpad
        tag9f33=[TLV tlvWithHexString:@"60 B0 C8" tag:TAG_9F33_TERMINAL_CAPABILITIES];
        //            tag9f33=[TLV tlvWithHexString:@"60 60 C8" tag:TAG_9F33_TERMINAL_CAPABILITIES];
    }else
    {//linea
        tag9f33=[TLV tlvWithHexString:@"40 28 C8" tag:TAG_9F33_TERMINAL_CAPABILITIES];
    }
    TLV *tag9f66=[TLV tlvWithHexString:@"36 20 40 00" tag:0x9f66];

    //enable cvv on manual card entry
    TLV *tagCVVEnabled=[TLV tlvWithHexString:@"01" tag:TAG_C1_CVV_ENABLED];

    //change decimal separator to .
    TLV *tagDecimalSeparator=[TLV tlvWithString:@" " tag:TAG_C2_DECIMAL_SEPARATOR];

    tag9f33=[TLV tlvWithHexString:@"E0 10 C8" tag:TAG_9F33_TERMINAL_CAPABILITIES];

    TLV *tagC8=[TLV tlvWithHexString:@"01" tag:0xC8];
    initData=[TLV encodeTags:@[tagCVVEnabled, tagDecimalSeparator, tagC8]];

    [dtdev emv2SetMessageForID:EMV_UI_ERROR_PROCESSING font:FONT_8X16 message:nil error:nil]; //disable transaction error

    [dtdev emv2SetPINOptions:PIN_ENTRY_AUTOMATIC error:nil];

    //amount: $1.00, currency code: USD(840), according to ISO 4217
    RF_COMMAND(@"EMV Init",[dtdev emv2SetTransactionType:0 amount:100 currencyCode:840 error:&error]);
    //start the transaction, transaction steps will be notified via emv2On... delegate methods
    RF_COMMAND(@"EMV Start Transaction",[dtdev emv2StartTransactionOnInterface:EMV_INTERFACE_CONTACT|EMV_INTERFACE_CONTACTLESS|EMV_INTERFACE_MAGNETIC|EMV_INTERFACE_MAGNETIC_MANUAL flags:0 initData:initData timeout:7*60 error:&error]);

    return true;
}

-(IBAction)onEMVTransaction:(id)sender
{
    [progressViewController viewWillAppear:FALSE];
    [self.view addSubview:progressViewController.view];
    [progressViewController updateText:@"Use payment card to initiate transaction"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

    if(![EMV2ViewController emv2Init] || ![self emv2StartTransaction])
    {
        [dtdev emv2Deinitialise:nil];
        [progressViewController.view removeFromSuperview];
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

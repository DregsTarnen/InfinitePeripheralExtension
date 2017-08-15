//#define FELICA_TEST

#import "RFViewController.h"
#import "bertlv.h"

@interface DTDevices(Private)
-(BOOL)rfFieldControlOnChannel:(int)channel enabled:(bool)enabled error:(NSError **)error;
@end

@implementation RFViewController

static int nRFCards=0;
static int nRFCardSuccess=0;

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

#define RF_COMMAND(operation,c) {if(!c){[self displayAlert:@"Operatin failed!" message:[NSString stringWithFormat:@"%@ failed, error %@, code: %d",operation,error.localizedDescription,(int)error.code]]; return;} }

NSData *stringToData(NSString *text)
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

static NSString *dataToString(NSString * label, NSData *data)
{
    return hexToString(label, data.bytes, data.length);
}

static NSString *hexToString(NSString * label, const void *data, size_t length)
{
	const char HEX[]="0123456789ABCDEF";
	char s[20000];
	for(int i=0;i<length;i++)
	{
		s[i*3]=HEX[((uint8_t *)data)[i]>>4];
		s[i*3+1]=HEX[((uint8_t *)data)[i]&0x0f];
		s[i*3+2]=' ';
	}
	s[length*3]=0;
	
    if(label)
        return [NSString stringWithFormat:@"%@(%d): %s",label,(int)length,s];
    else
        return [NSString stringWithCString:s encoding:NSASCIIStringEncoding];
}

-(IBAction)clear:(id)sender
{
    [logView setText:@""];
}

-(void)rfCardRemoved:(int)cardIndex
{
    //if the stop timer was running before, fire it again:
    if(rfStopTimer!=nil)
        rfStopTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(detectStopTimerFunc) userInfo:nil repeats:false];
    
    [logView setText:[logView.text stringByAppendingString:@"\nCard removed"]];
    logView.backgroundColor=[UIColor colorWithRed:0 green:0 blue:1 alpha:0.3];
}

#define CHECK_RESULT(description,result) if(result){[log appendFormat:@"%@: SUCCESS\n",description]; NSLog(@"%@: SUCCESS",description);} else {[log appendFormat:@"%@: FAILED (%@)\n",description,error.localizedDescription]; NSLog(@"%@: FAILED (%@)\n",description,error.localizedDescription); }
-(void)payCardDemo:(int)cardIndex log:(NSMutableString *)log
{
#define READ_RECORD(recNum, sfi) [dtdev iso14APDU:cardIndex cla:0x00 ins:0xB2 p1:recNum p2:(sfi<<3)|0x04 data:nil apduResult:&apduResult error:&error];
#define SELECT_RECORD(file,len) [dtdev iso14APDU:cardIndex cla:0x00 ins:0xA4 p1:0x04 p2:0x00 data:[NSData dataWithBytes:file length:len] apduResult:&apduResult error:&error];
#define GET_PROCESSING_OPTIONS(pdol,len) [dtdev iso14APDU:cardIndex cla:0x80 ins:0xA8 p1:0x00 p2:0x00 data:[NSData dataWithBytes:pdol length:len] apduResult:&apduResult error:&error];
    NSError *error;
    char appName[128]={0};
    char pan[128]={0};
    char name[128]={0};
    int expMonth=0;
    int expYear=0;
    
    
    NSData *ats=[dtdev iso14GetATS:cardIndex error:&error];
    if(ats)
        [log appendFormat:@"ATS: %@\n",hexToString(nil,ats.bytes,ats.length)];
    
    static const uint8_t AIDs[][7]=
    {
        {0xA0,0x00,0x00,0x00,0x03,0x10,0x10},// "VISA CREDIT"));
        {0xA0,0x00,0x00,0x00,0x03,0x20,0x10},// "VISA ELECTRON"));
        {0xA0,0x00,0x00,0x00,0x03,0x30,0x10},// "VISA INTERLINK"));
        {0xA0,0x00,0x00,0x00,0x03,0x40,0x10},// "VISA"));
        {0xA0,0x00,0x00,0x00,0x03,0x50,0x10},// "VISA"));
        {0xA0,0x00,0x00,0x00,0x03,0x80,0x10},// "VISA PLUS"));
        {0xA0,0x00,0x00,0x00,0x04,0x10,0x10},// "MASTERCARD CREDIT"));
        {0xA0,0x00,0x00,0x00,0x04,0x20,0x10},// "MASTERCARD"));
        {0xA0,0x00,0x00,0x00,0x04,0x30,0x10},// "MASTERCARD"));
        {0xA0,0x00,0x00,0x00,0x04,0x30,0x60},// "MAESTRO"));
        {0xA0,0x00,0x00,0x00,0x04,0x40,0x10},// "MASTERCARD"));
        {0xA0,0x00,0x00,0x00,0x04,0x50,0x10},// "MASTERCARD"));
        {0xA0,0x00,0x00,0x00,0x04,0x60,0x00},// "CIRRUS"));
        {0xA0,0x00,0x00,0x00,0x25,0x00,0x00},// "AMEX"));
        {0xA0,0x00,0x00,0x01,0x41,0x00,0x01},// "PAGOBANCOMAT"));
        {0xA0,0x00,0x00,0x02,0x28,0x10,0x10},// "SAMA"));
        {0xA0,0x00,0x00,0x02,0x77,0x10,0x10},// "INTERAC"));
    };
    
    uint16_t apduResult;
    uint8_t apdu[256];
    tlv_t *t=0;
    //select application
    NSData *appData=nil;
    
    //try PSE method first
    //try PSE first
    const char *PSE_NAME="2PAY.SYS.DDF01";
    NSData *pseData=SELECT_RECORD((const uint8_t *)PSE_NAME,strlen(PSE_NAME));
    if(pseData && apduResult==0x9000)
    {
        t=tlvFind1(pseData.bytes,pseData.length,0x4F); //AID
        if(t)
        {
            appData=SELECT_RECORD(t->data,t->length);
        }
    }else
    {//go for application
        //select application
        for(int i=0;i<sizeof(AIDs)/sizeof(AIDs[0]);i++)
        {
            appData=SELECT_RECORD(AIDs[i],sizeof(AIDs[i]));
            if(!appData)
                return;
            if(apduResult==0x9000)
                break;
        }
    }
    
    if(!appData || apduResult!=0x9000)
    {
        [log appendFormat:@"Unknown Application!\n"];
        return;
    }
    
    //get name
    t=tlvFind1(appData.bytes,appData.length,0x50); //app name
    if(t)
    {
        memcpy(appName,t->data,t->length);
        appName[t->length]=0;
    }
    
    //initial application processing
    //pdol
    t=tlvFind1(appData.bytes,appData.length,0x9F38); //PDOL
    int tagLen=0;
    if(t)
    {
        //parse pdol structure
        uint8_t tlvData[256]={0};
        //dummy data
        int index=0;
        
        for(int i=0;i<t->length;)
        {
            int tag=0;
            
            if((t->data[i]&0x1F)==0x1F)
            {//2byte tag
                tag=(t->data[i++]<<8);
            }
            tag|=t->data[i++];
            
            int length=0;
            if(t->data[i]&0x80)
            {//double
                length=((t->data[i++]&0x7f)<<8);
            }
            length|=t->data[i++];
            
            if(tag==0x9f66)
            {
                tlvData[index]=(1<<7)|(0<<5)|(1<<4)|(1<<2)|(0<<1);
            }
            if(tag==0x9F37)
            {
                for(int i=0;i<length;i++)
                    tlvData[index+i]=0x51;
            }
            index+=length;
        }
        
        tagLen=tlvMakeTag(0x83,tlvData,index,apdu);
    }else
        tagLen=tlvMakeTag(0x83,0,0,apdu);
    NSData *processingData=GET_PROCESSING_OPTIONS(apdu,tagLen);
    if(!processingData || apduResult!=0x9000)
        return;
    
    uint8_t aflData[256];
    size_t aflDataLen;
    t=tlvFind1(processingData.bytes,processingData.length,0x94); //AFL
    if(t)
    {
        aflDataLen=t->length;
        memcpy(aflData,t->data,aflDataLen);
    }else
    {
        aflDataLen=processingData.length-1-1-2;
        memcpy(aflData,processingData.bytes+1+1+2,aflDataLen);
    }
    
    //loop through records and extract info
    for(int i=0;i<aflDataLen;)
    {
        int sfi=aflData[i++]>>3;
        int srec=aflData[i++];
        int erec=aflData[i++];
        i++; //nrec
        for (; srec <= erec; srec++)
        {
            NSData *recordData=READ_RECORD(srec,sfi);
            if(!recordData)
                return;
            if(apduResult!=0x9000)
                continue;
            
            //track 1
            t=tlvFind1(recordData.bytes,recordData.length,0x56);
            if(t)
            {
                char *tmp=(char *)&t->data[1];
                char *divider=strchr(tmp,'^');
                *divider=0;
                strcpy(pan,tmp);
                
                tmp=divider+1;
                divider=strchr(tmp,'^');
                *divider=0;
                strcpy(name,tmp);
                
                divider++;
                expYear=2000+(divider[0]-'0')*10+(divider[1]-'0');
                expMonth=(divider[2]-'0')*10+(divider[3]-'0');
            }
            
            //track 2 equivalent data
            t=tlvFind1(recordData.bytes,recordData.length,0x57);
            if(t)
            {
                static char tmp[256];
                tmp[0]=0;
                for(int ti=0;ti<t->length;ti++)
                    sprintf(&tmp[strlen(tmp)],"%02X",t->data[ti]);
                char *divider=strchr(tmp,'D');
                *divider=0;
                strcpy(pan,tmp);
                
                divider++;
                expYear=2000+(divider[0]-'0')*10+(divider[1]-'0');
                expMonth=(divider[2]-'0')*10+(divider[3]-'0');
            }
            
            //PAN
            t=tlvFind1(recordData.bytes,recordData.length,0x5A);
            if(t)
            {
                static char tmp[256];
                tmp[0]=0;
                for(int ti=0;ti<t->length;ti++)
                    sprintf(&tmp[strlen(tmp)],"%02X",t->data[ti]);
                if(tmp[strlen(tmp)-1]=='F')
                    tmp[strlen(tmp)-1]=0;
                strcpy(pan,tmp);
            }
            
            //expiration date
            t=tlvFind1(recordData.bytes,recordData.length,0x5F24);
            if(t)
            {
                expYear=2000+(t->data[0]>>4)*10+(t->data[0]&0x0f);
                expMonth=(t->data[1]>>4)*10+(t->data[1]&0x0f);
            }

            //cardholder name
            t=tlvFind1(recordData.bytes,recordData.length,0x5F20);
            if(t)
            {
                memcpy(name,t->data,t->length);
                name[t->length]=0;
            }
        }
    }
    //mask the pan
    for(int i=6;i<strlen(pan)-4;i++)
        pan[i]='*';
    [log appendFormat:@"Card type: %s\n",appName];
    [log appendFormat:@"PAN: %s\n",pan];
    [log appendFormat:@"Name: %s\n",name];
    [log appendFormat:@"Expires: %02d/%04d\n",expMonth,expYear];
}

//#define MIARE_USE_STORED_KEY
-(bool)mifareAuthenticate:(int)cardIndex address:(int)address key:(NSData *)key error:(NSError **)error
{
    if(key==nil)
    {
        //use the default key
        const uint8_t keyBytes[]={0xFF,0xFF,0xFF,0xFF,0xFF,0xFF};
        key=[NSData dataWithBytes:keyBytes length:sizeof(keyBytes)];
    }
    
#ifdef MIARE_USE_STORED_KEY
    if(![dtdev mfStoreKeyIndex:0 type:'A' key:key error:error])
        return false;
    if(![dtdev mfAuthByStoredKey:cardIndex type:'A' address:address keyIndex:0 error:error])
        return false;
#else
    if(![dtdev mfAuthByKey:cardIndex type:'A' address:address key:key error:error])
        return false;
#endif
    
    return true;
}



//helper func to write some ordinary data on mifare classic cards without touching the sectors containing the sensitive data
//like keys being used
-(bool)mifareSafeWrite:(int)cardIndex address:(int)address data:(NSData *)data key:(NSData *)key error:(NSError **)error
{
    if(address<4) //don't touch the first sector
        return false;
    
    if(![self mifareAuthenticate:cardIndex address:address key:key error:error])
        return nil;
    
    int r;
    int written=0;
    while (written<data.length)
    {
        uint8_t block[16]={0};
        [data getBytes:block range:NSMakeRange(written, MIN(16, data.length-written))];
        
        if((address%4)==3)
        {
            address++;
            if(![self mifareAuthenticate:cardIndex address:address key:key error:error])
                return nil;
        }
        r=[dtdev mfWrite:cardIndex address:address data:[NSData dataWithBytes:block length:sizeof(block)] error:error];
        if(!r)
            return false;
        written+=sizeof(block);
        address++;
    }
    return true;
}

//helper func to read some ordinary data from mifare classic cards without touching the sectors containing the sensitive data
//like keys being used
-(NSData *)mifareSafeRead:(int)cardIndex address:(int)address length:(int)length key:(NSData *)key error:(NSError **)error
{
    if(![self mifareAuthenticate:cardIndex address:address key:key error:error])
        return nil;
    
    NSMutableData *data=[NSMutableData data];
    
    int read=0;
    while (read<length)
    {
        if((address%4)==3)
        {
            address++;
            if(![self mifareAuthenticate:cardIndex address:address key:key error:error])
                return nil;
        }
        
        NSData *block=[dtdev mfRead:cardIndex address:address length:16 error:error];
        if(!block)
            return nil;
        [data appendData:block];
        read+=16;
        address++;
    }
    return data;
}

NSString *dfStatus2String(int status)
{
    switch (status)
    {
        case 0x00:
            return @"OPERATION_OK";
        case 0x0C:
            return @"NO_CHANGES";
        case 0x0E:
            return @"OUT_OF_EEPROM_ERROR";
        case 0x1C:
            return @"ILLEGAL_COMMAND_CODE";
        case 0x1E:
            return @"INTEGRITY_ERROR";
        case 0x40:
            return @"NO_SUCH_KEY";
        case 0x7E:
            return @"LENGTH_ERROR";
        case 0x9D:
            return @"PERMISSION_DENIED";
        case 0x9E:
            return @"PARAMETER_ERROR";
        case 0xA0:
            return @"APPLICATION_NOT_FOUND";
        case 0xA1:
            return @"APPL_INTEGRITY_ERROR";
        case 0xAE:
            return @"AUTHENTICATION_ERROR";
        case 0xAF:
            return @"ADDITIONAL_FRAME";
        case 0xBE:
            return @"BOUNDARY_ERROR";
        case 0xC1:
            return @"PICC_INTEGRITY_ERROR";
        case 0xCD:
            return @"PICC_DISABLED_ERROR";
        case 0xCE:
            return @"COUNT_ERROR";
        case 0xDE:
            return @"DUPLICATE_ERROR";
        case 0xEE:
            return @"EEPROM_ERROR";
        case 0xF0:
            return @"FILE_NOT_FOUND";
        case 0xF1:
            return @"FILE_INTEGRITY_ERROR";
    }
    return @"UNKNOWN";
}

static void memswp(void *p1, const void *p2, uint32_t n)
{
    uint8_t x, *a, *b;
    if (n == 0) return;
    if (p2 == 0) p2 = p1;
    a = (uint8_t*)p1; b = (uint8_t*)p2;
    b = b + n - 1;
    if (p1 == p2)
        while (a<b) { x = *a; *a = *b; *b = x; a++; b--; }
    else
        while (n--) *a++ = *b--;
}


#define DF_CMD(command,description) r=[dtdev iso14Transceive:info.cardIndex data:[NSData dataWithBytes:command length:sizeof(command)] status:&cardStatus error:&error]; \
if(r) [log appendFormat:@"%@ succeed with status: %@ response: %@\n",description,dfStatus2String(cardStatus),r]; else [log appendFormat:@"%@ failed with error: %@\n",description,error.localizedDescription];


-(void)rfCardDetected:(int)cardIndex info:(DTRFCardInfo *)info
{
    //if the stop timer is running, kill it
    if(rfStopTimer!=nil)
    {
        [rfStopTimer invalidate];
    }
    
    NSError *error;
    
#ifndef FELICA_TEST
    [progressViewController viewWillAppear:FALSE];
    [self.view addSubview:progressViewController.view];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
#endif
    
    NSMutableString *log=[[NSMutableString alloc] init];
    [log appendFormat:@"%@ card detected\n",info.typeStr];
    [log appendFormat:@"Serial: %@\n",hexToString(nil,info.UID.bytes,info.UID.length)];
    NSDate *d=[NSDate date];
    switch (info.type)
    {
        case CARD_MIFARE_DESFIRE:
        {
            //delay the communication a bit, giving time the card to be more fully inserted into the field
            //it can happen that the card is detected, but not having enough power to do cryptography
            [NSThread sleepForTimeInterval:0.3];
            NSData *ats=[dtdev iso14GetATS:cardIndex error:&error];
            CHECK_RESULT(@"ATS",ats);
            if(ats)
                [log appendFormat:@"ATS Data: %@\n",hexToString(nil,ats.bytes,ats.length)];
            
            uint8_t SELECT_APPID_MASTER[] = { 0x5A, 0x00, 0x00, 0x00 };
//            uint8_t SELECT_APPID_WRONG[] = { 0x5A, 0x00, 0x00, 0x01 };
            uint8_t AUTH_ROUND_ONE[] = { 0xAA, 0x00 };
            
            NSData *r;
            uint8_t cardStatus;
            
//            DF_CMD(SELECT_APPID_WRONG,@"Select wrong application");
            DF_CMD(SELECT_APPID_MASTER,@"Select master application");
            DF_CMD(AUTH_ROUND_ONE,@"Authenticate round 1");
            
            //            DESFIRE ERROR CODES
            //            0x00 OPERATION_OK
            //            0x0C NO_CHANGES
            //            0x0E OUT_OF_EEPROM_ERROR
            //            0x1C ILLEGAL_COMMAND_CODE
            //            0x1E INTEGRITY_ERROR
            //            0x40 NO_SUCH_KEY
            //            0x7E LENGTH_ERROR
            //            0x9D PERMISSION_DENIED
            //            0x9E PARAMETER_ERROR
            //            0xA0 APPLICATION_NOT_FOUND
            //            0xA1 APPL_INTEGRITY_ERROR
            //            0xAE AUTHENTICATION_ERROR
            //            0xAF ADDITIONAL_FRAME
            //            0xBE BOUNDARY_ERROR
            //            0xC1 PICC_INTEGRITY_ERROR
            //            0xCD PICC_DISABLED_ERROR
            //            0xCE COUNT_ERROR
            //            0xDE DUPLICATE_ERROR
            //            0xEE EEPROM_ERROR
            //            0xF0 FILE_NOT_FOUND
            //            0xF1 FILE_INTEGRITY_ERROR
            
            //            uint16_t apduResult;
            //            NSData *apdu=[dtdev iso14APDU:cardIndex cla:0x00 ins:0x00 p1:0x00 p2:0x00 data:nil apduResult:&apduResult error:&error];
            //            CHECK_RESULT(@"APDU",apdu);
            //            if(apdu!=nil)
            //            {
            //                [log appendFormat:@"APDU Result: %04X\n",apduResult];
            //                [log appendFormat:@"APDU Data: %@\n",hexToString(nil,apdu.bytes,apdu.length)];
            //            }
            break;
        }
    
        case CARD_PICOPASS_15693:
        {
            NSData *r;
            tlv_t *t;
            
            r=[dtdev hidGetSerialNumber:&error];
            CHECK_RESULT(@"Get Serial Number",r);
            t=tlvFind1(r.bytes, r.length, 0x8A);
            if(t)
            {
                [log appendFormat:@"HID Serial: %@\n",hexToString(nil,t->data,t->length)];
            }

            r=[dtdev hidGetVersionInfo:&error];
            CHECK_RESULT(@"Get Version Info",r);
            t=tlvFind1(r.bytes, r.length, 0x8A); //SamResponse
            if(t)
            {
                t=tlvFind1(t->data, t->length, 0x80); //version
                if(t)
                {
                    [log appendFormat:@"Version: %d.%d\n",t->data[0],t->data[1]];
                }
            }
            
            r=[dtdev hidGetContentElement:4 pin:nil rootSoOID:nil error:&error];
            CHECK_RESULT(@"Get Content Element",r);
            t=tlvFind1(r.bytes, r.length, 0x8A); //SamResponse
            if(t)
            {
                t=tlvFind1(t->data, t->length, 0x03); //BitString
                if(t)
                {
                    [log appendFormat:@"Content element: %@\n",hexToString(nil,t->data,t->length)];
                }
            }
            break;
        }
        case CARD_PAYMENT:
            [self payCardDemo:cardIndex log:log];
            break;
        case CARD_MIFARE_MINI:
        case CARD_MIFARE_CLASSIC_1K:
        case CARD_MIFARE_CLASSIC_4K:
        case CARD_MIFARE_PLUS:
        {//16 bytes reading and 16 bytes writing
            //it is best to store the keys you are going to use once in the device memory, then use mfAuthByStoredKey function to authenticate blocks rahter than having the key in your program
            
//            const uint8_t dataToWrite[]={0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F};

//            BOOL r=[self mifareSafeWrite:cardIndex address:8 data:[NSData dataWithBytes:dataToWrite length:sizeof(dataToWrite)] key:nil error:&error];
//            CHECK_RESULT(@"Write blocks",r);
            //try reading a block we authenticated before
            NSData *block=[self mifareSafeRead:cardIndex address:8 length:4*16 key:nil error:&error];
//            NSData *block=[dtdev mfRead:cardIndex address:8 length:16 error:&error];
            CHECK_RESULT(@"Read blocks",block);
            if(block)
                [log appendFormat:@"Data: %@\n",hexToString(nil,(uint8_t *)block.bytes,block.length)];
            break;
            
            
            //            //unsafe
            //            const uint8_t keyBytes[]={0xFF,0xFF,0xFF,0xFF,0xFF,0xFF};
            //
            //            BOOL r=[dtdev mfAuthByKey:cardIndex type:'A' address:8 key:[NSData dataWithBytes:keyBytes length:sizeof(keyBytes)] error:&error];
            //            CHECK_RESULT(@"Authenticate",r);
            //            //write something, be VERY cautious where you write, as you can easily render the card useless forever
            //            r=[dtdev mfWrite:cardIndex address:8 data:[NSData dataWithBytes:dataToWrite length:sizeof(dataToWrite)] error:&error];
            //            CHECK_RESULT(@"Write block",r);
            
        }
        case CARD_MIFARE_ULTRALIGHT:
        case CARD_MIFARE_ULTRALIGHT_C:
        {//16 bytes reading, 4 bytes writing
            [NSThread sleepForTimeInterval:0.5];
            //try reading a block
            NSData *block=[dtdev mfRead:cardIndex address:8 length:16 error:&error];
            CHECK_RESULT(@"Read block",block);
            if(block)
                [log appendFormat:@"Data: %@\n",hexToString(nil,block.bytes,block.length)];
            
            CHECK_RESULT(@"Authenticate",[dtdev mfUlcAuthByKey:cardIndex key:[@"12345678abcdefgh" dataUsingEncoding:NSASCIIStringEncoding] error:&error]);
//            CHECK_RESULT(@"Authenticate",[dtdev mfUlcAuthByKey:cardIndex key:[@"BREAKMEIFYOUCAN!" dataUsingEncoding:NSASCIIStringEncoding] error:&error]);

//                            CHECK_RESULT(@"Write key block",[dtdev mfWrite:cardIndex address:8 data:[@"0000000000000000" dataUsingEncoding:NSASCIIStringEncoding] error:&error]);
            
            block=[dtdev mfRead:cardIndex address:8 length:16 error:&error];
            CHECK_RESULT(@"Read block",block);
            if(block)
                [log appendFormat:@"Data: %@\n",hexToString(nil,block.bytes,block.length)];
            
            if(block)
            {
                //change key

//                CHECK_RESULT(@"Write key block",[dtdev mfWrite:cardIndex address:0x2C data:[@"12345678abcdefgh" dataUsingEncoding:NSASCIIStringEncoding] error:&error]);
            }
            
//            write something to the card
//            const uint8_t dataToWrite[4]={0x00,0x01,0x02,0x03};
//            int r=[dtdev mfWrite:cardIndex address:8 data:[NSData dataWithBytes:dataToWrite length:sizeof(dataToWrite)] error:&error];
//            CHECK_RESULT(@"Write block",r);
            break;
        }
            
        case CARD_ISO15693:
        {//block size is different between cards
            [log appendFormat:@"Block size: %d\n",info.blockSize];
            [log appendFormat:@"Number of blocks: %d\n",info.nBlocks];

            NSData *security=[dtdev iso15693GetBlocksSecurityStatus:cardIndex startBlock:0 nBlocks:16 error:&error];
            CHECK_RESULT(@"Block security status",security);
            if(security)
                [log appendFormat:@"Security status: %@\n",hexToString(nil,(uint8_t *)security.bytes,security.length)];
            
            //write something to the card
            uint8_t dataToWrite[8];
            for(int i=0;i<sizeof(dataToWrite);i++)
                dataToWrite[i]=(uint8_t)i;
            int r=[dtdev iso15693Write:cardIndex startBlock:0 data:[NSData dataWithBytes:dataToWrite length:sizeof(dataToWrite)] error:&error];
            CHECK_RESULT(@"Write blocks",r);
            [log appendFormat:@"\nTime taken: %.02f\n",-[d timeIntervalSinceNow]];

            //try reading 2 blocks
            NSData *block=[dtdev iso15693Read:cardIndex startBlock:0 length:sizeof(dataToWrite) error:&error];
            CHECK_RESULT(@"Read blocks",block);
            if(block)
                [log appendFormat:@"Data: %@\n",hexToString(nil,(uint8_t *)block.bytes,block.length)];
            
            break;
        }
        case CARD_FELICA:
        {//16 byte blocks for both reading and writing
#ifdef FELICA_TEST
            [log appendFormat:@"Time taken: %.02f\n",-felicaDetectDate.timeIntervalSinceNow];

            [log appendFormat:@"PMm: %@\n",hexToString(nil,info.felicaPMm.bytes,info.felicaPMm.length)];
            if(info.felicaRequestData)
                [log appendFormat:@"RQData: %@\n",hexToString(nil,info.felicaRequestData.bytes,info.felicaRequestData.length)];

            int sound[]={2730,150};
            [dtdev playSound:100 beepData:sound length:sizeof(sound) error:nil];
            
            [dtdev rfClose:nil];
            break;
#else
            int sound[]={2730,150};
            [dtdev playSound:100 beepData:sound length:sizeof(sound) error:nil];
            

            //write something to the card
            int r;

            //custom command
            uint8_t readCmd[]={0x01,0x09,0x00,0x01,0x80,0x00};
            NSData *cmdResponse=[dtdev felicaSendCommand:cardIndex command:0x06 data:[NSData dataWithBytes:readCmd length:sizeof(readCmd)] error:&error];
            CHECK_RESULT(@"Custom command",cmdResponse);
            if(cmdResponse)
                [log appendFormat:@"Data: %@\n",hexToString(nil,(uint8_t *)cmdResponse.bytes,cmdResponse.length)];
            
            //check if the card is FeliCa SmartTag or normal felica
            uint8_t *uid=(uint8_t *)info.UID.bytes;
            if(uid[0]==0x03 && uid[1]==0xFE && uid[2]==0x00 && uid[3]==0x1D)
            {//SmartTag
                //read battery, call this command ALWAYS before communicating with the card
                int battery;
                r=[dtdev felicaSmartTagGetBatteryStatus:cardIndex status:&battery error:&error];
                CHECK_RESULT(@"Get battery",r);
                
                NSString *batteryString=@"Unknown";
                
                switch (battery)
                {
                    case FELICA_SMARTTAG_BATTERY_NORMAL1:
                    case FELICA_SMARTTAG_BATTERY_NORMAL2:
                        batteryString=@"Normal";
                        break;
                    case FELICA_SMARTTAG_BATTERY_LOW1:
                        batteryString=@"Low";
                        break;
                    case FELICA_SMARTTAG_BATTERY_LOW2:
                        batteryString=@"Very low";
                        break;
                }
                
                [log appendFormat:@"Battery status: %@(%d)\n",batteryString,battery];
                
                //perform read/write operations before screen access
                uint8_t dataToWrite[32];
                static uint8_t val=0;
                memset(dataToWrite,val,sizeof(dataToWrite));
                val++;
                r=[dtdev felicaSmartTagWrite:cardIndex address:0x0000 data:[NSData dataWithBytes:dataToWrite length:sizeof(dataToWrite)-5] error:&error];
                CHECK_RESULT(@"Write data",r);
                //try reading 2 blocks
                NSData *block=[dtdev felicaSmartTagRead:cardIndex address:0x0000 length:sizeof(dataToWrite) error:&error];
                CHECK_RESULT(@"Read data",block);
                if(block)
                    [log appendFormat:@"Data: %@\n",hexToString(nil,(uint8_t *)block.bytes,block.length)];
                
//                r=[dtdev felicaSmartTagClearScreen:cardIndex error:&error];
//                CHECK_RESULT(@"Clear screen",r);
//                r=[dtdev felicaSmartTagWaitCompletion:cardIndex error:&error];
//                CHECK_RESULT(@"Wait to complete",r);
//                r=[dtdev felicaSmartTagDisplayLayout:cardIndex layout:1 error:&error];
//                CHECK_RESULT(@"Display layout",r);
                
                UIImage *image=[UIImage imageNamed:@"paypass_logo.bmp"];
                r=[dtdev felicaSmartTagDrawImage:cardIndex image:[UIImage imageNamed:@"paypass_logo.bmp"] topLeftX:(200-image.size.width)/2 topLeftY:(96-image.size.height)/2 drawMode:FELICA_SMARTTAG_DRAW_WHITE_BACKGROUND layout:0 error:&error];
                CHECK_RESULT(@"Draw image",r);
//                UIImage *image=[UIImage imageNamed:@"rftaz.png"];
//                r=[dtdev felicaSmartTagDrawImage:cardIndex image:image topLeftX:(200-image.size.width)/2 topLeftY:0 drawMode:0 layout:0 error:&error];
//                CHECK_RESULT(@"Draw image",r);
//                r=[dtdev felicaSmartTagSaveLayout:cardIndex layout:1 error:&error];
//                CHECK_RESULT(@"Save layout",r);
            }else
            {//Normal
                uint8_t dataToWrite[16]={0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F};
                
                //write 1 block
                r=[dtdev felicaWrite:cardIndex serviceCode:0x0900 startBlock:0 data:[NSData dataWithBytes:dataToWrite length:sizeof(dataToWrite)] error:&error];
                CHECK_RESULT(@"Write blocks",r);
                
                //read 1 block
                NSData *block=[dtdev felicaRead:cardIndex serviceCode:0x0900 startBlock:0 length:sizeof(dataToWrite) error:&error];
                CHECK_RESULT(@"Read blocks",block);
                if(block)
                    [log appendFormat:@"Data: %@\n",hexToString(nil,(uint8_t *)block.bytes,block.length)];
            }
#endif
            break;
        }
        case CARD_ST_SRI:
        {//4 byte blocks for both reading and writing
            [log appendFormat:@"Block size: %d\n",info.blockSize];
            [log appendFormat:@"Number of blocks: %d\n",info.nBlocks];
            
            //write something to the card
            const uint8_t dataToWrite[4]={0x00,0x01,0x02,0x03};
            int r=[dtdev stSRIWrite:cardIndex address:8 data:[NSData dataWithBytes:dataToWrite length:sizeof(dataToWrite)] error:&error];
            CHECK_RESULT(@"Write blocks",r);
            [log appendFormat:@"\nTime taken: %.02f\n",-[d timeIntervalSinceNow]];
            
            //try reading 2 blocks
            NSData *block=[dtdev stSRIRead:cardIndex address:8 length:2*info.blockSize error:&error];
            CHECK_RESULT(@"Read blocks",block);
            if(block)
                [log appendFormat:@"Data: %@\n",hexToString(nil,(uint8_t *)block.bytes,block.length)];
        }
        case CARD_EPASSPORT:
        {
            uint16_t apduResult;
            //select lds
            CHECK_RESULT(@"Select LDS",[dtdev iso14APDU:cardIndex cla:0x00 ins:0xA4 p1:0x02 p2:0x0C data:stringToData(@"A0 00 00 02 47 10 01") apduResult:&apduResult error:&error]);

            CHECK_RESULT(@"Check for BAC",[dtdev iso14APDU:cardIndex cla:0x00 ins:0xA4 p1:0x02 p2:0x0C data:stringToData(@"01 1E") apduResult:&apduResult error:&error]);
            
            if(apduResult==0x6982)
            {
                [log appendString:@"BAC required!\n"];
            }else
            {
                [log appendString:@"BAC not required!\n"];
            }
        }
    }
 	[progressViewController.view removeFromSuperview];
    
    [log appendFormat:@"\nTime taken: %.02f\n",-[d timeIntervalSinceNow]];
    [log appendFormat:@"Please remove card"];
    
    if(error)
    {
        logView.backgroundColor=[UIColor colorWithRed:1 green:0 blue:0 alpha:0.3];
    }else
    {
        nRFCardSuccess++;
        logView.backgroundColor=[UIColor colorWithRed:0 green:1 blue:0 alpha:0.3];
    }
    
    nRFCards++;
    [log insertString:[NSString stringWithFormat:@"nRFCards: %d, success: %d, failed: %d\n",nRFCards,nRFCardSuccess,nRFCards-nRFCardSuccess] atIndex:0];
    [logView setText:log];
    
#ifndef FELICA_TEST
    [dtdev rfRemoveCard:cardIndex error:nil];
#endif
}

-(void)viewWillDisappear:(BOOL)animated
{
    if(rfStopTimer!=nil)
    {
        [rfStopTimer invalidate];
        rfStopTimer=nil;
    }
    
    [super viewWillDisappear:animated];
    [dtdev rfClose:nil];
}

#ifdef FELICA_TEST

-(void)detectStopTimerFunc
{
    if(rfStopTimer!=nil)
    {
        [rfStopTimer invalidate];
        rfStopTimer=nil;
    }
    [logView setText:@"Detection stopped"];
    [dtdev rfClose:nil];
}

int gain[]={0,-100,-250,-500,-1000};
int gindex=0;
NSTimer *fieldGainTimer;
-(void)fieldGainFunc
{
    NSError *error;
    RF_COMMAND(@"RF Init: gain",[dtdev rfInit:0 fieldGain:gain[gindex] error:&error]);
    RF_COMMAND(@"RF off",[dtdev rfFieldControlOnChannel:RF_CHANNEL_FELICA enabled:false error:&error]);
    RF_COMMAND(@"RF on",[dtdev rfFieldControlOnChannel:RF_CHANNEL_FELICA enabled:true error:&error]);
    logView.text=[logView.text stringByAppendingFormat:@"Field on with gain: %d\n",gain[gindex]];


    gindex++;
    if(gindex==5)
    {
        gindex=0;
        [fieldGainTimer invalidate];
    }
}

NSDate *felicaDetectDate=nil;

-(IBAction)onFelica:(id)sender
{
    NSError *error;

//    [dtdev felicaSetPollingParamsRequestCode:0x00 systemCode:0xFFFF timeSlot:3 detectionTimeMS:50 intervalTimeMS:200 error:&error];
//    //initialize detection with felica only active, waiting for rfCardDetected to be called
//    [dtdev rfInit:CARD_SUPPORT_FELICA error:&error];
    
    [progressViewController viewWillAppear:FALSE];
    [self.view addSubview:progressViewController.view];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    

    
    NSError* err;
    dtdev = [DTDevices sharedDevice];
    [dtdev felicaSetPollingParamsRequestCode:1 /* variable from RAS */
                                  systemCode: 3 /* variable from RAS */
                                    timeSlot: 3 /* variable  from RAS */
                             detectionTimeMS: 20 /* immediate */
                              intervalTimeMS: 100 /* immediate */
                                       error: &err];
        felicaDetectDate=[NSDate date];
    [dtdev rfInit:CARD_SUPPORT_FELICA error:&err];
    
    
}

#endif

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSError *error;
    logView.backgroundColor=[UIColor colorWithRed:0 green:0 blue:1 alpha:0.3];
    logView.text=@"";

#ifdef FELICA_TEST
//    gindex=0;
//    fieldGainTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(fieldGainFunc) userInfo:nil repeats:true];
//    return;

    //felica based demo code
    //set felica polling parameters
//    RF_COMMAND(@"RF Set Felica Polling",[dtdev felicaSetPollingParamsRequestCode:0x00 systemCode:0xFFFF timeSlot:3 detectionTimeMS:50 intervalTimeMS:200 error:&error]);
    //initialize detection with felica only active, waiting for rfCardDetected to be called
//    RF_COMMAND(@"RF Init",[dtdev rfInit:CARD_SUPPORT_FELICA error:&error]);
    //sets a timer that will disable detection in 30 seconds
//    rfStopTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(detectStopTimerFunc) userInfo:nil repeats:false];
    
//    NSError* err;
//    dtdev = [DTDevices sharedDevice];
//    [dtdev felicaSetPollingParamsRequestCode:1 /* variable from RAS */
//                                systemCode: 3 /* variable from RAS */
//                                  timeSlot: 3 /* variable  from RAS */
//                           detectionTimeMS: 20 /* immediate */
//                            intervalTimeMS: 100 /* immediate */
//                                     error: &err];
//    [dtdev rfInit:CARD_SUPPORT_FELICA error:&err];
#else
//    RF_COMMAND(@"RF Init",[dtdev rfInit:CARD_SUPPORT_FELICA error:&error]);
    RF_COMMAND(@"RF Init",[dtdev rfInit:CARD_SUPPORT_PICOPASS_ISO15|CARD_SUPPORT_TYPE_A|CARD_SUPPORT_TYPE_B|CARD_SUPPORT_ISO15|CARD_SUPPORT_FELICA error:&error]);
#endif


    //demo of manual rf card query (felica in this case with custom parameters
    //rfInit with 0 disables the automatic scanning code, so manual only is supported
//    RF_COMMAND(@"RF Init",[dtdev rfInit:0 error:&error]);
//    while (true)
//    {
//        //poll
//        //system code[2b], request code [1b], time slot[1b], detect timeoutms[2b], idle timeoutms[2b], total timeoutsec[2b]
//        int totalTimeout = 30; //seconds
//        int idletimeout = 200; //milliseconds
//        uint8_t felica[] = { /*system code*/ 0xFF, 0xFF, /*request code*/ 0x00, /*time slot*/ 0x03, /*detect timeoutms*/ 0x00, 0x10, /*idle timeoutms*/ idletimeout>>8, idletimeout, /*total timeoutms*/ totalTimeout>>8, totalTimeout };
//        
//        DTRFCardInfo *info=[dtdev rfDetectCardOnChannel:RF_CHANNEL_FELICA additionalData:[NSData dataWithBytes:felica length:sizeof(felica)] timeout:(double)(totalTimeout+1) error:&error];
//        if(info)
//        {
//            NSLog(@"Card detected %@",info);
//            
//            //requestservice
//            NSData *serviceResponse=[dtdev felicaSendCommand:info.cardIndex command:0x02 data:stringToData(@"0e ff ff 00 00 40 00 00 08 c0 0f 00 10 4a 00 88 00 10 08 c8 08 0c 09 08 10 4a 10 8c 10") error:&error];
//            NSLog(@"Service response: %@",serviceResponse);
//            
//            //request the service again, using felicatransieve command
//            NSMutableData *cmd=[NSMutableData data];
//            [cmd appendData:stringToData(@"02")];
//            [cmd appendData:info.UID];
//            [cmd appendData:stringToData(@"0e ff ff 00 00 40 00 00 08 c0 0f 00 10 4a 00 88 00 10 08 c8 08 0c 09 08 10 4a 10 8c 10")];
//            serviceResponse=[dtdev felicaTransieve:info.cardIndex data:cmd error:&error];
//            NSLog(@"Service1 response: %@",serviceResponse);
//
//
//            NSData *auth1Response=[dtdev felicaSendCommand:info.cardIndex command:0x10 data:stringToData(@"05 00 00 40 00 00 08 c0 0f 00 10 08 4a 00 88 00 10 08 c8 08 0c 09 08 10 4a 10 8c 10 83 d5 2e 3c a6 31 09 40") error:&error];
//            NSLog(@"Auth1 response: %@",auth1Response);
//            
//            NSData *auth2Response=[dtdev felicaSendCommand:info.cardIndex command:0x12 data:stringToData(@"cf 60 1b a8 73 1a bd a1") error:&error];
//            NSLog(@"Auth2 response: %@",auth2Response);
//            
////            NSData *block=[dtdev felicaRead:info.cardIndex serviceCode:0x0900 startBlock:0 length:16 error:&error];
////            NSLog(@"Data read: %@",block);
//        }else
//            NSLog(@"Card not detected");
//    }
}

-(void)viewDidLoad
{
	dtdev=[DTDevices sharedDevice];
    [dtdev addDelegate:self];
    [super viewDidLoad];
}


@end

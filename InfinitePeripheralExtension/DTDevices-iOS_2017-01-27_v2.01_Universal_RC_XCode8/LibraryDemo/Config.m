#import "Config.h"
#import "XMLParser.h"
#import "EMVTLV.h"

@implementation Config

static const uint8_t KEY_PPAD_TEST_HMK[16]={0x1A,0xC4,0xF2,0x34,0x79,0xCD,0x8F,0x23,0x0B,0xC4,0x9D,0x2C,0x98,0xC8,0x91,0xEA};
static const uint8_t KEY_PPAD_TEST_KEK_BDK[16]={0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF,0xFE,0xDC,0xBA,0x98,0x76,0x54,0x32,0x10};


static const uint8_t KEY_DUKPT_BDK[16]={0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF,0xFE,0xDC,0xBA,0x98,0x76,0x54,0x32,0x10};
static const uint8_t KEY_DUKPT_KSN_1[10]={0xFF,0xFF,0x98,0x76,0x54,0x32,0x10,0x00,0x00,0x00};
static const uint8_t KEY_DUKPT_KSN_2[10]={0xFF,0xFF,0x98,0x76,0x54,0x32,0x11,0x00,0x00,0x00};

static const uint8_t KEY_AES128_1[32]={'1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0'};
static const uint8_t KEY_AES128_2[32]={'1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','2','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0'};
static const uint8_t KEY_AES128_3[32]={'1','1','1','1','1','1','1','1','1','1','1','1','1','1','1','3','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0'};

static const uint8_t KEY_3DES_PIN[16]={0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11,0x11};
static const uint8_t KEY_3DES_DATA[16]={0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31};

+(NSData *)getDUKPTBDK
{
    return [NSData dataWithBytes:KEY_DUKPT_BDK length:sizeof(KEY_DUKPT_BDK)];
}

+(NSData *)getDUKPTKSN1
{
    return [NSData dataWithBytes:KEY_DUKPT_KSN_1 length:sizeof(KEY_DUKPT_KSN_1)];
}

+(NSData *)getDUKPTKSN2
{
    return [NSData dataWithBytes:KEY_DUKPT_KSN_2 length:sizeof(KEY_DUKPT_KSN_2)];
}

+(NSData *)getAES128Key1
{
    return [NSData dataWithBytes:KEY_AES128_1 length:sizeof(KEY_AES128_1)];
}

+(NSData *)getAES128Key2
{
    return [NSData dataWithBytes:KEY_AES128_2 length:sizeof(KEY_AES128_2)];
}

+(NSData *)getAES128Key3
{
    return [NSData dataWithBytes:KEY_AES128_3 length:sizeof(KEY_AES128_3)];
}

+(NSData *)get3DESDataKey
{
    return [NSData dataWithBytes:KEY_3DES_DATA length:sizeof(KEY_3DES_DATA)];
}

+(NSData *)get3DESPINKey
{
    return [NSData dataWithBytes:KEY_3DES_PIN length:sizeof(KEY_3DES_PIN)];
}

+(NSData *)getPPadTestKEKBDK
{
    return [NSData dataWithBytes:KEY_PPAD_TEST_KEK_BDK length:sizeof(KEY_PPAD_TEST_KEK_BDK)];
}

+(NSData *)parseTagData:(NSDictionary *)tagData
{
    NSString * data = [tagData valueForKey:@"id"];
    uint t=[TLV tagFromHexString:data];

    NSDictionary *subtags=[tagData valueForKey:@"tag"];

    if(subtags!=nil)
    {
        if([subtags isKindOfClass:[NSArray class]])
        {
            NSMutableData *d=[NSMutableData data];
            for (NSDictionary *stag in subtags)
            {
                [d appendData:[self parseTagData:stag]];
            }
            NSData *tag = [TLV tlvWithData:d tag:t].encodedData;
            return tag;
        }else
        {
            NSData *d=[self parseTagData:subtags];
            NSData *tag = [TLV tlvWithData:d tag:t].encodedData;
            return tag;
        }
    }else
    {
        TLV *tag = [TLV tlvWithHexString:[tagData valueForKey:@"text"] tag:t];
        return tag.encodedData;
    }
}

+(NSData *)paymentGetConfigurationFromXML:(NSString *)configFile
{
    NSString *file=[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Config"] stringByAppendingPathComponent:configFile];

    NSString *xml=[NSString stringWithContentsOfFile:file encoding:NSASCIIStringEncoding error:nil];
    if(!xml)
        return nil;

    NSDictionary *parsed = [XMLParser dictionaryForXMLString:xml error:nil];
    if(!parsed)
        return nil;

    //generate tag list
    NSDictionary *main=[parsed valueForKey:@"taglist"];
    if(main!=nil)
    {
        NSArray *tags=[main valueForKey:@"tag"];
        NSMutableData *d=[NSMutableData data];
        for (NSDictionary *tag in tags)
        {
            NSData *tagd=[self parseTagData:tag];
            [d appendData:tagd];
        }
        return d;
    }
    return nil;
}

@end

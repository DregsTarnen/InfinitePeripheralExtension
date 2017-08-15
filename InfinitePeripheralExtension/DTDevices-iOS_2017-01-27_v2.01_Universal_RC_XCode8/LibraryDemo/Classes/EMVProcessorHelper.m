#import "EMVProcessorHelper.h"


@implementation EMVProcessorHelper

uint8_t encodeToBCD(NSUInteger value)
{
    return (uint8_t)(((value / 10) << 4) | (value % 10));
}

+(NSData *)encodeTransactionDate:(NSDate *)date
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    
    uint8_t result[3];
    result[0] = encodeToBCD(components.year-2000);
    result[1] = encodeToBCD(components.month);
    result[2] = encodeToBCD(components.day);
    return [NSData dataWithBytes:result length:sizeof(result)];
}

+(NSData *)encodeTransactionTime:(NSDate *)date
{
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:date];
    
    uint8_t result[3];
    result[0] = encodeToBCD(components.hour);
    result[1] = encodeToBCD(components.minute);
    result[2] = encodeToBCD(components.second);
    return [NSData dataWithBytes:result length:sizeof(result)];
}

+(NSData *)encodeTransactionSequence:(int)value
{
    uint8_t result[3];
    result[0] = encodeToBCD(value / 10000);
    result[1] = encodeToBCD((value / 100) % 100);
    result[2] = encodeToBCD(value % 100);
    return [NSData dataWithBytes:result length:sizeof(result)];
}

+(NSData *)encodeAmount:(double)amount
{
    int v = (int)(amount * 100 + 0.5);
    uint8_t result[] = { (uint8_t)(v >> 24), (uint8_t)(v >> 16), (uint8_t)(v >> 8), (uint8_t)(v) };
    return [NSData dataWithBytes:result length:sizeof(result)];
}

+(NSString *)decodeNib:(NSData *)value
{
    if(!value)
        return nil;
    
    NSMutableString *sb=[NSMutableString string];

    const uint8_t *bytes=value.bytes;
    for (int i=0;i<value.length;i++)
    {
        int v = (int)bytes[i] & 0xff;
        int f = v >> 4;
        int s = v & 0xf;
        
        if (f > 9) {
            if (f != 0xf)
                return nil;
            } else {
                [sb appendFormat:@"%c",(char)(48 + f)];
        }
        
        if (s > 9) {
            if (s != 0xf)
                return nil;
        } else {
            [sb appendFormat:@"%c",(char)(48 + s)];
        }
    }
    
    return sb;
}

+(NSString *)decodeASCII:(NSData *)value
{
    if(!value)
        return nil;
    
    return [[NSString alloc] initWithData:value encoding:NSASCIIStringEncoding];
}

+(int)decodeInt:(NSData *)value
{
    if(!value)
        return 0;
    
    int n = 0;
    
    const uint8_t *bytes=value.bytes;
    for (int i=0;i<value.length;i++)
    {
        n = (n << 8) + (bytes[i] & 0xff);
    }
    
    return n;
}

+(NSString *)decodeDateString:(NSData *)value
{
    if(!value)
        return nil;

    NSString *s = [self decodeNib:value];
    return [NSString stringWithFormat:@"20%@-%@-%@", [s substringWithRange:NSMakeRange(0, 2)] ,[s substringWithRange:NSMakeRange(2, 2)], [s substringWithRange:NSMakeRange(4, 2)]];
}

+(NSString *)decodeTimeString:(NSData *)value
{
    if(!value)
        return nil;

    NSString *s = [self decodeNib:value];
    return [NSString stringWithFormat:@"%@:%@:%@", [s substringWithRange:NSMakeRange(0, 2)] ,[s substringWithRange:NSMakeRange(2, 2)], [s substringWithRange:NSMakeRange(4, 2)]];
}

+(NSString *)decodeAmountString:(NSData *)value
{
    if(!value)
        return nil;
    
    long amount = 0;
    
    const uint8_t *bytes=value.bytes;
    for (int i=0;i<value.length;i++)
    {
        amount = amount << 8;
        amount += (int)bytes[i] & 0xff;
    }
    
    return [NSString stringWithFormat:@"%d.%02d",(int)(amount/100), (int)(amount%100)];
}

+(NSString *)decodeHexString:(NSData *)value
{
    if(!value)
        return nil;
    
    char hex[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};
    char buf[value.length * 2 + 1];
    
    const uint8_t *bytes=value.bytes;
    for (int i = 0; i < value.length; i++)
    {
        buf[i * 2 + 0] = hex[(bytes[i] & 0xff) >> 4];
        buf[i * 2 + 1] = hex[(bytes[i] & 0x0f) >> 0];
    }
    buf[sizeof(buf)-1]=0;
    
    return [NSString stringWithCString:buf encoding:NSASCIIStringEncoding];
}

+(NSString *)getMaskedString:(NSString *)value unmaskedAtStart:(int)unmaskedAtStart unmaskedAtEnd:(int)unmaskedAtEnd
{
    if(!value)
        return nil;
    
    char result[value.length+1];
    
    for (int i = 0; i<value.length; i++)
    {
        if(i>=unmaskedAtStart && i<(value.length-unmaskedAtEnd))
            result[i]='*';
        else
            result[i]=[value characterAtIndex:i];
    }
    result[sizeof(result)-1]=0;
    return [NSString stringWithCString:result encoding:NSASCIIStringEncoding];
}

//+(NSData *)tlvMake:(NSDictionary *)parsed
//{
//    NSMutableData *r=[NSMutableData data];
//    
//    NSEnumerator *e = [parsed keyEnumerator];
//    NSString *key = nil;
//    while((key = [e nextObject]) != nil)
//    {
//        id obj=[parsed objectForKey:key];
//        NSData *data = nil;
//        
//        if([obj isKindOfClass:[NSData class]])
//            data=obj;
//        else
//        {
//            if([obj isKindOfClass:[NSString class]])
//                data=[(NSString *)obj dataUsingEncoding:NSASCIIStringEncoding];
//            else
//                data=[[NSString stringWithFormat:@"%@",obj] dataUsingEncoding:NSASCIIStringEncoding];
//        }
//        
//        
//        key=[key lowercaseString];
//        int tag=0;
//        for(int i=0;i<key.length;i++)
//        {
//            char c=[key characterAtIndex:i];
//            tag<<=4;
//            if(c>='0' && c<='9')
//                tag|=(c-'0');
//            else
//                tag|=(c-'a')+10;
//        }
//        uint8_t hdr[4];
//        int hdrLen=0;
//        if(tag&0xff00)
//            hdr[hdrLen++]=(tag>>8);
//        hdr[hdrLen++]=tag;
//        int dataLen=data?data.length:0;
//        if(dataLen>127)
//        {//long form
//            hdr[hdrLen++]=0x80|(dataLen>>8);
//        }
//        hdr[hdrLen++]=dataLen;
//        [r appendBytes:hdr length:hdrLen];
//        if(dataLen)
//            [r appendData:data];
//    }
//    
//	return r;
//}
//
//+(NSDictionary *)tlvParse:(NSData *)data
//{
//    const uint8_t *bytes=data.bytes;
//    int length=data.length;
//    
//    if(!data || data.length==0)
//        return nil;
//    
//    NSMutableDictionary *r=[NSMutableDictionary dictionary];
//    
//    for(int i=0;i<length;)
//    {
//        unsigned char t=bytes[i++];
//        
//		int tag=t;
//        //		tlv.tagClass=t>>6;
//        
//		if((tag&0x1F)==0x1F)
//		{//2byte tag
//			tag<<=8;
//			tag|=bytes[i++];
//		}
//        
//		int tagLen=0;
//        
//        if(bytes[i]&0x80)
//        {//long form
//            int nBytes=bytes[i++]&0x7f;
//            for(int j=0;j<nBytes;i++,j++)
//            {
//                tagLen<<=8;
//                tagLen|=bytes[i];
//            }
//        }else
//        {//short form
//            tagLen=bytes[i++]&0x7f;
//        }
//        if(tagLen>4096)
//            return 0;
//        
//        [r setValue:[NSData dataWithBytes:&bytes[i] length:tagLen] forKey:[NSString stringWithFormat:@"%x",tag]];
//        
//        i+=tagLen;
//    }
//    
//    return r;
//}


@end

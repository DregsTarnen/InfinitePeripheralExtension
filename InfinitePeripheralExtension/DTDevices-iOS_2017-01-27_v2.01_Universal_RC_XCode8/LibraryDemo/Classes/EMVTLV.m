#import "EMVTLV.h"


@implementation TLV

-(NSData *)encodedData
{
    return [TLV encodeTags:@[self]];
}

-(const unsigned char *)bytes
{
    if(self.data)
    {
        return self.data.bytes;
    }
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

static NSData *encodeToBCD(UInt64 value, int nBytes)
{
    uint8_t r[30];
    for (int i = 0; i < nBytes; i++)
    {
        r[nBytes - i - 1] = (uint8_t)(value % 10);
        value /= 10;
        r[nBytes - i - 1] |= (uint8_t)((value % 10) << 4);
        value /= 10;
    }
    return [NSData dataWithBytes:r length:nBytes];
}

+(NSArray *)decodeTagList:(NSData *)data;
{
    NSMutableArray *r=[NSMutableArray array];
    const uint8_t *bytes=data.bytes;

    for(int i=0;i<data.length;)
    {
        unsigned int tag=bytes[i++];

        if((tag&0x1F)==0x1F || tag==0xCF)
        {//2byte tag
            tag<<=8;
            tag|=bytes[i++];

            if(tag!=0xDFDC) //specific
            {
                if ((bytes[i - 1] & 0x80) > 0)
                {//3 byte tag
                    tag <<= 8;
                    tag |= bytes[i++];

                    if ((bytes[i - 1] & 0x80) > 0)
                    {//4 byte tag
                        tag <<= 8;
                        tag |= bytes[i++];
                    }
                }
            }
        }
        [r addObject:[NSNumber numberWithUnsignedInt:tag]];
    }
    return r;
}

+(NSData *)encodeTagList:(NSArray *)data;
{
    NSMutableData *r=[NSMutableData data];

    for (NSNumber *tag in data)
    {
        unsigned int t = tag.unsignedIntValue;

        uint8_t hdr[8];
        int hdrLen=0;

        if ((t & 0xff000000) != 0)
            hdr[hdrLen++]=(t>>24);
        if ((t & 0xff0000) != 0)
            hdr[hdrLen++]=(t>>16);
        if ((t & 0xff00) != 0)
            hdr[hdrLen++]=(t>>8);
        hdr[hdrLen++]=t;

        [r appendBytes:hdr length:hdrLen];
    }

    return r;
}

+(uint)tagFromHexString:(NSString *)string
{
    NSData *d=stringToData(string);
    const uint8_t *b = d.bytes;
    uint tag = 0;
    for(int i=0;i<d.length;i++)
    {
        tag<<=8;
        tag|=b[i];
    }
    return tag;
}

+(TLV *)tlvWithInt:(UInt64)data nBytes:(int)nBytes tag:(uint)tag;
{
    uint8_t r[30];
    for (int i = 0; i < nBytes; i++, data >>= 8)
        r[nBytes - i - 1] = (uint8_t)data;
    return [self tlvWithData:[NSData dataWithBytes:r length:nBytes] tag:tag];
}

+(TLV *)tlvWithBCD:(UInt64)data nBytes:(int)nBytes tag:(uint)tag;
{
    return [self tlvWithData:encodeToBCD(data, nBytes) tag:tag];
}

+(TLV *)tlvWithString:(NSString *)data tag:(uint)tag;
{
    return [self tlvWithData:[data dataUsingEncoding:NSASCIIStringEncoding] tag:tag];
}

+(TLV *)tlvWithHexString:(NSString *)data tag:(uint)tag;
{
    return [self tlvWithData:stringToData(data) tag:tag];
}

+(TLV *)tlvWithData:(NSData *)data tag:(uint)tag;
{
    TLV *tlv=[[TLV alloc] init];
    tlv.tag=tag;
    tlv.data=data;
    return tlv;
}

+(TLV *)findLastTag:(int)tag tags:(NSArray *)tags
{
    NSArray *r=[self findTag:tag tags:tags];
    if(r)
        return [r objectAtIndex:r.count-1];
    return nil;
}

+(NSArray *)findTag:(int)tag tags:(NSArray *)tags
{
    NSMutableArray *r=[NSMutableArray array];
    
    for (TLV *tlv in tags) {
        if(tlv.tag==tag)
        {
            [r addObject:tlv];
        }
    }
    if(r.count>0)
        return r;
    return nil;
}

+(NSMutableArray *)decodeTags:(NSData *)data
{
    const uint8_t *bytes=data.bytes;
    int length=(int)data.length;

    if(!data || data.length==0)
        return nil;

    NSMutableArray *r=[NSMutableArray array];

    for(int i=0;i<length;)
    {
        unsigned char t=bytes[i++];

        TLV *tlv=[[TLV alloc] init];

        tlv.tag=t;
        //		tlv.tagClass=t>>6;

        if((tlv.tag&0x1F)==0x1F || tlv.tag==0xCF)
        {//2byte tag
            tlv.tag<<=8;
            tlv.tag|=bytes[i++];

            if(tlv.tag!=0xDFDC) //specific
            {
                if ((bytes[i - 1] & 0x80) > 0)
                {//3 byte tag
                    tlv.tag <<= 8;
                    tlv.tag |= bytes[i++];

                    if ((bytes[i - 1] & 0x80) > 0)
                    {//4 byte tag
                        tlv.tag <<= 8;
                        tlv.tag |= bytes[i++];
                    }
                }
            }
        }

        int tagLen=0;

        if(bytes[i]&0x80)
        {//long form
            int nBytes=bytes[i++]&0x7f;
            for(int j=0;j<nBytes;i++,j++)
            {
                tagLen<<=8;
                tagLen|=bytes[i];
            }
        }else
        {//short form
            tagLen=bytes[i++]&0x7f;
        }
        if(tagLen>4096)
            return 0;

        tlv.data=[NSData dataWithBytes:&bytes[i] length:tagLen];
        [r addObject:tlv];

        i+=tagLen;
    }
    return r;
}

+(NSData *)encodeTags:(NSArray *)tags
{
    NSMutableData *r=[NSMutableData data];

    for (TLV *tag in tags)
    {
        uint8_t hdr[16];
        int hdrLen=0;

        if ((tag.tag & 0xff000000) != 0)
            hdr[hdrLen++]=(tag.tag>>24);
        if ((tag.tag & 0xff0000) != 0)
            hdr[hdrLen++]=(tag.tag>>16);
        if ((tag.tag & 0xff00) != 0)
            hdr[hdrLen++]=(tag.tag>>8);
        hdr[hdrLen++]=tag.tag;
        int dataLen=tag.data?(int)tag.data.length:0;
        if(dataLen>127)
        {//long form
            hdr[hdrLen++]=0x82;
            hdr[hdrLen++]=dataLen>>8;
        }
        hdr[hdrLen++]=dataLen;
        [r appendBytes:hdr length:hdrLen];
        if(dataLen)
            [r appendData:tag.data];
    }
    
    return r;
}

-(NSString *)description
{
    if(self.tag==0xD3 || self.tag==0xD4)
        return [NSString stringWithFormat:@"Tag: %x (%@)",self.tag,[[NSString alloc] initWithData:self.data encoding:NSASCIIStringEncoding]];
    else
        return [NSString stringWithFormat:@"Tag: %x (%@)",self.tag,self.data];
}

@end
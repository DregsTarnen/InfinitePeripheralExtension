#include "bertlv.h"
#include <string.h>

#define CLASS_UNIVERSAL 0x00
#define CLASS_APPLICATION 0x01
#define CLASS_CONTEXT_SPECIFIC 0x02
#define CLASS_PRIVATE 0x03
    
#define TYPE_PRIMITIVE 0x00
#define TYPE_CONSTRUCTED (1<<5)

static tlv_t tlv;

int tlvMakeTag(unsigned long tag, const unsigned char *inData, int inLength, unsigned char *outData)
{
	int outLen=0;
	if(tag&0xff00)
		outData[outLen++]=(tag>>8);
	outData[outLen++]=tag;
	if(inLength>127)
	{//long form
		outData[outLen++]=0x80|(inLength>>8);
	}
	outData[outLen++]=inLength;
	if(inData && inLength)
		memcpy(&outData[outLen],inData,inLength);
	outLen+=inLength;
	return outLen;
}

tlv_t *tlvFindArray(const unsigned char *data, size_t length, const unsigned long tags[])
{
	tlv_t *found=0;
	for(int i=0;tags[i];i++)
	{
		found=tlvFind1(data,length,tags[i]);
		if(!found)
			return 0;
		data=found->data;
		length=found->length;
	}
	return found;
}

static const char *_parseTag(const char *data, unsigned long *tag)
{
	*tag=0;
	while(1)
	{
		*tag<<=4;

		char c=*data;
		if(c>='0' && c<='9')
		{
			*tag|=c-'0';
		}else
		{
			if(c>='a' && c<='f')
				c&=(~0x20);
			if(c>='A' && c<='F')
				*tag|=(c-'A'+10);
			else
			{
				*tag>>=4;
                if(c)
                    data++;
				break;
			}
		}

		data++;
	}
	return data;
}

tlv_t *tlvFind(const unsigned char *data, size_t length, const char *tags)
{
	tlv_t *found=0;
	while(1)
	{
		unsigned long tag;
		tags=_parseTag(tags,&tag);
		if(!tag)
			break;
		found=tlvFind1(data,length,tag);
		if(!found)
			return 0;
		data=found->data;
		length=found->length;
	}
	return found;
}

tlv_t *tlvFind1(const unsigned char *data, size_t length, unsigned long tag)
{
    for(int i=0;i<length;)
    {
        unsigned char t=data[i++];
        if(i>=length)return NULL;
        
		tlv.tag=t;
		tlv.tagClass=t>>6;
        tlv.constructed=(t&TYPE_CONSTRUCTED)!=0;

		if((tlv.tag&0x1F)==0x1F)
		{//2byte tag
			tlv.tag<<=8;
			tlv.tag|=data[i++];
		}
        if(i>=length)return NULL;

		tlv.length=0;
        
        if(data[i]&0x80)
        {//long form
            int nBytes=data[i++]&0x7f;
            if(nBytes>2)return NULL;
            for(int j=0;j<nBytes;i++,j++)
            {
                if(i>=length)return NULL;
                tlv.length<<=8;
                tlv.length|=data[i];
            }
        }else
        {//short form
            tlv.length=data[i++]&0x7f;
        }
        if(tlv.length>4096 || i+tlv.length>length)
            return 0;

		tlv.data=&data[i];

		if(tag==tlv.tag)
			return &tlv;
        
        if(!tlv.constructed)
            i+=tlv.length;
    }
    
    return 0;
}

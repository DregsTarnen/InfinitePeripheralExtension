#define TYPE_INTEGER 0x02
#define TYPE_BIT_STRING 0x03
#define TYPE_OCTET_STRING 0x04
#define TYPE_NULL 0x05
#define TYPE_OBJECT_IDENTIFIER 0x06
#define TYPE_SEQUENCE 0x10
#define TYPE_SET 0x11
#define TYPE_PrintableString 0x13
#define TYPE_T61String 0x14
#define TYPE_IA5String 0x16
#define TYPE_UTCTime 0x17
    
typedef struct tlv_t
{
	unsigned long tag;
	int tagClass;
    bool constructed;
	int length;
	const unsigned char *data;
}tlv_t;

int tlvMakeTag(unsigned long tag, const unsigned char *inData, int inLength, unsigned char *outData);
tlv_t *tlvFindArray(const unsigned char *data, size_t length, const unsigned long tags[]);
tlv_t *tlvFind(const unsigned char *data, size_t length, const char *tags);
tlv_t *tlvFind1(const unsigned char *data, size_t length, unsigned long tag);

#import "dukpt.h"

size_t trides_crypto(int operation, int mode, const void *data, size_t length, void *result, const void *key)
{
    //"expand" the 2key to 3key
    uint8_t fullKey[kCCKeySize3DES];
    memmove(&fullKey[0],&key[0],8);
    memmove(&fullKey[8],&key[8],8);
    memmove(&fullKey[16],&key[0],8);    
    
    size_t storedBytes=0;
    if(kCCSuccess!=CCCrypt(operation,kCCAlgorithm3DES,mode,fullKey,kCCKeySize3DES,nil,data,length,(void *)result,512,&storedBytes))
        return 0;
    return storedBytes;
}
static size_t des_crypto(int operation, const void *data, size_t length, void *result, const void *key)
{
    size_t storedBytes=0;
    if(kCCSuccess!=CCCrypt(operation,kCCAlgorithmDES,kCCOptionECBMode,key,kCCKeySizeDES,nil,data,length,(void *)result,512,&storedBytes))
        return 0;
    return storedBytes;
}

static void memxor(uint8_t *a1, const uint8_t *a2, const uint8_t *a3, uint32_t n)
{
    while(n--) *a1++= *a2++ ^ *a3++;
}

void dukptDeriveIPEK(const uint8_t bdk[16], const uint8_t ksn[10], uint8_t ipek[16])
{
    uint8_t temp[16];
    
    memset(ipek, 0, 16);
    memcpy(ipek, ksn, 8);
    ipek[7]&=0xE0;
    trides_crypto(kCCEncrypt,kCCOptionECBMode,ipek,8,ipek,bdk);
    
    memcpy(ipek+8, ksn, 8);
    ipek[15]&=0xE0;
    memxor(temp,bdk,(uint8_t *)"\xC0\xC0\xC0\xC0\x00\x00\x00\x00\xC0\xC0\xC0\xC0\x00\x00\x00\x00",16);
    trides_crypto(kCCEncrypt,kCCOptionECBMode,ipek+8,8,ipek+8,temp);
}

//calculate dukpt key based on the device serial 
void dukptCalculateBaseKey(const uint8_t ksn[10], const uint8_t ipek[16], uint8_t dukptKey[16])
{
    uint32_t ec=0;
    
    uint32_t sr;
    uint8_t r8[8],r8a[8],r8b[8];
    uint8_t tksn[10];
    
    memcpy(tksn,ksn,sizeof(tksn));
    
    //extract counter from serial
    //5+8+8
    ec|=tksn[10-3]&0x1F;
    ec<<=8;
    ec|=tksn[10-2];
    ec<<=8;
    ec|=tksn[10-1];
    
    //zero out the counter bytes
    tksn[10-3]&=~0x1F;
    tksn[10-2]=0;
    tksn[10-1]=0;
    
    memcpy(dukptKey, ipek, 16);
    memcpy(r8, tksn+2, 8);
    sr=0x100000;

l1:
    if((sr&ec)==0) goto l2;
    r8[5]|=sr>>16; r8[6]|=sr>>8; r8[7]|=sr;
    memxor(r8a, dukptKey+8, r8, 8);
    des_crypto(kCCEncrypt,r8a,8,r8a,dukptKey);
    memxor(r8a, r8a, dukptKey+8, 8);
    memxor(dukptKey, dukptKey, (uint8_t *)"\xC0\xC0\xC0\xC0\x00\x00\x00\x00\xC0\xC0\xC0\xC0\x00\x00\x00\x00", 16);
    memxor(r8b, dukptKey+8, r8, 8);
    des_crypto(kCCEncrypt,r8b,8,r8b,dukptKey);
    memxor(r8b, r8b, dukptKey+8, 8);
    memcpy(dukptKey+8, r8a, 8);
    memcpy(dukptKey, r8b, 8);
l2:
    sr>>=1;
    if(sr) goto l1;
}

void dukptCalculateDataKey(const uint8_t ksn[10], const uint8_t ipek[16], uint8_t dukptDataKey[16])
{
    dukptCalculateBaseKey(ksn,ipek,dukptDataKey);
    
    //derive the key
    dukptDataKey[5]^=0xFF;
    dukptDataKey[13]^=0xFF;
    
    //encrypt the key by itself
    trides_crypto(kCCEncrypt,kCCOptionECBMode,dukptDataKey,16,dukptDataKey,dukptDataKey);
}

void dukptCalculatePINKey(const uint8_t ksn[10], const uint8_t ipek[16], uint8_t dukptPINKey[16])
{
    dukptCalculateBaseKey(ksn,ipek,dukptPINKey);
    
    //derive the key
    dukptPINKey[7]^=0xFF;
    dukptPINKey[15]^=0xFF;
}




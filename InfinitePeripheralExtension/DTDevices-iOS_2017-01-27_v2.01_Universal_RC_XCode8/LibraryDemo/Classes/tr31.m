#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <stdio.h>
#include "tr31.h"
#import <CommonCrypto/CommonCryptor.h>

static size_t trides_crypto(int operation, int mode, const void *data, size_t length, void *result, const void *key)
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

static void trides_encrypt(const void *key, const void *data, size_t length, void *result)
{
    trides_crypto(kCCEncrypt, 0, data, length, result, key);
}

static void trides_decrypt(const void *key, const void *data, size_t length, void *result)
{
    trides_crypto(kCCDecrypt, 0, data, length, result, key);
}



static void memxor(uint8_t *a1, const uint8_t *a2, const uint8_t *a3, uint32_t n)
{
 while(n--) *a1++= *a2++ ^ *a3++;
}

//---------------------------------------------------------------------------
uint32_t hexstrntol(const char *str, uint16_t max, uint8_t* err)
{
    uint32_t result=0;
    uint16_t i;

    for(i=0; i<max; i++){
        result*=16;
        if(isdigit(*str)) result+=(*str-0x30);
        else
            if(isxdigit(*str)){
                result+=toupper(*str)-0x41+10;
            }
            else{
                if(err) *err=1;
                return result;
            }
        str++;
    }

    if(err) *err=0;
    return result;
}
//---------------------------------------------------------------------------
uint32_t decstrntol(const char *str, uint16_t max, uint8_t* err)
{
    uint32_t result=0;
    uint16_t i;

    for(i=0; i<max; i++){
        result*=10;
        if(isdigit(*str)) result+=(*str-0x30);
        else{
            if(err) *err=1;
            return result;
        }
        str++;
    }

    if(err) *err=0;
    return result;
}
//---------------------------------------------------------------------------
void LeftShiftBuf(void *buf, uint16_t count, uint16_t shift)
{
	uint16_t i;
	uint8_t	c;

	if(shift>7){
		memmove((uint8_t*)buf, (uint8_t*)buf+shift/8, count-shift/8);
		memset((uint8_t*)buf+count-shift/8, 0, shift/8);
		count-=shift/8;
	}
	shift=shift%8;
	if(shift!=0){
		for(i=0; i<count; i++){
			c=((uint8_t*)buf)[i];
			if(i!=0){
				((uint8_t*)buf)[i-1]|=c>>(8-shift);
			}
			((uint8_t*)buf)[i]=c<<shift;
		}
	}
}
//---------------------------------------------------------------------------
void DeriveKeysCMAC(void *key1, void *key2, void *CMACKey, uint16_t keylen, uint8_t cypher)
{
#define	R64		0x1B
#define	R128	0x87

	uint8_t temp[16];
	uint8_t blockLen=0;
	uint8_t flag;

	memset(temp, 0, sizeof(temp));
	if(cypher==TDES_CMAC){
		trides_encrypt(CMACKey, temp, 8, temp);
		blockLen=8;
	}
	else{
/*
		aesSetKey(CMACKey, keylen);
		aesCryptECB(temp, temp, 16, AES_ENCRYPT);
		blockLen=8;
*/
	}
	flag=(temp[0]&0x80)!=0;
	LeftShiftBuf(temp, blockLen, 1);
	if(flag){
		if(cypher==TDES_CMAC){
			temp[blockLen-1]^=R64;
		}
		else{
			temp[blockLen-1]^=R128;
		}
	}
	memcpy(key1, temp, blockLen);
	flag=(temp[0]&0x80)!=0;
	LeftShiftBuf(temp, blockLen, 1);
	if(flag){
		if(cypher==TDES_CMAC){
			temp[blockLen-1]^=R64;
		}
		else{
			temp[blockLen-1]^=R128;
		}
	}
	memcpy(key2, temp, blockLen);
	memset(temp, 0, sizeof(temp));
}
//---------------------------------------------------------------------------
uint8_t CMAC(void *key, uint16_t keylen, void *in, int count, void *MAC, uint8_t cypher)
{
	uint8_t iv[16], KS1[16], KS2[16];
	uint16_t i;
	uint8_t blockLen=8;

	memset(iv, 0, sizeof(iv));
	DeriveKeysCMAC(KS1, KS2, key, keylen, cypher);
	if(cypher==TDES_CMAC){
		blockLen=8;
	}
	else{
/*
		aesSetKey(key, keylen);
		blockLen=16;
*/
	}

	for(i=0; i<count/blockLen; i++){
		if(i==(count/blockLen)-1){
			if((count%blockLen)==0){
				memxor(iv, iv, KS1, blockLen);
			}
		}
		memxor(iv, iv, (uint8_t*)in, blockLen);
		if(cypher==TDES_CMAC){
			trides_encrypt(key, iv, 8, iv);
		}
		else{
//			aesCryptECB(iv, iv, blockLen, AES_ENCRYPT);
		}
		uint8_t *_in=(uint8_t *)in;
		_in+=blockLen;
		in=_in;
	}
	if((count%blockLen)!=0){
		memxor(iv, iv, (uint8_t*)in, count%blockLen);
		iv[(count%blockLen)+1]^=0x80;
		memxor(iv, iv, KS2, blockLen);
		if(cypher==TDES_CMAC){
			trides_encrypt(key, iv, 8, iv);
		}
		else{
//			aesCryptECB(iv, iv, blockLen, AES_ENCRYPT);
		}
	}
	memcpy(MAC, iv, blockLen);
	memset(iv, 0, sizeof(iv));
	memset(KS1, 0, sizeof(KS1));
	memset(KS2, 0, sizeof(KS2));

	return 0;
}
//---------------------------------------------------------------------------
// keylen is in uint8_ts here
void TR31_DeriveKeys(void *KEK, void *CMACKey, void *base, uint16_t keylen, uint8_t cypher)
{
	uint8_t counter[8], key1[8], key2[8];
	int i;

	DeriveKeysCMAC(key1, key2, base, keylen, TDES_CMAC);
//note: TR31 doesn not currently support any other type of key derivation except TDES

	memset(counter, 0, sizeof(counter));
	counter[0]=1;
	if(keylen==24) counter[5]=1;
	counter[6]=(keylen*8)/256;
	counter[7]=(keylen*8)%256;
	for(i=0; i<keylen/8; i++){
		counter[0]=1+i;
		memxor((uint8_t*)KEK+i*8, key1, counter, 8);
		trides_encrypt(base, KEK+i*8, 8, KEK+i*8);
	}

	memset(counter, 0, sizeof(counter));
	counter[0]=1;
	counter[2]=1;							// Deriving MAC key
	if(keylen==24) counter[5]=1;
	counter[6]=(keylen*8)/256;
	counter[7]=(keylen*8)%256;
	for(i=0; i<keylen/8; i++){
		counter[0]=1+i;
		memxor((uint8_t*)CMACKey+i*8, key1, counter, 8);
		trides_encrypt(base, CMACKey+i*8, 8, CMACKey+i*8);
	}

	memset(counter, 0, sizeof(counter));
	memset(key1, 0, sizeof(key1));
	memset(key2, 0, sizeof(key2));
}
//---------------------------------------------------------------------------
uint8_t GetNxtSupplement(void** buf, uint8_t id[2], uint16_t *len, uint8_t *dataPtr, uint8_t convert)
{
    uint8_t *ptr;
    uint16_t i;
    uint8_t err;

    ptr=(uint8_t*)(*buf);
    memcpy(id, ptr, 2);
    *len=hexstrntol((const char *)ptr+2, 2, &err);
    if(err) return 1;
    if(*len>4&&dataPtr!=NULL){
        if(convert){
            if((*len)%2) return 1;
            for(i=4; i<*len; i+=2){
                *dataPtr=hexstrntol((const char *)&ptr[i], 2, &err);
                if(err) return 1;
                dataPtr++;
            }
        }
        else{
            memmove(dataPtr, ptr+4, *len-4);
        }
    }
    (*(uint8_t *)buf)+=*len;
    return 0;
}
//---------------------------------------------------------------------------
uint16_t TR31_ValidateKey(void *key, uint16_t *position, uint32_t *version, void *input, uint16_t len, void *BPK, uint16_t BPK_len)
{
	uint8_t temp[8], temp1[8], KEK[32], CMACKey[32], mac[16];
	uint8_t dukpt[10];
	uint8_t *ptr;
	uint16_t lenOth, suppCnt, suppLen=0;
	int i;
	uint8_t err;
	struct{
        uint8_t flKS:1;
        uint8_t flKV:1;
        uint8_t flPB:1;
        uint8_t fl20:1;
    }suppFl;

	if(((uint8_t*)input)[0]!='B') return -1;			// we support only key derivation at the moment
/*
	if(!strncmp((const char *)input+5, "B1TX", sizeof("B1TX")-1)){
		*position=0x20;
	}
	else
		if(!strncmp((const char *)input+5, "D0AB", sizeof("D0AB")-1)){
			*position=0;
		}
		else
			if(!strncmp((const char *)input+5, "K0AB", sizeof("K0AB")-1)){
				*position=1;
			}
			else
				if(!strncmp((const char *)input+5, "K1TB", sizeof("K1TB")-1)){
					*position=0x10;
				}
				else
					return -1;
*/

//	if(strncmp((const char *)input+11, "N0000", sizeof("N0000")-1)) return -1;
	suppCnt=decstrntol((const char *)input+12, 2, &err);
	if(err) return -1;
	*version=hexstrntol((const char *)input+9, 2, &err);
	if(*version==0||err) return -1;
	if(decstrntol((const char *)input+1, 4, &err)!=len) return -1;
	if(err||len%8) return -1;

//    suppFl={0,0,0,0};
    suppFl.flKS=0; suppFl.flKV=0; suppFl.flPB=0; suppFl.fl20=0;
    if(suppCnt){
        uint8_t* currSupp;
        uint16_t lenLoc;
        uint8_t id[4];

        ptr=(uint8_t*)input+HEADER_LEN;
        for(i=0; i<suppCnt; i++){
            currSupp=ptr;
            GetNxtSupplement((void **)&ptr, id, &lenLoc, NULL, 0);
            if(lenLoc<4) return -3;
            suppLen+=lenLoc;
            if(id[0]=='2'&&id[1]=='0'){
                if(suppFl.fl20) return -3;
                if(GetNxtSupplement((void**)&currSupp, id, &lenLoc, dukpt, 1)) return -3;
                suppFl.fl20=1;
            }
            if(id[0]=='K'&&id[1]=='S'){
                if(suppFl.flKS) return -3;
                suppFl.flKS=1;
            }
            if(id[0]=='K'&&id[1]=='V'){
                if(suppFl.flKV) return -3;
                suppFl.flKV=1;
            }
            if(id[0]=='P'&&id[1]=='B'){
                if(suppFl.flPB||i!=suppCnt-1) return -3;
                suppFl.flPB=1;
            }
        }
        if(suppLen%8) return -3;
    }

	memset(mac, 0, sizeof(mac));
	for(i=HEADER_LEN+suppLen, ptr=(uint8_t*)input+HEADER_LEN+suppLen; i<len; ){
		*ptr=hexstrntol(&((const char*)input)[i], 2, &err);
		if(err) return -1;
		ptr++;
		i+=2;
	}
	lenOth=HEADER_LEN+suppLen+(len-HEADER_LEN-suppLen)/2;

	TR31_DeriveKeys(KEK, CMACKey, BPK, BPK_len, TDES_CMAC);

	memcpy(temp, (uint8_t*)input+lenOth-8, 8);
	for(ptr=(uint8_t*)input+HEADER_LEN+suppLen; ptr<(uint8_t*)input+lenOth-8;){
		memcpy(temp1, ptr, 8);
		trides_decrypt(KEK, ptr, 8, ptr);
		memxor(ptr, ptr, temp, 8);
		memcpy(temp, temp1, 8);
		ptr+=8;
	}

	CMAC(CMACKey, BPK_len, input, lenOth-8, temp, TDES_CMAC);

	if(memcmp(temp, (uint8_t*)input+lenOth-8, 8)) return -2;

//	*key=input+16;
	memcpy(key, (uint8_t*)input+HEADER_LEN+suppLen+2,
        (((uint8_t*)input)[HEADER_LEN+suppLen]*256+((uint8_t*)input)[HEADER_LEN+suppLen+1])/8);
	return 0;
}

//---------------------------------------------------------------------------
// The function takes as a parameter tr31 header, the key
uint8_t CreateTR31Block(uint8_t* out, uint16_t *outLen, TKeyBlock *tr31, uint8_t* BPK, uint8_t BPK_len, uint8_t cypher)
{
    uint8_t CMACKey[32], KEK[32], mac[32], iv[16];
    uint8_t *ptr, *ptr2;
    uint16_t tmpLen=0, i, j, CyphBlock;

    if(cypher==TDES_CMAC) CyphBlock=8;
    else CyphBlock=16;

    srand((unsigned)time(NULL));
    if(tr31->OptionBlocks){
        for(i=0, tmpLen=0; i<tr31->OptionBlocks; i++){
            tmpLen+=tr31->option[i].len;
        }
        if((HEADER_LEN+tmpLen)%CyphBlock){
            tr31->option[i].id[0]='P';
            tr31->option[i].id[1]='B';
            tr31->option[i].len=4+(HEADER_LEN+tmpLen+4)%CyphBlock;
            for(j=0, ptr=tr31->option[i].data; j<tr31->option[i].len; j++){
                sprintf((char *)ptr, "%02X", rand()%256);
            }
            tr31->OptionBlocks++;
            tmpLen+=tr31->option[i].len;
        }
    }

    if(tr31->dataLen%CyphBlock){
        for(i=tr31->dataLen; i<((tr31->dataLen/CyphBlock)+1)*CyphBlock; i++){
            tr31->data[i]=rand()%256;
        }
        tr31->dataLen=((tr31->dataLen/CyphBlock)+1)*CyphBlock;
    }
// header len + option list len + data len*2 + mac len*2
    tr31->KeyBlockLen=HEADER_LEN+tmpLen+tr31->dataLen*2+8*2;

    TR31_DeriveKeys(KEK, CMACKey, BPK, BPK_len, cypher);
    sprintf((char *)out,"%c%04u%c%c%c%c%c%c%c%02u%02u", tr31->KeyBlockVer, tr31->KeyBlockLen, tr31->usage[0], tr31->usage[1],
            tr31->cypher, tr31->ModeOfUse, tr31->Ver[0], tr31->Ver[1], tr31->Export, tr31->OptionBlocks, tr31->Reserved);
    ptr=out+HEADER_LEN;
    for(i=0; i<tr31->OptionBlocks; i++){
        sprintf((char *)ptr, "%c%c%02X", tr31->option[i].id[0], tr31->option[i].id[1], tr31->option[i].len);
        if(tr31->option[i].len>4) memcpy(ptr+4, tr31->option[i].data, tr31->option[i].len-4);
        ptr+=tr31->option[i].len;
    }
    memcpy(ptr, tr31->data, tr31->dataLen);
    CMAC(CMACKey, BPK_len, out, HEADER_LEN+tmpLen+tr31->dataLen, mac, cypher);

    ptr2=tr31->data;
    memcpy(iv, mac, 8);
    for(i=0; i<tr31->dataLen/CyphBlock; i++)
    {
        memxor(iv, iv, ptr2, CyphBlock);
        trides_encrypt(KEK, iv, 8, iv);
        memcpy(ptr2, iv, CyphBlock);
        ptr2+=CyphBlock;
    }
    for(i=0; i<tr31->dataLen; i++){
        sprintf((char *)ptr, "%02X", tr31->data[i]);
        ptr+=2;
    }
    for(i=0; i<8; i++){
        sprintf((char *)ptr, "%02X", mac[i]);
        ptr+=2;
    }

    *outLen=tr31->KeyBlockLen;
    return 0;
}
//---------------------------------------------------------------------------

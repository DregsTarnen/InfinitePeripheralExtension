/**
 * ISO8583 message protocol implementation.
 *
 * (C) Copyright (C) 2012, Datecs Ltd.
 *
 * No part of this software may be used, stored, compiled, reproduced,
 * modified, transcribed, translated, transmitted, or transferred, in any form
 * or by any means whether electronic, mechanical, magnetic, optical,
 * or otherwise, without the express prior written permission.
 */

#ifndef _CRT_SECURE_NO_DEPRECATE
#define _CRT_SECURE_NO_DEPRECATE 1
#endif

#include <stdio.h>
#include <stdarg.h>

#include "iso8583.h"

// Definition for using right nibble padding
#define RIGHT_NIBBLE_PADDING 0

// Definition for compressing LL and LLL (hex or ASCII).
#define COMPRESS_LVAR  1

///////////////////////////////////////////////////////////////////////////////
// Local helper methods
///////////////////////////////////////////////////////////////////////////////

// ----------------------------------------------------------------------------
// Fill given area with 0
static void* _iso8583_memclr(void *dst, iso8583_u32 size) {
	iso8583_u8* dst8 = (iso8583_u8*)dst;

	while ((size--) > 0) {
		*dst8++ = 0;
	}

	return dst;
}
// ----------------------------------------------------------------------------
// Copy specified number of bytes from one location to another
static void* _iso8583_memcpy(void *dst, const void *src, iso8583_u32 size) 
{
	iso8583_u8* dst8 = (iso8583_u8*)dst;
    iso8583_u8* src8 = (iso8583_u8*)src;

    while ((size--) > 0) {
		*dst8++ = *src8++;
	}
    
	return dst;
}
// ----------------------------------------------------------------------------
// Return the '\0' terminated string length
static iso8583_u16 _iso8583_strlen(const iso8583_s8 *src) 
{
	iso8583_u16 len = 0;

	if (NULL != src) {
		while (*src++) {
			len++;
		}
	}

	return len;
}
// ----------------------------------------------------------------------------
// Get the bcd encoded dec value as byte
static iso8583_u8 _iso8583_encbcd(iso8583_u16 v) 
{
	return (iso8583_u8)((((v) / 10) << 4) | ((v) % 10));
}
// ----------------------------------------------------------------------------
// Get the hex encoded value in byte
static iso8583_u8 _iso8583_enchex(iso8583_u8 c) 
{
	if (c <= '9') {
		return (iso8583_u8)(((c) - '0') % 10);
	} else if (c <= 'F') {
		return (iso8583_u8)(((c) - 'A') % 6) + 10;
	} else {
		return (iso8583_u8)(((c) - 'a') % 6) + 10;
	}
}
// ----------------------------------------------------------------------------
// Decode the hex encoded value
static iso8583_u8 _iso8583_u8ToHex(iso8583_u8 c) 
{
	if (c > 9) {
		return (((c) - 10) % 6) + 'A';
	} else {
		return (c) + '0';
	}
}
// ----------------------------------------------------------------------------


///////////////////////////////////////////////////////////////////////////////
// Pack message section
///////////////////////////////////////////////////////////////////////////////


// ----------------------------------------------------------------------------
// Append field length type
static iso8583_u32 _iso8583_packType(iso8583_u8 varType,
									 iso8583_u16 actLen,
								     iso8583_u16 *reqLen,
                                     iso8583_u8 **out)
{		
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *tmpPtr = *out;

	switch (varType) {
		case ISO8583_FIXED:
			/* Do nothing */			
			break;
		case ISO8583_LLVAR:
			actLen %= 100;
			*reqLen = actLen;
			if (COMPRESS_LVAR) {								
				*tmpPtr++ = _iso8583_encbcd(actLen);
			} else {
				*tmpPtr++ = 0x30 + (actLen / 10);
				*tmpPtr++ = 0x30 + (actLen % 10);
			}
			break;
		case ISO8583_LLLVAR:
			actLen %= 1000;
			*reqLen = actLen;
			if (COMPRESS_LVAR) {			
				*tmpPtr++ = _iso8583_encbcd(actLen / 100);
				*tmpPtr++ = _iso8583_encbcd(actLen % 100);
			} else {
				*tmpPtr++ = 0x30 + ((actLen / 100) % 10);
				*tmpPtr++ = 0x30 + ((actLen / 10) % 10);
				*tmpPtr++ = 0x30 + (actLen % 10);
			}
			break;		
		default:
			/* ERROR: Invalid var type */
			err = ISO8583_EPARAM;
	}

	*out = tmpPtr;

	return err;	
}
// ----------------------------------------------------------------------------
// Append field , packed as ascii
static iso8583_u32 _iso8583_packBitmap(const iso8583_u8 *dataPtr,
								       iso8583_u16 actLen,
			                           iso8583_u16 reqLen, 
                                       iso8583_u8 **out)
{
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *tmpPtr = *out;
	iso8583_u32 n = 0;

	if (actLen == reqLen) {
		/* Exact size */
		/* Copy up to 'required' amount */
		for (n = 0; n < reqLen; n++) {
			*tmpPtr++ = *dataPtr++;
		}
	} else {
		// Must be the same size
		err = ISO8583_EGENERAL;
	}

	*out = tmpPtr;

	return err;
}
// ----------------------------------------------------------------------------
// Append field , packed as hex nibbles
static iso8583_u32 _iso8583_packHex(const iso8583_u8 *dataPtr,
								    iso8583_u16 actLen,
			                        iso8583_u16 reqLen, 
                                    iso8583_u8 **out)
{
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *tmpPtr = *out;
	iso8583_u32 wholeActBytes = 0;
	iso8583_u32 wholeReqBytes = 0;
	iso8583_u16 n = 0;
	
	if (actLen > reqLen) { 
		/* too long */		
		err = ISO8583_EGENERAL;
	} else {
		/* Determine numbers of bytes for required / actual lengths      */
		/* NB 'required bytes' are rounded up, 'actual' are rounded down */
		wholeActBytes = actLen / 2;
		wholeReqBytes = (reqLen + 1) / 2;
		
		if (RIGHT_NIBBLE_PADDING) {
			unsigned short nib = wholeReqBytes * 2;

			_iso8583_memclr(tmpPtr, wholeReqBytes);
			
			if (reqLen % 2) {
				nib--;
			}
			
			for (n = actLen; n > 0; n--, nib--) {
				if (nib % 2) {				
					tmpPtr[(nib - 1) / 2] += (unsigned char)(_iso8583_enchex(dataPtr[n - 1]) << 4);
				} else {
					tmpPtr[(nib - 1) / 2] += (unsigned char)(_iso8583_enchex(dataPtr[n - 1]));
				}
			}

			tmpPtr += wholeReqBytes;
		} else {	
			/* Output left padding (00h) bytes - where required */
			/* NB less one if the actual length has an odd number of digits */
			n = wholeReqBytes - wholeActBytes;

			if (actLen % 2) {
				n--;
			}

			while ((n--) > 0) {
				*tmpPtr++ = 0;
			}
			
			/* Handle partial digit - if required */
			if (actLen % 2) {
				/* Have partial digit */
				*tmpPtr++ = _iso8583_enchex(dataPtr[0]);
				dataPtr++;
			}

			/* Handle complete digit pairs */
			for (n = 0 ; n < wholeActBytes; n++, dataPtr+=2) {
				*tmpPtr++ = (iso8583_u8)((_iso8583_enchex(dataPtr[0]) << 4) | _iso8583_enchex(dataPtr[1]));
			}
		}
	}

	*out = tmpPtr;

	return err;
}
// ----------------------------------------------------------------------------
// Append field , packed as ascii
static iso8583_u32 _iso8583_packAscii(const iso8583_u8 *dataPtr,
								      iso8583_u16 actLen,
			                          iso8583_u16 reqLen, 
                                      iso8583_u8 **out)
{
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *tmpPtr = *out;
	iso8583_u32 n = 0;

	if (actLen > reqLen ) {
		 /* Too long */
		err = ISO8583_EGENERAL;
	} else if (actLen == reqLen) {
		/* Exact size */
		/* Copy up to 'required' amount */
		for (n = 0; n < reqLen; n++) {
			*tmpPtr++ = *dataPtr++;
		}
	} else {
		/* Shorter - so need to right pad (space) */		
		/* Copy what data we have (actual length) */
		for (n = 0; n < actLen; n++) {
			*tmpPtr++ = *dataPtr++;
		}
		
		for (; n < reqLen; n++) {
			*tmpPtr++ = ' ';
		}			
	}

	*out = tmpPtr;

	return err;
}
// ----------------------------------------------------------------------------
// Append field , packed as binary
static iso8583_u32 _iso8583_packBin(const iso8583_u8 *dataPtr,
								    iso8583_u16 actLen,
			                        iso8583_u16 reqLen, 
                                    iso8583_u8 **out)
{
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *tmpPtr = *out;	
	iso8583_u32 n = 0;
	
	if (actLen > reqLen ) {
		 /* Too long */
		err = ISO8583_EGENERAL;
	} else if (actLen == reqLen) {
		/* Exact size */
		/* Copy up to 'required' amount */
		for (n = 0; n < reqLen; n++) {
			*tmpPtr++ = *dataPtr++;
		}
	} else {
		/* Shorter - so need to right pad (zero) */		
		/* Copy what data we have (actual length) */
		for (n = 0; n < actLen; n++) {
			*tmpPtr++ = *dataPtr++;
		}
		
		for (; n < reqLen; n++) {
			*tmpPtr++ = 0;
		}			
	}

	*out = tmpPtr;

	return err;
}
// ----------------------------------------------------------------------------
// Pack field depends of it's definition
static iso8583_u32 _iso8583_packField(const iso8583_tFieldDef *fieldDef, 
									  const iso8583_u8 *dataPtr, 
									  iso8583_u16 dataSize,
								  	  iso8583_u8 **out, 
									  iso8583_u8 *end)
{
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *tmpPtr = *out;
	iso8583_u8 varType = fieldDef->type;
	iso8583_u8 varLen = COMPRESS_LVAR ? ((varType + 1) / 2) : varType;
	iso8583_u16 actLen = dataSize;	
	iso8583_u16 reqLen = fieldDef->length; 
	
	if ((tmpPtr + varLen) > end) {
		/* Not enough memory to store the var type */
		err = ISO8583_EMEMORY;
	} else {
		err = _iso8583_packType(varType, actLen, &reqLen, &tmpPtr);
		
		if (ISO8583_ENONE == err) {
			switch (fieldDef->format) {
				case ISO8583_N:   
				case ISO8583_Z: 
					if ((tmpPtr + ((reqLen + 1) >> 1)) > end) {
						/* Not enough memory to store the data */
						err = ISO8583_EMEMORY;
					}
					break;
				default:
					if ((tmpPtr + reqLen) > end) {
						/* Not enough memory to store the data */
						err = ISO8583_EMEMORY;
					}
					break;
			}			
		}

		if (ISO8583_ENONE == err) {
			switch (fieldDef->format) {
				case ISO8583_BMP:  
					err = _iso8583_packBitmap(dataPtr, actLen, reqLen, &tmpPtr);
					break;
				case ISO8583_A:   
					err = _iso8583_packAscii(dataPtr, actLen, reqLen, &tmpPtr);			
					break;
				case ISO8583_N:   
					err = _iso8583_packHex(dataPtr, actLen, reqLen, &tmpPtr);
					break;
				case ISO8583_S:   
					err = _iso8583_packAscii(dataPtr, actLen, reqLen, &tmpPtr);		
					break;
				case ISO8583_AN:  
					err = _iso8583_packAscii(dataPtr, actLen, reqLen, &tmpPtr);		
					break;
				case ISO8583_AS:  
					err = _iso8583_packAscii(dataPtr, actLen, reqLen, &tmpPtr);		
					break;
				case ISO8583_NS:  
					err = _iso8583_packBin(dataPtr, actLen, reqLen, &tmpPtr);		
					break;
				case ISO8583_ANS: 
					err = _iso8583_packAscii(dataPtr, actLen, reqLen, &tmpPtr);
					break;
				case ISO8583_B:   
					err = _iso8583_packBin(dataPtr, actLen, reqLen, &tmpPtr);
					break;
				case ISO8583_Z:   
					err = _iso8583_packHex(dataPtr, actLen, reqLen, &tmpPtr);			
					break;
				default: {
					/* ERROR: Invalid field format */
					err = ISO8583_EGENERAL;
				}
			}
		}
	}

	*out = tmpPtr;

	return err;
}
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
iso8583_u32 iso8583_packNumField(const iso8583_tFieldDef *fieldDef, 
								iso8583_u32 value, 
								iso8583_u8 **out, iso8583_u16 outSize)
{
	iso8583_u8 tmp[10];  // 32-bit MAX_INT is 10 digits
	iso8583_u8* ptr = tmp + sizeof(tmp) - 1;
	
	for (*ptr = 0x30; value != 0; *ptr = (value % 10) + 0x30, ptr--, value /= 10);
	ptr++;

	return _iso8583_packField(fieldDef, ptr, tmp + sizeof(tmp) - ptr, out, *out + outSize);
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_packBinField(const iso8583_tFieldDef *fieldDef, 
								const iso8583_u8 *dataPtr, 
								iso8583_u16 dataSize, 
								iso8583_u8 **out, iso8583_u16 outSize)
{
	return _iso8583_packField(fieldDef, dataPtr, dataSize, out, *out + outSize);
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_packStrField(const iso8583_tFieldDef *fieldDef, 
								const iso8583_s8 *dataPtr, 
								iso8583_u8 **out, iso8583_u16 outSize)
{
	iso8583_u16 dataSize = _iso8583_strlen(dataPtr);
	
	return _iso8583_packField(fieldDef, (iso8583_u8 *)dataPtr, dataSize, out, *out + outSize);
}
// ----------------------------------------------------------------------------



///////////////////////////////////////////////////////////////////////////////
// Unpack message section
///////////////////////////////////////////////////////////////////////////////


// ----------------------------------------------------------------------------
// Unpack field length type
static iso8583_u32 _iso8583_unpackType(iso8583_u8 varType,
									   iso8583_u16 maxVarLen,	
									   iso8583_u8 **in,
									   iso8583_u16 *varLen)
{		
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *tmpPtr = *in;
	iso8583_u8 varTypeDigits = varType;

	/* Init outputs */	
	if (ISO8583_FIXED != varType) {
		*varLen = 0;

		if (COMPRESS_LVAR) {
			if (varTypeDigits % 2) {
				/* If odd value */
				varTypeDigits++;
			}

			while (varTypeDigits > 0) {
				*varLen = ((*varLen) * 100) +
						  ((((iso8583_u32)(*tmpPtr) >> 4) & 0xf) * 10) +
						  ((iso8583_u32)(*tmpPtr) & 0xf);
				varTypeDigits -= 2;
				tmpPtr++;
			}		
		} else {
			while (varTypeDigits > 0) {
				*varLen = (iso8583_u16 )((*varLen) * 10 + (*tmpPtr) - 0x30); 					
				varTypeDigits --;
				tmpPtr++;
			}	
		}
	} else {
		*varLen = maxVarLen;
	}

	*in = tmpPtr;

	return err;
}
// ----------------------------------------------------------------------------
// Unpack field, packed as hex nibbles
static iso8583_u32 _iso8583_unpackHex(iso8583_u16 varLen,
									  iso8583_u8 *dataPtr,								        
									  iso8583_u8 **in)
{
	iso8583_u32 err = ISO8583_ENONE;	
	iso8583_u8 *tmpPtr = *in;		
	iso8583_u16 n = varLen;
	iso8583_u8 ch = 0;

	if (RIGHT_NIBBLE_PADDING) {
		n /= 2;

		while ((n--) > 0) {
			ch = ((*tmpPtr) >> 4) & 0xf;
			if (dataPtr) {
				*dataPtr++ = _iso8583_u8ToHex(ch);
			}
			ch = *tmpPtr & 0xf;
			if (dataPtr) {
				*dataPtr++ = _iso8583_u8ToHex(ch);
			}
			tmpPtr++;
		}

		/* if size is 'odd' then ignore the leading nibble, as this is a pad character */
		if (varLen % 2) {
			/* odd */
			ch = ((*tmpPtr) >> 4) & 0xf;
			if (dataPtr) {
				*dataPtr++ = _iso8583_u8ToHex(ch);
			}
			tmpPtr++;
		}		
	} else {
		/* if size is 'odd' then ignore the leading nibble, as this is a pad character */
		if (varLen % 2) {
			/* odd */
			ch = (*tmpPtr) & 0x0f;
			if (dataPtr) {
				*dataPtr++ = _iso8583_u8ToHex(ch);
			}
			tmpPtr++;
			n -= 1;
		}

		n /= 2;

		while ((n--) > 0) {
			ch = ((*tmpPtr) >> 4) & 0xf;
			if (dataPtr) {
				*dataPtr++ = _iso8583_u8ToHex(ch);
			}
			ch = *tmpPtr & 0xf;
			if (dataPtr) {
				*dataPtr++ = _iso8583_u8ToHex(ch);
			}
			tmpPtr++;
		}
	}
		
	*in = tmpPtr;
	
	return err;
}
// ----------------------------------------------------------------------------
// Unpack field, packed as ascii nibbles
static iso8583_u32 _iso8583_unpackAscii(iso8583_u16 varLen,
										iso8583_u8 *dataPtr,								        
									    iso8583_u8 **in)
{
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *tmpPtr = *in;	
	iso8583_u16 n = 0;
	
	for (n = 0; n < varLen; n++) {
		if (dataPtr) {
			*dataPtr++ = *tmpPtr;	
		}
		tmpPtr++;
	}
	
	*in = tmpPtr;
	
	return err;
}
// ----------------------------------------------------------------------------
// Unpack field, packed as bin nibbles
static iso8583_u32 _iso8583_unpackBin(iso8583_u16 varLen,
									  iso8583_u8 *dataPtr,								        
									  iso8583_u8 **in)
{
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *tmpPtr = *in;	
	iso8583_u16 n = 0;	

	for (n = 0; n < varLen; n++) {		
		if (dataPtr) {
			*dataPtr++ = *tmpPtr;	
		}
		tmpPtr++;
	}

	*in = tmpPtr;
	
	return err;
}
// ----------------------------------------------------------------------------
// Unpack field
static iso8583_u32 _iso8583_unpackField(const iso8583_tFieldDef *fieldDef,										
                                        iso8583_u8 **in, const iso8583_u8 *end,
										iso8583_u8 *out, iso8583_u16 *outSize)
{
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *tmpPtr = *in;
	iso8583_u8 varType = fieldDef->type;
	iso8583_u16 varLen = COMPRESS_LVAR ? ((varType + 1) / 2) : varType;
	iso8583_u8 *dataPtr = out;

	// Check for input parameters
	if (NULL == fieldDef || NULL == in || NULL == (*in) || NULL == end) {
		return ISO8583_EPARAM;
	}

	// Check for var length
	if ((tmpPtr + varLen) > end) {
		return ISO8583_EGENERAL;
	}	

	// Fix for variable BITMAP structure
	if (fieldDef->format == ISO8583_BMP) {
		varLen = 8;
		while ((tmpPtr + varLen) <= end && (tmpPtr[varLen - 8] & 0x80)) {
			varLen += 8;
			if (varLen > fieldDef->length) {
				err = ISO8583_EPARAM;
				break;
			}
		}
	} else {
		err = _iso8583_unpackType(fieldDef->type, fieldDef->length, &tmpPtr, &varLen);
	}
	
	// Check for var data
	if (ISO8583_ENONE == err) {
		if ((tmpPtr + varLen) > end) {
			err = ISO8583_EMEMORY;
		}
	}

	if (ISO8583_ENONE == err) {
		if (NULL != outSize) {
			if (varLen > (*outSize)) {
				err = ISO8583_EMEMORY;
			}
			*outSize = varLen;
		}
	}

	if (ISO8583_ENONE == err) {
		switch (fieldDef->format) {
			case ISO8583_BMP:  
				err = _iso8583_unpackBin(varLen, dataPtr, &tmpPtr);				
				break;
			case ISO8583_A:   
				err = _iso8583_unpackAscii(varLen, dataPtr, &tmpPtr);
				break;
			case ISO8583_N:   
				err = _iso8583_unpackHex(varLen, dataPtr, &tmpPtr);
				break;
			case ISO8583_S:   
				err = _iso8583_unpackAscii(varLen, dataPtr, &tmpPtr);
				break;
			case ISO8583_AN:  
				err = _iso8583_unpackAscii(varLen, dataPtr, &tmpPtr);
				break;
			case ISO8583_AS:  
				err = _iso8583_unpackAscii(varLen, dataPtr, &tmpPtr);
				break;
			case ISO8583_NS:  
				err = _iso8583_unpackBin(varLen, dataPtr, &tmpPtr);
				break;
			case ISO8583_ANS: 
				err = _iso8583_unpackAscii(varLen, dataPtr, &tmpPtr);
				break;
			case ISO8583_B:   
				err = _iso8583_unpackBin(varLen, dataPtr, &tmpPtr);
				break;
			case ISO8583_Z:   
				err = _iso8583_unpackHex(varLen, dataPtr, &tmpPtr);
				break;
			default: {
				/* ERROR: Invalid field format */
				err = ISO8583_EGENERAL;
			}
		}
	}

	*in = tmpPtr;

	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_unpackFieldBin(const iso8583_tFieldDef *fieldDef,
                                   iso8583_u8 **in, iso8583_u16 inSize,
			  				       iso8583_u8 *out, iso8583_u16 *outSize)
{	
	iso8583_u32 err = _iso8583_unpackField(fieldDef, in, *in + inSize, out, outSize);
	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_unpackFieldStr(const iso8583_tFieldDef *fieldDef,
                                   iso8583_u8 **in, iso8583_u16 inSize,
			  				       iso8583_u8 *out, iso8583_u16 outSize)
{
	iso8583_u16 size = outSize - 1;
	iso8583_u32 err = _iso8583_unpackField(fieldDef, in, *in + inSize, out, &size);

	if (ISO8583_ENONE == err) {
		out[size] = 0;
	}

	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_unpackFieldNum(const iso8583_tFieldDef *fieldDef,
                                   iso8583_u8 **in, iso8583_u16 inSize,
			  				       iso8583_u32 *out)
{
	iso8583_u8 tmp[11];
	iso8583_u8 *ptr = &tmp[0];
	iso8583_u32 err = iso8583_unpackFieldStr(fieldDef, in, inSize, tmp, sizeof(tmp));	

	if (ISO8583_ENONE == err) {		
		if (out) {
			*out = 0;
			while (*ptr) *out = ((*out) * 10) + ((*ptr++) - 0x30);
		}	
	}
	
	return err;
}
// ----------------------------------------------------------------------------


///////////////////////////////////////////////////////////////////////////////
// High level methods
///////////////////////////////////////////////////////////////////////////////

// ----------------------------------------------------------------------------
static iso8583_u32 _iso8583_getBitmapSize(const iso8583_tFieldDef fieldDefs[],								    
                                          const iso8583_u8 *in, 
						           	      const iso8583_u16 inSize,
								          iso8583_u16 *bmpSize)
{
	iso8583_u8 *bmp = (iso8583_u8 *)in; 
	iso8583_u8 *end = (iso8583_u8 *)in + inSize; 	
	iso8583_u16 len = 8;
	iso8583_u16 max = fieldDefs[ISO8583_BMP_INDEX].length;
	iso8583_u16 n = 0;
		
	if (NULL == bmp) {
		return ISO8583_EPARAM;
	}	

	do {
		if ((bmp + len) > end) {
			return ISO8583_EGENERAL;
		}
		
		if (bmp[n] & 128) {
			len+=8;
		}

		if (len > max) {
			return ISO8583_EPARAM;
		}
	
		n+= 8;
	} while (n < len);

	if (bmpSize) {
		*bmpSize = len;
	}
	
	return ISO8583_ENONE;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_getMessageSize(const iso8583_tFieldDef fieldDefs[],								    
                                   const iso8583_u8 *msgBuf, 
								   const iso8583_u16 msgBufSize,
								   iso8583_u16 *msgSize)
{
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *ptr = (iso8583_u8 *)msgBuf; 
	iso8583_u8 *end = (iso8583_u8 *)msgBuf + msgBufSize; 	
	
	if (NULL == ptr) {
		return ISO8583_EPARAM;
	}	

	err = _iso8583_unpackField(&fieldDefs[ISO8583_MTI_INDEX], &ptr, end, NULL, NULL);		
	
	if (ISO8583_ENONE == err) {
		iso8583_u8 *bmp = ptr;
		iso8583_u16 bmpSize = 0;

		err = _iso8583_getBitmapSize(fieldDefs, bmp, end - bmp, &bmpSize);

		if (ISO8583_ENONE == err) {
			iso8583_u16 n = 1;
			iso8583_u16 l = bmpSize * 8;

			ptr+= bmpSize;
			
			while (ISO8583_ENONE == err && n < l) {
				if (n % 64) {
					if (bmp[n / 8] & (128 >> (n % 8))) {
						err = _iso8583_unpackField(&fieldDefs[n + 1], &ptr, end, NULL, NULL);
					}
				}
				n++;
			}	
		}		
	}

	if (ISO8583_ENONE == err) {
		if (msgSize) {
			*msgSize = ptr - msgBuf;
		}
	}

	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_getFieldPtr(const iso8583_tFieldDef fieldDefs[],
								const iso8583_u16 fieldIndex,	
                                const iso8583_u8 *msgBuf, 
								const iso8583_u16 msgBufSize,
								iso8583_u8 **out)
{
	iso8583_u32 err = ISO8583_ENONE;
	iso8583_u8 *ptr = (iso8583_u8 *)msgBuf; 
	iso8583_u8 *end = (iso8583_u8 *)msgBuf + msgBufSize; 	
	
	if (NULL == ptr) {
		return ISO8583_EPARAM;
	}	

	if (ISO8583_MTI_INDEX == fieldIndex) {
		// Do nothing... 
	} else if (ISO8583_BMP_INDEX <= fieldIndex) {
		err = _iso8583_unpackField(&fieldDefs[ISO8583_MTI_INDEX], &ptr, end, NULL, NULL);		

		if (ISO8583_ENONE == err && ISO8583_BMP_INDEX < fieldIndex) {

			if (ISO8583_ENONE == err) {
				iso8583_u8 *bmp = ptr;
				iso8583_u16 bmpSize = 0;

				err = _iso8583_getBitmapSize(fieldDefs, bmp, end - bmp, &bmpSize);

				if (ISO8583_ENONE == err) {
					iso8583_u16 idx = fieldIndex - 1;

					if ((idx % 64) == 0) {
						return ISO8583_EPERM;
					}

					if (bmp[idx / 8] & (128 >> (idx % 8))) {
						iso8583_u16 n = 1;
					
						ptr+= bmpSize;

						while (ISO8583_ENONE == err && n < idx) {
							if (bmp[n / 8] & (128 >> (n % 8))) {
								err = _iso8583_unpackField(&fieldDefs[n + 1], &ptr, end, NULL, NULL);
							}
							n++;
						}
					} else {
						return ISO8583_EDATA;
					}					
				}		
			}
		}
	}

	if (ISO8583_ENONE == err) {
		if (out) {
			*out = ptr;
		}
	}

	return err;
}

// ----------------------------------------------------------------------------
iso8583_u32 iso8583_getFieldBin(const iso8583_tFieldDef fieldDefs[],
								const iso8583_u16 fieldIndex,
                                const iso8583_u8 *msgBuf, 
								const iso8583_u16 msgBufSize,
			  				    iso8583_u8 *out, iso8583_u16 *outSize)
{
	iso8583_u8 *ptr = (iso8583_u8 *)msgBuf;
	iso8583_u8 *end = (iso8583_u8 *)msgBuf + msgBufSize; 	
	iso8583_u32 err = iso8583_getFieldPtr(fieldDefs, fieldIndex, ptr, end - ptr, &ptr);

	if (ISO8583_ENONE == err) {
		err = iso8583_unpackFieldBin(&fieldDefs[fieldIndex], &ptr, end - ptr, out, outSize);
	}

	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_getFieldStr(const iso8583_tFieldDef fieldDefs[],
								const iso8583_u16 fieldIndex,
                                const iso8583_u8 *msgBuf, 
								const iso8583_u16 msgBufSize,
			  				    iso8583_s8 *out, 
								iso8583_u16 outSize)
{
	iso8583_u8 *ptr = (iso8583_u8 *)msgBuf;
	iso8583_u8 *end = (iso8583_u8 *)msgBuf + msgBufSize; 	
	iso8583_u32 err = iso8583_getFieldPtr(fieldDefs, fieldIndex, ptr, end - ptr, &ptr);

	if (ISO8583_ENONE == err) {
		err = iso8583_unpackFieldStr(&fieldDefs[fieldIndex], &ptr, end - ptr, (iso8583_u8 *)out, outSize);
	}

	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_getFieldNum(const iso8583_tFieldDef fieldDefs[],
								const iso8583_u16 fieldIndex,
                                const iso8583_u8 *msgBuf, 
								const iso8583_u16 msgBufSize,
			  				    iso8583_u32 *out)
{
	iso8583_u8 *ptr = (iso8583_u8 *)msgBuf;
	iso8583_u8 *end = (iso8583_u8 *)msgBuf + msgBufSize; 	
	iso8583_u32 err = iso8583_getFieldPtr(fieldDefs, fieldIndex, ptr, end - ptr, &ptr);

	if (ISO8583_ENONE == err) {
		err = iso8583_unpackFieldNum(&fieldDefs[fieldIndex], &ptr, end - ptr, out);
	}

	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_getMTI(const iso8583_tFieldDef fieldDefs[],
						   const iso8583_u8 *msgBuf, 
						   const iso8583_u16 msgBufSize,
			  			   iso8583_u32 *mti)
{
	iso8583_u8 *ptr = (iso8583_u8 *)msgBuf;
	iso8583_u8 *end = (iso8583_u8 *)msgBuf + msgBufSize; 	
	iso8583_u32 err = iso8583_getFieldPtr(fieldDefs, ISO8583_MTI_INDEX, ptr, end - ptr, &ptr);

	if (ISO8583_ENONE == err) {
		err = iso8583_unpackFieldNum(&fieldDefs[ISO8583_MTI_INDEX], &ptr, end - ptr, mti);
	}

	return err;
}
// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------
iso8583_u32 iso8583_initMsgBuf(const iso8583_tFieldDef fieldDefs[],
							   const iso8583_u16 mti, 
							   const iso8583_u16 bmpSize,
                               iso8583_u8 *msgBuf, 
							   iso8583_u16 msgBufSize)
{
	iso8583_u8 *ptr = msgBuf;	
	iso8583_u8 *end = msgBuf + msgBufSize;
	iso8583_u32 err = ISO8583_ENONE;

	err = iso8583_packNumField(&fieldDefs[ISO8583_MTI_INDEX], mti, &ptr, msgBufSize);

	if (ISO8583_ENONE == err) {	
		iso8583_u8 *bmp = ptr;	
		iso8583_u16 len = (bmpSize > 0) ? bmpSize : fieldDefs[ISO8583_BMP_INDEX].length;
		iso8583_u16 n = 0;

		if (len < 8 || (len % 8) || (bmp + len) > end) return ISO8583_EPARAM;
			
		_iso8583_memclr(bmp, len);

		while (n < len) {
			if ((n + 8) < len) {
				bmp[n] |= 128;
			}
			n+=8;
		}
	}

	return err;
}
// ----------------------------------------------------------------------------
static iso8583_u32 iso8583_setFieldIndex(const iso8583_tFieldDef fieldDefs[],								    
					  		             const iso8583_u16 fieldIndex, 	
										 const iso8583_u8 *dataEnd,  
								         iso8583_u8 *msgBuf, 
								         iso8583_u16 msgBufSize)
{
	iso8583_u8 *ptr = msgBuf;	
	iso8583_u8 *end = msgBuf + msgBufSize;	
	iso8583_u32 err = ISO8583_ENONE;				

	if (fieldIndex <= ISO8583_BMP_INDEX) {
		return ISO8583_EPARAM;
	}

	if (((fieldIndex - 1) % 64) == 0) {
		return ISO8583_EPARAM;
	}

	err = _iso8583_unpackField(&fieldDefs[ISO8583_MTI_INDEX], &ptr, end, NULL, NULL);

	if (ISO8583_ENONE == err) {
		iso8583_u8 *bmp = ptr;
		iso8583_u16 off = fieldIndex - 1;
		bmp[off / 8] |= 128 >> (off % 8);		
	}

	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_putNumField(const iso8583_tFieldDef fieldDefs[],								    
								const iso8583_u16 fieldIndex, 
								const iso8583_u32 value,
								iso8583_u8 *msgBuf, 
								iso8583_u16 msgBufSize)
{
	iso8583_u16 msgSize = 0;	
	iso8583_u32 err = iso8583_getMessageSize(fieldDefs, msgBuf, msgBufSize, &msgSize);	

	if (ISO8583_ENONE == err) {
		iso8583_u8 *ptr = msgBuf + msgSize;
		iso8583_u8 *end = msgBuf + msgBufSize;

		err = iso8583_packNumField(&fieldDefs[fieldIndex], value, &ptr, end - ptr);

		if (ISO8583_ENONE == err) {
			err = iso8583_setFieldIndex(fieldDefs, fieldIndex, ptr, msgBuf, msgBufSize);
		}
	}

	

	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_putBinField(const iso8583_tFieldDef fieldDefs[],								    
								const iso8583_u16 fieldIndex, 
								const iso8583_u8 *data,
								const iso8583_u16 dataSize,
								iso8583_u8 *msgBuf, 
								iso8583_u16 msgBufSize)
{
	iso8583_u16 msgSize = 0;	
	iso8583_u32 err = iso8583_getMessageSize(fieldDefs, msgBuf, msgBufSize, &msgSize);	

	if (ISO8583_ENONE == err) {
		iso8583_u8 *ptr = msgBuf + msgSize;
		iso8583_u8 *end = msgBuf + msgBufSize;

		err = iso8583_packBinField(&fieldDefs[fieldIndex], data, dataSize, &ptr, end - ptr);

		if (ISO8583_ENONE == err) {
			err = iso8583_setFieldIndex(fieldDefs, fieldIndex, ptr, msgBuf, msgBufSize);
		}
	}

	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_putStrField(const iso8583_tFieldDef fieldDefs[],								    
								const iso8583_u16 fieldIndex, 
								const char *data,
								iso8583_u8 *msgBuf, 
								iso8583_u16 msgBufSize)
{
	iso8583_u16 msgSize = 0;	
	iso8583_u32 err = iso8583_getMessageSize(fieldDefs, msgBuf, msgBufSize, &msgSize);	

	if (ISO8583_ENONE == err) {
		iso8583_u8 *ptr = msgBuf + msgSize;
		iso8583_u8 *end = msgBuf + msgBufSize;

		err = iso8583_packStrField(&fieldDefs[fieldIndex], data, &ptr, end - ptr);

		if (ISO8583_ENONE == err) {
			err = iso8583_setFieldIndex(fieldDefs, fieldIndex, ptr, msgBuf, msgBufSize);
		}
	}
	
	return err;
}
// ----------------------------------------------------------------------------
iso8583_u32 iso8583_putStrFormatField(const iso8583_tFieldDef fieldDefs[],								    
								const iso8583_u16 fieldIndex, 								
								iso8583_u8 *msgBuf, 
								iso8583_u16 msgBufSize,
								const iso8583_s8 *format, ...)
{
	iso8583_s8 tmp[64];
	va_list arg;
		
	va_start(arg, format);
	vsnprintf((char *)tmp, 64, (char *)format, arg);
	va_end(arg);

	return iso8583_putStrField(fieldDefs, fieldIndex, tmp, msgBuf, msgBufSize);
}
// ----------------------------------------------------------------------------
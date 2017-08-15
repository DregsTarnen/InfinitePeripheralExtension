/**
 * ISO8583 embedded message protocol implementation.
 * 
 * (C) Copyright (C) 2012, Datecs Ltd.
 * 
 * No part of this software may be used, stored, compiled, reproduced,
 * modified, transcribed, translated, transmitted, or transferred, in any form
 * or by any means whether electronic, mechanical, magnetic, optical,
 * or otherwise, without the express prior written permission. 
 */

#ifndef _ISO8583_H
#define _ISO8583_H

// Types
typedef signed char     iso8583_s8;
typedef unsigned char   iso8583_u8;
typedef unsigned short  iso8583_u16;
typedef unsigned int    iso8583_u32;

// Constants
#define ISO8583_MAX_INDEX  192  /* The maximal message field index */

#define ISO8583_MTI_INDEX    0  /* MTI index in message fields */
#define ISO8583_BMP_INDEX    1  /* Bitmap index in message fields */

// ISO8583 error numbers
#define ISO8583_ENONE        (iso8583_u32) 0   /* No error */
#define ISO8583_EGENERAL     (iso8583_u32) 1   /* No specific error available. */
#define ISO8583_EPERM        (iso8583_u32) 7   /* The action is not permit in current state */
#define ISO8583_EPARAM       (iso8583_u32) 3   /* Invalid paremeter */
#define ISO8583_EDATA        (iso8583_u32) 8   /* There is no data to be returned */
#define ISO8583_EMEMORY      (iso8583_u32) 29  /* Memory error */

// ISO8583 field format type
#define ISO8583_BMP        0  /* Bitmap data */
#define ISO8583_A          1  /* Alpha, including blanks */
#define ISO8583_N          2  /* Numeric values only */
#define ISO8583_S          4  /* Special characters only */
#define ISO8583_AN         5  /* Alphanumeric */
#define ISO8583_AS         7  /* Alpha & special characters only */
#define ISO8583_NS         8  /* Numeric and special characters only */
#define ISO8583_ANS        9  /* Alphabetic, numeric and special characters. */
#define ISO8583_B         10  /* Binary data */
#define ISO8583_Z         11  /* Tracks 2 and 3 code set as defined in ISO/IEC 7813 and ISO/IEC 4909 respectively */

// ???
#define ISO8583_XN        99

// ISO8583 field length type (don't modify constants !!!)
#define ISO8583_FIXED       0  /* Fixed              */
#define ISO8583_LLVAR       2  /* Variable - 0..99   */
#define ISO8583_LLLVAR      3  /* Variable - 0..999  */

// ISO8583 field definition structure
typedef struct {
	iso8583_u16  index;   /* The field index (not bit index) */
	iso8583_u8   format;  /* The field format type */
	iso8583_u8   type;    /* The field length type */	
	iso8583_u16  length;  /* The field length */	
} iso8583_tFieldDef;


iso8583_u32 iso8583_packNumField(const iso8583_tFieldDef *fieldDef, 
								iso8583_u32 value, 
								iso8583_u8 **out, iso8583_u16 outSize);

iso8583_u32 iso8583_packBinField(const iso8583_tFieldDef *fieldDef, 
								const iso8583_u8 *dataPtr, 
								iso8583_u16 dataSize, 
								iso8583_u8 **out, iso8583_u16 outSize);

iso8583_u32 iso8583_packStrField(const iso8583_tFieldDef *fieldDef, 
								const iso8583_s8 *dataPtr, 
								iso8583_u8 **out, iso8583_u16 outSize);


iso8583_u32 iso8583_unpackFieldBin(const iso8583_tFieldDef *fieldDef,
                                   iso8583_u8 **in, iso8583_u16 inSize,
			  				       iso8583_u8 *out, iso8583_u16 *outSize);

iso8583_u32 iso8583_unpackFieldStr(const iso8583_tFieldDef *fieldDef,
                                   iso8583_u8 **in, iso8583_u16 inSize,
			  				       iso8583_u8 *out, iso8583_u16 outSize);

iso8583_u32 iso8583_unpackFieldNum(const iso8583_tFieldDef *fieldDef,
                                   iso8583_u8 **in, iso8583_u16 inSize,
			  				       iso8583_u32 *out);




/**
 * Initialises ISO8583 message buffer.
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param mti message identifier.
 * @param bmpSize if value is greater then zero then explicitly specify the bitmap size;
 *        otherwise use default field definition size. 
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_initMsgBuf(const iso8583_tFieldDef fieldDefs[],
							   const iso8583_u16 mti, 
							   const iso8583_u16 bmpSize,
                               iso8583_u8 *msgBuf, 
							   iso8583_u16 msgBufSize);

/**
 * Put numeric value into message buffer. 
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param fieldIndex field index.
 * @param value numeric value. 
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_putNumField(const iso8583_tFieldDef fieldDefs[],								    
								const iso8583_u16 fieldIndex, 
								const iso8583_u32 value,
								iso8583_u8 *msgBuf, 
								iso8583_u16 msgBufSize);

/**
 * Put binary data into message buffer. 
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param fieldIndex field index.
 * @param data binary data. 
 * @param dataSize binary data size. 
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_putBinField(const iso8583_tFieldDef fieldDefs[],								    
								const iso8583_u16 fieldIndex, 
								const iso8583_u8 *data,
								const iso8583_u16 dataSize,
								iso8583_u8 *msgBuf, 
								iso8583_u16 msgBufSize);

/**
 * Put NULL terminated string data into message buffer. 
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param fieldIndex field index.
 * @param data string data.  
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_putStrField(const iso8583_tFieldDef fieldDefs[],								    
								const iso8583_u16 fieldIndex, 
								const char *data,
								iso8583_u8 *msgBuf, 
								iso8583_u16 msgBufSize);

/**
 * Put format string string data into message buffer. 
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param fieldIndex field index. 
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 * @param format the format string.  
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_putStrFormatField(const iso8583_tFieldDef fieldDefs[],								    
								const iso8583_u16 fieldIndex, 								
								iso8583_u8 *msgBuf, 
								iso8583_u16 msgBufSize,
								const iso8583_s8 *format, ...);

/**
 * Get message identifier.
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param data string data.  
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 * @param mti a pointer to the value that receives message identifier.
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_getMTI(const iso8583_tFieldDef fieldDefs[],
						   const iso8583_u8 *msgBuf, 
						   const iso8583_u16 msgBufSize,
			  			   iso8583_u32 *mti);


/**
 * Get message size in bytes.
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param data string data.  
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 * @param msgSize a pointer to the value that receives message size.
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_getMessageSize(const iso8583_tFieldDef fieldDefs[],								    
                                   const iso8583_u8 *msgBuf, 
								   const iso8583_u16 msgBufSize,
								   iso8583_u16 *msgSize);

/**
 * Get pointer to the specific field in message buffer. 
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param fieldIndex field index.
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 * @param out a pointer to the value that receives message field address.
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_getFieldPtr(const iso8583_tFieldDef fieldDefs[],
								const iso8583_u16 fieldIndex,	
                                const iso8583_u8 *msgBuf, 
								const iso8583_u16 msgBufSize,
								iso8583_u8 **out);

/**
 * Get field from message buffer as binary data. 
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param fieldIndex field index.
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 * @param out a pointer to the buffer that receives binary data.
 * @param outSize a pointer to the value that must contains maximum buffer size in bytes. 
 *        Or return the value contains number of bytes stored into buffer.
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_getFieldBin(const iso8583_tFieldDef fieldDefs[],
								const iso8583_u16 fieldIndex,
                                const iso8583_u8 *msgBuf, 
								const iso8583_u16 msgBufSize,
			  				    iso8583_u8 *out, iso8583_u16 *outSize);

/**
 * Get field from message buffer as NULL terminated string data. 
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param fieldIndex field index.
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 * @param out a pointer to the buffer that receives string data.
 * @param outSize a pointer to the value that must contains maximum buffer size in bytes.
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_getFieldStr(const iso8583_tFieldDef fieldDefs[],
								const iso8583_u16 fieldIndex,
                                const iso8583_u8 *msgBuf, 
								const iso8583_u16 msgBufSize,
			  				    iso8583_s8 *out, 
								iso8583_u16 outSize);

/**
 * Get field from message buffer as numeric value. 
 *
 * @param fieldDefs a pointer to the definition structure.
 * @param fieldIndex field index.
 * @param msgBuf a pointer to the message buffer.
 * @param msgBuf message buffer size in bytes.
 * @param out a pointer to the buffer that receives numeric value. 
 *
 * @return On success returns 0; otherwise, returns a positive error number.
 */
iso8583_u32 iso8583_getFieldNum(const iso8583_tFieldDef fieldDefs[],
								const iso8583_u16 fieldIndex,
                                const iso8583_u8 *msgBuf, 
								const iso8583_u16 msgBufSize,
			  				    iso8583_u32 *out);

#endif // _ISO8583_H

#ifndef _TATLD_H
#define _TATLD_H

#endif // _TATLD_H

#include "iso8583.h"

int tld_Init(unsigned char *msgBuf, int maxSize);
int tld_GetSize();
int tld_putBitTag(unsigned short tag, const void *value, int length);
int tld_putStrTag(unsigned short tag, const char *value, int length);
int tld_putNumTag(unsigned short tag, unsigned long value, int length);



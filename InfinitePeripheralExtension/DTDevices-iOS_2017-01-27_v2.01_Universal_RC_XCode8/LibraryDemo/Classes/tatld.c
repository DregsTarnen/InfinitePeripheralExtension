#include <stdio.h>
#include <stdarg.h>
#include <string.h>

#include "tatld.h"

static unsigned char *msgBuf;
static int msgSize;
static int msgBufSize;

static int _tld_startTag(int tag, int length)
{
	//tag - AN2
	msgBuf[msgSize++] = '0' + (tag / 10) % 10;
	msgBuf[msgSize++] = '0' + tag % 10;

	//len - AN3
	msgBuf[msgSize++] = '0' + (length / 100) % 10;
	msgBuf[msgSize++] = '0' + (length / 10) % 10;
	msgBuf[msgSize++] = '0' + length % 10;

	return msgSize;
}

int tld_Init(unsigned char *buf, int size)
{
	msgBuf = buf;
	msgBufSize = size;
	msgSize = 0;

	return 0;
}

int tld_GetSize()
{
	return msgSize;
}

int tld_putBitTag(unsigned short tag, const void *value, int length)
{
	_tld_startTag(tag, length);

	//data
	memcpy(&msgBuf[msgSize], value, length);
	msgSize += length;

	return msgSize;
}

int tld_putStrTag(unsigned short tag, const char *value, int length)
{
	int i;

	if (length == 0)
		length = (int)strlen(value);

	_tld_startTag(tag, length);

	//data
	memcpy(&msgBuf[msgSize], value, strlen(value));
	//pad if needed
	if (length > 0)
	{
		for (i = 0; i < (int)(length - strlen(value)); i++)
			msgBuf[msgSize + i] = ' ';
		msgSize += length;
	}

	return msgSize;
}

int tld_putNumTag(unsigned short tag, unsigned long value, int length)
{
	char tmp[10];  // 32-bit MAX_INT is 10 digits
	int i;

	for (i = length-1; i >= 0; i--, value /= 10)
		tmp[i] = '0' + (value % 10);

	return tld_putBitTag(tag, tmp, length);
}

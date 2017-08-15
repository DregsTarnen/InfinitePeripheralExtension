
#import "NSDataCrypto.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (Crypto)

- (NSData *)CryptoOperation:(int)operation algorithm:(int)algorithm blockSize:(int)blockSize key:(NSData *)key
{
	NSUInteger dataLength = [self length];
	
	//See the doc: For block ciphers, the output size will always be less than or 
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + blockSize;
	void *buffer = malloc(bufferSize);
	
	size_t numBytes = 0;
	CCCryptorStatus cryptStatus = CCCrypt(operation, algorithm, 0,
										  key.bytes, key.length,
										  NULL /* initialization vector (optional) */,
										  [self bytes], dataLength, /* input */
										  buffer, bufferSize, /* output */
										  &numBytes);
	if (cryptStatus == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return [NSData dataWithBytesNoCopy:buffer length:dataLength];
	}
	
	free(buffer); //free the buffer;
	return nil;
}

- (NSData *)AESOperation:(int)operation key:(NSData *)key
{
    return [self CryptoOperation:operation algorithm:kCCAlgorithmAES128 blockSize:kCCBlockSizeAES128 key:key];
}

- (NSData *)AESEncryptWithKey:(NSData *)key
{
	return [self AESOperation:kCCEncrypt key:key];
}

- (NSData *)AESDecryptWithKey:(NSData *)key
{
	return [self AESOperation:kCCDecrypt key:key];
}


- (NSData *)DESOperation:(int)operation key:(NSData *)key
{
    //convert key to 24bytes if needed
    if(key.length==16)
    {
        NSMutableData *x=[NSMutableData dataWithData:key];
        [x appendData:[key subdataWithRange:NSMakeRange(0, 8)]];
        key=x;
    }
    return [self CryptoOperation:operation algorithm:kCCAlgorithm3DES blockSize:kCCBlockSize3DES key:key];
}

- (NSData *)DESEncryptWithKey:(NSData *)key
{
    return [self DESOperation:kCCEncrypt key:key];
}

- (NSData *)DESDecryptWithKey:(NSData *)key
{
    return [self DESOperation:kCCDecrypt key:key];
}

@end
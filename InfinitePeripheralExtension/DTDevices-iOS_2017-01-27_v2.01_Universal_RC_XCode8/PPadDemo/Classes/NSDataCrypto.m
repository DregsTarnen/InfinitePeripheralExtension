
#import "NSDataCrypto.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (AES)

- (NSData *)AESOperation:(int)operation key:(NSData *)key
{
	int keySize=kCCKeySizeAES256;
	if([key length]<=16)
		keySize=kCCKeySizeAES128;
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char keyPtr[kCCKeySizeAES256]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
	
	// fetch key data
	[key getBytes:keyPtr length:[key length]];
	
	NSUInteger dataLength = [self length];
	
	//See the doc: For block ciphers, the output size will always be less than or 
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	
	size_t numBytes = 0;
	CCCryptorStatus cryptStatus = CCCrypt(operation, kCCAlgorithmAES128, 0,
										  keyPtr, keySize,
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

- (NSData *)AESEncryptWithKey:(NSData *)key
{
	return [self AESOperation:kCCEncrypt key:key];
}

- (NSData *)AESDecryptWithKey:(NSData *)key
{
	return [self AESOperation:kCCDecrypt key:key];
}

@end
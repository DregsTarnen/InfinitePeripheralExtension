#import <Foundation/Foundation.h>

@interface NSData (AES)
- (NSData *)AESOperation:(int)operation key:(NSData *)key;
- (NSData *)AESEncryptWithKey:(NSData *)key;
- (NSData *)AESDecryptWithKey:(NSData *)key;
@end


#import <Foundation/Foundation.h>

@interface NSData (Crypto)
- (NSData *)AESOperation:(int)operation key:(NSData *)key;
- (NSData *)AESEncryptWithKey:(NSData *)key;
- (NSData *)AESDecryptWithKey:(NSData *)key;

- (NSData *)DESOperation:(int)operation key:(NSData *)key;
- (NSData *)DESEncryptWithKey:(NSData *)key;
- (NSData *)DESDecryptWithKey:(NSData *)key;
@end


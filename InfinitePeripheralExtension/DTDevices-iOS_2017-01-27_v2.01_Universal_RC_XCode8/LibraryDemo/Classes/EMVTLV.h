#import <Foundation/Foundation.h>

@interface TLV : NSObject

@property (assign) int tag;
@property (copy) NSData *data;
@property (readonly) const unsigned char *bytes;
@property (readonly) NSData *encodedData;

+(NSArray *)decodeTagList:(NSData *)data;
+(NSData *)encodeTagList:(NSArray *)data;


+(uint)tagFromHexString:(NSString *)string;

+(TLV *)tlvWithString:(NSString *)data tag:(uint)tag;
+(TLV *)tlvWithHexString:(NSString *)data tag:(uint)tag;
+(TLV *)tlvWithData:(NSData *)data tag:(uint)tag;
+(TLV *)tlvWithInt:(UInt64)data nBytes:(int)nBytes tag:(uint)tag;
+(TLV *)tlvWithBCD:(UInt64)data nBytes:(int)nBytes tag:(uint)tag;

+(TLV *)findLastTag:(int)tag tags:(NSArray *)tags;
+(NSArray *)findTag:(int)tag tags:(NSArray *)tags;
+(NSArray *)decodeTags:(NSData *)data;
+(NSData *)encodeTags:(NSArray *)tags;

@end
#import <Foundation/Foundation.h>

@interface EMVProcessorHelper : NSObject

+(NSData *)encodeTransactionDate:(NSDate *)date;
+(NSData *)encodeTransactionTime:(NSDate *)date;
+(NSData *)encodeTransactionSequence:(int)value;
+(NSData *)encodeAmount:(double)amount;
+(NSString *)decodeNib:(NSData *)value;
+(NSString *)decodeASCII:(NSData *)value;
+(int)decodeInt:(NSData *)value;
+(NSString *)decodeDateString:(NSData *)value;
+(NSString *)decodeTimeString:(NSData *)value;
+(NSString *)decodeAmountString:(NSData *)value;
+(NSString *)decodeHexString:(NSData *)value;
+(NSString *)getMaskedString:(NSString *)string unmaskedAtStart:(int)unmaskedAtStart unmaskedAtEnd:(int)unmaskedAtEnd;

@end

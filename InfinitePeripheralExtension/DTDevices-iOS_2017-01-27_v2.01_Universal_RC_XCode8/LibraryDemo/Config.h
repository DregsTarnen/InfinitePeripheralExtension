#import <Foundation/Foundation.h>

@interface Config : NSObject

+(NSData *)getDUKPTBDK;
+(NSData *)getDUKPTKSN1;
+(NSData *)getDUKPTKSN2;
+(NSData *)getAES128Key1;
+(NSData *)getAES128Key2;
+(NSData *)getAES128Key3;
+(NSData *)get3DESDataKey;
+(NSData *)get3DESPINKey;
+(NSData *)getPPadTestKEKBDK;
+(NSData *)paymentGetConfigurationFromXML:(NSString *)file;

@end

#import <CommonCrypto/CommonCryptor.h>

void dukptDeriveIPEK(const uint8_t bdk[16], const uint8_t ksn[10], uint8_t ipek[16]);
void dukptCalculateDataKey(const uint8_t ksn[10], const uint8_t ipek[16], uint8_t dukptDataKey[16]);
void dukptCalculatePINKey(const uint8_t ksn[10], const uint8_t ipek[16], uint8_t dukptPINKey[16]);
size_t trides_crypto(int operation, int mode, const void *data, size_t length, void *result, const void *key);

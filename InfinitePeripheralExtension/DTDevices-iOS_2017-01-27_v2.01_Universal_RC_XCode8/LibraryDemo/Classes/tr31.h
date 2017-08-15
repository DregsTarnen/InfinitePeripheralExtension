
#define HEADER_LEN 16

#define TDES_CMAC	0
#define AES_CMAC	1


typedef struct{
    uint8_t id[2];
    uint8_t len;
    uint8_t convert;
    uint8_t data[32];
}TSuppItem;

typedef struct{
    char KeyBlockVer;
    uint16_t KeyBlockLen;        // it is ASCII
    char usage[2];
    char cypher;
    char ModeOfUse;
    char Ver[2];
    char Export;
    uint16_t OptionBlocks;
    uint16_t Reserved;
    TSuppItem option[10];
    uint16_t dataLen;
    uint8_t data[256];
}TKeyBlock;


uint8_t CreateTR31Block(uint8_t* out, uint16_t *outLen, TKeyBlock *tr31, uint8_t* BPK, uint8_t BPK_len, uint8_t cypher);

class EMVTags {
    /**
    * Interface definition for EMV tags.
    */
    
    static let TAG_BF0C_FCI_ISSUER_DISCRETIONARY_DATA : UInt64 = 0xBF0C
    
    
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..10 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5A_PAN : UInt64 = 0x5A
    
    /**
    * ???
    */
    static let TAG_61_APPLICATION_TEMPLATE : UInt64 = 0x61
    
    /**
    * ???
    */
    static let TAG_6F_FCI : UInt64 = 0x6F
    
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..252 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    
    static let TAG_77_ICC_DATA : UInt64 = 0x77
    
    static let TAG_80_ICC_DATA : UInt64 = 0x80
    
    static let TAG_83_DATA : UInt64 = 0x83
    
    static let TAG_84_DF_NAME : UInt64 = 0x84
    
    static let TAG_8C_CDOL_1 : UInt64 = 0x8C
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..252 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_8D_CDOL_2 : UInt64 = 0x8D
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..252 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_8E_CVM_LIST : UInt64 = 0x8E
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..252 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_97_TDOL : UInt64 = 0x97
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..248 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_90_ISSUER_PK_CERTIFICATE : UInt64 = 0x90
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..248 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_93_SIGNED_STA_APP_DAT : UInt64 = 0x93
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..248 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_92_ISSUER_PK_REMAINDER : UInt64 = 0x92
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_8F_CA_PK_INDEX : UInt64 = 0x8F
    
    
    static let TAG_A5_FILE_CONTROL_INFORMATION : UInt64 = 0xA5
    
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2-26 <br>
    * Format: A <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F20_CARDHOLDER_NAME : UInt64 = 0x5F20
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F30_SERVICE_CODE : UInt64 = 0x5F30
    /**
    * <br>
    * Source: ICC <br>
    * Length: 27-45 <br>
    * Format: A <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F0B_CARDHOLDER_NAME_EXTEN : UInt64 = 0x9F0B
    
    static let TAG_9F0D_ISSUER_ACTION_CODE_DEFAULT : UInt64 = 0x9F0D
    
    static let TAG_9F0E_ISSUER_ACTION_CODE_DENIAL : UInt64 = 0x9F0E
    
    static let TAG_9F0F_ISSUER_ACTION_CODE_ONLINE : UInt64 = 0x9F0F
    
    
    /**
    * <br>
    * Source: ICC <br>
    * Length: 3 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F24_EXPIRY_DATE : UInt64 = 0x5F24
    /**
    * <br>
    * Source: ICC <br>
    * Length: 3 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F25_EFFECTIVE_DATE : UInt64 = 0x5F25
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F28_ISSUER_COUNTRY_CODE : UInt64 = 0x5F28
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: A <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F55_ISSUER_COUNTRY_CODE_A2 : UInt64 = 0x5F55
    /**
    * <br>
    * Source: ICC <br>
    * Length: 3 <br>
    * Format: A <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F56_ISSUER_COUNTRY_CODE_A3 : UInt64 = 0x5F56
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F34_PAN_SEQUENCE_NUMBER : UInt64 = 0x5F34
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1-32 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F05_APP_DISCRETION_DAT : UInt64 = 0x9F05
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F07_APP_USAGE_CONTROL : UInt64 = 0x9F07
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F08_ICC_APP_VERSION_NUMBER : UInt64 = 0x9F08
    /**
    * <br>
    * Source: ICC <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F0D_ISSUER_ACTION_DEFAULT : UInt64 = 0x9F0D
    /**
    * <br>
    * Source: ICC <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F0E_ISSUER_ACTION_DENIAL : UInt64 = 0x9F0E
    /**
    * <br>
    * Source: ICC <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F0F_ISSUER_ACTION_ONLINE : UInt64 = 0x9F0F
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2-8 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F3B_APPL_REF_CURRENCY : UInt64 = 0x9F3B
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F42_APPL_CURRENCY_CODE : UInt64 = 0x9F42
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1-4 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F43_APPL_REF_CURRENCY_EXP : UInt64 = 0x9F43
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F44_APPL_CURRENCY_EXP : UInt64 = 0x9F44
    /**
    * <br>
    * Source: ICC <br>
    * Length: 248 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F46_ICC_PK_CERTIFICATE : UInt64 = 0x9F46
    /**
    * <br>
    * Source: ICC <br>
    * Length: 248 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F2D_ICC_PIN_PK_CERTIFICATE : UInt64 = 0x9F2D
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1-3 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F47_ICC_PK_EXP : UInt64 = 0x9F47
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1-3 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F2E_ICC_PIN_PK_EXP : UInt64 = 0x9F2E
    /**
    * <br>
    * Source: ICC <br>
    * Length: 248 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F48_ICC_PK_REMAINDER : UInt64 = 0x9F48
    /**
    * <br>
    * Source: ICC <br>
    * Length: 248 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F2F_ICC_PIN_PK_REMAINDER : UInt64 = 0x9F2F
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..252 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F4A_STA_DAT_AUTH_TAG_LIST : UInt64 = 0x9F4A
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..252 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F49_DDOL : UInt64 = 0x9F49
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1-3 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F32_ISSUER_PK_EXP : UInt64 = 0x9F32
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F14_LOW_CONSEC_OFFLINE_LIMIT : UInt64 = 0x9F14
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F23_UPP_CONSEC_OFFLINE_LIMIT : UInt64 = 0x9F23
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..22 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F20_TRACK2_DISCRETION_DAT : UInt64 = 0x9F20
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..52 <br>
    * Format: A <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F1F_TRACK1_DISCRETION_DAT : UInt64 = 0x9F1F
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..19 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_57_TRACK2_EQUIVALENT_DATA : UInt64 = 0x57
    /**
    * <br>
    * Source: KER <br>
    * Length: 4 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F37_UNPREDICTABLE_NUMBER : UInt64 = 0x9F37
    /**
    * <br>
    * Source: APP <br>
    * Length: 6 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F01_ACQUIRER_IDENTIFIER : UInt64 = 0x9F01
    /**
    * <br>
    * Source: APP <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F40_ADD_TERM_CAPABILITIES : UInt64 = 0x9F40
    /**
    * <br>
    * Source: APP <br>
    * Length: 4 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_81_AMOUNT_AUTHORISED_BINARY : UInt64 = 0x81
    /**
    * <br>
    * Source: APP <br>
    * Length: 6 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F02_AMOUNT_AUTHORISED_NUM : UInt64 = 0x9F02
    /**
    * <br>
    * Source: APP <br>
    * Length: 4 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F04_AMOUNT_OTHER_BINARY : UInt64 = 0x9F04
    /**
    * <br>
    * Source: APP <br>
    * Length: 6 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F03_AMOUNT_OTHER_NUM : UInt64 = 0x9F03
    /**
    * <br>
    * Source: APP <br>
    * Length: 4 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F3A_AMOUNT_REF_CURR : UInt64 = 0x9F3A
    /**
    * <br>
    * Source: ICC <br>
    * Length: 8 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F26_APP_CRYPTOGRAM : UInt64 = 0x9F26
    /**
    * <br>
    * Source: ICC <br>
    * Length: ...252 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_94_AFL : UInt64 = 0x94
    /**
    * <br>
    * Source: ICC <br>
    * Length: 5-16 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_4F_ICC_AID : UInt64 = 0x4F
    /**
    * <br>
    * Source: APP <br>
    * Length: 5-16 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F06_TERM_AID : UInt64 = 0x9F06
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_82_AIP : UInt64 = 0x82
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1-16 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_50_APP_LABEL : UInt64 = 0x50
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1-16 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F12_APP_PREFERRED_NAME : UInt64 = 0x9F12
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_87_APP_PRIORITY_INDICATOR : UInt64 = 0x87
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F36_ATC : UInt64 = 0x9F36
    /**
    * <br>
    * Source: APP <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F09_APP_VERSION_NUMBER : UInt64 = 0x9F09
    /**
    * <br>
    * Source: APP <br>
    * Length: 6 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_89_AUTH_CODE : UInt64 = 0x89
    /**
    * <br>
    * Source: APP <br>
    * Length: 2 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_8A_AUTH_RESP_CODE : UInt64 = 0x8A
    /**
    * <br>
    * Source: KER <br>
    * Length: 3 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F34_CH_VERIF_METHOD_RESULT : UInt64 = 0x9F34
    /**
    * <br>
    * Source: APP <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F22_CA_PUBLIC_KEY_INDEX : UInt64 = 0x9F22
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F27_CRYPT_INFO_DATA : UInt64 = 0x9F27
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F45_DAT_AUTH_CODE : UInt64 = 0x9F45
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2-8 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F4C_ICC_DYN_NUMBER : UInt64 = 0x9F4C
    /**
    * <br>
    * Source: APP <br>
    * Length: 8 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F1E_SERIAL_NUMBER : UInt64 = 0x9F1E
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..32 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F10_ISSUER_APP_DAT : UInt64 = 0x9F10
    /**
    * <br>
    * Source: APP <br>
    * Length: 8-16 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_91_ISSUER_AUTH_DAT : UInt64 = 0x91
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F11_ISSUER_CODE_TABLE_INDEX : UInt64 = 0x9F11
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2-8 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F2D_LANGUAGE_PREFERENCE : UInt64 = 0x5F2D
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F13_LATC : UInt64 = 0x9F13
    /**
    * <br>
    * Source: APP <br>
    * Length: 2 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F15_MERCHANT_CATEGORY_CODE : UInt64 = 0x9F15
    /**
    * <br>
    * Source: APP <br>
    * Length: 15 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F16_MERCHANT_IDENTIFIER : UInt64 = 0x9F16
    /**
    * <br>
    * Source: ICC <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F17_PIN_TRY_COUNTER : UInt64 = 0x9F17
    /**
    * <br>
    * Source: APP <br>
    * Length: 1 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F39_POS_ENTRY_MODE : UInt64 = 0x9F39
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..252 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F38_PDOL : UInt64 = 0x9F38
    /**
    * <br>
    * Source: APP <br>
    * Length: 3 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F33_TERMINAL_CAPABILITIES : UInt64 = 0x9F33
    /**
    * <br>
    * Source: APP <br>
    * Length: 2 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F1A_TERMINAL_COUNTRY_CODE : UInt64 = 0x9F1A
    /**
    * <br>
    * Source: APP <br>
    * Length: 4 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F1B_TERMINAL_FLOOR_LIMIT : UInt64 = 0x9F1B
    /**
    * <br>
    * Source: APP <br>
    * Length: 8 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F1C_TERMINAL_ID : UInt64 = 0x9F1C
    /**
    * <br>
    * Source: APP <br>
    * Length: 1-8 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F1D_TERMINAL_RISK_DAT : UInt64 = 0x9F1D
    /**
    * <br>
    * Source: APP <br>
    * Length: 1 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F35_TERMINAL_TYPE : UInt64 = 0x9F35
    /**
    * <br>
    * Source: KER <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_95_TVR : UInt64 = 0x95
    /**
    * <br>
    * Source: APP <br>
    * Length: 2 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_5F2A_TRANSACTION_CURR_CODE : UInt64 = 0x5F2A
    /**
    * <br>
    * Source: APP <br>
    * Length: 1 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_5F36_TRANSACTION_CURR_EXP : UInt64 = 0x5F36
    /**
    * <br>
    * Source: APP <br>
    * Length: 3 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9A_TRANSACTION_DATE : UInt64 = 0x9A
    /**
    * <br>
    * Source: APP <br>
    * Length: 2 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F3C_TRANSACTION_REF_CURR_CODE : UInt64 = 0x9F3C
    /**
    * <br>
    * Source: APP <br>
    * Length: 1 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F3D_TRANSACTION_REF_CURR_EXP : UInt64 = 0x9F3D
    /**
    * <br>
    * Source: APP <br>
    * Length: 2-4 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F41_TRANSACTION_SEQ_COUNTER : UInt64 = 0x9F41
    /**
    * <br>
    * Source: KER <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9B_TSI : UInt64 = 0x9B
    /**
    * <br>
    * Source: APP <br>
    * Length: 3 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F21_TRANSACTION_TIME : UInt64 = 0x9F21
    /**
    * <br>
    * Source: APP <br>
    * Length: 1 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9C_TRANSACTION_TYPE : UInt64 = 0x9C
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..248 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F4B_SIGNED_DYN_APP_DAT : UInt64 = 0x9F4B
    /**
    * <br>
    * Source: APP <br>
    * Length: 20 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_98_TC_HASH_VALUE : UInt64 = 0x98
    /**
    * <br>
    * Source: APP <br>
    * Length: 1 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_5F37_ACCOUNT_TYPE : UInt64 = 0x5F37
    /**
    * <br>
    * Source: ICC <br>
    * Length: 8-11 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F54_BANK_IDENTIFIER_CODE : UInt64 = 0x5F54
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..34 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F53_IBAN : UInt64 = 0x5F53
    /**
    * <br>
    * Source: ICC <br>
    * Length: 3 <br>
    * Format: N <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_42_ISSUER_IDENTIFICATION_NUMBER : UInt64 = 0x42
    /**
    * <br>
    * Source: ICC <br>
    * Length: ..255 <br>
    * Format: AN <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_5F50_ISSUER_URL : UInt64 = 0x5F50
    /**
    * <br>
    * Source: ICC <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_9F4D_LOG_ENTRY : UInt64 = 0x9F4D
    
    /**
    * <br>
    * Source: APP <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_9F53_TRANSACTION_CATEGORY_CODE : UInt64 = 0x9F53
    /**
    * <br>
    * Source: APP <br>
    * Length: 4 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF01_TRANSACTION_REFERENCE_NUMBER : UInt64 = 0xDF01
    /**
    * <br>
    * Source: APP <br>
    * Length: 4 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF02_RISK_AMOUNT : UInt64 = 0xDF02
    /**
    * <br>
    * Source: APP <br>
    * Length: 4 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF02_TRANSACTION_AUTHORIZATION_NUMBER : UInt64 = 0xDF02
    /**
    * <br>
    * Source: APP <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF03_TERM_ACTION_DEFAULT : UInt64 = 0xDF03
    /**
    * <br>
    * Source: APP <br>
    * Length: 4 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF03_TRANSACTION_REFERENCE : UInt64 = 0xDF03
    /**
    * <br>
    * Source: APP <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF04_TERM_ACTION_DENIAL : UInt64 = 0xDF04
    /**
    * <br>
    * Source: APP <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF05_TERM_ACTION_ONLINE : UInt64 = 0xDF05
    /**
    * <br>
    * Source: APP <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF05_TRANSACTION_RESULT : UInt64 = 0xDF05
    /**
    * <br>
    * Source: APP <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF06_TRANSACTION_ERROR_CODE : UInt64 = 0xDF06
    /**
    * <br>
    * Source: APP <br>
    * Length: 5 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF07_THRESHOLD_VALUE : UInt64 = 0xDF07
    /**
    * <br>
    * Source: APP <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF08_TARGET_PERCENTAGE : UInt64 = 0xDF08
    /**
    * <br>
    * Source: APP <br>
    * Length: 1 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF09_MAX_TARGET_PERCENTAGE : UInt64 = 0xDF09
    /**
    * <br>
    * Source: APP <br>
    * Length: ...252 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF15_DEFAULT_DDOL : UInt64 = 0xDF15
    /**
    * <br>
    * Source: APP <br>
    * Length: ..252 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF18_DEFAULT_TDOL : UInt64 = 0xDF18
    /**
    * <br>
    * Source: APP <br>
    * Length: 2 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF19_FLOOR_LIMIT_CURRENCY : UInt64 = 0xDF19
    /**
    * <br>
    * Source: APP <br>
    * Length: ..2048 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_DF23_OFF_AUTH_DAT : UInt64 = 0xDF23
    /**
    * <br>
    * Source: APP <br>
    * Length: ..256 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: YES
    */
    static let TAG_DF24_ISSUER_SCRIPTS : UInt64 = 0xDF24
    /**
    * <br>
    * Source: APP <br>
    * Length: ..256 <br>
    * Format: B <br>
    * Read: YES <br>
    * Write: NO
    */
    static let TAG_DF25_ISSUER_SCRIPTS_RESULT : UInt64 = 0xDF25
    
    /**
    * <br>
    */
    static let TAG_DF27_COMMON_APP_NUMBER : UInt64 = 0xDF27
    
    
}
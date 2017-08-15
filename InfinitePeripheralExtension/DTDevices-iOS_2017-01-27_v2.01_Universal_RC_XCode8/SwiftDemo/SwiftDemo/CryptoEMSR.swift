import Foundation

class CryptoEMSR: CryptoTemplate {
    var headType = EMSR_REAL
    var kekPresent = false
    
    var settings = [String]()
    
    override func getSectionName() -> String {
        return (headType == EMSR_REAL) ? "Encrypted Magnetic Head" : "Emulated EMSR"
    }
    
    func update() throws {
        settings=[]
        settings.append("Refresh Information")
        settings.append("Reads current keys and state")
        settings.append("Load Keys")
        settings.append("Loads KEK, AES256 Data, DUKPT")
        
        //read current
        try lib.emsrSetActiveHead(headType)
        let emsrInfo = try lib.emsrGetDeviceInfo()
        let emsrKeysInfo = try lib.emsrGetKeysInfo()
        settings.append("Tampered: \(emsrKeysInfo.tampered), ver: \(emsrInfo.firmwareVersionString), sec: \(emsrInfo.securityVersionString)")
        settings.append("Serial: \(emsrInfo.serialNumberString)")
        
        //keys
        for key in emsrKeysInfo.keys {
            if key.keyVersion != 0 {
                settings.append("Type: \(key.keyName)")
                settings.append("Version: \(key.keyVersion)")
            }
            
            //mark if kek is present, this is gonna be used later when loading keys
            if key.keyID == KEY_EH_AES256_LOADING {
                kekPresent = key.keyVersion != 0
            }
        }
    }
    
    init(viewController: CryptoViewController, section: Int, headType: Int32) {
        super.init(viewController: viewController, section: section)
        
        self.headType = headType
        do {
            try update()
        } catch {
        }
    }
    
    override func getNumberOfRows() -> Int {
        return settings.count/2
    }
    
    override func setCell(cell: UITableViewCell, row: Int) {
        cell.textLabel?.text=settings[row*2+0]
        cell.detailTextLabel?.text=settings[row*2+1]
        cell.accessoryType = UITableViewCellAccessoryType.none
    }
    
    func SHA256(data: NSData) -> NSData {
        let hash = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(CC_SHA256_DIGEST_LENGTH))
        
        CC_SHA256(data.bytes,UInt32(data.length),hash)
        
        let r = NSData(bytes: hash, length: Int(CC_SHA256_DIGEST_LENGTH))
        free(hash)
        
        return r
    }
    
    func AESOperation(data: NSData, operation:CCOperation, key:NSData) -> NSData? {
        var keySize=kCCKeySizeAES256;
        if key.length <= 16 {
            keySize=kCCKeySizeAES128;
        }
        
        //See the doc: For block ciphers, the output size will always be less than or
        //equal to the input size plus the size of one block.
        //That's why we need to add the size of one block here
        let bufferSize = data.length + kCCBlockSizeAES128;
        //        let hash = UnsafeMutablePointer<UInt8>.alloc(Int(CC_SHA256_DIGEST_LENGTH))
        let buffer = malloc(bufferSize);
        var numBytes:size_t = 0;
        let cryptStatus = CCCrypt(operation, CCAlgorithm(kCCAlgorithmAES128), 0, key.bytes, keySize, nil, data.bytes, data.length, buffer, bufferSize, &numBytes);
        
        var d: NSData? = nil
        if (cryptStatus == CCCryptorStatus(kCCSuccess)) {
            //the returned NSData takes ownership of the buffer and will free it on deallocation
            d=NSData(bytes: buffer, length: numBytes);
        }
        
        free(buffer); //free the buffer;
        return d;
    }
    
    func AESEncryptWithKey(data: NSData, key:NSData) -> NSData? {
        return AESOperation(data: data, operation:CCAlgorithm(kCCEncrypt), key:key);
    }
    
    func AESDecryptWithKey(data: NSData, key:NSData) -> NSData? {
        return AESOperation(data: data, operation:CCAlgorithm(kCCDecrypt), key:key);
    }
    
    /**
     Loads initial key in plain text or changes existing key. Keys in plain text can be loaded only once,
     on every subsequent key change, they needs to be encrypted with KEY_EH_AES256_LOADING.
     
     KEY_EH_AES256_LOADING can be used to change all the keys in the head except for the TMK, and KEY_AES256_LOADING
     can be loaded in plain text the first time too.
     */
    func emsrGenerateKeyData(keyID: Int32, keyVersion: Int, keyData: [UInt8], kekData: [UInt8]?) -> [UInt8] {
        var data: [UInt8] = []
        
        data.append(0x2b)
        //key to encrypt with, either KEY_AES256_LOADING or 0xff to use plain text
        data.append((kekData != nil) ? UInt8(KEY_EH_AES256_LOADING) : 0xff)
        data.append(UInt8(keyID)) //key to set
        data.append(UInt8(keyVersion>>24)) //key version
        data.append(UInt8(keyVersion>>16)) //key version
        data.append(UInt8(keyVersion>>8)) //key version
        data.append(UInt8(keyVersion)) //key version
        
        let keyStart = data.count
        
        var hashed: [UInt8] = []
        hashed.append(contentsOf: data)
        hashed.append(contentsOf: keyData) //key data
        let hash = SHA256(data: NSData(bytes: hashed, length: hashed.count))
        
        hashed.append(contentsOf: hash.getBytes())
        
        //encrypt the data if using the encryption key
        if kekData != nil {
            let toEncrypt=NSData(bytes:&hashed[keyStart], length: hashed.count-keyStart)
            let encrypted=AESEncryptWithKey(data: toEncrypt, key: kekData!.getNSData() as NSData)
            
            //store the encryptd data back into the packet
            data.append(contentsOf: encrypted!.getBytes())
        }else {
            
        }
        return data
    }
    
    //prepares and loads a key
    //NOTE!!!! There can't be a key with duplicate value, this is PCI requirement!
    func loadKeyID(keyID: Int32, keyData:[UInt8], keyVersion:Int, kekData:[UInt8]?) -> Bool {
        //format the key to load it, optionally encrypt with KEK
        let generatedKeyData = emsrGenerateKeyData(keyID: keyID, keyVersion: keyVersion, keyData: keyData, kekData: kekData)
        //get the key name, for display purposers
        let keyName = EMSRKeysInfo.keyName(byID: keyID)
        
        do {
            //try to load the key in the slot
            try lib.emsrLoadKey(generatedKeyData.getNSData())
            Utils.showMessage("Success!", message: "Key \(String(describing: keyName)) loaded successfully!")
            return true
        } catch let error as NSError {
            Utils.showError("Loading \(String(describing: keyName)) failed!", error: error)
        }
        return false;
    }
    
    override func execute(cell: UITableViewCell, row: Int) {
        
        do {
            if row == 0 {
                try update()
            }
            if row == 1 {
                var result=true
                if result {
                    //see if kek is present, if not, load it
                    var kekVer:Int32 = 0
                    do {
                        try lib.emsrGetKeyVersion(KEY_EH_AES256_LOADING, keyVersion: &kekVer)
                        if kekVer <= 0 {
                            result = loadKeyID(keyID: KEY_EH_AES256_LOADING, keyData: Constants.keyAES256KEK, keyVersion: 2, kekData: nil)
                        }
                    }
                }
                if result {
                    //load aes256 data key
                    result = loadKeyID(keyID: KEY_EH_AES256_ENCRYPTION1, keyData: Constants.keyAES256Data, keyVersion: 2, kekData: Constants.keyAES256KEK)
                }
            }
        } catch let error as NSError {
            Utils.showError("Operation", error: error)
        }
        self.viewController.tvCrypto.reloadData()
    }
}

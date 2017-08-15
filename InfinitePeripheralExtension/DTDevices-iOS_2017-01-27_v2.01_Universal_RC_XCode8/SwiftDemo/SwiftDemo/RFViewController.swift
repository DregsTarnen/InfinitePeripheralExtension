import UIKit

class RFViewController: UIViewController, DTDeviceDelegate {

    let TOTAL = 100

    @IBOutlet weak var tvInfo: UITextView!

    let lib=DTDevices.sharedDevice() as! DTDevices

    //#define CHECK_RESULT(description,result) if(result){[log appendFormat:@"%@: SUCCESS\n",description]; NSLog(@"%@: SUCCESS",description);} else {[log appendFormat:@"%@: FAILED (%@)\n",description,error.localizedDescription]; NSLog(@"%@: FAILED (%@)\n",description,error.localizedDescription); }

    //    #define DF_CMD(command,description) r=[dtdev iso14Transceive:info.cardIndex data:[NSData dataWithBytes:command length:sizeof(command)] status:&cardStatus error:&error]; \
    //    if(r) [log appendFormat:@"%@ succeed with status: %@ response: %@\n",description,dfStatus2String(cardStatus),r]; else [log appendFormat:@"%@ failed with error: %@\n",description,error.localizedDescription];


    //support functions
    //#define MIARE_USE_STORED_KEY
    func mifareAuthenticate(cardIndex: Int32, address: Int32, key:[UInt8]?) throws {

        var keyData:Data? = nil
        if key==nil
        {
            let defaultMifareKey:[UInt8] = [0xFF,0xFF,0xFF,0xFF,0xFF,0xFF]
            //use the default key
            keyData = defaultMifareKey.getNSData()
        }

        try lib.mfAuth(byKey: cardIndex, type: 0x41, address: address, key: keyData)
    }



    //helper func to write some ordinary data on mifare classic cards without touching the sectors containing the sensitive data
    //like keys being used
    func mifareSafeWrite(cardIndex: Int32, address:Int32, data:[UInt8], key:[UInt8]?) throws {

        guard address < 4 else {
            return
        }

        var lastAuth: Int32 = -1
        var addr = address;
        var written = 0
        while written < data.count {
            if (addr % 4) == 3 {
                addr += 1;
                continue
            }
            if lastAuth != (addr / 4) {
                lastAuth = addr / 4
                try mifareAuthenticate(cardIndex: cardIndex, address: addr, key: key)
            }
            let block = data.subArray(written, end: min(16, data.count - written))

            var bytesWritten: Int32 = 0;
            try lib.mfWrite(cardIndex, address: addr, data: block.getNSData(), bytesWritten: &bytesWritten)
            written += Int(bytesWritten)
            addr += 1;
        }
    }

    //helper func to read some ordinary data from mifare classic cards without touching the sectors containing the sensitive data
    //like keys being used
    func mifareSafeRead(cardIndex: Int32, address:Int32, length: Int, key:[UInt8]?) throws -> [UInt8] {
        var data = [UInt8]()
        var lastAuth: Int32 = -1
        var addr = address;
        var read = 0
        while read < length {
            if (addr % 4) == 3 {
                addr += 1;
                continue
            }
            if lastAuth != (addr / 4) {
                lastAuth = addr / 4
                try mifareAuthenticate(cardIndex: cardIndex, address: addr, key: key)
            }

            let block = try lib.mfRead(cardIndex, address: addr, length: 16)
            data.append(contentsOf: block)
            read += block.count
            addr += 1;
        }
        return data
    }

    func dfStatus2String(status: UInt8) -> String
    {
        switch (status)
        {
        case 0x00:
            return "OPERATION_OK";
        case 0x0C:
            return "NO_CHANGES";
        case 0x0E:
            return "OUT_OF_EEPROM_ERROR";
        case 0x1C:
            return "ILLEGAL_COMMAND_CODE";
        case 0x1E:
            return "INTEGRITY_ERROR";
        case 0x40:
            return "NO_SUCH_KEY";
        case 0x7E:
            return "LENGTH_ERROR";
        case 0x9D:
            return "PERMISSION_DENIED";
        case 0x9E:
            return "PARAMETER_ERROR";
        case 0xA0:
            return "APPLICATION_NOT_FOUND";
        case 0xA1:
            return "APPL_INTEGRITY_ERROR";
        case 0xAE:
            return "AUTHENTICATION_ERROR";
        case 0xAF:
            return "ADDITIONAL_FRAME";
        case 0xBE:
            return "BOUNDARY_ERROR";
        case 0xC1:
            return "PICC_INTEGRITY_ERROR";
        case 0xCD:
            return "PICC_DISABLED_ERROR";
        case 0xCE:
            return "COUNT_ERROR";
        case 0xDE:
            return "DUPLICATE_ERROR";
        case 0xEE:
            return "EEPROM_ERROR";
        case 0xF0:
            return "FILE_NOT_FOUND";
        case 0xF1:
            return "FILE_INTEGRITY_ERROR";
        default:
            return "UNKNOWN";
        }
    }

    func dfCommand(description: String, cardIndex: Int32, data:[UInt8]) -> Bool {

        do {
            var status: UInt8 = 0
            let r = try lib.iso14Transceive(cardIndex, data: data.getNSData(), status: &status)

            let statusStr = dfStatus2String(status: status)
            tvInfo.text.append("\(description) succeeded with status \(statusStr)(\(status)) and response: \(r.toHexString())\n")
            return true
        } catch {
            tvInfo.text.append("\(description) failed: \(error.localizedDescription)\n")
        }
        return false
    }

    //rf delegates
    func rfCardRemoved(_ cardIndex: Int32) {
        tvInfo.text.append("\nCard removed")
        tvInfo.backgroundColor=UIColor.init(red: 0, green: 0, blue: 1, alpha: 0.3)
    }

    func rfCardDetected(_ cardIndex: Int32, info: DTRFCardInfo!) {

        Progress.show(self);
        RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 0.1)) //just to show the progress, the correct way is to get all this on a separate thread

        tvInfo.text = "\(info.typeStr!) card detected\n"
        tvInfo.text.append("Serial: \(info.uid.toHexString())\n")

        var success = true

        switch (info.type)
        {
        case .CARD_MIFARE_DESFIRE:
            //delay the communication a bit, giving time the card to be more fully inserted into the field
            //it can happen that the card is detected, but not having enough power to do cryptography
            Thread.sleep(forTimeInterval: 0.3)

            do {
                let ats = try lib.iso14GetATS(cardIndex)
                tvInfo.text.append("ATS Data: \(ats.toHexString())\n")
            } catch {
                tvInfo.text.append("Get ATS failed: \(error.localizedDescription)\n")
                success = false
            }

            let SELECT_APPID_MASTER: [UInt8] = [ 0x5A, 0x00, 0x00, 0x00 ]
            //            let SELECT_APPID_WRONG: [UInt8] = [ 0x5A, 0x00, 0x00, 0x01 ]
            let AUTH_ROUND_ONE: [UInt8] = [ 0xAA, 0x00 ]

            if !dfCommand(description: "Select master application", cardIndex: cardIndex, data: SELECT_APPID_MASTER) {
                success = false
            }

            if !dfCommand(description: "Authenticate round 1", cardIndex: cardIndex, data: AUTH_ROUND_ONE) {
                success = false
            }

            break

        case .CARD_MIFARE_MINI, .CARD_MIFARE_CLASSIC_1K, .CARD_MIFARE_CLASSIC_4K, .CARD_MIFARE_PLUS:
            //16 bytes reading and 16 bytes writing
            //it is best to store the keys you are going to use once in the device memory, then use mfAuthByStoredKey function to authenticate blocks rahter than having the key in your program

            do {
                let dataToWrite:[UInt8]=[0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1A,0x1B,0x1C,0x1D,0x1E,0x1F,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2A,0x2B,0x2C,0x2D,0x2E,0x2F];
                try mifareSafeWrite(cardIndex: cardIndex, address: 8, data: dataToWrite, key: nil)
                tvInfo.text.append("Mifare write complete!\n")
            } catch {
                tvInfo.text.append("Mifare write failed: \(error.localizedDescription)\n")
                success = false
            }

            do {
                let block = try mifareSafeRead(cardIndex: cardIndex, address: 8, length: 4*16, key: nil)
                tvInfo.text.append("Mifare read complete: \(block.toHexString())\n")
            } catch {
                tvInfo.text.append("Mifare read failed: \(error.localizedDescription)\n")
                success = false
            }
            break

        case .CARD_MIFARE_ULTRALIGHT, .CARD_MIFARE_ULTRALIGHT_C:
            //16 bytes reading, 4 bytes writing
            Thread.sleep(forTimeInterval: 0.5) //give the card some time if we are going to try crypto operations
            //try reading a block
            do {
                let block = try lib.mfRead(cardIndex, address: 8, length: 16)
                tvInfo.text.append("Mifare read complete: \(block.toHexString())\n")
            } catch {
                tvInfo.text.append("Mifare read failed: \(error.localizedDescription)\n")
                success = false
            }

            do {
                try lib.mfUlcAuth(byKey: cardIndex, key: "BREAKMEIFYOUCAN!".data(using: .ascii))
                tvInfo.text.append("Mifare authenticate complete\n")
            } catch {
                tvInfo.text.append("Mifare authenticate failed: \(error.localizedDescription)\n")
                success = false
            }

            do {
                let block = try lib.mfRead(cardIndex, address: 8, length: 16)
                tvInfo.text.append("Mifare read complete: \(block.toHexString())\n")
            } catch {
                tvInfo.text.append("Mifare read failed: \(error.localizedDescription)\n")
                success = false
            }

            //change key
            do {
                try lib.mfWrite(cardIndex, address: 0x2C, data: "12345678abcdefgh!".data(using: .ascii), bytesWritten: nil)
                tvInfo.text.append("Mifare write complete\n")
            } catch {
                tvInfo.text.append("Mifare write failed: \(error.localizedDescription)\n")
                success = false
            }
            break;

        case .CARD_ISO15693:
            //block size is different between cards
            tvInfo.text.append("Block size: \(info.blockSize)\n")
            tvInfo.text.append("Number of blocks: \(info.nBlocks)\n")

            do {
                let security = try lib.iso15693GetBlocksSecurityStatus(cardIndex, startBlock: 0, nBlocks: 16)
                tvInfo.text.append("Security status: \(security.toHexString())\n")
            } catch {
                tvInfo.text.append("Security status failed: \(error.localizedDescription)\n")
                success = false
            }

            //write something to the card
            do {
                let dataToWrite:[UInt8]=[0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07]
                try lib.iso15693Write(cardIndex, startBlock: 0, data: dataToWrite.getNSData(), bytesWritten: nil)
                tvInfo.text.append("Write complete\n")
            } catch {
                tvInfo.text.append("Write failed: \(error.localizedDescription)\n")
                success = false
            }

            //try reading 2 blocks
            do {
                let block = try lib.iso15693Read(cardIndex, startBlock: 0, length: 2*info.blockSize)
                tvInfo.text.append("Read complete: \(block.toHexString())\n")
            } catch {
                tvInfo.text.append("Read failed: \(error.localizedDescription)\n")
                success = false
            }
            break;

        case .CARD_FELICA:
            //16 byte blocks for both reading and writing

            //custom command
            do {
                let readCmd:[UInt8]=[0x01,0x09,0x00,0x01,0x80,0x00]
                let cmdResponse = try lib.felicaSendCommand(cardIndex, command: 0x06, data: readCmd.getNSData())
                tvInfo.text.append("Custom command: \(cmdResponse.toHexString())\n")
            } catch {
                tvInfo.text.append("Custom command failed: \(error.localizedDescription)\n")
                success = false
            }

            //check if the card is FeliCa SmartTag or normal felica
            let uid = info.uid.getBytes()!
            if uid[0]==0x03 && uid[1]==0xFE && uid[2]==0x00 && uid[3]==0x1D
            {//SmartTag
                //read battery, call this command ALWAYS before communicating with the card
                do {
                    var battery:Int32 = 0;
                    try lib.felicaSmartTagGetBatteryStatus(cardIndex, status: &battery)
                    var batteryString = "Unknown"
                    switch FELICA_SMARTTAG_BATERY_STATUSES(rawValue: battery)! {
                    case .BATTERY_NORMAL1, .BATTERY_NORMAL2:
                        batteryString = "Normal"
                        break

                    case .BATTERY_LOW1:
                        batteryString = "Low"
                        break

                    case .BATTERY_LOW2:
                        batteryString = "Very low"
                        break
                    }

                    tvInfo.text.append("SmartTag battery: \(batteryString)\n")
                } catch {
                    tvInfo.text.append("SmartTag battery failed: \(error.localizedDescription)\n")
                    success = false
                }


            }else
            {//Normal

                //write 1 block
                do {
                    let dataToWrite:[UInt8]=[0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F]
                    try lib.felicaWrite(cardIndex, serviceCode: 0x0900, startBlock: 0, data: dataToWrite.getNSData(), bytesWritten: nil)
                    tvInfo.text.append("Write complete\n")
                } catch {
                    tvInfo.text.append("Write failed: \(error.localizedDescription)\n")
                    success = false
                }

                //read 1 block
                do {
                    let block = try lib.felicaRead(cardIndex, serviceCode: 0x0900, startBlock: 0, length: info.blockSize)
                    tvInfo.text.append("Read complete: \(block.toHexString())\n")
                } catch {
                    tvInfo.text.append("Read failed: \(error.localizedDescription)\n")
                    success = false
                }
            }

            break

        default:
            break
        }

        if success {
            tvInfo.backgroundColor=UIColor.init(red: 0, green: 0, blue: 1, alpha: 0.3)
        } else {
            tvInfo.backgroundColor=UIColor.init(red: 0, green: 0, blue: 1, alpha: 0.3)
        }

        Progress.hide()

        do {
            try lib.rfRemoveCard(cardIndex)
        } catch {
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        lib.addDelegate(self)
        do {
            try lib.rfInit(CARD_SUPPORT_PICOPASS_ISO15|CARD_SUPPORT_TYPE_A|CARD_SUPPORT_TYPE_B|CARD_SUPPORT_ISO15|CARD_SUPPORT_FELICA)
            tvInfo.text="Put RF card in the field..."
        } catch {
            Utils.showError("RF Module init failed", error: error as NSError?)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        lib.removeDelegate(self)
        do {
            try lib.rfClose()
        } catch {
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


import Foundation

class SettingsAlgorithm: SettingsTemplate {
    
    var selected = -1
    
    override func getSectionName() -> String {
        return "Encryption Algorithm"
    }
    
    let formsts=[
        ALG_EH_AES256,
        ALG_EH_IDTECH,
        ALG_EH_RSA_OAEP,
        ALG_EH_VOLTAGE,
        ALG_EH_MAGTEK,
        ALG_EH_AES128,
        ALG_PPAD_DUKPT,
        ALG_PPAD_3DES_CBC,
        ALG_EH_IDTECH_AES128,
        ALG_EH_MAGTEK_AES128,
        ALG_TRANSARMOR,
        ALG_PPAD_DUKPT_SEPARATE_TRACKS,
        ]
    
    let settings=[
        "AES 256",
        "IDTECH 3",
        "RSA-OAEP",
        "Voltage",
        "Magtek",
        "AES 128",
        "PPAD DUKPT",
        "PPAD 3DES",
        "IDTECH 3 (AES128)",
        "Magtek (AES128)",
        "TransArmor",
        "PPAD DUKPT (Separate)",
        ]
    
    override func getNumberOfRows() -> Int {
        return settings.count
    }
    
    override func setCell(cell: UITableViewCell, row: Int) {
        cell.textLabel?.text=settings[row]
        cell.detailTextLabel?.text=""
        
        if selected == -1 {
            var algorithm: Int32 = ALG_EH_IDTECH
            
            let prefs = UserDefaults.standard;
            if prefs.value(forKey: "Algorithm") != nil {
                algorithm = Int32(prefs.integer(forKey: "Algorithm"))
            }
            
            selected = formsts.index(of: algorithm)!
        }
        
        if selected == row {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
    }

    static func getSelectedAlgorithm() -> (Int32, Int32, [AnyHashable: Any]) {
        var params : [AnyHashable: Any] = [:]
        var keyID: Int32 = -1 //if -1, automatically selects the first available key for the specified algorithm

        var algorithm: Int32 = ALG_EH_IDTECH

        let prefs = UserDefaults.standard;
        if prefs.value(forKey: "Algorithm") != nil {
            algorithm = Int32(prefs.integer(forKey: "Algorithm"))
        }

        if(algorithm==ALG_EH_VOLTAGE)
        {
            params["encryption"] = "SPE"
            params["merchantID"] = "0123456"
        }
        if(algorithm==ALG_EH_IDTECH)
        {//Just a demo how to select key
            keyID = 0
        }
        if(algorithm==ALG_EH_MAGTEK)
        {//Just a demo how to select key
            keyID = KEY_EH_DUKPT_MASTER1
        }
        if(algorithm==ALG_EH_AES128)
        {//Just a demo how to select key
            keyID = KEY_EH_AES128_ENCRYPTION1
        }
        if(algorithm==ALG_EH_AES256)
        {//Just a demo how to select key
            keyID = KEY_EH_AES256_ENCRYPTION1
        }
        if(algorithm==ALG_PPAD_DUKPT)
        {//Just a demo how to select key, in the pinpad, the dukpt keys are between 0 and 7
            keyID = 0
        }
        if(algorithm==ALG_PPAD_3DES_CBC)
        {//Just a demo how to select key, in the pinpad, the 3des keys are from 1 to 49, key 1 is automatically selected if you pass 0
            //the key loaded needs to be data encryption 3des type, or card will not read. Assuming such is loaded on position 2:
            keyID = 2
        }
        if(algorithm==ALG_EH_IDTECH_AES128)
        {//Just a demo how to select key
            keyID = KEY_EH_DUKPT_MASTER1
        }
        if(algorithm==ALG_EH_MAGTEK_AES128)
        {//Just a demo how to select key
            keyID = KEY_EH_DUKPT_MASTER1
        }

        return (algorithm, keyID, params)
    }
    
    static func setAlgorithm(lib: DTDevices) throws {

        let (algorithm, keyID, params) = getSelectedAlgorithm()

        try lib.emsrSetEncryption(algorithm, keyID:keyID, params: params as [AnyHashable: AnyObject])
    }
    
    override func execute(cell: UITableViewCell, row: Int) {
 
        UserDefaults.standard.set(Int(formsts[row]), forKey: "Algorithm")
        
        selected = row
     
        do {
            try SettingsAlgorithm.setAlgorithm(lib: lib)
            self.viewController.tvSettings.reloadData()
        } catch {
            Utils.showError("Setting algorithm", error: error as NSError?)
        }
        
        
    }
}

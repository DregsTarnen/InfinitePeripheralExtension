import Foundation

class CryptoAlgorithm: CryptoTemplate {
    
    var selected = 0
    
    override func getSectionName() -> String {
        return "Magnetic Card Algorithm"
    }
    
    let settings=[
        "AES256","Proprietary",
        "AES128","Proprietary",
        "IDTech v3","Using 3DES",
        "IDTech v3","Using AES128",
        "Magtek v2","Using 3DES",
        "Magtek v2","Using AES128",
        "Pinpad DUKPT","Proprietary",
        "Pinpad 3DES","Proprietary",
        "Voltage","",
        "TransArmor","",
    ]
    
    let algorithms_keys=[
        ALG_EH_AES256,KEY_EH_AES256_ENCRYPTION1,
        ALG_EH_AES128,KEY_EH_AES128_ENCRYPTION1,
        ALG_EH_IDTECH,KEY_EH_DUKPT_MASTER1,
        ALG_EH_IDTECH_AES128,KEY_EH_AES128_ENCRYPTION1,
        ALG_EH_MAGTEK,KEY_EH_DUKPT_MASTER1,
        ALG_EH_MAGTEK_AES128,KEY_EH_AES128_ENCRYPTION1,
        ALG_PPAD_DUKPT,0,
        ALG_PPAD_3DES_CBC,2,
        ALG_EH_VOLTAGE,0,
        ALG_TRANSARMOR,0,
    ]
    
    override func getNumberOfRows() -> Int {
        return settings.count/2
    }
    
    override func setCell(cell: UITableViewCell, row: Int) {
        cell.textLabel?.text=settings[row*2+0]
        cell.detailTextLabel?.text=settings[row*2+1]
        if row == selected {
            cell.accessoryType=UITableViewCellAccessoryType.checkmark
        }else {
            cell.accessoryType=UITableViewCellAccessoryType.none
        }
    }
    
    override func execute(cell: UITableViewCell, row: Int) {
        do {
            try lib.emsrSetEncryption(algorithms_keys[row*2+0], keyID: algorithms_keys[row*2+1], params: nil)
            selected = row
        } catch let error as NSError {
            Utils.showError("Operation", error: error)
        }
        self.viewController.tvCrypto.reloadData()
    }
}

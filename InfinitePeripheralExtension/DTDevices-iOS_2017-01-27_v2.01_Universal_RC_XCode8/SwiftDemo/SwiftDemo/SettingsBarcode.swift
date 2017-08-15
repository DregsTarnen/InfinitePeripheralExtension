import Foundation

class SettingsBarcode: SettingsTemplate {
    
    let modes = [SCAN_MODES.MODE_SINGLE_SCAN]
    var currentMode = 0
    
    let settings=[
        "Enable scan button","When disabled button only sends events",
        "Beep upon scan","Enable/disable scan sound",
        "Reset barcode engine","Reset engine to defaults",
        "Enable Code128 barcode","Test purpose, enable/disable code128",
        "Mode: Single scan","Turns off after scan",
        "Mode: Multi scan","Continue to scan until button release",
        "Mode: Multi scan w/o duplicates","Does not allow same barcode to be scannned",
        "Mode: Motion detect","Low power mode, scanner activates on motion",
    ]
    
    enum settingsNames : Int {
        case EnableScan
        case BeepUponScan
        case ResetBarcodeEngine
        case EnableCode128
        case Modes
    }
    
    var values = [Bool]()
    
    override func getSectionName() -> String {
        return "Barcode Scanner"
    }
    
    override init(viewController: SettingsViewController, section: Int) {
        super.init(viewController: viewController, section: section)

        values = [Bool](repeating: false, count:settings.count)
        
        //read current
        do {
            var index=0
            
            //scan button
            var buttonMode: Int32 = 0
            try lib.barcodeGetScanButtonMode(&buttonMode)
            values[index] = buttonMode==BUTTON_STATES.ENABLED.rawValue
            index += 1
            //beep upon scan
            values[index] = false
            index += 1
            //reset engine
            values[index] = false
            index += 1
            //enable code128
            values[index] = true
            index += 1
            
            //scan mode
            var scanMode = SCAN_MODES.MODE_SINGLE_SCAN
            try lib.barcodeGetScanMode(&scanMode)
            for i: Int in 0...modes.count
            {
                if modes[i] == scanMode
                {
                    currentMode=i
                    break
                }
            }
            
        } catch {}
    }
    
    override func getNumberOfRows() -> Int {
        return settings.count/2
    }
    
    override func setCell(cell: UITableViewCell, row: Int) {
        cell.textLabel?.text=settings[row*2+0]
        cell.detailTextLabel?.text=settings[row*2+1]
        if row >= settingsNames.Modes.rawValue
        {
            cell.accessoryType = currentMode == row-settingsNames.Modes.rawValue ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        }else
        {
            cell.accessoryType = values[row] ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        }
    }
    
    override func execute(cell: UITableViewCell, row: Int) {
        
        var value = !values[row]
        
        do {
            if row == settingsNames.EnableScan.rawValue
            {//scan button
                try lib.barcodeSetScanButtonMode(value ? BUTTON_STATES.ENABLED.rawValue : BUTTON_STATES.DISABLED.rawValue)
            }
            if row == settingsNames.BeepUponScan.rawValue
            {//beep
                let beep: [Int32] = [2730,150,65000,20,2730,150]

                if value
                {
//                    let beepPointer = beep.withUnsafeBufferPointer({pointer in return pointer.baseAddress})
                    try lib.barcodeSetScanBeep(true, volume: 100, beepData: beep, length: Int32(beep.count*4))
                }else
                {
                    try lib.barcodeSetScanBeep(false, volume: 0, beepData: nil, length: 0)
                }
            }
            if row == settingsNames.ResetBarcodeEngine.rawValue
            {//reset engine
                try lib.barcodeEngineResetToDefaults()
                value=false
            }
            if row == settingsNames.EnableCode128.rawValue
            {//enable code128
                //opticon
                let barcodeEngine = lib.getSupportedFeature(FEATURES.FEAT_BARCODE, error:nil)
                if barcodeEngine == FEAT_BARCODES.BARCODE_OPTICON.rawValue
                {
                    try lib.barcodeOpticonSetInitString(value ? "B6" : "VE")
                }
                //intermec
                if barcodeEngine == FEAT_BARCODES.BARCODE_INTERMEC.rawValue
                {
                    let intermecInit: [UInt8] =
                        [
                            0x41, //start
                            0x43,0x40,value ? 1 : 0,
                        ]
                    
                    try lib.barcodeIntermecSetInitData(NSData(bytes: intermecInit, length: intermecInit.count) as Data!)
                }
                //newland
                if barcodeEngine == FEAT_BARCODES.BARCODE_NEWLAND.rawValue
                {
                    try lib.barcodeNewlandSetInitString(value ? "NLS0400020;" : "NLS0400010;")
                }
            }
            if row >= settingsNames.Modes.rawValue
            {
                try lib.barcodeSetScanMode(modes[row-settingsNames.Modes.rawValue])
                currentMode = row
            }
            
        } catch let error as NSError {
            //revert back
            value = !value
            Utils.showError("Operation", error: error)
        }
        values[row]=value
        self.viewController.tvSettings.reloadData()
    }
}

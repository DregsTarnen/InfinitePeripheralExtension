import Foundation

class SettingsBarcodeMode: SettingsTemplate, DTDeviceDelegate {
    
    let modes = [SCAN_MODES.MODE_SINGLE_SCAN]
    var currentMode = 0
    
    override func getSectionName() -> String {
        return "Barcode Scan Mode"
    }
    
    let settings=[
        "Single scan","Turns off after scan",
        "Multi scan","Continue to scan until button release",
        "Multi scan w/o duplicates","Does not allow same barcode to be scannned",
        "Motion detect","Low power mode, scanner activates on motion",
    ]
    
    override init(viewController: SettingsViewController, section: Int) {
        super.init(viewController: viewController, section: section)
        
        //read current
        do {
            var mode = SCAN_MODES.MODE_SINGLE_SCAN
            
            try lib.barcodeGetScanMode(&mode)
            
            for i: Int in 0...modes.count
            {
                if modes[i] == mode
                {
                    currentMode=i
                    break
                }
            }
        } catch _ {}
    }
    
    override func getNumberOfRows() -> Int {
        return settings.count/2
    }
    
    override func setCell(cell: UITableViewCell, row: Int) {
        cell.accessoryType = currentMode == row ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        cell.textLabel?.text=settings[row*2+0]
        cell.detailTextLabel?.text=settings[row*2+1]
    }
    
    override func execute(cell: UITableViewCell, row: Int) {
        
        do {
            try lib.barcodeSetScanMode(modes[row])
            currentMode = row
        } catch let error as NSError {
            Utils.showError("Operation", error: error)
        }
        self.viewController.tvSettings.reloadData()
    }
}

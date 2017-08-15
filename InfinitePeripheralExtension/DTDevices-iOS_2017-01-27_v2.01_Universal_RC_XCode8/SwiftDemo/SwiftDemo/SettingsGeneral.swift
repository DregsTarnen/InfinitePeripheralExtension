import Foundation

class SettingsGeneral: SettingsTemplate {
    
    override func getSectionName() -> String {
        return "General"
    }
    
    let settings=[
        "Automated charge enabled","Specific devices, chages from own battery",
        "Enable external speaker","Infinea only",
        "External speaker hardware button","",
        "External speaker auto mode","Auto enabled when not app controlled",
        "Enable pass-through sync","Disables iOS connection when usb plugged",
        "Enable Kiosk Mode","iPad models only",
        "Turn device off","",
    ]
    
    var values = [Bool]()
    
    override init(viewController: SettingsViewController, section: Int) {
        super.init(viewController: viewController, section: section)
        
        values = [Bool](repeating: false, count:settings.count)
        
        //read current
        do {
            var enabled:ObjCBool = false
            var index=0
            
            let defaults=UserDefaults.standard
            //automatic charge, this is stored as app preference
            values[index] = defaults.bool(forKey: "AutomatedCharge")
            index += 1
            
            //external speaker
            if lib.getSupportedFeature(FEATURES.FEAT_SPEAKER, error: nil) == FEAT_SUPPORTED {
                try lib.uiIsSpeakerEnabled(&enabled)
                values[index] = enabled.boolValue
                index += 1
            }else {
                values[index] = false
                index += 1
            }
            //external speaker hardware button
            if lib.getSupportedFeature(FEATURES.FEAT_SPEAKER, error: nil) == FEAT_SUPPORTED {
                try lib.uiIsSpeakerButtonEnabled(&enabled)
                values[index] = enabled.boolValue
                index += 1
            }else {
                values[index] = false
                index += 1
            }
            //external speaker auto mode
            if lib.getSupportedFeature(FEATURES.FEAT_SPEAKER, error: nil) == FEAT_SUPPORTED {
                values[index] = enabled.boolValue
                index += 1
            }else {
                values[index] = false
                index += 1
            }
            //pass-through sync
            try lib.getPassThroughSync(&enabled)
            values[index] = enabled.boolValue
            index += 1
            //kiosk mode
            try lib.getKioskMode(&enabled)
            values[index] = enabled.boolValue
            index += 1
            //turn device off
            values[index] = false
            index += 1
        } catch _ {}
    }
    
    override func getNumberOfRows() -> Int {
        return settings.count/2
    }
    
    override func setCell(cell: UITableViewCell, row: Int) {
        cell.accessoryType = values[row] ? UITableViewCellAccessoryType.checkmark : UITableViewCellAccessoryType.none
        cell.textLabel?.text=settings[row*2+0]
        cell.detailTextLabel?.text=settings[row*2+1]
    }
    
    override func execute(cell: UITableViewCell, row: Int) {
        
        var value = !values[row]
        
        do {
            if row==0
            {//auto charge
                try lib.setCharging(value)
            }
            if row==1
            {//external speaker
                try lib.uiEnableSpeaker(value)
            }
            if row==2
            {//external speaker hardware button
                try lib.uiEnableSpeakerButton(value)
            }
            if row==3
            {//external speaker auto mode
                try lib.uiEnableSpeakerAutoControl(value)
            }
            if row==4
            {//pass-through sync
                try lib.setPassThroughSync(value)
            }
            if row==5
            {//kiosk mode
                try lib.setKioskMode(value)
            }
            if row==6
            {//turn device off
                try lib.sysPowerOff()
                value=false
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

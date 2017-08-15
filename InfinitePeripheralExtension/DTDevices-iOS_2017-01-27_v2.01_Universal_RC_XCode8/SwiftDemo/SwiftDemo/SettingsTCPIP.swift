import Foundation

class SettingsTCPIP: SettingsTemplate {
    
    override func getSectionName() -> String {
        return "TCP/IP Connection"
    }
    
    let settings=[
        "Connect to device","",
    ]
    
    override func getNumberOfRows() -> Int {
        return settings.count/2
    }
    
    override func setCell(cell: UITableViewCell, row: Int) {
        cell.textLabel?.text=settings[row*2+0]
        cell.detailTextLabel?.text=settings[row*2+1]
        cell.accessoryType=UITableViewCellAccessoryType.none
    }
    
    override func execute(cell: UITableViewCell, row: Int) {
        Utils.showMessage("Error", message: "Unsupported")
    }
}

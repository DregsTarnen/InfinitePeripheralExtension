import Foundation

class SettingsBT: SettingsTemplate, DTDeviceDelegate {
    
    override func getSectionName() -> String {
        return "Bluetooth Devices"
    }
    
    var btDevices = [String]()
    
    override func getNumberOfRows() -> Int {
        return btDevices.count/2+1
    }
    
    func isConnected(address: String) -> Bool
    {
        for device in lib.btConnectedDevices
        {
            if device==address
            {
                return true;
            }
        }
        
        return false;
    }
    
    override func setCell(cell: UITableViewCell, row: Int) {
        cell.accessoryType=UITableViewCellAccessoryType.none
        if(row==0)
        {
            cell.textLabel?.text="Discover supported devices"
            cell.detailTextLabel?.text="Printers and Pinpads"
        }else
        {
            cell.textLabel?.text=btDevices[(row-1)*2+0]
            cell.detailTextLabel?.text="address: \(btDevices[(row-1)*2+1])"
            if isConnected(address: btDevices[(row-1)*2+1])
            {
                cell.accessoryType=UITableViewCellAccessoryType.checkmark
            }
        }
    }
    
    func bluetoothDeviceDiscovered(_ address: String!, name: String!) {
        btDevices.append(name)
        btDevices.append(address)
    }
    
    func bluetoothDiscoverComplete(_ success: Bool) {
        Progress.hide()
        self.viewController.tvSettings.reloadData()
        if !success
        {
            Utils.showError("Bluetooth discover", error: nil)
        }
    }
    
    override func execute(cell: UITableViewCell, row: Int) {
        Progress.show(viewController)
        
        DispatchQueue.global().async {
            if row==0
            {//discover
                self.btDevices.removeAll(keepingCapacity: false)
                
                self.lib.addDelegate(self)
                do {
                    try self.lib.btDiscoverSupportedDevices(inBackground: 8, maxTime: 10.0, filter: BLUETOOTH_FILTER.ALL)
                } catch let error as NSError {
                    Progress.hide()
                    Utils.showError("Bluetooth discover", error: error)
                } catch {
                    fatalError()
                }
            }else
            {//connect
                let selectedAddress = self.btDevices[(row-1)*2+1]
                if self.isConnected(address: selectedAddress)
                {
                    do {
                        try self.lib.btDisconnect(selectedAddress)
                    } catch _ {
                    }
                }else
                {
                    do {
                        try self.lib.btConnectSupportedDevice(selectedAddress, pin: "0000")
                    } catch let error as NSError {
                        Utils.showError("Device connect", error: error)
                    }
                }
                Progress.hide()
            }
            self.viewController.tvSettings.reloadData()
        }
    }
}

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DTDeviceDelegate {

    @IBOutlet weak var tvSettings: UITableView!
    
    
    let lib=DTDevices.sharedDevice() as! DTDevices
    
    var tableObjects=[SettingsTemplate]()
    
    func connectionState(_ state: Int32) {
        var section = 0
        
        tableObjects=[]
        if state==CONN_STATES.CONNECTED.rawValue
        {
            //analyze the connected device features and build proper list
            tableObjects.append(SettingsGeneral(viewController: self, section: section))
            section += 1
            
            if (lib.getSupportedFeature(FEATURES.FEAT_BLUETOOTH, error: nil) & FEAT_BLUETOOTH_TYPES.BLUETOOTH_CLIENT.rawValue) != 0
            {
                tableObjects.append(SettingsBT(viewController: self, section: section))
                section += 1
            }
            if lib.getSupportedFeature(FEATURES.FEAT_BARCODE, error: nil) != FEAT_UNSUPPORTED
            {
                tableObjects.append(SettingsBarcode(viewController: self, section: section))
                section += 1
                tableObjects.append(SettingsBarcodeMode(viewController: self, section: section))
                section += 1
            }
            tableObjects.append(SettingsAlgorithm(viewController: self, section: section))
            section += 1
        }else
        {
            //let only manual tcp/ip connect
            tableObjects.append(SettingsTCPIP(viewController: self, section: section))
            section += 1
        }
        tvSettings.reloadData()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableObjects[section].getSectionName()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableObjects.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableObjects[section].getNumberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell=tvSettings.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) 
        
        tableObjects[indexPath.section].setCell(cell: cell, row: indexPath.row)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell=tvSettings.cellForRow(at: indexPath)
        tableObjects[indexPath.section].execute(cell: cell!, row: indexPath.row)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        lib.addDelegate(self)
        //force to update
        connectionState(lib.connstate)
        tvSettings.delegate=self
        tvSettings.dataSource=self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


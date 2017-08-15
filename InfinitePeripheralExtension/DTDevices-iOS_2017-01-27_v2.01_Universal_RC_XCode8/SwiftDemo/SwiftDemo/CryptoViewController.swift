import UIKit

class CryptoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DTDeviceDelegate {
    
    @IBOutlet weak var tvCrypto: UITableView!

    
    let lib=DTDevices.sharedDevice() as! DTDevices
    

    var tableObjects=[CryptoTemplate]()
    
    func connectionState(_ state: Int32) {
        var section = 0
        
        tableObjects=[]
        if state==CONN_STATES.CONNECTED.rawValue
        {
            if (lib.getSupportedFeature(FEATURES.FEAT_MSR, error: nil) & FEAT_MSRS.MSR_ENCRYPTED.rawValue) != 0 {
                tableObjects.append(CryptoEMSR(viewController: self, section: section, headType:EMSR_REAL))
                section += 1
                if (lib.getSupportedFeature(FEATURES.FEAT_MSR, error: nil) & FEAT_MSRS.MSR_ENCRYPTED_EMUL.rawValue) != 0 {
                    tableObjects.append(CryptoEMSR(viewController: self, section: section, headType:EMSR_EMULATED))
                    section += 1
                }
                tableObjects.append(CryptoAlgorithm(viewController: self, section: section))
                section += 1
            }
        }
        tvCrypto.reloadData()
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
        let cell=tvCrypto.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath as IndexPath)
        
        tableObjects[indexPath.section].setCell(cell: cell, row: indexPath.row)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell=tvCrypto.cellForRow(at: indexPath as IndexPath)
        tableObjects[indexPath.section].execute(cell: cell!, row: indexPath.row)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        lib.addDelegate(self)
        //force to update
        connectionState(lib.connstate)
        tvCrypto.delegate=self
        tvCrypto.dataSource=self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


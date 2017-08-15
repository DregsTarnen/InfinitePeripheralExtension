import Foundation

class CryptoTemplate: NSObject {
    
    let lib: DTDevices = DTDevices.sharedDevice() as! DTDevices
    
    var viewController: CryptoViewController
    var section: Int
    
    init(viewController: CryptoViewController, section: Int)
    {
        self.viewController=viewController
        self.section=section
        super.init()
    }
    
    func isSupported(lib: DTDevices) -> Bool
    {
        return lib.connstate==CONN_STATES.CONNECTED.rawValue
    }
    
    func getSectionName() -> String
    {
        return ""
    }
    
    func getNumberOfRows() -> Int
    {
        return 0
    }
    
    func setCell(cell: UITableViewCell, row: Int)
    {
        
    }
    
    func execute(cell: UITableViewCell, row: Int)
    {
        
    }
}
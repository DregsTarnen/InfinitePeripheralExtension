import UIKit

class MainViewController: UIViewController, DTDeviceDelegate {
    
    @IBOutlet weak var tvInfo: UITextView!
    @IBOutlet weak var btScan: UIButton!
    @IBOutlet weak var btBattery: UIButton!
    @IBOutlet weak var ivCharging: UIImageView!
    
    let lib=DTDevices.sharedDevice() as! DTDevices
    
    var scanActive = false
    
//MARK: Controls
    
    @IBAction func onScanDown()
    {
        do
        {
            var scanMode = SCAN_MODES.MODE_SINGLE_SCAN
            try lib.barcodeGetScanMode(&scanMode)
            
            if scanMode==SCAN_MODES.MODE_MOTION_DETECT {
                scanActive = !scanActive
                if scanActive {
                    try lib.barcodeStartScan()
                }else {
                    try lib.barcodeStopScan()
                }
            }else
            {
                try lib.barcodeStartScan()
            }
        }catch let error as NSError {
            tvInfo.text="Operation failed with: \(error.localizedDescription)"
        }
    }

    @IBAction func onScanUp()
    {
        do
        {
            try lib.barcodeStopScan()
        }catch let error as NSError {
            tvInfo.text="Operation failed with: \(error.localizedDescription)"
        }
    }
    
    @IBAction func onBattery()
    {
        updateBattery()
    }
    
    func updateBattery()
    {
        do
        {
            let info = try lib.getBatteryInfo()
            
            let v = info.voltage.format(".2")
            btBattery.setTitle("\(info.capacity)% (\(v)v)", for: UIControlState.normal)
            ivCharging.isHidden = !info.charging
            if info.capacity<10
            {
                btBattery.setBackgroundImage(UIImage(named: "0.png"), for: UIControlState.normal)
            }else
            {
                if info.capacity<40
                {
                    btBattery.setBackgroundImage(UIImage(named: "25.png"), for: UIControlState.normal)
                }else
                {
                    if info.capacity<60
                    {
                        btBattery.setBackgroundImage(UIImage(named: "50.png"), for: UIControlState.normal)
                    }else
                    {
                        if info.capacity<10
                        {
                            btBattery.setBackgroundImage(UIImage(named: "75.png"), for: UIControlState.normal)
                        }else
                        {
                            btBattery.setBackgroundImage(UIImage(named: "100.png"), for: UIControlState.normal)
                        }
                    }
                }
            }

            var s = ""
            s+="Voltage: "+info.voltage.format(".3")+"v\n"
            s+="Capacity: \(info.capacity)%\n"
            s+="Maximum capacity: \(info.maximumCapacity)mA/h\n"
            if info.health>0
            {
                s+="Health: \(info.health)%\n"
            }
            s+="Charging: \(info.charging)\n"
            if info.extendedInfo != nil
            {
                s+="Extended info: \(info.extendedInfo)\n"
            }
            tvInfo.text=s
        }catch let error as NSError {
            btBattery!.isHidden=true
            tvInfo.text="Operation failed with: \(error.localizedDescription)"
        }
    }
    
//MARK: DTDevices notifications
    
    //sent when supported device connects or disconnects. always wait for this message or check connstate before attempting communication. calling connect function does not mean that the device will be connected on the next line
    func connectionState(_ state: Int32) {
        var info="SDK: ver \(lib.sdkVersion/100).\(String.init(format: "%02d", lib.sdkVersion%100)) \(DateFormatter.localizedString(from: lib.sdkBuildDate, dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.none))\n"
        
        do
        {
            
            if state==CONN_STATES.CONNECTED.rawValue
            {
                let connected = try lib.getConnectedDevicesInfo()
                for device in connected
                {
                    info+="\(device.name!) \(device.model!) connected\nFW Rev: \(device.firmwareRevision!) HW Rev: \(device.hardwareRevision!)\nSerial: \(device.serialNumber!)\n"
                }
                
                if lib.getSupportedFeature(FEATURES.FEAT_BARCODE, error: nil) != FEAT_UNSUPPORTED
                {
                    btScan.isHidden=false
                }

                btBattery.isHidden=false
                updateBattery()
            }else {
                btScan.isHidden=true
                btBattery.isHidden=true
            }
        }catch {}
        tvInfo.text=info
    }
    
    func barcodeData(_ barcode: String!, type: Int32) {
        Utils.showMessage("Barcode scanned", message: "Type: \(type)\nBarcode: \(barcode!)")
    }
    
    func magneticCardEncryptedData(_ encryption: Int32, tracks: Int32, data: Data!, track1masked: String!, track2masked: String!, track3: String!, source: Int32) {
        let card = lib.msExtractFinancialCard(track1masked, track2: track2masked)
        var status = "Encryption: "
        
        switch encryption {
        case ALG_EH_AES256:
            status += "AES256"

        case ALG_EH_AES128:
            status += "AES128"
            
        case ALG_EH_MAGTEK:
            status += "MAGTEK"
            
        case ALG_EH_IDTECH:
            status += "IDTECH"
            
        case ALG_PPAD_DUKPT:
            status += "Pinpad DUKPT"
            
        case ALG_PPAD_3DES_CBC:
            status += "Pinpad 3DES CBC"
            
        case ALG_TRANSARMOR:
            status += "TransArmor"
            
        case ALG_EH_VOLTAGE:
            status += "Voltage"
            
        default:
            status += ""
        }
        
        status += "\n"
        
        if card != nil
        {
            if !(card?.cardholderName.isEmpty)! {
                status += "Name: \(String(describing: card?.cardholderName!))\n"
            }
            status += "PAN: \(String(describing: card?.accountNumber))\n"
            status += "Expires: \(String(describing: card?.expirationMonth))/\(String(describing: card?.expirationYear))\n"
            if !(card?.serviceCode.isEmpty)! {
                status += "Service Code: \(String(describing: card?.serviceCode!))\n"
            }
            if !(card?.discretionaryData.isEmpty)! {
                status += "Discretionary: \(String(describing: card?.discretionaryData!))\n"
            }
        }
        
        status += "Data: "+data.toHexString()
        
        do {
            let sound: [Int32] = [2730,150,0,30,2730,150];
            try lib.playSound(100, beepData: sound, length: Int32(sound.count*4))
        } catch {
        }
        
        Utils.showMessage("Card Data", message: status)
    }
    
    //plain magnetic card data
    func magneticCardData(_ track1: String!, track2: String!, track3: String!) {
        let card = lib.msExtractFinancialCard(track1, track2: track2)
        var status = ""
        if card != nil {
            if card!.cardholderName != nil && !(card!.cardholderName.isEmpty) {
                status += "Name: \(card!.cardholderName!)\n"
            }
            status += "PAN: \((card!.accountNumber)!.masked(4, end: 4))\n"
            status += "Expires: \(card!.expirationMonth)/\(card!.expirationYear)\n"
            if card!.serviceCode != nil && !(card!.serviceCode.isEmpty) {
                status += "Service Code: \(card!.serviceCode!)\n"
            }
            if card!.discretionaryData != nil && !(card!.discretionaryData.isEmpty) {
                status += "Discretionary: \(card!.discretionaryData!)\n"
            }
        }
        
        if track1 != nil && !track1.isEmpty {
            status += "Track1: \(track1!)\n"
        }
        if track2 != nil && !track2.isEmpty {
            status += "Track2: \(track2!)\n"
        }
        if track3 != nil && !track3.isEmpty {
            status += "Track3: \(track3!)\n"
        }
        
        do {
            let sound: [Int32] = [2730,150,0,30,2730,150];
            try lib.playSound(100, beepData: sound, length: Int32(sound.count*4))
        } catch {
        }
        
        Utils.showMessage("Card Data", message: status)
    }
    
//MARK: ViewController stuff
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        lib.addDelegate(self)
        lib.connect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}


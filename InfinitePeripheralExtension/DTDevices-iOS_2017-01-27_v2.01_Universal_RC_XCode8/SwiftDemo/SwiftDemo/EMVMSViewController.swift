import UIKit

class EMVMSViewController: UIViewController, DTDeviceDelegate {

    let TOTAL = 100

    @IBOutlet weak var tvInfo: UITextView!

    let lib=DTDevices.sharedDevice() as! DTDevices

    @IBAction func onTransaction()
    {
        //start transaction
        Progress.show(self)
        do {
            try EMVViewController.initEMV(lib: lib)

            let (algorithm, keyID, _) = SettingsAlgorithm.getSelectedAlgorithm()

            //set transaction to be ms emulation, use the encryption already selected in crypt algorithm
            try lib.emv2SetCardEmulationMode(true, encryption: algorithm, keyID: keyID)

            //start the transaction - payment (0), $1 (100) usd (840)
            try lib.emv2SetTransactionType(0, amount: Int32(TOTAL), currencyCode: 840)
            try lib.emv2StartTransaction(onInterface: -1, flags: 0, initData: nil, timeout: 30)

        } catch let error as NSError {
            Progress.hide()
            Utils.showError("EMV Transaction", error: error)
        }
    }

    //EMV lib delegates
    //used only as a means to detect finished transaction
    func emv2(onTransactionFinished data: Data!) {
        Progress.hide()
        do {
            try lib.uiShowInitScreen()
        } catch {
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        lib.addDelegate(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        lib.removeDelegate(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}


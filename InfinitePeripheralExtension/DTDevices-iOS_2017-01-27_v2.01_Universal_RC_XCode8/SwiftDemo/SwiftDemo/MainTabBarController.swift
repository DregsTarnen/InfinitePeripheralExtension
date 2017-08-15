import Foundation

class MainTabBarController: UITabBarController, DTDeviceDelegate {
    
    @IBOutlet weak var printViewController: UIViewController?
    
    let lib=DTDevices.sharedDevice() as! DTDevices
    var cachedViewControllers = Dictionary<String, UIViewController>()
    
    func getViewController(name: String) -> UIViewController
    {
        var vc=cachedViewControllers[name]
        if vc == nil
        {
            vc = self.storyboard?.instantiateViewController(withIdentifier: name)
            cachedViewControllers[name]=vc
        }
        return vc!
    }
    
    func connectionState(_ state: Int32) {
        var tabs: [UIViewController] = []
       
        tabs.append(getViewController(name: "Scan"))
        tabs.append(getViewController(name: "Settings"))
        if state==CONN_STATES.CONNECTED.rawValue
        {
            if lib.getSupportedFeature(FEATURES.FEAT_PRINTING, error: nil) != FEAT_UNSUPPORTED {
                tabs.append(getViewController(name: "Print"))
            }
            if lib.getSupportedFeature(FEATURES.FEAT_MSR, error: nil) != FEAT_UNSUPPORTED || lib.getSupportedFeature(FEATURES.FEAT_PIN_ENTRY, error: nil) != FEAT_UNSUPPORTED {
                tabs.append(getViewController(name: "Crypto"))
            }
            if lib.getSupportedFeature(FEATURES.FEAT_EMVL2_KERNEL, error: nil) != FEAT_UNSUPPORTED {
                tabs.append(getViewController(name: "EMV"))
                tabs.append(getViewController(name: "EMVMS"))
            }
            if lib.getSupportedFeature(FEATURES.FEAT_RF_READER, error: nil) != FEAT_UNSUPPORTED {
                tabs.append(getViewController(name: "RF"))
            }

            do {
                try SettingsAlgorithm.setAlgorithm(lib: lib)
            } catch {
            }
        }
        
        setViewControllers(tabs, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.viewControllers = [UIViewController]()
        lib.addDelegate(self)
        lib.connect()
    }
    
}

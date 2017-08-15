//
//  ViewController.swift
//  InfinitePeripheralExtension
//
//  Created by Erik Fritts on 8/15/17.
//  
//

import UIKit

class ViewController: UIViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet weak var labelbatterylevel: UILabel!
    @IBOutlet weak var labelbarcode: UILabel!
    var scanned = Timer()
    
    func scannerStart() {
        if !self.scanned.isValid {
            self.scanned = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.barcodeScan), userInfo: nil, repeats: true) }
    }
    
    func scannerStop() {
        if self.scanned.isValid {
            self.scanned.invalidate() }
    }
    
    func barcodeScan() {
        appDelegate.checkScannerBatteryState()
        self.labelbatterylevel.text = "\(scan.batteryinfo)%"
        if scan.scan != "" {
            self.labelbarcode.text = scan.scan }
    }


    
    @IBAction func buttonChargeYes(_ sender: Any) {
        appDelegate.setBackUpChargeState(value: true)
    }
    
    @IBAction func buttonChargeNo(_ sender: Any) {
        appDelegate.setBackUpChargeState(value: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.scannerStart()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.scannerStop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


//
//  ScannerPreferences.swift
//  InfinitePeripheralExtension
//
//  Created by Erik Fritts on 8/15/17.
//  
//

import UIKit

extension AppDelegate: DTDeviceDelegate { //infinite peripherals iOS Swift AppDelegate extension
    
    
    //use function to initiate scanner
    func startScanner() {
        scanner = DTDevices()
        scanner.delegate = self
        scanner.connect()
    }
    
    //this function catches the barcode data in a string variable when scanner is connected and button is pressed
    func barcodeData(_ barcode: String!, type: Int32) {
        scan.scan = barcode
    }
    
    //this function retrieves connection state
    func connectionState(_ state: Int32) {
        if state == 2 {
            scan.connstate = 2 //connected
            setBackUpChargeState(value: true)
        } else if state == 1 {
            scan.connstate = 1 //not connected
        } else {
            scan.connstate = 0 } //trying to connect
    }
    
    //set ipod to charge from scanner battery
    func setBackUpChargeState(value: Bool) {
        switch scan.connstate {
        case 2:
            do { try scanner.setCharging(value) } catch let error as NSError { print("error: \(error)") }
        default:
            break
        }
    }
    
    //get scanner battery charge level in percent 0-100
    func checkScannerBatteryState() {
        switch scan.connstate {
        case 2:
            do {scan.batteryinfo = Int(try scanner.getBatteryInfo().capacity) } catch let error as NSError { print("error: \(error)") }
        default:
            break
        }
    }
    
    //reset barcode engine to factory default
    func resetBarcodeEngine() -> Bool {
        switch scan.connstate {
        case 2:
            do { try scanner.barcodeEngineResetToDefaults() } catch let error as NSError { print("error: \(error)"); return false }
        default:
            return false }
        return true
    }
    
    //set parameters for intermec barcode engine devices
    func setIntermecParameters(intermecInit: [UInt8]) {
        switch scan.connstate {
        case 2:
            do { try scanner.barcodeIntermecSetInitData(NSData(bytes: intermecInit, length: intermecInit.count) as Data!) } catch let error as NSError { print("error: \(error)") }
        default:
            break
        }
    }
    
    //set parameters for opticon barcode engine devices
    func setOpticonParameters(opticonInit: String) {
        switch scan.connstate {
        case 2:
            do { try scanner.barcodeOpticonSetInitString(opticonInit) } catch let error as NSError { print("error: \(error)") }
        default:
            break
        }
    }
    
    //set parameters for newland barcode engine devices
    func setNewlandParameters(newlandInit: String) {
        switch scan.connstate {
        case 2:
            do { try scanner.barcodeNewlandSetInitString(newlandInit) } catch let error as NSError { print("error: \(error)") }
        default:
            break
        }
    }
    
} //end scanner appdelegate extension














//
//  ScannerData.swift
//  InfinitePeripheralExtension
//
//  Created by Erik Fritts on 8/15/17.
//  
//
import UIKit
import Foundation

class ScannerData {
    
    //for devices that have intermec engine
    let intermecmicroqr:[UInt8] = [ 0x41, 0x55, 0x44, 1] //enable MicroQR
    let intermecgs1:[UInt8] = [ 0x41, 0x7B, 0x46, 7 ] //enable GS1
    let intmecdatbaromni:[UInt8] = [ 0x41, 0x4f, 0x40, 1 ] //enable GS1 databar omnidirection
    let intmecdatbarlimited:[UInt8] = [ 0x41, 0x4f, 0x41, 1 ] //enable GS1 databar limited
    let intmecdatbarextend:[UInt8] = [ 0x41, 0x4f, 0x42, 1 ] //enable GS1 databar extended
    let intmecmicropdf417:[UInt8] = [ 0x41, 0x4c, 0x42, 1 ] //enable micro pdf417
    let intmecqrcode:[UInt8] = [ 0x41, 0x55, 0x40, 1 ] //enable qr code
    let intmecaztec:[UInt8] = [ 0x41, 0x53, 0x40, 1 ] //enable aztec code
    
    //for devices that have opticon engine
    let opticonmicroqr:String = "D2U" //enable MicroQR
    let opticongs128:String = "OG" //enable GS1-128
    let opticoncode128:String = "B6" //enable code 128
    let opticonaztec:String = "BCH" //enable aztec code
    let opticonqrcode:String = "BCD" //enable qr code
    let optmicropdf417:String = "BCG" //enable micro pdf417
    
    //for devices that have newland engine
    let newlandmicroqr:String = "NLS0502110" //enable MicroQR
    
    var batteryinfo:Int = 0 //variable to hold scanner's current charge in percent 0-100
    
    var connstate:Int = 0       //2 connected, 1 not connected, 0 trying to connect
    
    var scan = "" //string entry from the scanner
    
}
let scan = ScannerData()
//end of scanner data





import UIKit

class PrintViewController: UIViewController, DTDeviceDelegate {
    
    @IBOutlet weak var lbPaperStatus: UILabel?
    
    let lib=DTDevices.sharedDevice() as! DTDevices
    
    func paperStatus(present: Bool) {
        lbPaperStatus?.isHidden = present
    }
    
    @IBAction func onFontsDemo()
    {
        do {
            try lib.prnPrintText("{=C}FONT SIZES" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintText("{=F0}Font 9x16\n{+DW}Double width\n{-DW}{+DH}Double height\n{+DW}{+DH}DW & DH" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintText("{=F1}Font 12x24\n{+DW}Double width\n{-DW}{+DH}Double height\n{+DW}{+DH}DW & DH" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintText("{=C}FONT STYLES\n{=L}Normal\n{+B}Bold\n{+I}Bold Italic{-I}{-B}\n{+U}Underlined{-U}\n{+V}Inversed{-V}\n" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintText("{=C}FONT ROTATION\n{=L}{=R1}Rotated 90 degrees\n{=R2}Rotated 180 degrees\n" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintText("{+W}{=F0}This function demonstrates the use of the built-in word-wrapping capability" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintText("{+W}{=F1}This function demonstrates the use of the built-in word-wrapping capability" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintText("{+W}{=F0}{=J}This function demonstrates the use of the built-in word-wrapping capability and the use of justify" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintText("{+W}{=F1}{=J}This function demonstrates the use of the built-in word-wrapping capability and the use of justify" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintText("{+W}{=L}Left {=R}and right aligned" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            
            try lib.prnFeedPaper(0)
            try lib.prnWaitPrintJob(30)
        } catch let error as NSError {
            Utils.showError("Print", error: error)
        }
    }
    
    @IBAction func onSelfTest()
    {
        do {
            try lib.prnPrintLogo(LOGO_NORMAL)
            try lib.prnSelfTest(false)
            try lib.prnWaitPrintJob(30)
        } catch let error as NSError {
            Utils.showError("Print", error: error)
        }
    }
    
    @IBAction func onOnFeedPaper()
    {
        do {
            try lib.prnFeedPaper(0)
        } catch let error as NSError {
            Utils.showError("Feed paper", error: error)
        }
    }
    
    @IBAction func onCalibrate()
    {
        var calib: Int32 = 0
        do {
            try lib.prnCalibrateBlackMark(&calib)
        } catch let error as NSError {
            Utils.showError("Calibrate", error: error)
            return
        }
        Utils.showMessage("Success", message: "Printer calibrated successfully, returned value is: \(calib)")
    }
    
    @IBAction func onBarcodesDemo()
    {
        do {
            try lib.prnSetBarcodeSettings(2, height:77, hriPosition:BAR_TEXT_BELOW, align:ALIGN_LEFT)
            try lib.prnPrintText("UPC-A" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcode(BAR_PRN.UPCA, barcode:"12345678901".data(using: String.Encoding.ascii))
            try lib.prnPrintText("\nUPC-E" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcode(BAR_PRN.UPCE, barcode:"012340000040".data(using: String.Encoding.ascii))
            try lib.prnPrintText("\nJAN13(EAN)" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcode(BAR_PRN.EAN13, barcode:"123456789012".data(using: String.Encoding.ascii))
            try lib.prnPrintText("\nJAN8(EAN)" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcode(BAR_PRN.EAN8, barcode:"96385074".data(using: String.Encoding.ascii))
            try lib.prnPrintText("\nCODE 39" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcode(BAR_PRN.CODE39, barcode:"1A1234567".data(using: String.Encoding.ascii))
            try lib.prnPrintText("\nITF" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcode(BAR_PRN.ITF, barcode:"123456789012".data(using: String.Encoding.ascii))
            try lib.prnPrintText("\nCODABAR (NW-7)" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcode(BAR_PRN.CODABAR, barcode:"A12356789A".data(using: String.Encoding.ascii))
            try lib.prnPrintText("\nCODE 93" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcode(BAR_PRN.CODE93, barcode:"AABCD12345".data(using: String.Encoding.ascii))
            try lib.prnPrintText("\nCODE 128" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcode(BAR_PRN.CODE128, barcode:"BABCD12345".data(using: String.Encoding.ascii))
            try lib.prnPrintText("\nPDF-417" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcodePDF417("Hey try to read this :)".data(using: String.Encoding.ascii), truncated:false, autoEncoding:true, eccl:PDF417_ECCL._AUTO, size:PDF417_SIZE.W2_H15)
            try lib.prnPrintText("\nQRCODE" , usingEncoding:String.Encoding.windowsCP1252.rawValue)
            try lib.prnPrintBarcodeQRCode("Hey try to read this :)".data(using: String.Encoding.ascii), eccl:QRCODE_ECCL._7, size:QRCODE_SIZE._6)
            
            try lib.prnFeedPaper(0)
            try lib.prnWaitPrintJob(30)
        } catch let error as NSError {
            Utils.showError("Print", error: error)
        }
    }
    
    @IBAction func onGraphicsDemo()
    {
        do {
            if(lib.pageIsSupported())
            {
                //print it using page mode instead
                let img=UIImage(named: "taz.png")
                try lib.pageStart()
                try lib.pageSetWorkingArea(0, top:0, width:0, height:Int32(img!.size.height))
                try lib.prnPrint(img, align:ALIGN_CENTER)
                try lib.pagePrint()
                try lib.pageEnd()
            }else
            {
                try lib.prnPrint(UIImage(named: "taz.png"), align:ALIGN_CENTER)
            }
            
            try lib.prnFeedPaper(0)
            try lib.prnWaitPrintJob(30)
        } catch let error as NSError {
            Utils.showError("Print", error: error)
        }
    }
    
    @IBAction func onLoadLogo()
    {
        do {
            try lib.uiLoadLogo(UIImage(named: "Icon-72.png"), align:ALIGN_CENTER)
            try lib.prnPrintLogo(LOGO_NORMAL)
            
            try lib.prnFeedPaper(0)
            try lib.prnWaitPrintJob(30)
        } catch let error as NSError {
            Utils.showError("Operation", error: error)
        }
    }
    
    func print2InchTicket()
    {
        let info: DTPrinterInfo!
        do {
            info = try lib.prnGetPrinterInfo()
            
            let width: Int32=info.paperWidthPx
            let height: Int32=170
            let lineSize: Int32=4
            
            try lib.pageStart()
            try lib.pageSetCoordinatesTranslation(true)
            try lib.pageSetWorkingArea(0, top:0, width:-1, heigth:-1, orientation:PAGE_HORIZONTAL_TOPLEFT)
            try lib.pageSetLabelHeight(height)
            try lib.pageRectangleFrame(lineSize, top:lineSize, width:width-2*lineSize, height:height-2*lineSize, framewidth:lineSize, color:UIColor.black)
            
            let img=UIImage(named: "printer1.png")
            try lib.pageSetWorkingArea(15, top:(height-Int32(img!.size.height))/2, width:-1, height:-1)
            try lib.prnPrint(img, align:ALIGN_LEFT)
            try lib.pageSetWorkingArea(75, top:10, width:-1, height:-1)
            try lib.prnSetBarcodeSettings(2, height:60, hriPosition:BAR_TEXT_BELOW, align:ALIGN_LEFT)
            try lib.prnPrintBarcode(BAR_PRN.CODE128AUTO, barcode:"BABCD12345".data(using: String.Encoding.ascii))
            
            try lib.prnPrintText("{=F0}Sample Text\n{=F1}{+B}And more!\n")
            
            try lib.pagePrint()
            try lib.pageEnd()
            try lib.prnFeedPaper(0)
            try lib.prnWaitPrintJob(30)
        } catch let error as NSError {
            Utils.showError("Print", error: error)
        }
    }
    
    func print3InchTicket()
    {
        var img: UIImage
        
        let width:Int32=1284
        let height:Int32=576
        
        do {
            try lib.pageStart()
            try lib.pageSetCoordinatesTranslation(true)
            try lib.pageSetWorkingArea(0, top:0, width:width, heigth:height, orientation:PAGE_VERTICAL_TOPRIGHT)
            
            try lib.pageFillRectangle(910, top:0, width:2, height:height, color:UIColor.black)
            
            //left part
            img=UIImage(named: "jb_logo.png")!
            try lib.pageSetWorkingArea(0, top:11, width:-1, height:-1)
            try lib.prnPrint(img, align:ALIGN_LEFT)
            
            try lib.pageSetWorkingArea(156, top:35, width:-1, height:-1)
            try lib.prnPrintText("{+B}BOARDING PASS")
            
            try lib.pageSetWorkingArea(0, top:100, width:-1, height:-1)
            try lib.prnPrintText("{=F1}Name:\n{=F0}{+B}TA/THAI HOA")
            
            try lib.pageSetWorkingArea(0, top:195, width:-1, height:-1)
            try lib.prnPrintText("{=F1}From:\n{=F0}{+B}Long Beach,CA (LGB)")
            try lib.prnPrintText("{=F1}To:\n{=F0}{+B}Seattle,WA (SEA)")
            try lib.prnPrintText("{=F1}Confirmation:\n{=F0}{+B}IZVNRI")
            try lib.prnPrintText("{=F1}TryeBlue Number:\n{=F0}{+B}B6 2018414054")
            
            try lib.pageSetWorkingArea(0, top:484, width:-1, height:-1)
            try lib.prnPrintText("{=F0}{+B}Boarding gate closes 15 minutes prior to depatrture")
            
            try lib.pageSetWorkingArea(0, top:550, width:-1, height:-1)
            try lib.prnPrintText("{=F0}{+B}DBAG")
            
            try lib.pageSetWorkingArea(430, top:0, width:390, height:-1)
            try lib.prnSetBarcodeSettings(1, height:120, hriPosition:BAR_TEXT_NONE, align:ALIGN_LEFT)
            try lib.prnPrintBarcodePDF417("M1TA/THAI HOA         EIZVNRI LGBSEAB6 0206 209R003C0002 147>3181OK5209BB6              29279          3 B6 B6                     ^160MEUCICht+/p4ZnM42SnW2B8vtVYsEKH7fWdpUrTvg4pMGJBrAiEAmph8K1A+kOcDmjJKCbualTL9UZ1rNp8vT5KeBWzcZDM=".data(using: String.Encoding.ascii), truncated:false, autoEncoding:true, eccl:PDF417_ECCL._AUTO, size:PDF417_SIZE.W2_H4)
            
            img=UIImage(named: "jb_seat.png")!
            try lib.pageSetWorkingArea(625, top:130, width:-1, height:-1)
            try lib.prnPrint(img, align:ALIGN_LEFT)
            
            img=UIImage(named: "jb_direction.png")!
            try lib.pageSetWorkingArea(700, top:130, width:-1, height:-1)
            try lib.prnPrint(img, align:ALIGN_LEFT)
            
            try lib.pageSetWorkingArea(395, top:195, width:-1, height:-1)
            try lib.prnPrintText("{=F1}Depart:\n{=F0}{+B}7:37 PM")
            try lib.prnPrintText("{=F1}Arrive:\n{=F0}{+B}10:09 PM")
            try lib.prnPrintText("{=F1}Boarding Time:\n{=F0}{+B}7:02 PM")
            try lib.prnPrintText("{=F1}Ticket Number:\n{=F0}{+B}2792135207199")
            
            try lib.pageSetWorkingArea(577, top:195, width:-1, height:-1)
            try lib.prnPrintText("{=F1}Date:\n{=F0}{+B}28 Jul 15")
            try lib.prnPrintText("{=F1} \n{=F0} ")
            try lib.prnPrintText("{=F1}Gate:\n{=F0}{+B}7")
            
            try lib.pageSetWorkingArea(770, top:195, width:-1, height:-1)
            try lib.prnPrintText("{=F1}Flight:\n{=F0}{+B}B6 206")
            try lib.prnPrintText("{=F1} \n{=F0} ")
            try lib.prnPrintText("{=F1}Seat:\n{=F0}{+B}3C")
            try lib.prnPrintText("{=F1}Seq:\n{=F0}{+B}0002")
            
            //right part
            img=UIImage(named: "jb_logo.png")!
            try lib.pageSetWorkingArea(940, top:11, width:-1, height:-1)
            try lib.prnPrint(img, align:ALIGN_LEFT)
            
            img=UIImage(named: "jb_tsa.png")!
            try lib.pageSetWorkingArea(1115, top:20, width:-1, height:-1)
            try lib.prnPrint(img, align:ALIGN_LEFT)
            
            try lib.pageSetWorkingArea(940, top:100, width:-1, height:-1)
            try lib.prnPrintText("{=F1}Name:\n{=F0}{+B}TA/THAI HOA\n")
            
            try lib.pageSetWorkingArea(940, top:195, width:-1, height:-1)
            try lib.prnPrintText("{=F1}From:\n{=F0}{+B}LGB/SEA")
            try lib.prnPrintText("{=F1}Depart:\n{=F0}{+B}7:37 PM")
            try lib.prnPrintText("{=F1}Flight:\n{=F0}{+B}B6 206")
            try lib.prnPrintText("{=F1}Class:\n{=F0}{+B}R")
            
            try lib.pageSetWorkingArea(1100, top:195, width:-1, height:-1)
            try lib.prnPrintText("{=F1} \n{=F0} ")
            try lib.prnPrintText("{=F1}Date:\n{=F0}{+B}28 Jul 15")
            try lib.prnPrintText("{=F1}Seat:\n{=F0}{+B}3C")
            
            try lib.pagePrint()
            try lib.pageEnd()
            
            try lib.prnFeedPaper(0)
            try lib.prnWaitPrintJob(30)
        } catch let error as NSError {
            Utils.showError("Print", error: error)
        }
    }
    
    func print4InchTicket()
    {
        let hoffset:Int32=16
        let width:Int32=800
        let height:Int32=600
        let lineSize:Int32=6
        
        do {
            try lib.prnSetBarcodeSettings(2, height:77, hriPosition:BAR_TEXT_BELOW, align:ALIGN_LEFT)
            
            try lib.pageStart()
            try lib.pageSetWorkingArea(hoffset, top:0, width:width, height:height)
            
            try lib.pageStart()
            try lib.pageSetWorkingArea(0, top:0, width:width, heigth:height, orientation:PAGE_VERTICAL_TOPRIGHT)
            try lib.pageRectangleFrame(hoffset+lineSize, top:lineSize, width:width-2*lineSize, height:height-2*lineSize, framewidth:lineSize, color:UIColor.black)
            try lib.pageFillRectangle(hoffset+207, top:20, width:lineSize, height:200, color:UIColor.black)
            try lib.pageFillRectangle(hoffset+20, top:220, width:width-2*20, height:lineSize, color:UIColor.black)
            try lib.pageFillRectangle(hoffset+20, top:295, width:width-2*20, height:lineSize, color:UIColor.black)
            
            let p=UIImage(named: "P.png")!
            try lib.pageSetWorkingArea(hoffset+56, top:46, width:-1, height:Int32(p.size.height))
            try lib.prnPrint(p, align:ALIGN_LEFT)
            
            try lib.pageSetWorkingArea(hoffset+254, top:35, width:-1, height:192-35)
            try lib.prnPrintText("US POSTAGE\nmPOS\n")
            try lib.prnPrintBarcode(BAR_PRN.PDF417, barcode:"Test barcode".data(using: String.Encoding.ascii))
            
            try lib.pageSetWorkingArea(hoffset+254, top:35, width:763-254, height:192-35)
            try lib.prnPrintText("{=R}062S0030243717\nFROM 20151\n{+B}$5.15{-B}\n0024\n08/13/2013")
            
            try lib.pageSetWorkingArea(hoffset+0, top:240, width:-1, height:-1)
            try lib.prnPrintText("{=C}{=F1}{+B}{+DW}{+DH}PRIORITY MAIL 1-DAY™")
            
            try lib.pageSetWorkingArea(hoffset+0, top:320, width:-1, height:-1)
            try lib.prnPrintText("{=C}{=F1}{+B}{+DW}{+DH}USPS TRACKING #")
            try lib.prnFeedPaper(20)
            try lib.prnSetBarcodeSettings(3, height:90, hriPosition:BAR_TEXT_BELOW, align:ALIGN_CENTER)
            try lib.prnPrintBarcode(BAR_PRN.CODE128AUTO, barcode:"420221529405511201080106322512".data(using: String.Encoding.ascii))
            
            try lib.pagePrint()
            try lib.pageEnd()
            
            try lib.prnFeedPaper(0)
            try lib.prnWaitPrintJob(30)
        } catch let error as NSError {
            Utils.showError("Print", error: error)
        }
    }
    
    
    @IBAction func onPrintLabelDemo()
    {
        if !lib.pageIsSupported()
        {
            Utils.showMessage("Error", message: "Page mode is not supported")
            return
        }
        
        let info=try? lib.prnGetPrinterInfo()
        if info != nil
        {
            if(info!.paperWidthInch==2)
            {
                print2InchTicket()
            }
            if(info!.paperWidthInch==3)
            {
                print3InchTicket()
            }
            if(info!.paperWidthInch==4)
            {
                print4InchTicket()
            }
        }
    }
    
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


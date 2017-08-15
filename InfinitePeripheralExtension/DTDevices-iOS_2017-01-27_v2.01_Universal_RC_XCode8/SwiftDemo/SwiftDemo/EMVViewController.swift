import UIKit

class EMVViewController: UIViewController, DTDeviceDelegate {

    let TOTAL = 100

    @IBOutlet weak var tvInfo: UITextView!

    let lib=DTDevices.sharedDevice() as! DTDevices

    static func initEMV(lib: DTDevices) throws {
        try lib.emv2Initialise()

        //try loading configuration, if it is not there already
        let info = try lib.emv2GetInfo()

        let configContactless = try EMVHelper.getConfigurationFromXMLFile(configFile: "Config/contactless.xml")!

        if info.contactlessConfigurationVersion != EMVHelper.getConfigurationVesrsion(configuration: configContactless) {
            try lib.emv2LoadContactlessConfiguration(configContactless.getNSData())
        }

        if (lib.getSupportedFeature(FEATURES.FEAT_EMVL2_KERNEL, error: nil) & FEAT_EMV2_KERNELS.EMV_KERNEL_UNIVERSAL.rawValue) != 0 {

            //in case of universal kernel supporting contact/contactless and magnetic payments load contact configuration too
            let configContact = try EMVHelper.getConfigurationFromXMLFile(configFile: "Config/contact.xml")!

            if info.contactConfigurationVersion != EMVHelper.getConfigurationVesrsion(configuration: configContact) {
                try lib.emv2LoadContactConfiguration(configContact.getNSData())
            }

            let capkContact = try EMVHelper.getConfigurationFromXMLFile(configFile: "Config/contact_capk.xml")!

            if info.contactCAPKVersion != EMVHelper.getConfigurationVesrsion(configuration: capkContact) {
                try lib.emv2LoadContactCAPK(capkContact.getNSData())
            }
        }
    }

    @IBAction func onTransaction()
    {
        //start transaction
        Progress.show(self)

        do {
            try EMVViewController.initEMV(lib: lib)

            //disable ms emulation mode that might have been enabled by the EMVMS
            try lib.emv2SetCardEmulationMode(false, encryption: 0, keyID: 0)

            //start the transaction - payment (0), $1 (100) usd (840)
            try lib.emv2SetTransactionType(0, amount: Int32(TOTAL), currencyCode: 840)
            try lib.emv2StartTransaction(onInterface: -1, flags: 0, initData: nil, timeout: 30)
            
        } catch let error as NSError {
            Progress.hide()
            Utils.showError("EMV Transaction", error: error)
        }
    }

    //EMV lib delegates

    
    func emv2(onOnlineProcessing data: Data!) {
        //for the demo fake a successful server response (30 30)
        let serverResponse=BerTlv.tlvWithHexString("30 30", tag: EMVTags.TAG_8A_AUTH_RESP_CODE).encode()

        let tags: [BerTlv] = [ BerTlv.tlvWithHexString("01", tag: 0xC2), BerTlv.tlvWithBytes(serverResponse!, tag: 0xE6) ]

        do {
            try lib.emv2SetOnlineResult(BerTlv.encodeTags(tags)?.getNSData())
        } catch {

        }
    }

    func emv2(onTransactionFinished data: Data!) {

        if data == nil
        {
            Progress.hide()

            do {
                try lib.emv2Deinitialise()
                try lib.uiShowInitScreen()
            } catch {
            }
            Utils.showMessage("Error", message: "Transaction could not be completed!")
            return;
        }

        //emv2OnTransactionFinished is used to get the final response from the transaction in non-emulation mode
        //data is extracted from the returned tags or manually asked for before calling emv2Deinitialise

        //parse data to display, send the rest to server

        let tags = BerTlv.decodeTags(data.getBytes())!

        var t: BerTlv?

        var receipt = ""

        NSLog("Tags: %@",tags);

        receipt.append("* Datecs Ltd *\n")
        receipt.append("\n")

        t = BerTlv.findLastTag(EMVTags.TAG_9F1C_TERMINAL_ID, tags: tags)
        if t != nil {
            receipt.append(String.init(format: "Terminal ID: %@\n", t!.hexStringvalue() ))
            receipt.append("\n")
        }


        let tDate=BerTlv.findLastTag(EMVTags.TAG_9A_TRANSACTION_DATE, tags: tags)
        let tTime=BerTlv.findLastTag(EMVTags.TAG_9F21_TRANSACTION_TIME, tags: tags)
        if tDate != nil && tTime != nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyMMddHHmmss"
            var date = dateFormatter.date(from: (tDate?.hexStringvalue())! + (tTime?.hexStringvalue())!)
            if date == nil {
                date = Date()
            }

            dateFormatter.dateFormat = "dd/MM/yyyy"
            let dateString = dateFormatter.string(from: date! as Date)

            dateFormatter.dateFormat = "HH:mm:ss"
            let timeString = dateFormatter.string(from: date! as Date)

            receipt.append("Date: " + dateString + " " + timeString + "\n")
        }

        receipt.append("* Payment *\n")


        let transactionResult = Int32(BerTlv.findLastTag(0xC1, tags: tags)!.intValue())

        var transactionResultString = ""
        switch transactionResult
        {
        case EMV_RESULT_APPROVED:
            transactionResultString="APPROVED";
            break;
        case EMV_RESULT_DECLINED:
            transactionResultString="DECLINED";
            break;
        case EMV_RESULT_TRY_ANOTHER_INTERFACE:
            transactionResultString="TRY ANOTHER INTERFACE";
            break;
        case EMV_RESULT_TRY_AGAIN:
            transactionResultString="TRY AGAIN";
            break;
        case EMV_RESULT_END_APPLICATION:
            transactionResultString="END APPLICATION";
            break;

        default:
            break
        }
        receipt.append("Transaction Result:\n")
        receipt.append(transactionResultString + "\n")
        receipt.append("\n")

        t = BerTlv.findLastTag(0xC3, tags: tags)
        if t != nil
        {
            switch EMV2_INTERFACES(rawValue: Int32(t!.data[0]))! {
            case EMV2_INTERFACES.EMV_INTERFACE_CONTACT:
                receipt.append("Interface: contact\n")
                break;
            case EMV2_INTERFACES.EMV_INTERFACE_CONTACTLESS:
                receipt.append("Interface: contactless\n")
                break;
            case EMV2_INTERFACES.EMV_INTERFACE_MAGNETIC:
                receipt.append("Interface: magnetic\n")
                break;
            case EMV2_INTERFACES.EMV_INTERFACE_MAGNETIC_MANUAL:
                receipt.append("Interface: manual entry\n")
                break;
            }
        }

        do {
            let trackData = try lib.emv2GetCardTracksEncrypted(withFormat: ALG_PPAD_DUKPT, keyID: 0)

            receipt.append("Encrypted track data:\n" + trackData.toHexString() + "\n")
        } catch  {

        }

        if(transactionResult == EMV_RESULT_APPROVED)
        {
            var rtags = [UInt8]()
            rtags.append(0xD3)
            rtags.append(0xD4)

            var card: DTFinancialCardInfo? = nil

            do {
                let maskedBytes = try lib.emv2GetTagsPlain(rtags.getNSData())
                let maskedTags = BerTlv.decodeTags(maskedBytes.getBytes())!

                //find and get Track1 masked and Track2 masked tags for display purposes
                var t1Masked: String? = nil
                var t2Masked: String? = nil

                t = BerTlv.findLastTag(0xD3, tags: maskedTags)
                if t != nil {
                    t1Masked = t?.stringValue()
                }
                t = BerTlv.findLastTag(0xD4, tags: maskedTags)
                if t != nil {
                    t2Masked = t?.stringValue()
                }

                card = lib.msExtractFinancialCard(t1Masked, track2: t2Masked)

                if card != nil
                {
                    if card!.cardholderName.length() > 0 {
                        receipt.append("Name: " + card!.cardholderName + "\n")
                    }
                    receipt.append("PAN: " + card!.accountNumber + "\n")
                    receipt.append(String.init(format: "Expires: %02d/%02d", card!.expirationMonth, card!.expirationYear))

                    receipt.append("\n")
                }

            } catch  {
            }


            //for the sake of the demo, print a receipt if there is a printer connected
            if lib.getSupportedFeature(FEATURES.FEAT_PRINTING, error: nil) != FEAT_UNSUPPORTED {
                Progress.setMessage("Printing receipt\nPlease wait...");

                do {
                    try lib.prnPrintText("{+B}{=C}TRANSACTION COMPLETE\n")
                    //prepare printout
                    try lib.prnPrintText("{=F0}{+B}{=C}INVOICE\nDATECS LTD\n")
                    try lib.prnPrintDelimiter("-".utf8CString[0])



                    try lib.prnPrintDelimiter("-".utf8CString[0])
                    try lib.prnPrintText(String.init(format: "{+DW}{+DH}{+B}TOTAL: {=R}$%.02f", TOTAL))
                    try lib.prnPrintDelimiter("*".utf8CString[0])
                    try lib.prnPrintText("Paid by: card")

                    if card != nil
                    {
                        if card!.cardholderName.length() > 0 {
                            try lib.prnPrintText("Name: " + card!.cardholderName)
                        }
                        try lib.prnPrintText("PAN: " + card!.accountNumber)
                        try lib.prnPrintText(String.init(format: "Expires: %02d/%02d", card!.expirationMonth, card!.expirationYear))

                        receipt.append("\n")
                    }
                    try lib.prnPrintText("\n\n\n")
                    try lib.prnPrintText("{+DW}{+DH}{+B}{=C}THANK YOU")

                    try lib.prnFeedPaper(0);
                    try lib.prnWaitPrintJob(30.0)
                } catch  {

                }

            }


            tvInfo.text = receipt


            Progress.hide()


            Utils.showMessage("Transaction complete", message: receipt)
        }else
        {
            Progress.hide()

            var reasonMessage="Terminal declined";
            t = BerTlv.findLastTag(0xC4, tags: tags)

            if t != nil
            {
                switch Int32(t!.data[0]) {
                case REASON_FAILED:
                    reasonMessage = "Terminal declined"
                    break

                case REASON_TIMEOUT:
                    reasonMessage = "Transaction timed out"
                    break

                case REASON_CANCELED:
                    reasonMessage = "User cancelled"
                    break

                case REASON_CARD_BLOCKED:
                    reasonMessage = "Card blocked"
                    break

                case REASON_CARD_READ_FAILED:
                    reasonMessage = "Card read failed"
                    break

                case REASON_DOUBLE_TAP_TRANSACTION:
                    reasonMessage = "Another transaction needed"
                    break

                default:
                    reasonMessage = "Unknown"
                }
            }
            Utils.showMessage("Transaction failed", message: reasonMessage)
        }

        //done with, deinit
        do {
            try lib.emv2Deinitialise()
            try lib.uiShowInitScreen()
        } catch {
        }
    }

    func emv2(onUserInterfaceCode code: Int32, status: Int32, holdTime: TimeInterval) {
        var ui = ""
        var uistatus = "not provided"

        switch code
        {
        case EMV_UI_NOT_WORKING:
            ui = "Not working";
            break;
        case EMV_UI_APPROVED:
            ui = "Approved";
            break;
        case EMV_UI_DECLINED:
            ui = "Declined";
            break;
        case EMV_UI_PLEASE_ENTER_PIN:
            ui = "Please enter PIN";
            break;
        case EMV_UI_ERROR_PROCESSING:
            ui = "Error processing";
            break;
        case EMV_UI_REMOVE_CARD:
            ui = "Please remove card";
            break;
        case EMV_UI_IDLE:
            ui = "Idle";
            break;
        case EMV_UI_PRESENT_CARD:
            ui = "Please present card";
            break;
        case EMV_UI_PROCESSING:
            ui = "Processing...";
            break;
        case EMV_UI_CARD_READ_OK_REMOVE:
            ui = "It is okay to remove card";
            break;
        case EMV_UI_TRY_OTHER_INTERFACE:
            ui = "Try another interface";
            break;
        case EMV_UI_CARD_COLLISION:
            ui = "Card collision";
            break;
        case EMV_UI_SIGN_APPROVED:
            ui = "Signature approved";
            break;
        case EMV_UI_ONLINE_AUTHORISATION:
            ui = "Online authorization";
            break;
        case EMV_UI_TRY_OTHER_CARD:
            ui = "Try another card";
            break;
        case EMV_UI_INSERT_CARD:
            ui = "Please insert card";
            break;
        case EMV_UI_CLEAR_DISPLAY:
            ui = "Clear display";
            break;
        case EMV_UI_SEE_PHONE:
            ui = "See phone";
            break;
        case EMV_UI_PRESENT_CARD_AGAIN:
            ui = "Please present card again";
            break;
        case EMV_UI_SELECT_APPLICAITON:
            ui = "Select application on device";
            break;
        case EMV_UI_MANUAL_ENTRY:
            ui = "Enter card on device";
            break;
        case EMV_UI_NA:
            ui = "N/A";
            break;

        default:
            break
        }
        
        switch status
        {
        case EMV_UI_STATUS_NOT_READY:
            uistatus = "Status Not Ready";
            break;
        case EMV_UI_STATUS_IDLE:
            uistatus = "Status Idle";
            break;
        case EMV_UI_STATUS_READY_TO_READ:
            uistatus = "Status Ready To Read";
            break;
        case EMV_UI_STATUS_PROCESSING:
            uistatus = "Status Processing";
            break;
        case EMV_UI_STATUS_CARD_READ_SUCCESS:
            uistatus = "Status Card Read Success";
            break;
        case EMV_UI_STATUS_ERROR_PROCESSING:
            uistatus = "Status Processing";
            break;
            
        default:
            break
        }
        
        Progress.setMessage(ui)
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


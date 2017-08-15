#import "PrintViewController.h"


@implementation PrintViewController

-(BOOL)textFieldShouldEndEditing:(UITextField *)theTextField;
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [textField resignFirstResponder];
    return YES;
}

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

-(void)paperStatus:(BOOL)present
{
    [paperStatusLabel setText:present?@"":@"Out of paper!"];
}

#define COMMAND(operation,x) if(!x){[self displayAlert:@"Error" message:[NSString stringWithFormat:@"%@ failed with error: %@",operation,err.localizedDescription]]; return; }

-(IBAction)onFontsDemo:(id)sender;
{
    NSError *err;


    DTPrinterInfo *info=[dtdev prnGetPrinterInfo:&err];
    if(info && !info.paperPresent)
    {
        [self displayAlert:@"Error" message:@"Please insert paper!"];
        return;
    }


//    COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F0}1This function demonstrates the use of the built-in word-wrapping capability" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
//    COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F1}1This function demonstrates the use of the built-in word-wrapping capability" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
//    COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F0}{=J}1This function demonstrates the use of the built-in word-wrapping capability and the use of justify" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
//    COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F1}{=J}1This function demonstrates the use of the built-in word-wrapping capability and the use of justify" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
//
//    [dtdev prnFeedPaperTemporary:0 error:nil];
//
//    [NSThread sleepForTimeInterval:4.0];
//
//    [dtdev prnRetractPaper:nil];
//
//
//    COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F0}2This function demonstrates the use of the built-in word-wrapping capability" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
//    COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F1}2This function demonstrates the use of the built-in word-wrapping capability" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
//    COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F0}{=J}2This function demonstrates the use of the built-in word-wrapping capability and the use of justify" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
//    COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F1}{=J}2This function demonstrates the use of the built-in word-wrapping capability and the use of justify" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
//
//    COMMAND(@"Wait for job",[dtdev prnWaitPrintJob:30 error:&err]);
//
//    return;
//

    COMMAND(@"Print text",[dtdev prnPrintText:@"{=C}FONT SIZES" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"{=F0}Font 9x16\n{+DW}Double width\n{-DW}{+DH}Double height\n{+DW}{+DH}DW & DH" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"{=F1}Font 12x24\n{+DW}Double width\n{-DW}{+DH}Double height\n{+DW}{+DH}DW & DH" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	
	COMMAND(@"Print text",[dtdev prnPrintText:@"{=C}FONT STYLES\n{=L}Normal\n{+B}Bold\n{+I}Bold Italic{-I}{-B}\n{+U}Underlined{-U}\n{+V}Inversed{-V}\n" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"{=C}FONT ROTATION\n{=L}{=R1}Rotated 90 degrees\n{=R2}Rotated 180 degrees\n" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);

    [dtdev prnFeedPaperTemporary:0 error:nil];

    [NSThread sleepForTimeInterval:2.0];

    [dtdev prnRetractPaper:nil];
	
	COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F0}This function demonstrates the use of the built-in word-wrapping capability" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F1}This function demonstrates the use of the built-in word-wrapping capability" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F0}{=J}This function demonstrates the use of the built-in word-wrapping capability and the use of justify" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=F1}{=J}This function demonstrates the use of the built-in word-wrapping capability and the use of justify" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
    
	COMMAND(@"Print text",[dtdev prnPrintText:@"{+W}{=L}Left {=R}and right aligned" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);

	COMMAND(@"Feed paper",[dtdev prnFeedPaper:0 error:&err]);
    COMMAND(@"Wait for job",[dtdev prnWaitPrintJob:30 error:&err]);
}

-(IBAction)onSelfTest:(id)sender;
{
    NSError *err;
    
	COMMAND(@"Print logo",[dtdev prnPrintLogo:LOGO_NORMAL error:&err]);
	COMMAND(@"Print self test",[dtdev prnSelfTest:FALSE error:&err]);
	
    COMMAND(@"Wait for job",[dtdev prnWaitPrintJob:30 error:&err]);
}

-(IBAction)onOnFeedPaper:(id)sender;
{
    NSError *err;
    
	COMMAND(@"Feed paper",[dtdev prnFeedPaper:0 error:&err]);
}

-(IBAction)onCalibrate:(id)sender;
{
    NSError *err;
    
    int calib=0;
    if(![dtdev prnCalibrateBlackMark:&calib error:&err])
    {
        [self displayAlert:@"Error" message:[NSString stringWithFormat:@"%@ failed with error: %@",@"Calibrate",err.localizedDescription]];
        return;
    }
    [self displayAlert:@"Success" message:[NSString stringWithFormat:@"Printer calibrated successfully, returned value is: %d",calib]];
}


-(NSString *)getLogFile
{
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"print-20151127-15.46.50-ZoneReportFormatting.txt"];
}

static NSData *stringToData(NSString *text)
{
    NSMutableData *d=[NSMutableData data];
    text=[text lowercaseString];
    int count=0;
    uint8_t b=0;
    for(int i=0;i<text.length;i++)
    {
        b<<=4;
        char c=[text characterAtIndex:i];
        if(c<'0' || (c>'9' && c<'a') || c>'f')
        {
            b=0;
            count=0;
            continue;
        }
        if(c>='0' && c<='9')
            b|=c-'0';
        else
            b|=c-'a'+10;
        count++;
        if(count==2)
        {
            [d appendBytes:&b length:1];
            b=0;
            count=0;
        }
    }
    return d;
}

-(void)test
{
    NSString *log=[NSString stringWithContentsOfFile:[self getLogFile] encoding:NSASCIIStringEncoding error:nil];
    NSArray *lines=[log componentsSeparatedByString:@"\n"];
    
    for (NSString *line in lines) {
        if(line.length==0)
            break;
        if([line rangeOfString:@"printWrite"].length!=0)
        {
            int pos = (int)([line rangeOfString:@" "].location+1);
            NSData *data=stringToData([line substringFromIndex:pos]);
            if(data.length>4)
            [dtdev prnWriteDataToChannel:CHANNEL_PRN data:[data subdataWithRange:NSMakeRange(4, data.length-4)] error:nil];
        }
    }
}

-(IBAction)onSetLabelWidth:(id)sender;
{
    NSError *err;
    int len=tfLabelWidth.text.intValue;

    COMMAND(@"Set max label length",[dtdev prnSetMaxLabelLength:len error:&err]);
}

-(IBAction)onBarcodesDemo:(id)sender;
{
    NSError *err;
    
//    [self test];
    
	COMMAND(@"Barcode settings",[dtdev prnSetBarcodeSettings:2 height:77 hriPosition:BAR_TEXT_BELOW align:ALIGN_LEFT error:&err]);

	COMMAND(@"Print text",[dtdev prnPrintText:@"UPC-A" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print barcode",[dtdev prnPrintBarcode:BAR_PRN_UPCA barcode:[@"12345678901" dataUsingEncoding:NSASCIIStringEncoding] error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"\nUPC-E" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print barcode",[dtdev prnPrintBarcode:BAR_PRN_UPCE barcode:[@"012340000040" dataUsingEncoding:NSASCIIStringEncoding] error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"\nJAN13(EAN)" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print barcode",[dtdev prnPrintBarcode:BAR_PRN_EAN13 barcode:[@"123456789012" dataUsingEncoding:NSASCIIStringEncoding] error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"\nJAN8(EAN)" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print barcode",[dtdev prnPrintBarcode:BAR_PRN_EAN8 barcode:[@"96385074" dataUsingEncoding:NSASCIIStringEncoding] error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"\nCODE 39" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print barcode",[dtdev prnPrintBarcode:BAR_PRN_CODE39 barcode:[@"1A1234567" dataUsingEncoding:NSASCIIStringEncoding] error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"\nITF" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print barcode",[dtdev prnPrintBarcode:BAR_PRN_ITF barcode:[@"123456789012" dataUsingEncoding:NSASCIIStringEncoding] error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"\nCODABAR (NW-7)" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print barcode",[dtdev prnPrintBarcode:BAR_PRN_CODABAR barcode:[@"A12356789A" dataUsingEncoding:NSASCIIStringEncoding] error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"\nCODE 93" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print barcode",[dtdev prnPrintBarcode:BAR_PRN_CODE93 barcode:[@"AABCD12345" dataUsingEncoding:NSASCIIStringEncoding] error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"\nCODE 128" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print barcode",[dtdev prnPrintBarcode:BAR_PRN_CODE128 barcode:[@"BABCD12345" dataUsingEncoding:NSASCIIStringEncoding] error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"\nPDF-417" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);
	COMMAND(@"Print barcode",[dtdev prnPrintBarcodePDF417:[@"Hey try to read this :)" dataUsingEncoding:NSASCIIStringEncoding] truncated:false autoEncoding:true eccl:PDF417_ECCL_AUTO size:PDF417_SIZE_W2_H15 error:&err]);
	COMMAND(@"Print text",[dtdev prnPrintText:@"\nQRCODE" usingEncoding:NSWindowsCP1252StringEncoding error:&err]);

    [dtdev prnSetDensity:60 error:nil];
    COMMAND(@"Print barcode",[dtdev prnPrintBarcodeQRCode:[@"Hey try to read this :)" dataUsingEncoding:NSASCIIStringEncoding] eccl:QRCODE_ECCL_7 size:QRCODE_SIZE_6 error:&err]);
    [dtdev prnSetDensity:100 error:nil];

	
	COMMAND(@"Feed paper",[dtdev prnFeedPaper:0 error:&err]);
    COMMAND(@"Wait for job",[dtdev prnWaitPrintJob:30 error:&err]);
}

-(IBAction)onGraphicsDemo:(id)sender;
{
    NSError *err;
    NSDate *d=[NSDate date];
    
    if([dtdev pageIsSupported])
    {
        //print it using page mode instead
        UIImage *img=[UIImage imageNamed:@"taz.png"];
        COMMAND(@"Page start",[dtdev pageStart:&err]);
        COMMAND(@"Page set working area",[dtdev pageSetWorkingArea:0 top:0 width:0 height:img.size.height error:&err]);
        COMMAND(@"Print image",[dtdev prnPrintImage:img align:ALIGN_CENTER error:&err]);
        COMMAND(@"Print print",[dtdev pagePrint:&err]);
        COMMAND(@"Print end",[dtdev pageEnd:&err]);
    }else
    {
        COMMAND(@"Print image",[dtdev prnPrintImage:[UIImage imageNamed:@"taz.png"] align:ALIGN_CENTER error:&err]);
    }
	COMMAND(@"Feed paper",[dtdev prnFeedPaper:0 error:&err]);
    [self displayAlert:@"Print done" message:[NSString stringWithFormat:@"Time taken: %.02f",-[d timeIntervalSinceNow]]];
    COMMAND(@"Wait for job",[dtdev prnWaitPrintJob:30 error:&err]);
}

-(IBAction)onLoadLogo:(id)sender;
{
    NSError *err;
    
    COMMAND(@"Load logo",[dtdev prnLoadLogo:[UIImage imageNamed:@"Icon-72.png"] align:ALIGN_CENTER error:&err]);
    COMMAND(@"Print logo",[dtdev prnPrintLogo:LOGO_NORMAL error:&err]);
    
	COMMAND(@"Feed paper",[dtdev prnFeedPaper:0 error:&err]);
    COMMAND(@"Wait for job",[dtdev prnWaitPrintJob:30 error:&err]);
}

-(void)print2InchTicket
{
    NSError *err = nil;
    
    DTPrinterInfo *info=[dtdev prnGetPrinterInfo:&err];
    
    int width=info.paperWidthPx;
    int height=170;
    int lineSize=4;
    
    [dtdev pageStart:&err];
    [dtdev pageSetCoordinatesTranslation:true error:&err];
    [dtdev pageSetWorkingArea:0 top:0 width:-1 heigth:-1 orientation:PAGE_HORIZONTAL_TOPLEFT error:&err];
    
    [dtdev pageSetLabelHeight:height error:&err];
    [dtdev pageRectangleFrame:lineSize top:lineSize width:width-2*lineSize height:height-2*lineSize framewidth:lineSize color:[UIColor blackColor] error:&err];
    
    UIImage *img=[UIImage imageNamed:@"printer1.png"];
    [dtdev pageSetWorkingArea:15 top:(height-img.size.height)/2 width:-1 height:-1 error:&err];
    [dtdev prnPrintImage:img align:ALIGN_LEFT error:&err];

    [dtdev pageSetWorkingArea:75 top:10 width:-1 height:-1 error:&err];
    [dtdev prnSetBarcodeSettings:2 height:60 hriPosition:BAR_TEXT_BELOW align:ALIGN_LEFT error:&err];
    [dtdev prnPrintBarcode:BAR_PRN_CODE128AUTO barcode:[@"BABCD12345" dataUsingEncoding:NSASCIIStringEncoding ] error:&err];
    
    [dtdev prnPrintText:@"{=F0}Sample Text\n{=F1}{+B}And more!\n" error:&err];
    
    COMMAND(@"Page Print",[dtdev pagePrint:&err]);
    COMMAND(@"Page End",[dtdev pageEnd:&err]);
    
    COMMAND(@"Feed paper",[dtdev prnFeedPaper:0 error:&err]);
    COMMAND(@"Wait for job",[dtdev prnWaitPrintJob:30 error:&err]);
}

-(void)print3InchTicket
{
    NSError *err = nil;
    UIImage *img = nil;
    
    int width=1284;
    int height=576;
    
    [dtdev pageStart:&err];
    [dtdev pageSetCoordinatesTranslation:true error:&err];
    [dtdev pageSetWorkingArea:0 top:0 width:width heigth:height orientation:PAGE_VERTICAL_TOPRIGHT error:&err];
    
    [dtdev pageFillRectangle:910 top:0 width:2 height:height color:[UIColor blackColor] error:&err];
    
    //left part
    img=[UIImage imageNamed:@"jb_logo.png"];
    [dtdev pageSetWorkingArea:0 top:11 width:-1 height:-1 error:&err];
    [dtdev prnPrintImage:img align:ALIGN_LEFT error:&err];
    
    [dtdev pageSetWorkingArea:156 top:35 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{+B}BOARDING PASS" error:&err];
    
    [dtdev pageSetWorkingArea:0 top:100 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{=F1}Name:\n{=F0}{+B}SMITH/JOHN" error:&err];
    
    [dtdev pageSetWorkingArea:0 top:195 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{=F1}From:\n{=F0}{+B}Long Beach,CA (LGB)" error:&err];
    [dtdev prnPrintText:@"{=F1}To:\n{=F0}{+B}Seattle,WA (SEA)" error:&err];
    [dtdev prnPrintText:@"{=F1}Confirmation:\n{=F0}{+B}IZVNRI" error:&err];
    [dtdev prnPrintText:@"{=F1}TryeBlue Number:\n{=F0}{+B}B6 1234567890" error:&err];
    
    [dtdev pageSetWorkingArea:0 top:484 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{=F0}{+B}Boarding gate closes 15 minutes prior to depatrture" error:&err];
    
    [dtdev pageSetWorkingArea:0 top:550 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{=F0}{+B}DBAG" error:&err];
    
    
    [dtdev pageSetWorkingArea:430 top:00 width:390 height:-1 error:&err];
    [dtdev prnSetBarcodeSettings:1 height:120 hriPosition:BAR_TEXT_NONE align:ALIGN_LEFT error:&err];
    [dtdev prnPrintBarcodePDF417:[@"M1SMITH/JOHN          EIZVNRI LGBSEAB6 0206 209R003C0002 147>3181OK5209BB6              29279          3 B6 B6                     ^160MEUCICht+/p4ZnM42SnW2B8vtVYsEKH7fWdpUrTvg4pMGJBrAiEAmph8K1A+kOcDmjJKCbualTL9UZ1rNp8vT5KeBWzcZDM=" dataUsingEncoding:NSASCIIStringEncoding] truncated:false autoEncoding:true eccl:PDF417_ECCL_AUTO size:PDF417_SIZE_W2_H4 error:&err];
    
    img=[UIImage imageNamed:@"jb_seat.png"];
    [dtdev pageSetWorkingArea:625 top:130 width:-1 height:-1 error:&err];
    [dtdev prnPrintImage:img align:ALIGN_LEFT error:&err];
    
    img=[UIImage imageNamed:@"jb_direction.png"];
    [dtdev pageSetWorkingArea:700 top:130 width:-1 height:-1 error:&err];
    [dtdev prnPrintImage:img align:ALIGN_LEFT error:&err];
    
    
    [dtdev pageSetWorkingArea:395 top:195 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{=F1}Depart:\n{=F0}{+B}7:37 PM" error:&err];
    [dtdev prnPrintText:@"{=F1}Arrive:\n{=F0}{+B}10:09 PM" error:&err];
    [dtdev prnPrintText:@"{=F1}Boarding Time:\n{=F0}{+B}7:02 PM" error:&err];
    [dtdev prnPrintText:@"{=F1}Ticket Number:\n{=F0}{+B}1234567890123" error:&err];
    
    [dtdev pageSetWorkingArea:577 top:195 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{=F1}Date:\n{=F0}{+B}28 Jul 15" error:&err];
    [dtdev prnPrintText:@"{=F1} \n{=F0} " error:&err];
    [dtdev prnPrintText:@"{=F1}Gate:\n{=F0}{+B}7" error:&err];
    
    [dtdev pageSetWorkingArea:770 top:195 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{=F1}Flight:\n{=F0}{+B}B6 206" error:&err];
    [dtdev prnPrintText:@"{=F1} \n{=F0} " error:&err];
    [dtdev prnPrintText:@"{=F1}Seat:\n{=F0}{+B}3C" error:&err];
    [dtdev prnPrintText:@"{=F1}Seq:\n{=F0}{+B}0002" error:&err];
    
    //right part
    img=[UIImage imageNamed:@"jb_logo.png"];
    [dtdev pageSetWorkingArea:940 top:11 width:-1 height:-1 error:&err];
    [dtdev prnPrintImage:img align:ALIGN_LEFT error:&err];
    
    [dtdev pageSetWorkingArea:940 top:100 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{=F1}Name:\n{=F0}{+B}SMITH/JOHN\n" error:&err];
    
    [dtdev pageSetWorkingArea:940 top:195 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{=F1}From:\n{=F0}{+B}LGB/SEA" error:&err];
    [dtdev prnPrintText:@"{=F1}Depart:\n{=F0}{+B}7:37 PM" error:&err];
    [dtdev prnPrintText:@"{=F1}Flight:\n{=F0}{+B}B6 206" error:&err];
    [dtdev prnPrintText:@"{=F1}Class:\n{=F0}{+B}R" error:&err];
    
    [dtdev pageSetWorkingArea:1100 top:195 width:-1 height:-1 error:&err];
    [dtdev prnPrintText:@"{=F1} \n{=F0} " error:&err];
    [dtdev prnPrintText:@"{=F1}Date:\n{=F0}{+B}28 Jul 15" error:&err];
    [dtdev prnPrintText:@"{=F1}Seat:\n{=F0}{+B}3C" error:&err];
    
    
    [dtdev pagePrint:&err];
    [dtdev pageEnd:&err];
    
    [dtdev prnFeedPaper:0 error:&err];
    COMMAND(@"Wait for job",[dtdev prnWaitPrintJob:30 error:&err]);
}

-(void)print4InchTicket
{
    NSError *err = nil;
    
    int hoffset=8;
    int width=800;
    int height=600;
    int lineSize=6;
    
    COMMAND(@"Barcode settings",[dtdev prnSetBarcodeSettings:2 height:77 hriPosition:BAR_TEXT_BELOW align:ALIGN_LEFT error:&err]);
    
    COMMAND(@"Page Start",[dtdev pageStart:&err]);
    COMMAND(@"Page Set Working Area",[dtdev pageSetWorkingArea:hoffset top:0 width:width height:height error:&err]);
    
    COMMAND(@"Page Start",[dtdev pageStart:&err]);
    [dtdev pageSetWorkingArea:0 top:0 width:width heigth:height orientation:PAGE_HORIZONTAL_TOPLEFT error:&err];
    COMMAND(@"Page Rectangle Frame",[dtdev pageRectangleFrame:hoffset+lineSize top:lineSize width:width-2*lineSize height:height-2*lineSize framewidth:lineSize color:[UIColor blackColor] error:&err]);
    COMMAND(@"Page Rectangle",[dtdev pageFillRectangle:hoffset+207 top:20 width:lineSize height:200 color:[UIColor blackColor] error:&err]);
    COMMAND(@"Page Rectangle",[dtdev pageFillRectangle:hoffset+20 top:220 width:width-2*20 height:lineSize color:[UIColor blackColor] error:&err]);
    COMMAND(@"Page Rectangle",[dtdev pageFillRectangle:hoffset+20 top:295 width:width-2*20 height:lineSize color:[UIColor blackColor] error:&err]);
    
    
    
    
    COMMAND(@"Page Set Working Area",[dtdev pageSetWorkingArea:hoffset+254 top:35 width:-1 height:192-35 error:&err]);
    COMMAND(@"US POSTAGE",[dtdev prnPrintText:@"POSTAGE\nmPOS\n" error:&err]);
    COMMAND(@"Barcode",[dtdev prnPrintBarcode:BAR_PRN_PDF417 barcode:[@"Test barcode" dataUsingEncoding:NSASCIIStringEncoding ] error:&err]);
    
    COMMAND(@"Page Set Working Area",[dtdev pageSetWorkingArea:hoffset+254 top:35 width:763-254 height:192-35 error:&err]);
    COMMAND(@"Text",[dtdev prnPrintText:@"{=R}062S0030243717\nFROM 20151\n{+B}$5.15{-B}\n0024\n08/13/2013" error:&err]);
    
    COMMAND(@"Page Set Working Area",[dtdev pageSetWorkingArea:hoffset+0 top:240 width:-1 height:-1 error:&err]);
    COMMAND(@"Text",[dtdev prnPrintText:@"{=C}{=F1}{+B}{+DW}{+DH 1-DAY™" error:&err]);
    
    COMMAND(@"Page Set Working Area",[dtdev pageSetWorkingArea:hoffset+0 top:320 width:-1 height:-1 error:&err]);
    COMMAND(@"Text",[dtdev prnPrintText:@"{=C}{=F1}{+B}{+DW}{+DH} TRACKING #" error:&err]);
    COMMAND(@"Feed paper",[dtdev prnFeedPaper:20 error:&err]);
    COMMAND(@"Barcode settings",[dtdev prnSetBarcodeSettings:3 height:90 hriPosition:BAR_TEXT_BELOW align:ALIGN_CENTER error:&err]);
    COMMAND(@"Barcode",[dtdev prnPrintBarcode:BAR_PRN_CODE128AUTO barcode:[@"420221529405511201080106322512" dataUsingEncoding:NSASCIIStringEncoding ] error:&err]);
    
    
    
    COMMAND(@"Page Print",[dtdev pagePrint:&err]);
    COMMAND(@"Page End",[dtdev pageEnd:&err]);
    
    COMMAND(@"Feed paper",[dtdev prnFeedPaper:0 error:&err]);
    COMMAND(@"Wait for job",[dtdev prnWaitPrintJob:30 error:&err]);
}


-(IBAction)onPrintLabelDemo:(id)sender
{
    if (![dtdev pageIsSupported])
    {
        [self displayAlert:@"Error" message:@"Page mode is not supported"];
        return;
    }
    
    DTPrinterInfo *info=[dtdev prnGetPrinterInfo:nil];
    if(info)
    {
        if(info.paperWidthInch==2)
            [self print2InchTicket];
        if(info.paperWidthInch==3)
            [self print3InchTicket];
        if(info.paperWidthInch==4)
            [self print4InchTicket];
    }
}

static NSString *toHexString(const uint8_t *data, size_t length, BOOL ascii)
{
#define GLOBAL_MAX_DEBUG_DATA_LENGTH 1024
    if (length <= 0) {
        return @"";
    }
    
    const char HEX[]="0123456789ABCDEF";
    int i,j;
    char s[GLOBAL_MAX_DEBUG_DATA_LENGTH*3+3];
    for(i=0,j=0;i<length && i<GLOBAL_MAX_DEBUG_DATA_LENGTH;i++)
    {
        if(ascii)
        {
            s[j++]='(';
            if(data[i]<0x20)
                s[j++]='.';
            else
                s[j++]=data[i];
            s[j++]=')';
        }
        s[j++]=HEX[data[i]>>4];
        s[j++]=HEX[data[i]&0x0f];
        s[j++]=' ';
    }
    if(length>GLOBAL_MAX_DEBUG_DATA_LENGTH)
    {
        s[j++]='.';
        s[j++]='.';
        s[j++]='.';
    }
    s[j]=0;
    return [NSString stringWithCString:s encoding:NSASCIIStringEncoding];
}

static NSString *toHexString1(NSData *data)
{
    return toHexString(data.bytes, data.length, false);
}

-(IBAction)onSCCheck:(id)sender;
{
    NSError *err;
    
    COMMAND(@"Init Smartcard",[dtdev scInit:SLOT_MAIN error:&err]);
    if([dtdev scIsCardPresent:SLOT_MAIN error:&err])
    {
        [dtdev scClose:SLOT_MAIN error:&err];
        NSData *atr=[dtdev scCardPowerOn:SLOT_MAIN error:&err];
        COMMAND(@"Power on Smartcard",atr);
        uint8_t rnd[]={0x00,0x84,0x00,0x00,0x08};
        NSData *random=[dtdev scCAPDU:SLOT_MAIN apdu:[NSData dataWithBytes:rnd length:sizeof(rnd)] error:&err];
        COMMAND(@"APDU Command",random);
        [self displayAlert:@"Success" message:[NSString stringWithFormat:@"ATR: %@\nAPDU: %@",toHexString1(atr),toHexString1(random)]];
        [dtdev scClose:SLOT_MAIN error:&err];
        atr=[dtdev scCardPowerOn:SLOT_MAIN error:&err];
        COMMAND(@"Power on Smartcard",atr);
        random=[dtdev scCAPDU:SLOT_MAIN apdu:[NSData dataWithBytes:rnd length:sizeof(rnd)] error:&err];
        COMMAND(@"APDU Command",random);
        [self displayAlert:@"Success" message:[NSString stringWithFormat:@"ATR: %@\nAPDU: %@",toHexString1(atr),toHexString1(random)]];
    }else
        [self displayAlert:@"SmartCard" message:@"Card missing"];
    COMMAND(@"Close Smartcard",[dtdev scClose:SLOT_MAIN error:&err]);
}

-(void)viewDidAppear:(BOOL)animated
{
    //read some settings
    int len=[dtdev prnGetMaxLabelLength:nil];
    if(len!=0)
        tfLabelWidth.text=[NSString stringWithFormat:@"%d",len];
    else
        tfLabelWidth.text=@"1000";
}

-(void)viewDidLoad
{
	dtdev=[DTDevices sharedDevice];
    [dtdev addDelegate:self];
    [super viewDidLoad];
    [self paperStatus:true];
}


@end

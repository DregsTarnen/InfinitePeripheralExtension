#import "AmountViewController.h"
#import "MainViewController.h"


@implementation AmountViewController

- (void)addQty:(char)symbol
{
	if((amount<1000 || decimalPoints>0) && decimalPoints<=2 && (symbol!='.' || (symbol=='.' && decimalPoints==0)))
	{
		if(symbol=='.')
		{
			decimalPoints=1;
		}else
		{
			double d=(symbol-'0');
			if(decimalPoints==0)
			{
				amount*=10;
				amount+=d;
			}else
			{
				amount+=d/pow(10,decimalPoints);
				decimalPoints++;
			}
		}
	}
	
    [amountButton setTitle:[NSString stringWithFormat:@"%.2f",amount] forState:UIControlStateNormal];
}

- (IBAction)onButton:(id)sender
{
	UIButton *btn=(UIButton *)sender;
	char text[10];
	
    if(clear)
    {
        amount=0;
        clear=FALSE;
    }
	[[btn titleLabel].text getCString:text maxLength:sizeof(text) encoding:NSASCIIStringEncoding];
	[self addQty:text[0]];
}

- (IBAction)onButtonBack:(id)sender
{
    if(clear)
    {
        amount=0;
        clear=FALSE;
    }
    if((decimalPoints-1)>0)
    {
        amount*=pow(10,decimalPoints-1);
        amount-=((int)amount%10);
        amount/=pow(10,decimalPoints-1);
        decimalPoints--;
    }else
    {
        double t=amount-(int)amount;
        amount=((int)amount/10)+t;
        decimalPoints=0;
    }
    [amountButton setTitle:[NSString stringWithFormat:@"%.2f",amount] forState:UIControlStateNormal];
}

- (IBAction)onButtonClr:(id)sender
{
	amount=0;
	decimalPoints=0;
    clear=FALSE;
    [amountButton setTitle:@"0.00" forState:UIControlStateNormal];
}

- (IBAction)onAccept:(id)sender
{
    [self dismissModalViewControllerAnimated:TRUE];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationAmount object:[NSNumber numberWithDouble:amount] userInfo:nil];
}

- (IBAction)onCancel:(id)sender
{
    [self dismissModalViewControllerAnimated:TRUE];
}

- (void)setAmount:(double)value
{
    clear=TRUE;
    amount=value;
    decimalPoints=0;
    [amountButton setTitle:[NSString stringWithFormat:@"%.2f",amount] forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
	amount=1;
	decimalPoints=0;
    [super viewDidLoad];
}
@end

//
//  DirectionVCViewController.h
//  googlemap


#import <UIKit/UIKit.h>

@interface DirectionVCViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>
{
    NSArray *contentArray;
    
}


@property (weak, nonatomic) IBOutlet UITableView *directionTbl;

@property (nonatomic,retain)NSArray *contentArray;
@property (weak, nonatomic) IBOutlet UIButton *dismissBtn;

- (IBAction)dismissAction:(id)sender;
@end

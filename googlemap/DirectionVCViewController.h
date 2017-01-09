//
//  DirectionVCViewController.h
//  googlemap
//
//  Created by C N Soft Net on 07/01/17.
//  Copyright © 2017 C N Soft Net. All rights reserved.
//

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

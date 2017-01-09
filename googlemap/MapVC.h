//
//  ViewController.h
//  googlemap
//
//  Created by C N Soft Net on 04/01/17.
//  Copyright © 2017 C N Soft Net. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import "CSMarker.h"
#import "DirectionVCViewController.h"


@interface MapVC : UIViewController <GMSMapViewDelegate,NSURLSessionDelegate,CLLocationManagerDelegate>
{

    GMSMapView *map;
    CSMarker *selectedMarker;
    GMSPolyline *polyline;
    CLLocationManager *locationManager;
    DirectionVCViewController *objdirection;


    NSSet *markers;
    NSArray *stepsArray;
    NSDictionary *directionDict;
    UIView *detailVw;
    UIButton *moreDetail,*pathBtn,*navigationBtn;

    CGSize textSize;
}

@property (nonatomic,retain)GMSMapView *map;
@property (nonatomic,retain)GMSPolyline *polyline;
@property (nonatomic,copy)NSSet *markers;
@property (nonatomic,retain)NSArray *stepsArray;


-(void)readMarkersFromFile;
-(void)moreDetail;
-(void)addpinfromjson:(NSDictionary *)jsonDict;
-(void)directionTapped:(id)sender;
-(void)callDirectionApi:(CSMarker *)selectedMarker;
-(void)navigationInfo:(id)sender;

@end


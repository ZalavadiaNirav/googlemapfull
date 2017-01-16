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

#import "SDWebImageDownloader.h"
#import "SDWebImage/UIImageView+WebCache.h"


@interface MapVC : UIViewController <GMSMapViewDelegate,NSURLSessionDelegate,CLLocationManagerDelegate>
{

    GMSMapView *map;
    CSMarker *selectedMarker;
    GMSPolyline *polyline;
    CLLocationManager *locationManager;
    DirectionVCViewController *objdirection;

    
    NSSet *markers;
    NSArray *stepsArray,*nearPlacesArray;
    NSDictionary *directionDict;
    UIView *detailVw;
    UIButton *nearByMe,*pathBtn,*navigationBtn;

    CGSize textSize;
    float selectedLat,selectedLongtitude;
    NSString *nearPlacesToSearch;
}

@property (nonatomic,retain)GMSMapView *map;
@property (nonatomic,retain)GMSPolyline *polyline;
@property (nonatomic,copy)NSSet *markers;
@property (nonatomic,retain)NSArray *stepsArray;


-(void)readMarkersFromFile;
-(void)nearByMe;
-(void)addpinfromjson:(NSDictionary *)jsonDict;
-(void)directionTapped:(id)sender;
-(void)callDirectionApi:(CSMarker *)selectedMarker;
-(void)navigationInfo:(id)sender;
-(void)fetchNearestPlaces;

@end


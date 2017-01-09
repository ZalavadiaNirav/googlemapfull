//
//  ViewController.m
//  googlemap
//
//  Created by C N Soft Net on 04/01/17.
//  Copyright © 2017 C N Soft Net. All rights reserved.
//

#import "MapVC.h"

@interface MapVC ()
{
    
}
@end

@implementation MapVC

@synthesize map,markers,stepsArray,polyline;

- (void)viewDidLoad {
    [super viewDidLoad];

    //In Build Setting add Other Linker Flag = -ObjC
    GMSCameraPosition *position=[GMSCameraPosition cameraWithLatitude:23.0 longitude:72.0 zoom:7 bearing:0 viewingAngle:0];
    self.map=[GMSMapView mapWithFrame:self.view.bounds camera:position];
    self.map.delegate=self;
    [self.map setMinZoom:03 maxZoom:20];

    
    //asking for location also set two description in info.plist
    [self enableMyLocation];
    
    //enble my location button
    self.map.settings.myLocationButton=YES;
    
    
    
    [self.view addSubview:self.map];
    
    UIBarButtonItem *fitBoundsButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Fit Bounds"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(didTapFitBounds)];
    self.navigationItem.rightBarButtonItem = fitBoundsButton;
    
    //read markers from json file locally
    [self readMarkersFromFile];
    
//    Marker using local data
//    [self setupMarker];
    
    
}
#pragma mark - location Authorization


-(void)enableMyLocation
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status == kCLAuthorizationStatusNotDetermined)
        [self requestLocationAuthorization];
    else if (status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted)
        return; // we weren't allowed to show the user's location so don't enable
    else
        self.map.myLocationEnabled = YES;
    
}

- (void)requestLocationAuthorization
{
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    
    [locationManager requestAlwaysAuthorization];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status != kCLAuthorizationStatusNotDetermined) {
        [self performSelectorOnMainThread:@selector(enableMyLocation) withObject:nil waitUntilDone:[NSThread isMainThread]];
        
        locationManager.delegate = nil;
        locationManager = nil;
    }
}

#pragma mark - Map Fit Bounds Method

- (void)didTapFitBounds
{
    NSMutableArray *marksArray=[[NSMutableArray alloc] init];
    marksArray=[[self.markers allObjects] mutableCopy];
    if ([marksArray count] == 0)
        return;
    CLLocationCoordinate2D firstPos = ((GMSMarker *)marksArray.firstObject).position;
    GMSCoordinateBounds *bounds =[[GMSCoordinateBounds alloc] initWithCoordinate:firstPos coordinate:firstPos];
    for (GMSMarker *marker in marksArray)
    {
        bounds = [bounds includingCoordinate:marker.position];
    }
    GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:bounds withPadding:50.0f];
    [self.map moveCamera:update];
}

#pragma mark - simulate json api from local and add marker on map

-(void)readMarkersFromFile
{
    NSString *filePath=[[NSBundle mainBundle] pathForResource:@"locationApi" ofType:@"json"];
    NSString *locationStr = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    NSData *locationData = [locationStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *locationDict = [NSJSONSerialization JSONObjectWithData:locationData
                                                          options:NSJSONReadingMutableContainers
                                                            error:nil];
    
    NSLog(@"Array %@",[locationDict objectForKey:@"features"]);
    [self addpinfromjson:locationDict];
}

-(void)addpinfromjson:(NSDictionary *)jsonDict
{
    NSMutableSet *mutableSet=[[NSMutableSet alloc] initWithSet:self.markers];
    NSArray *locationArr=[jsonDict objectForKey:@"features"];
    for(int i=0;i<locationArr.count;i++)
    {
       double lat= [[[[[locationArr objectAtIndex:i] objectForKey:@"geometry"] objectForKey:@"coordinates"] objectAtIndex:1] doubleValue];
        double lon= [[[[[locationArr objectAtIndex:i] objectForKey:@"geometry"] objectForKey:@"coordinates"] objectAtIndex:0] doubleValue];
        
        CSMarker *marker=[[CSMarker alloc] init];
        marker.objectID=[NSString stringWithFormat:@"%@",[[[locationArr objectAtIndex:i] objectForKey:@"properties"] objectForKey:@"markerid"]];
        marker.position=CLLocationCoordinate2DMake(lat, lon);
        marker.title=[NSString stringWithFormat:@"Marker %d",i];
        marker.appearAnimation=kGMSMarkerAnimationPop;
        
        [mutableSet addObject:marker];
    }
    self.markers=[mutableSet copy];
    [self drawMarkers];
}

#pragma mark - plot markers on the map

-(void)drawMarkers
{
    for (CSMarker *marker in self.markers)
    {
        if(marker.map==nil)
            marker.map=self.map;
    }
}


#pragma mark - Direction api to know direction

-(void)callDirectionApi:(CSMarker *)marker
{
    NSLog(@"latitude %f longtitude %f",self.map.myLocation.coordinate.latitude,self.map.myLocation.coordinate.longitude);
    if(self.map.myLocation !=nil)
    {
        NSURLSession *session=[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%f,%f&sensor=true&key=AIzaSyCDuC3eH6GW766vnvHZWHpJbTGyOKiszJU",self.map.myLocation.coordinate.latitude,self.map.myLocation.coordinate.longitude,marker.position.latitude,marker.position.longitude]];
        NSURLSessionDataTask *datatask= [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError *error)
        {
            NSError *err=nil;
            directionDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
            NSLog(@"direction api %@",[directionDict[@"routes"][0][@"legs"][0][@"steps"] description]);
            
            if(!err)
            {
                self.stepsArray=directionDict[@"routes"][0][@"legs"][0][@"steps"];
                if(self.stepsArray!=nil)
                {
                    NSLog(@"Direction Api data loaded sucessfully");
                }
                else
                {
                    err = [NSError errorWithDomain:@"Directionapi data return nil" code:200 userInfo:nil];
                    NSLog(@"%@",[err description]);
                }
            }
        }];
        
        [datatask resume];
    }
}

#pragma mark - Draw path between two coordinates

-(void)drawpath
{
    if(directionDict!=nil)
    {
        GMSPath *path =[GMSPath pathFromEncodedPath:directionDict[@"routes"][0][@"overview_polyline"][@"points"]];
        self.polyline = [GMSPolyline polylineWithPath:path];
        self.polyline.strokeWidth = 5;
        self.polyline.strokeColor = [UIColor redColor];
        self.polyline.map = self.map;
    }
    else
    {
        NSError *err = [NSError errorWithDomain:@"Route can not be defined" code:100 userInfo:nil];
        NSLog(@"%@",[err description]);
    }
}

#pragma mark - Call directionApi for get details of navigation and points to draw path on map

-(void)directionTapped:(id)sender
{
    if(directionDict!=nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.polyline.map=nil;
            [self drawpath];
            
        });
    }
    
}

-(void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(CSMarker *)marker
{
    NSLog(@"Marker Tapped");
 
    selectedMarker=marker;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:
     ^{
            [self callDirectionApi:selectedMarker];
         
            //create Information Window
            if([[self.map subviews] containsObject:detailVw])
            {
                [detailVw removeFromSuperview];
            }
         
            detailVw=[[UIView alloc] initWithFrame:CGRectMake(0,self.view.frame.size.height+200,self.view.frame.size.width, 200)];
            [detailVw setBackgroundColor:[UIColor whiteColor]];
            
            UILabel *pinLbl=[[UILabel alloc] initWithFrame:CGRectMake(5, 0,detailVw.frame.size.width-10,30)];
            pinLbl.textAlignment=NSTextAlignmentCenter;
            pinLbl.text=[NSString stringWithFormat:@"%@",marker.title];
            pinLbl.textColor=[UIColor redColor];
            pinLbl.backgroundColor=[UIColor whiteColor];
            
            moreDetail=[UIButton buttonWithType:UIButtonTypeCustom];
            [moreDetail setBackgroundColor:[UIColor blackColor]];
            [moreDetail setTitle:@"MORE DETAIL" forState:UIControlStateNormal];
            [moreDetail setFrame:CGRectMake(5,60,(detailVw.frame.size.width)-10, 35)];
            [moreDetail addTarget:self action:@selector(moreDetail) forControlEvents:UIControlEventTouchUpInside];
            
            pathBtn=[UIButton buttonWithType:UIButtonTypeSystem];
            [pathBtn setTitle:@"Show path" forState:UIControlStateNormal];
            [pathBtn setBackgroundColor:[UIColor blackColor]];
            [pathBtn addTarget:self action:@selector(directionTapped:) forControlEvents:UIControlEventTouchUpInside];
            [pathBtn setFrame:CGRectMake(5,110,(detailVw.frame.size.width/2)-5, 35)];
            pathBtn.backgroundColor=[UIColor blackColor];
         
            
            navigationBtn=[UIButton buttonWithType:UIButtonTypeSystem];
            [navigationBtn setTitle:@"Navigation Info" forState:UIControlStateNormal];
            [navigationBtn setBackgroundColor:[UIColor blackColor]];
            [navigationBtn addTarget:self action:@selector(navigationInfo:) forControlEvents:UIControlEventTouchUpInside];
            [navigationBtn setFrame:CGRectMake((detailVw.frame.size.width/2)+5,110,(detailVw.frame.size.width/2)-10, 35)];
            navigationBtn.backgroundColor=[UIColor blackColor];
         
         
            [detailVw addSubview:pinLbl];
            [detailVw addSubview:moreDetail];
            [detailVw addSubview:pathBtn];
            [detailVw addSubview:navigationBtn];

         
            [UIView animateWithDuration:0.5 delay:0.1 options:1 animations:^{
                detailVw.frame = CGRectMake(0,self.view.frame.size.height-200,self.view.frame.size.width, 200);
            }completion:^(BOOL finished){}];
            
            [self.map addSubview:detailVw];

    }];
}

#pragma mark - Navigation inforamtion

-(void)navigationInfo:(id)sender
{
    NSLog(@"stpes api %@",[self.stepsArray description]);
    [self performSegueWithIdentifier:@"directionSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"directionSegue"]) {
         objdirection = segue.destinationViewController;
        NSLog(@"array %@",[self.stepsArray description]);
        objdirection.contentArray = self.stepsArray;
        NSLog(@"content array %@",[objdirection.contentArray description]);
    }

}

#pragma mark - Tap on map to hide detail information

-(void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"didtapatcoordinate");
    if([[self.map subviews] containsObject:detailVw])
    {
        [UIView animateWithDuration:0.5 delay:0.1 options:2 animations:^{
            detailVw.frame = CGRectMake(0,self.view.frame.size.height+200,self.view.frame.size.width, 200);
        }completion:^(BOOL finished)
        {
            [detailVw removeFromSuperview];
        }];
    }

}

-(void)mapView:(GMSMapView *)mapView didTapOverlay:(GMSOverlay *)overlay
{
    NSLog(@"overlay tapped");
}

- (void)mapView:(GMSMapView *)mapView
didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    NSLog(@"long press");
}

-(void)moreDetail
{
    NSLog(@"BUTTON TAPPED");
}


/*
 
 #pragma mark - Marker Info window called
 
 - (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker
 {
 marker.icon=[GMSMarker markerImageWithColor:[UIColor blueColor]];
 UIView *infoWindow=[[UIView alloc] initWithFrame:CGRectMake(0, 0,150, 60)];
 
 
 UILabel *pinLbl=[[UILabel alloc] initWithFrame:CGRectMake(0, 0,150,30)];
 pinLbl.text=[NSString stringWithFormat:@"%@",marker.title];
 pinLbl.textColor=[UIColor redColor];
 pinLbl.backgroundColor=[UIColor whiteColor];
 
 UILabel *detailLbl=[[UILabel alloc] initWithFrame:CGRectMake(0,30,150,30)];
 detailLbl.text=[NSString stringWithFormat:@"%@",marker.snippet];
 detailLbl.textColor=[UIColor blueColor];
 detailLbl.backgroundColor=[UIColor whiteColor];
 
 [infoWindow addSubview:pinLbl];
 [infoWindow addSubview:detailLbl];
 
 return infoWindow;
 }
 
 #pragma mark - Draw text on marker's image
 
 -(UIImage*)drawText:(NSString*)text inImage:(UIImage*)image
 {
 UIFont *font = [UIFont boldSystemFontOfSize:11];
 CGSize size = image.size;
 UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
 [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
 CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
 
 NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
 paragraphStyle.alignment = NSTextAlignmentCenter;
 NSDictionary *attributes = @{
 NSFontAttributeName : font,
 NSParagraphStyleAttributeName : paragraphStyle,
 NSForegroundColorAttributeName : [UIColor redColor]
 };
 textSize = [text sizeWithAttributes:attributes];
 CGRect textRect = CGRectMake((rect.size.width-textSize.width)/2, (rect.size.height-textSize.height)/2 - 2, textSize.width, textSize.height);
 [text drawInRect:CGRectIntegral(textRect) withAttributes:attributes];
 NSLog(@"height %f width %f",textSize.height,textSize.width);
 UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
 [newImage drawInRect:CGRectMake(0, 0,textSize.width, textSize.height)];
 UIGraphicsEndImageContext();
 
 return newImage;
 }
 
 
 //locally set marker
 -(void)setupMarker
 {
 GMSMarker *marker1=[[GMSMarker alloc] init];
 marker1.position=CLLocationCoordinate2DMake(23.0,72.0);
 marker1.title=@"pin1";
 marker1.snippet=@"This is snippet1";
 marker1.appearAnimation=kGMSMarkerAnimationPop;
 
 
 GMSMarker *marker2=[[GMSMarker alloc] init];
 marker2.position=CLLocationCoordinate2DMake(23.1236,72.0527);
 marker2.title=@"pin2";
 marker2.snippet=@"This is snippet2";
 marker2.appearAnimation=kGMSMarkerAnimationPop;
 
 GMSMarker *marker3=[[GMSMarker alloc] init];
 marker3.title=@"pin3";
 marker3.snippet=@"This is snippet3";
 marker3.position=CLLocationCoordinate2DMake(23.26,72.6);
 marker3.appearAnimation=kGMSMarkerAnimationPop;
 
 
 GMSMarker *marker4=[[GMSMarker alloc] init];
 marker4.position=CLLocationCoordinate2DMake(23.30,72.8);
 marker4.title=@"pin4";
 marker4.snippet=@"This is snippet4";
 marker4.appearAnimation=kGMSMarkerAnimationPop;
 
 
 GMSMarker *marker5=[[GMSMarker alloc] init];
 marker5.position=CLLocationCoordinate2DMake(23.9,72.7);
 marker5.title=@"pin5";
 marker5.snippet=@"This is snippet5";
 marker5.appearAnimation=kGMSMarkerAnimationPop;
 
 
 GMSMarker *marker6=[[GMSMarker alloc] init];
 marker6.position=CLLocationCoordinate2DMake(23.2,72.2);
 marker6.title=@"pin6";
 marker6.snippet=@"This is snippet6";
 marker6.appearAnimation=kGMSMarkerAnimationPop;
 
 
 GMSMarker *marker7=[[GMSMarker alloc] init];
 marker7.position=CLLocationCoordinate2DMake(22.6,72.3);
 marker7.title=@"pin7";
 marker7.snippet=@"This is snippet7";
 marker7.appearAnimation=kGMSMarkerAnimationPop;
 
 
 GMSMarker *marker8=[[GMSMarker alloc] init];
 marker8.position=CLLocationCoordinate2DMake(22.3,72.4);
 marker8.title=@"pin8";
 marker8.snippet=@"This is snippet8";
 marker8.appearAnimation=kGMSMarkerAnimationPop;
 
 
 GMSMarker *marker9=[[GMSMarker alloc] init];
 marker9.position=CLLocationCoordinate2DMake(22.9,72.7);
 //    UIImage *nwimg=[self drawText:[NSString stringWithFormat:@"pin9"] inImage:[UIImage imageNamed:@"icon-marker"]];
 //    marker9.icon=nwimg;
 
 marker9.title=@"pin9";
 marker9.snippet=@"This is snippet9";
 marker9.appearAnimation=kGMSMarkerAnimationPop;
 self.markers=[NSSet setWithObjects:marker1,marker2,marker3,marker4,marker5,marker6,marker7,marker8,marker9,nil];
 
 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
 [self drawMarkers];
 }];
 }
 
 */

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

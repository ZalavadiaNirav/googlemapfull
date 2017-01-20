
//  ViewController.m
//  googlemap

#import "MapVC.h"
#import "GlobalConstants.h"

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
    
    NSLog(@"All Markers %@",[self.markers description]);
    int i=0;
    for (CSMarker *marker in self.markers)
    {

        if(marker.map==nil)
            marker.map=self.map;

    }
    if(nearPlacesMarkers!=nil)
    {
        for (CSMarker *marker in nearPlacesMarkers)
        {
            if(distanceArray!=nil)
            {
                 marker.snippet=[NSString stringWithFormat:@"%@",[[[[[distanceArray objectAtIndex:i] objectForKey:@"elements"] objectAtIndex:0] objectForKey:@"distance"] objectForKey:@"text"]];
                NSLog(@"distance %@",[NSString stringWithFormat:@"%@",[[[[[distanceArray objectAtIndex:i] objectForKey:@"elements"] objectAtIndex:0] objectForKey:@"distance"] objectForKey:@"text"]]);
                i++;
                 marker.map=self.map;
            }
        }
    }
}


#pragma mark - Draw Direction between current location or between selected marker to nearest places

-(void)directionTapped:(id)sender
{
    [self callDirectionApi];
    
}

-(void)callDirectionApi
//:(CSMarker *)marker
{
    NSLog(@"latitude %f longtitude %f",self.map.myLocation.coordinate.latitude,self.map.myLocation.coordinate.longitude);
    if(self.map.myLocation !=nil)
    {
        NSURLSession *session=[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURL *url;
         CSMarker *marker=[[CSMarker alloc] init];
        
        if(originCordinatesStr==nil && selectedMarker!=nil)
        {
           
             marker=selectedMarker;
             url=[NSURL URLWithString:[NSString stringWithFormat:@"%@directions/json?origin=%f,%f&destination=%f,%f&sensor=true&key=%@",API_PREFIX,self.map.myLocation.coordinate.latitude,self.map.myLocation.coordinate.longitude,marker.position.latitude,marker.position.longitude,GOOGLEAPIKEY_CONST]];
        }
        else
        {
            url=[NSURL URLWithString:[NSString stringWithFormat:@"%@directions/json?origin=%@&destination=%f,%f&sensor=true&key=%@",API_PREFIX,originCordinatesStr,selectedLat,selectedLongtitude,GOOGLEAPIKEY_CONST]];
        }
    
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
                    if(directionDict!=nil)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.polyline.map=nil;
                            [self drawpath];
                            
                        });
                    }
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
#pragma mark - Custom Information windows

-(void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(CSMarker *)marker
{
    NSLog(@"Marker Tapped");
 
    selectedMarker=marker;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:
     ^{
         
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
            
            nearByMe=[UIButton buttonWithType:UIButtonTypeCustom];
            [nearByMe setBackgroundColor:[UIColor blackColor]];
            [nearByMe setTitle:@"Near By Me" forState:UIControlStateNormal];
            [nearByMe setFrame:CGRectMake(5,60,(detailVw.frame.size.width)-10, 35)];
            [nearByMe addTarget:self action:@selector(nearByMe) forControlEvents:UIControlEventTouchUpInside];
         
             selectedLat=marker.position.latitude;
             selectedLongtitude=marker.position.longitude;
             NSLog(@"lat %f long %f",selectedLat,selectedLongtitude);
            
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
            [detailVw addSubview:nearByMe];
            [detailVw addSubview:pathBtn];
            [detailVw addSubview:navigationBtn];

         
            [UIView animateWithDuration:0.5 delay:0.1 options:1 animations:^{
                detailVw.frame = CGRectMake(0,self.view.frame.size.height-200,self.view.frame.size.width, 200);
            }completion:^(BOOL finished){}];
            
            [self.map addSubview:detailVw];

    }];
}

#pragma mark - Navigation Inforamtion

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

#pragma mark - Near by button Action

-(void)nearByMe
{
    NSLog(@"BUTTON TAPPED");
    
    if(selectedMarker!=nil)
    {
        UIAlertController *locatlityOption=[UIAlertController alertControllerWithTitle:@"Select Places" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *foodinfo=[UIAlertAction actionWithTitle:@"Food" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            nearPlacesToSearch=@"food";
            [self fetchNearestPlaces];

        }];
        UIAlertAction *petrolinfo=[UIAlertAction actionWithTitle:@"Petrol Station" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            nearPlacesToSearch=@"gas_station";
            [self fetchNearestPlaces];

        }];
        UIAlertAction *atminfo=[UIAlertAction actionWithTitle:@"ATM" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            nearPlacesToSearch=@"atm";
            [self fetchNearestPlaces];
            
        }];
        UIAlertAction *cancelInfo=[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [locatlityOption addAction:foodinfo];
        [locatlityOption addAction:petrolinfo];
        [locatlityOption addAction:atminfo];

        [locatlityOption addAction:cancelInfo];
        [self presentViewController:locatlityOption animated:YES completion:^{
        }];
    }
    else
    {
        NSLog(@"No Marker Selected");
    }
}

-(void)fetchNearestPlaces
{
//https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=AIzaSyDHoU3-mZYIh2_yXYoPi4PmGUDgXetdmow&location=23.0225,72.5714&radius=1000&keyword=cafe&type=food
    
    NSURLSessionConfiguration *config=[NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session=[NSURLSession sessionWithConfiguration:config];
    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@place/nearbysearch/json?key=%@&location=%f,%f&radius=%d&types=%@",API_PREFIX,PLACESAPIKEY_CONST,selectedLat,selectedLongtitude,RADIUS_CONST,nearPlacesToSearch]];
    NSURLSessionTask *fetchTask=[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        NSDictionary *tempDict=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        nearPlacesArray=[tempDict objectForKey:@"results"];
        NSLog(@"places %@",[nearPlacesArray description]);
        nearPlacesMarkers=[[NSMutableSet alloc] init];
        nearPlacesLatLong=[[NSMutableArray alloc] init];
        imageUrl=[[NSMutableArray alloc] init];
        
//        for (int i=0; i<[nearPlacesArray count]; i++)
//        {
//            
//            id obj=[nearPlacesArray objectAtIndex:i];
//            [nearPlacesLatLong addObject:[NSString stringWithFormat:@"%@,%@",[[[obj objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"],[[[obj objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"]]];
//            [imageUrl addObject:[NSURL URLWithString:[NSString stringWithFormat:@"%@",[obj objectForKey:@"icon"]]]];
//
//        }
//        int q1task=(int)(nearPlacesArray.count/4);
//        int q2task=(int)(nearPlacesArray.count/4);
//        int q3task=(int)(nearPlacesArray.count/4);
//        int q4task=(int)((nearPlacesArray.count/4)+(int)((nearPlacesArray.count)%4));
//        
//        
//        NSOperationQueue *q1=[[NSOperationQueue alloc] init];
//        NSOperationQueue *q2=[[NSOperationQueue alloc] init];
//        NSOperationQueue *q3=[[NSOperationQueue alloc] init];
//        NSOperationQueue *q4=[[NSOperationQueue alloc] init];
//        
//        [q1 addOperationWithBlock:^{
//            for (int i=0; i<q1task; i++)
//            {
//                NSURL *url=[imageUrl objectAtIndex:i];
//                SDWebImageDownloader *downloader=[SDWebImageDownloader sharedDownloader];
//
//                [downloader downloadImageWithURL:url options:SDWebImageDownloaderContinueInBackground progress:
//                 ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
//
//                     //measure download progress of icon
//                    NSLog(@"Total Bytes %ld Bytes Received %ld",expectedSize,receivedSize);
//
//                }
//                completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
//                    NSLog(@"Complete Download q1");
//                    image = [self image:image ByScalingAndCroppingForSize:CGSizeMake(MAPICONWIDTH_CONST,MAPICONHEIGHT_CONST)];
//                    [[SDImageCache sharedImageCache] storeImage:image forKey:@"image" toDisk:YES completion:nil];
////                    [[SDImageCache sharedImageCache] storeImage:image forKey:myCacheKey];
//                }];
//                
//            }
//        }];
//        
//        [q2 addOperationWithBlock:^{
//            for (int i=q1task; i<=q2task; i++)
//            {
//                NSURL *url=[imageUrl objectAtIndex:i];
//                SDWebImageDownloader *downloader=[SDWebImageDownloader sharedDownloader];
//                
//                [downloader downloadImageWithURL:url options:SDWebImageDownloaderContinueInBackground progress:
//                 ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
//                     
//                     //measure download progress of icon
//                     NSLog(@"Total Bytes %ld Bytes Received %ld",expectedSize,receivedSize);
//                     
//                 }
//                                       completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
//                                           NSLog(@"Complete Download q2");
//                                           image = [self image:image ByScalingAndCroppingForSize:CGSizeMake(MAPICONWIDTH_CONST,MAPICONHEIGHT_CONST)];
//                                           [[SDImageCache sharedImageCache] storeImage:image forKey:@"image" toDisk:YES completion:nil];
//
//                }];
//            }
//            
//        }];
//        
//        [q3 addOperationWithBlock:^{
//            for (int i=q2task; i<=q3task; i++)
//            {
//                NSURL *url=[imageUrl objectAtIndex:i];
//                SDWebImageDownloader *downloader=[SDWebImageDownloader sharedDownloader];
//                
//                [downloader downloadImageWithURL:url options:SDWebImageDownloaderContinueInBackground progress:
//                 ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
//                     
//                     //measure download progress of icon
//                     NSLog(@"Total Bytes %ld Bytes Received %ld",expectedSize,receivedSize);
//                     
//                 }
//                                       completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
//                                           NSLog(@"Complete Download q3");
//                                           image = [self image:image ByScalingAndCroppingForSize:CGSizeMake(MAPICONWIDTH_CONST,MAPICONHEIGHT_CONST)];
//                                           [[SDImageCache sharedImageCache] storeImage:image forKey:@"image" toDisk:YES completion:nil];
//
//                                       }];
//                
//            }
//            
//            
//        }];
//        [q4 addOperationWithBlock:^{
//            for (int i=q3task; i<=q4task; i++)
//            {
//                NSURL *url=[imageUrl objectAtIndex:i];
//                SDWebImageDownloader *downloader=[SDWebImageDownloader sharedDownloader];
//                
//                [downloader downloadImageWithURL:url options:SDWebImageDownloaderContinueInBackground progress:
//                 ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
//                     
//                     //measure download progress of icon
//                     NSLog(@"Total Bytes %ld Bytes Received %ld",expectedSize,receivedSize);
//                     
//                 }
//                                       completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
//                                           NSLog(@"Complete Download q4");
//                                           image = [self image:image ByScalingAndCroppingForSize:CGSizeMake(MAPICONWIDTH_CONST,MAPICONHEIGHT_CONST)];
//                                           [[SDImageCache sharedImageCache] storeImage:image forKey:@"image" toDisk:YES completion:nil];
//
//                                       }];
//                
//            }
//            
//            
//        }];
//        
        
        
//        __block NSData *iconData=nil;
//        NSBlockOperation *downloadPlacesIcon=[[NSBlockOperation alloc] init];
//        __weak NSBlockOperation *weakDownloadPlacesIcon=downloadPlacesIcon;
//    
//        [weakDownloadPlacesIcon addExecutionBlock:^{
//            
//        }];

        
        dispatch_async(dispatch_get_main_queue(),
        ^{
            for (id obj in nearPlacesArray)
            {
            //used to create origins for distance matrix
                [nearPlacesLatLong addObject:[NSString stringWithFormat:@"%@,%@",[[[obj objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"],[[[obj objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"]]];
                
                CSMarker *marker=[[CSMarker alloc] init];
                marker.title=[NSString stringWithFormat:@"%@",[obj objectForKey:@"name"]];
                marker.objectID=[NSString stringWithFormat:@"%@",[obj objectForKey:@"id"]];
                
                NSURL *imageUrl=[NSURL URLWithString:[NSString stringWithFormat:@"%@",[obj objectForKey:@"icon"]]];
                SDWebImageDownloader *downloader=[SDWebImageDownloader sharedDownloader];
                
                [downloader downloadImageWithURL:imageUrl options:SDWebImageDownloaderContinueInBackground progress:
                 ^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                  
                     //measure download progress of icon
                    NSLog(@"Total Bytes %ld Bytes Received %ld",expectedSize,receivedSize);
                    
                }
                completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                    NSLog(@"Complete Download");
                    image = [self image:image ByScalingAndCroppingForSize:CGSizeMake(MAPICONWIDTH_CONST,MAPICONHEIGHT_CONST)];
                    [marker setIcon:image];
//                    [nearPlacesMarkers addObject:marker];
                }];
                double lat=[[[[obj objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
                double longti=[[[[obj objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue];
                CLLocationCoordinate2D loc=CLLocationCoordinate2DMake(lat,longti);
                marker.position=loc;
                [nearPlacesMarkers addObject:marker];
            }
//            self.markers=[tempMarkerset copy];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^(void){
                [self distanceNearPlaces];
            });
            
//            NSLog(@"Address array %@",[nearPlacesLatLong description]);
//          
//            NSLog(@"Marker %@",[self.markers description]);
//            [self drawMarkers];
        });
        [self drawMarkers];
    }];
    [fetchTask resume];
    
}


-(void)distanceNearPlaces
{

    NSString *origin=[nearPlacesLatLong componentsJoinedByString:@"|"];
    origin = [origin stringByAddingPercentEncodingWithAllowedCharacters: [NSCharacterSet URLQueryAllowedCharacterSet]];
    NSLog(@"Origin address %@",origin);
    NSURLSessionConfiguration *config=[NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session=[NSURLSession sessionWithConfiguration:config];
    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@distancematrix/json?origins=%@&destinations=%f,%f&key=%@",API_PREFIX,origin,selectedLat,selectedLongtitude,PLACESAPIKEY_CONST]];
    originCordinatesStr=[NSString stringWithFormat:@"%f,%f",selectedLat,selectedLongtitude];
    NSLog(@"distance matrix url %@",url);
    NSURLSessionTask *distanceFetchTask=[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        NSError *err;
        distanceArray=[[NSMutableArray alloc] init];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(distanceDataReceived) name:@"distanceArrayNotification" object:nil];
        NSDictionary *distanceDict=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
        distanceArray=[distanceDict objectForKey:@"rows"];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"distanceArrayNotification" object:nil];
        [self distanceDataReceived];
      
    }];

    [distanceFetchTask resume];


}

-(void)distanceDataReceived
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.map clear];
        [self drawMarkers];
    });
   
}

- (UIImage*)image:(UIImage *)image ByScalingAndCroppingForSize:(CGSize)targetSize
{
    UIImage *sourceImage = image;
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
    }
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil) 
        UIGraphicsEndImageContext();
    return newImage;
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

-(void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"distanceArrayNotification" object:nil];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

//
//  CSMarker.h
//  googlemap




// PURPOSE :- We make this class to achive distinct marker by comparing marker id by checking hash of it
#import <GoogleMaps/GoogleMaps.h>

@interface CSMarker : GMSMarker

@property (nonatomic, copy) NSString *objectID;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;
@end

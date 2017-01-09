//
//  CSMarker.h
//  googlemap
//
//  Created by C N Soft Net on 06/01/17.
//  Copyright © 2017 C N Soft Net. All rights reserved.
//



// PURPOSE :- We make this class to achive distinct marker by comparing marker id by checking hash of it
#import <GoogleMaps/GoogleMaps.h>

@interface CSMarker : GMSMarker

@property (nonatomic, copy) NSString *objectID;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;
@end

//
//  CSMarker.m
//  googlemap
//
//  Created by C N Soft Net on 06/01/17.
//  Copyright © 2017 C N Soft Net. All rights reserved.
//

#import "CSMarker.h"

@implementation CSMarker

- (BOOL)isEqual:(id)object
{
    CSMarker *otherMarker = (CSMarker *)object;
    if(self.objectID == otherMarker.objectID)
        return YES;
    else
        return NO;

}


- (NSUInteger)hash
{
    return [self.objectID hash];
}

@end

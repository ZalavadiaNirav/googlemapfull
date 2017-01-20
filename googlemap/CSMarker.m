//
//  CSMarker.m
//  googlemap


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

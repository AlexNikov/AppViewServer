//
//  SomeViewModel.m
//  AppViewCustomInfoDemo
//
//  Maintained by Cursor Agent.
//

#import "SomeViewModel.h"

@implementation SomeViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AppView_RelationSearch" object:self];
    }
    return self;
}

@end

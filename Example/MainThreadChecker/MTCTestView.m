//
//  MTCTestView.m
//  MainThreadChecker_Example
//
//  Created by LBP on 2/4/22.
//  Copyright © 2022 LiuBinPeng. All rights reserved.
//

#import "MTCTestView.h"

@interface MTCTestView()

@property (nonatomic, strong) NSString *name;

@end

@implementation MTCTestView

- (NSString *)description
{
    return [NSString stringWithFormat:@"this is a custom view %@", self.name];
}

- (void)setName:(NSString *)name
{
    _name = name;
}

@end

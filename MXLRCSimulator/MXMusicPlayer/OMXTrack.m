//
//  OMXTrack.m
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/8.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import "OMXTrack.h"

@implementation OMXTrack

- (NSURL *)audioFileURL
{
    return [[NSBundle mainBundle] URLForResource:_file withExtension:@"mp3"];
}

@end

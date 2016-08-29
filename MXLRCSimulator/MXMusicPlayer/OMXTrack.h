//
//  OMXTrack.h
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/8.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DOUAudioStreamer/DOUAudioFile.h>

@interface OMXTrack : NSObject <DOUAudioFile>

@property (copy, nonatomic) NSString *artist;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *file;

@end

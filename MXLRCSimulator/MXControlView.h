//
//  MXControlView.h
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/7.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MXControlStateForRepeatMode) {
    MXControlStateForRepeatModeDefault, /**< 顺序播放*/
    MXControlStateForRepeatModeShuffle, /**< 随机播放*/
    MXControlStateForRepeatModeOne,     /**< 单曲循环*/
    MXControlStateForRepeatModeAll      /**< 列表循环*/
};

typedef NS_ENUM(NSInteger, MXControlStateForPlaybackState) {
    MXControlStateForPlaybackStatePlaying, /**< 正在播放*/
    MXControlStateForPlaybackStateOther    /**< 其他状态*/
};

@interface MXControlView : UIView

@property (readonly) UIButton *playButton;
@property (readonly) UIButton *prevButton;
@property (readonly) UIButton *nextButton;
@property (readonly) UIButton *modeButton;
@property (readonly) UIButton *listButton;
@property (readonly) UISlider *slider;
@property (readonly) UILabel *currentTimeLabel;
@property (readonly) UILabel *durationLabel;

- (void)changeControlStateForPlaybackState:(MXControlStateForPlaybackState)playbackState;

- (NSString *)changeControlStateForRepeatMode:(MXControlStateForRepeatMode)repeatMode;

@end

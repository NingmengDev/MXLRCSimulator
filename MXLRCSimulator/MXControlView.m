//
//  MXControlView.m
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/7.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import "MXControlView.h"

#import <Masonry/Masonry.h>

@interface MXControlView ()

@property (retain, nonatomic) UIButton *playButton;
@property (retain, nonatomic) UIButton *prevButton;
@property (retain, nonatomic) UIButton *nextButton;
@property (retain, nonatomic) UIButton *modeButton;
@property (retain, nonatomic) UIButton *listButton;
@property (retain, nonatomic) UISlider *slider;
@property (retain, nonatomic) UILabel *currentTimeLabel;
@property (retain, nonatomic) UILabel *durationLabel;

@end

@implementation MXControlView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self setupSubviews];
        [self autoLayoutSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    self.slider = [self customSlider];
    
    self.currentTimeLabel = [[UILabel alloc] init];
    [self.currentTimeLabel setFont:[UIFont systemFontOfSize:14.0]];
    [self.currentTimeLabel setTextColor:[UIColor whiteColor]];
    [self.currentTimeLabel setText:@"00:00"];
    
    self.durationLabel = [[UILabel alloc] init];
    [self.durationLabel setTextAlignment:NSTextAlignmentRight];
    [self.durationLabel setFont:[UIFont systemFontOfSize:14.0]];
    [self.durationLabel setTextColor:[UIColor whiteColor]];
    [self.durationLabel setText:@"00:00"];
    
    self.playButton = [self buttonWithImage:@"ttp_bar_play.png"];
    self.prevButton = [self buttonWithImage:@"ttp_bar_prev.png"];
    self.nextButton = [self buttonWithImage:@"ttp_bar_next.png"];
    self.modeButton = [self buttonWithImage:@"ttp_bar_repeat_normal.png"];
    self.listButton = [self buttonWithImage:@"ttp_bar_play_list.png"];
    
    [self addSubview:self.slider];
    [self addSubview:self.playButton];
    [self addSubview:self.prevButton];
    [self addSubview:self.nextButton];
    [self addSubview:self.modeButton];
    [self addSubview:self.listButton];
    [self addSubview:self.currentTimeLabel];
    [self addSubview:self.durationLabel];
}

- (void)autoLayoutSubviews
{
    typeof(self) __weak weakSelf = self;
    
    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weakSelf);
        make.left.equalTo(weakSelf).offset(10.0);
        make.right.equalTo(weakSelf).offset(-10.0);
        make.height.mas_equalTo(CGRectGetHeight(weakSelf.slider.bounds));
    }];
    
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(weakSelf.slider);
        make.right.equalTo(weakSelf.mas_centerX).offset(-5.0);
        make.top.equalTo(weakSelf.slider.mas_bottom);
        make.height.mas_equalTo(weakSelf.currentTimeLabel.font.lineHeight);
    }];
    
    [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(weakSelf.slider);
        make.left.equalTo(weakSelf.mas_centerX).offset(5.0);
        make.top.equalTo(weakSelf.currentTimeLabel);
        make.height.mas_equalTo(weakSelf.durationLabel.font.lineHeight);
    }];
    
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(60.0);
        make.bottom.and.centerX.equalTo(weakSelf);
    }];
    
    [self.prevButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(44.0);
        make.centerY.equalTo(weakSelf.playButton);
        make.right.equalTo(weakSelf.playButton.mas_left).offset(-20.0);
    }];
    
    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(weakSelf.prevButton);
        make.centerY.equalTo(weakSelf.playButton);
        make.left.equalTo(weakSelf.playButton.mas_right).offset(20.0);
    }];
    
    [self.modeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(34.0);
        make.centerY.equalTo(weakSelf.playButton);
        make.left.equalTo(weakSelf).offset(20.0);
    }];
    
    [self.listButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(weakSelf.modeButton);
        make.centerY.equalTo(weakSelf.playButton);
        make.right.equalTo(weakSelf).offset(-20.0);
    }];
}

- (UISlider *)customSlider
{
    UISlider *slider = [UISlider new];
    UIImage *minImage = [[UIImage imageNamed:@"ttp_bar_min_track.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 1.0, 0.0, 1.0)];
    UIImage *maxImage = [[UIImage imageNamed:@"ttp_bar_max_track.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 1.0, 0.0, 1.0)];
    UIImage *thumbImage = [UIImage imageNamed:@"ttp_bar_thumb.png"];
    [slider setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [slider setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [slider setThumbImage:thumbImage forState:UIControlStateNormal];
    [slider setThumbImage:thumbImage forState:UIControlStateHighlighted];
    return slider;
}

- (UIButton *)buttonWithImage:(NSString *)imageName
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button setShowsTouchWhenHighlighted:YES];
    [button setExclusiveTouch:YES];
    return button;
}

- (void)changeControlStateForPlaybackState:(MXControlStateForPlaybackState)playbackState
{
    NSString *imageName = @"ttp_bar_pause.png";
    if (playbackState == MXControlStateForPlaybackStateOther) {
        imageName = @"ttp_bar_play.png";
    }
    [self.playButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

- (NSString *)changeControlStateForRepeatMode:(MXControlStateForRepeatMode)repeatMode;
{
    NSString *imageName;
    NSString *repeatModeName;
    switch (repeatMode) {
        case MXControlStateForRepeatModeShuffle: {
            imageName = @"ttp_bar_repeat_shuffle.png";
            repeatModeName = @"随机播放";
        }
            break;
            
        case MXControlStateForRepeatModeOne: {
            imageName = @"ttp_bar_repeat_one.png";
            repeatModeName = @"单曲循环";
        }
            break;
            
        case MXControlStateForRepeatModeAll: {
            imageName = @"ttp_bar_repeat_all.png";
            repeatModeName = @"列表循环";
        }
            break;
            
        default: {
            imageName = @"ttp_bar_repeat_normal.png";
            repeatModeName = @"顺序播放";
        }
            break;
    }
    
    [self.modeButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    return repeatModeName;
}

@end

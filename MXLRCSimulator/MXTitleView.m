//
//  MXTitleView.m
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/7.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import "MXTitleView.h"

#import <Masonry/Masonry.h>

@interface MXTitleView ()

@property (retain, nonatomic) UILabel *titleLabel;
@property (retain, nonatomic) UILabel *artistLabel;

@end

@implementation MXTitleView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    self.titleLabel = [UILabel new];
    [self.titleLabel setFont:[UIFont boldSystemFontOfSize:19.0]];
    [self.titleLabel setTextColor:[UIColor whiteColor]];
    [self.titleLabel setText:@"未知标题"];
    
    self.artistLabel = [UILabel new];
    [self.artistLabel setFont:[UIFont systemFontOfSize:14.0]];
    [self.artistLabel setTextColor:[UIColor whiteColor]];
    [self.artistLabel setText:@"未知艺术家"];
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.artistLabel];
    
    typeof(self) __weak weakSelf = self;
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(weakSelf).offset(10.0);
        make.right.equalTo(weakSelf).offset(-10.0);
        make.top.equalTo(weakSelf);
        make.height.equalTo(weakSelf.artistLabel);
    }];
    
    [self.artistLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(weakSelf.titleLabel);
        make.top.equalTo(weakSelf.titleLabel.mas_bottom);
        make.bottom.equalTo(weakSelf);
    }];
}

@end

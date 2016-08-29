//
//  MXTrackListView.m
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/8.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import "MXTrackListView.h"

#import <Masonry/Masonry.h>
#import "OMXTrack.h"
#import "MXMusicPlayer/MXMusicPlayer.h"

@interface MXTrackListView () <UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) UIView *contentView;
@property (retain, nonatomic) UILabel *titleLabel;
@property (retain, nonatomic) UITableView *tableView;

@end

@implementation MXTrackListView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UIView *contentView = [UIView new];
        contentView.layer.masksToBounds = YES;
        contentView.layer.cornerRadius = 5.0;
        contentView.alpha = 0.0;
        
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        
        self.titleLabel = [UILabel new];
        self.titleLabel.textColor = [UIColor whiteColor];
        
        UIImageView *line = [UIImageView new];
        line.backgroundColor = [UIColor whiteColor];
        
        self.tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.tableFooterView = [UIView new];
        
        [self addSubview:contentView];
        [contentView addSubview:effectView];
        [contentView addSubview:self.titleLabel];
        [contentView addSubview:line];
        [contentView addSubview:self.tableView];
        
        [contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(20.0);
            make.right.equalTo(self).offset(-20.0);
            make.height.equalTo(self).dividedBy(2);
            make.top.equalTo(self.mas_bottom);
        }];
        
        [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(contentView);
        }];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(contentView).offset(20.0);
            make.right.equalTo(contentView).offset(-20.0);
            make.top.equalTo(contentView);
            make.height.mas_equalTo(40.0);
        }];
        
        [line mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(contentView);
            make.top.equalTo(self.titleLabel.mas_bottom);
            make.height.mas_equalTo(1.0 / [UIScreen mainScreen].scale);
        }];
        
        [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.and.bottom.equalTo(contentView);
            make.top.equalTo(line.mas_bottom);
        }];
        
        [self setContentView:contentView];
    }
    return self;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UIView *touchView = [touches.anyObject view];
    if (touchView == self) [self dismiss];
}

- (void)setAllTracks:(NSArray<OMXTrack *> *)allTracks
{
    _allTracks = [allTracks copy];
    [self.tableView reloadData];
    
    self.titleLabel.text = [NSString stringWithFormat:@"播放列表 (%lu)", (unsigned long)allTracks.count];
}

- (void)showInView:(UIView *)aView
{
    [aView addSubview:self];
    [self layoutIfNeeded];
    
    CGFloat offset = CGRectGetHeight(self.bounds) / 4 * 3;
    [self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_bottom).offset(-offset);
    }];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.contentView setAlpha:1.0];
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)dismiss
{
    [self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_bottom);
    }];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.contentView setAlpha:0.0];
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.allTracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const CellIdentifier = @"MXTrackListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        
        UIView *selectedBackgroundView = [UIView new];
        selectedBackgroundView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.35];
        cell.selectedBackgroundView = selectedBackgroundView;
        
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [UIColor whiteColor];
    }
    
    cell.imageView.image = [UIImage imageNamed:@"ttp_track_icon.png"];
    
    OMXTrack *track = self.allTracks[indexPath.row];
    cell.textLabel.text = track.title;
    cell.detailTextLabel.text = track.artist;
    
    OMXTrack *nowPlayingTrack = [MXMusicPlayer musicPlayer].nowPlayingTrack;
    if ([track isEqual:nowPlayingTrack]) {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(listView:didSelectTrack:)]) {
        OMXTrack *track = self.allTracks[indexPath.row];
        [self.delegate listView:self didSelectTrack:track];
    }
}

@end

//
//  MainViewController.m
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/4.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import "MainViewController.h"

#import <Masonry/Masonry.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import "MXTitleView.h"
#import "MXLRCSimulator/MXLRCSimulator.h"
#import "MXControlView.h"

#import "MXLRCParser.h"
#import "MXLRCAddition.h"
#import "MXMusicPlayer/MXMusicPlayer.h"
#import "MXTrackListView.h"

@interface MainViewController () <MXMusicPlayerDelegate, MXLRCSimulatorDelegate, MXTrackListViewDelegate>

@property (retain, nonatomic) UIVisualEffectView *backgroundView;
@property (retain, nonatomic) MXTitleView *titleView;
@property (retain, nonatomic) MXLRCSimulator *lrcSimulator;
@property (retain, nonatomic) MXControlView *controlView;
@property (retain, nonatomic) MXTrackListView *listView;

@property (strong, nonatomic) CADisplayLink *timer;
@property (assign, nonatomic) BOOL sliderTouching;

@end

@implementation MainViewController

- (void)loadView {
    [super loadView];
    
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    
    self.titleView = [MXTitleView new];
    
    self.controlView = [MXControlView new];
    [self.controlView.slider addTarget:self action:@selector(sliderTouchDownEvent:) forControlEvents:UIControlEventTouchDown];
    [self.controlView.slider addTarget:self action:@selector(sliderValueChangedEvent:) forControlEvents:UIControlEventValueChanged];
    [self.controlView.slider addTarget:self action:@selector(sliderTouchEndEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.slider addTarget:self action:@selector(sliderTouchEndEvent:) forControlEvents:UIControlEventTouchUpOutside];
    [self.controlView.slider addTarget:self action:@selector(sliderTouchEndEvent:) forControlEvents:UIControlEventTouchCancel];
    
    [self.controlView.modeButton addTarget:self action:@selector(modeButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.prevButton addTarget:self action:@selector(prevButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.playButton addTarget:self action:@selector(playButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.nextButton addTarget:self action:@selector(nextButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlView.listButton addTarget:self action:@selector(listButtonEvent:) forControlEvents:UIControlEventTouchUpInside];

    self.lrcSimulator = [[MXLRCSimulator alloc] initWithFrame:self.view.bounds];
    self.lrcSimulator.linePlaceholder = @"Music...";
    self.lrcSimulator.delegate = self;
    
    [self.view addSubview:self.backgroundView];
    [self.view addSubview:self.titleView];
    [self.view addSubview:self.controlView];
    [self.view addSubview:self.lrcSimulator];
    
    [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.titleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(20.0);
        make.height.mas_equalTo(44.0);
    }];
    
    [self.controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-20.0);
        make.height.mas_equalTo(120.0);
    }];
    
    [self.lrcSimulator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.titleView.mas_bottom);
        make.bottom.equalTo(self.controlView.mas_top);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"Skin" ofType:@"jpg"];
    UIImage *backgroundImage = [UIImage imageWithContentsOfFile:imagePath];
    self.view.layer.contents = (__bridge id _Nullable)(backgroundImage.CGImage);
    
    NSArray *tracks = [self prepareForTracks];
    [[MXMusicPlayer musicPlayer] setDelegate:self];
    [[MXMusicPlayer musicPlayer] setQueueWithTrackCollection:tracks];
    
    [self.listView setAllTracks:tracks];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (MXTrackListView *)listView
{
    if (_listView == nil) {
        _listView = [[MXTrackListView alloc] initWithFrame:self.view.bounds];
        _listView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _listView.delegate = self;
    }
    return _listView;
}

#pragma mark - Timer Event

- (void)timerEvent:(CADisplayLink *)timer
{
    if (self.sliderTouching) return; /**< 在slider滑动过程中，暂时屏蔽计时器的调用，避免影响体验*/
    
    NSTimeInterval musicTime = [MXMusicPlayer musicPlayer].currentTime;
    self.controlView.slider.value = musicTime / [MXMusicPlayer musicPlayer].duration;
    [self.lrcSimulator updateProgressWithMusicCurrentTime:musicTime];
    
    self.controlView.currentTimeLabel.text = [NSString timeFormatFromSecond:musicTime];
}

#pragma mark - Control Event

- (void)sliderTouchDownEvent:(UISlider *)slider
{
    self.sliderTouching = YES;
}

- (void)sliderValueChangedEvent:(UISlider *)slider
{
    NSTimeInterval musicTime = [MXMusicPlayer musicPlayer].duration * slider.value;
    [self.lrcSimulator updateProgressWithMusicCurrentTime:musicTime];;
}

- (void)sliderTouchEndEvent:(UISlider *)slider
{
    NSTimeInterval musicTime = [MXMusicPlayer musicPlayer].duration * slider.value;
    [self.lrcSimulator updateProgressWithMusicCurrentTime:musicTime];
    
    [[MXMusicPlayer musicPlayer] setCurrentTime:musicTime];
    self.sliderTouching = NO;
}

- (void)modeButtonEvent:(UIButton *)button
{
    MXMusicRepeatMode repeatMode = [MXMusicPlayer musicPlayer].repeatMode;
    if (repeatMode == MXMusicRepeatModeAll) {
        repeatMode = MXMusicRepeatModeDefault;
    }
    else {
        repeatMode += 1;
    }
    [[MXMusicPlayer musicPlayer] setRepeatMode:repeatMode];
}

- (void)prevButtonEvent:(UIButton *)button
{
    [[MXMusicPlayer musicPlayer] skipToPreviousTrack];
}

- (void)playButtonEvent:(UIButton *)button
{
    MXMusicPlaybackState playbackState = [MXMusicPlayer musicPlayer].playbackState;
    if (playbackState == MXMusicPlaybackStatePaused ||
        playbackState == MXMusicPlaybackStateStopped) {
        [[MXMusicPlayer musicPlayer] play];
    }
    else {
        [[MXMusicPlayer musicPlayer] pause];
    }
}

- (void)nextButtonEvent:(UIButton *)button
{
    [[MXMusicPlayer musicPlayer] skipToNextTrack];
}

- (void)listButtonEvent:(UIButton *)button
{
    [self.listView showInView:self.view];
}

#pragma mark - Custom Method

- (NSArray <OMXTrack *> *)prepareForTracks
{
    NSString *resourcesPath = [[NSBundle mainBundle] pathForResource:@"Resources" ofType:@"plist"];
    NSArray *objects = [NSArray arrayWithContentsOfFile:resourcesPath];
    
    NSMutableArray *tracks = [NSMutableArray array];
    for (NSDictionary *trackInfo in objects) {
        OMXTrack *track = [OMXTrack new];
        [track setValuesForKeysWithDictionary:trackInfo];
        [tracks addObject:track];
    }
    return [NSArray arrayWithArray:tracks];
}

- (void)prepareForPlay
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    self.titleView.titleLabel.text = @"未知标题";
    self.titleView.artistLabel.text = @"未知艺术家";
    self.controlView.currentTimeLabel.text = [NSString timeFormatFromSecond:0.0];
    self.controlView.durationLabel.text = [NSString timeFormatFromSecond:0.0];
    self.controlView.slider.value = 0.0;
}

- (void)prepareForPlayWithTrack:(OMXTrack *)track
{
    [self prepareForPlay];
    [self.lrcSimulator prepareForReuse];
    
    if (track) {
        self.titleView.titleLabel.text = track.title;
        self.titleView.artistLabel.text = track.artist;
        self.controlView.durationLabel.text = [NSString timeFormatFromSecond:[MXMusicPlayer musicPlayer].duration];
        
        NSString *lrcPath = [[NSBundle mainBundle] pathForResource:track.file ofType:@"lrc"];
        [MXLRCParser parseLRCWithContentsOfFile:lrcPath completion:^(NSArray<MXLRCLine *> *lyrics) {
            NSTimeInterval duration = [MXMusicPlayer musicPlayer].duration;
            [self.lrcSimulator amendDurationForLastLineWithMusicDurationIfNeeded:duration];
            [self.lrcSimulator startWithLyrics:lyrics];
        }];
    }
}

- (void)resumeTimerIfNeeded
{
    if (self.timer && self.timer.isPaused) {
        [self.timer setPaused:NO];
    }
    else {
        self.timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerEvent:)];
        [self.timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)showLoadingProgressWithMessage:(NSString *)message
{
    MBProgressHUD *messageHub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    messageHub.mode = MBProgressHUDModeText;
    messageHub.label.text = message;
    [messageHub hideAnimated:YES afterDelay:1.0];
}

#pragma mark - MXLRCSimulatorDelegate

- (void)simulator:(MXLRCSimulator *)simulator didScrollToLRCTime:(NSTimeInterval)lrcTime
{
    if (0.0 <= lrcTime && lrcTime <= [MXMusicPlayer musicPlayer].duration) {
        [[MXMusicPlayer musicPlayer] setCurrentTime:lrcTime];
    }
}

#pragma mark - MXMusicPlayerDelegate

- (void)musicPlayerNowPlayingTrackDidChange:(MXMusicPlayer *)player
{
    [self prepareForPlayWithTrack:player.nowPlayingTrack];
}

- (void)musicPlayerDurationDidChange:(MXMusicPlayer *)player
{
    NSTimeInterval duration = [MXMusicPlayer musicPlayer].duration;
    self.controlView.durationLabel.text = [NSString timeFormatFromSecond:duration];
    [self.lrcSimulator amendDurationForLastLineWithMusicDurationIfNeeded:duration];
}

- (void)musicPlayerPlaybackStateDidChange:(MXMusicPlayer *)player
{
    MXMusicPlaybackState playbackState = player.playbackState;
    if (playbackState == MXMusicPlaybackStateFinished) {
        [self.timer invalidate]; // 歌曲播放结束，把计时器停掉
    }
    else if (playbackState == MXMusicPlaybackStatePlaying) {
        [self resumeTimerIfNeeded]; // 歌曲播放恢复播放，把计时器激活
    }
    else {
        [self.timer setPaused:YES]; // 其他情况，把计时器暂停
    }
    
    MXControlStateForPlaybackState cPlaybackState = (MXControlStateForPlaybackState)playbackState;
    [self.controlView changeControlStateForPlaybackState:cPlaybackState];
}

- (void)musicPlayerRepeatModeDidChange:(MXMusicPlayer *)player
{
    MXControlStateForRepeatMode repeatMode = (MXControlStateForRepeatMode)player.repeatMode;
    NSString *repeatModeName = [self.controlView changeControlStateForRepeatMode:repeatMode];
    [self showLoadingProgressWithMessage:repeatModeName];
}

#pragma mark - MXTrackListViewDelegate

- (void)listView:(MXTrackListView *)listView didSelectTrack:(OMXTrack *)track
{
    if ([track isEqual:[MXMusicPlayer musicPlayer].nowPlayingTrack]) {
        [self playButtonEvent:self.controlView.playButton];
    }
    else {
        [[MXMusicPlayer musicPlayer] playTrack:track];
    }
}

@end

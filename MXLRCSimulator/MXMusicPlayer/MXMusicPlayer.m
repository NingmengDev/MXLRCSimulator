//
//  MXMusicPlayer.m
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/8.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import "MXMusicPlayer.h"

#import <DOUAudioStreamer/DOUAudioStreamer.h>

static void *kMXMusicPlayerStatusKVOContext = &kMXMusicPlayerStatusKVOContext;
static void *kMXMusicPlayerDurationKVOContext = &kMXMusicPlayerDurationKVOContext;

static NSString *const kMXMusicPlayerStatusKey = @"status";
static NSString *const kMXMusicPlayerDurationKey = @"duration";

@interface MXMusicPlayer ()

@property (strong, nonatomic) DOUAudioStreamer *streamer;

@property (copy, nonatomic) NSArray <OMXTrack *> *trackCollection;

@end

@implementation MXMusicPlayer

+ (MXMusicPlayer *)musicPlayer
{
    static id obj;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [self new];
    });
    return obj;
}

#pragma mark - Setter & Getter

- (void)setCurrentTime:(NSTimeInterval)currentTime
{
    _streamer.currentTime = currentTime;
}

- (NSTimeInterval)currentTime
{
    return _streamer ? _streamer.currentTime : 0.0;
}

- (NSTimeInterval)duration
{
    return _streamer ? _streamer.duration : 0.0;
}

- (void)setRepeatMode:(MXMusicRepeatMode)repeatMode
{
    if (_repeatMode == repeatMode) return;
    
    _repeatMode = repeatMode;
    
    if (_delegate && [_delegate respondsToSelector:@selector(musicPlayerRepeatModeDidChange:)]) {
        [_delegate musicPlayerRepeatModeDidChange:self];
    }
}

- (MXMusicPlaybackState)playbackState
{
    return (MXMusicPlaybackState)_streamer.status;
}

- (void)setVolume:(double)volume
{
    [DOUAudioStreamer setVolume:volume];
}

- (double)volume
{
    return [DOUAudioStreamer volume];
}

- (OMXTrack *)nowPlayingTrack
{
    return _streamer ? [_streamer audioFile] : nil;
}

- (NSUInteger)indexOfNowPlayingTrack
{
    return [self.trackCollection indexOfObject:self.nowPlayingTrack];
}

@end


@implementation MXMusicPlayer (MXPlaybackControl)

#pragma mark - Public Method

- (void)setQueueWithTrackCollection:(NSArray <OMXTrack *> *)trackCollection
{
    _trackCollection = [trackCollection copy];
    
    [self playTrack:nil play:NO];
}

- (void)play
{
    [_streamer play];
}

- (void)pause
{
    [_streamer pause];
}

- (void)stop
{
    [_streamer stop];
}

- (void)playTrack:(OMXTrack *)track
{
    [self playTrack:track play:YES];
}

- (void)skipToNextTrack
{
    OMXTrack *nextTrack;
    if (_trackCollection.count) {
        NSUInteger nextTrackIndex = [self indexOfNowPlayingTrack] + 1;
        if (_repeatMode == MXMusicRepeatModeShuffle) {
            nextTrackIndex = [self randomTrackIndex];
        }
        else if (nextTrackIndex >= _trackCollection.count) {
            nextTrackIndex = 0;
        }
        nextTrack = _trackCollection[nextTrackIndex];
    }
    
    [self playTrack:nextTrack play:YES];
}

- (void)skipToPreviousTrack
{
    OMXTrack *previousTrack;
    if (_trackCollection.count) {
        NSInteger previousTrackIndex = [self indexOfNowPlayingTrack] - 1;
        
        if (_repeatMode == MXMusicRepeatModeShuffle) {
            previousTrackIndex = [self randomTrackIndex];
        }
        else if (previousTrackIndex < 0) {
            previousTrackIndex = _trackCollection.count - 1;
        }
        
        previousTrack = _trackCollection[previousTrackIndex];
    }
    
    [self playTrack:previousTrack play:YES];
}

#pragma mark - Private Method

- (void)resetStreamer
{
    if (_streamer != nil) {
        [_streamer stop];
        [_streamer removeObserver:self forKeyPath:kMXMusicPlayerStatusKey context:kMXMusicPlayerStatusKVOContext];
        [_streamer removeObserver:self forKeyPath:kMXMusicPlayerDurationKey context:kMXMusicPlayerDurationKVOContext];
        _streamer = nil;
    }
}

- (void)prepareToPlayWithTrack:(OMXTrack *)track
{
    _streamer = [DOUAudioStreamer streamerWithAudioFile:track];
    [_streamer addObserver:self forKeyPath:kMXMusicPlayerStatusKey options:NSKeyValueObservingOptionNew context:kMXMusicPlayerStatusKVOContext];
    [_streamer addObserver:self forKeyPath:kMXMusicPlayerDurationKey options:NSKeyValueObservingOptionNew context:kMXMusicPlayerDurationKVOContext];
}

- (void)playTrack:(OMXTrack *)track play:(BOOL)play /**< play表示加载完成后是否立即播放*/
{
    if (![_trackCollection containsObject:track]) {
        if (_trackCollection.count) {
            track = _trackCollection.firstObject;
        }
    }
    
    [self resetStreamer];
    if (track) [self prepareToPlayWithTrack:track];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate && [_delegate respondsToSelector:@selector(musicPlayerNowPlayingTrackDidChange:)]) {
            [_delegate musicPlayerNowPlayingTrackDidChange:self];
        }
    });
    
    if (play) [self play];
}

- (NSInteger)randomTrackIndex
{
    NSInteger idx = arc4random_uniform((u_int32_t)_trackCollection.count);
    while (idx == [self indexOfNowPlayingTrack]) {
        idx = arc4random_uniform((u_int32_t)_trackCollection.count);
    }
    return idx;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == kMXMusicPlayerStatusKVOContext) {
        if (_streamer.status == DOUAudioStreamerFinished) { // 歌曲自然播放完成，自动根据播放模式切换歌曲
            if (_repeatMode == MXMusicRepeatModeShuffle || _repeatMode == MXMusicRepeatModeAll) {
                [self skipToNextTrack];
            }
            else if (_repeatMode == MXMusicRepeatModeOne) {
                [self playTrack:[self nowPlayingTrack] play:YES];
            }
            else {
                if ([self nowPlayingTrack] == _trackCollection.lastObject) {
                    [self playTrack:nil play:NO];
                }
                else {
                    [self skipToNextTrack];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_delegate && [_delegate respondsToSelector:@selector(musicPlayerPlaybackStateDidChange:)]) {
                [_delegate musicPlayerPlaybackStateDidChange:self];
            }
        });
    }
    else if (context == kMXMusicPlayerDurationKVOContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_delegate && [_delegate respondsToSelector:@selector(musicPlayerDurationDidChange:)]) {
                [_delegate musicPlayerDurationDidChange:self];
            }
        });
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
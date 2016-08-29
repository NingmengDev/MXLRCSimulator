//
//  MXMusicPlayer.h
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/8.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OMXTrack.h"

@class MXMusicPlayer;

typedef NS_ENUM(NSInteger, MXMusicRepeatMode) {
    MXMusicRepeatModeDefault,
    MXMusicRepeatModeShuffle,
    MXMusicRepeatModeOne,
    MXMusicRepeatModeAll
};

typedef NS_ENUM(NSInteger, MXMusicPlaybackState) {
    MXMusicPlaybackStatePlaying,
    MXMusicPlaybackStatePaused,
    MXMusicPlaybackStateStopped,
    MXMusicPlaybackStateFinished,
    MXMusicPlaybackStateBuffering,
    MXMusicPlaybackStateError
};

@protocol MXMusicPlayerDelegate <NSObject>
@optional

- (void)musicPlayerNowPlayingTrackDidChange:(MXMusicPlayer *)player;

- (void)musicPlayerDurationDidChange:(MXMusicPlayer *)player;

- (void)musicPlayerPlaybackStateDidChange:(MXMusicPlayer *)player;

- (void)musicPlayerRepeatModeDidChange:(MXMusicPlayer *)player;

@end


@interface MXMusicPlayer : NSObject

@property (readwrite) NSTimeInterval currentTime;

@property (readonly) NSTimeInterval duration;

@property (assign, nonatomic) MXMusicRepeatMode repeatMode;

@property (readonly) MXMusicPlaybackState playbackState;

@property (readwrite) double volume;

@property (readonly) OMXTrack *nowPlayingTrack;

@property (readonly) NSUInteger indexOfNowPlayingTrack;

@property (assign, nonatomic) id <MXMusicPlayerDelegate> delegate;

+ (MXMusicPlayer *)musicPlayer;

@end


@interface MXMusicPlayer (MXPlaybackControl)

- (void)setQueueWithTrackCollection:(NSArray <OMXTrack *> *)trackCollection;

- (void)play;

- (void)pause;

- (void)stop;

- (void)playTrack:(OMXTrack *)track;

- (void)skipToNextTrack;

- (void)skipToPreviousTrack;

@end
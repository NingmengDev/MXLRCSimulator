//
//  MXLRCSimulator.h
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/6.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MXLRCLine;
@class MXLRCSimulator;

@protocol MXLRCSimulatorDelegate <NSObject>

@required

/**
 *  手动滚动了歌词内容，滚动完成后把滚动到的位置所对应的歌词时间返回，用于歌曲把播放进度调整过来
 *
 *  @param simulator 歌词播放模拟器
 *  @param lrcTime   滚动结束后对应的歌词时间
 */
- (void)simulator:(MXLRCSimulator *)simulator didScrollToLRCTime:(NSTimeInterval)lrcTime;

@end


@interface MXLRCSimulator : UIView

@property (strong, nonatomic) UIFont *font; /**< 歌词字体，默认[UIFont systemFontOfSize:17.0]*/
@property (strong, nonatomic) UIColor *normalTintColor; /**< 歌词常规字体颜色，默认[UIColor whiteColor]*/
@property (strong, nonatomic) UIColor *highlightedTintColor; /**< 歌词高亮字体颜色，默认[UIColor yellowColor]*/
@property (copy, nonatomic) NSString *linePlaceholder; /**< 歌词某一行内容为空时，默认显示的文字，默认nil，即留空*/
@property (weak, nonatomic) id <MXLRCSimulatorDelegate> delegate; /**< 代理*/

/**
 *  在切换歌曲播放时，新歌曲的歌词下载或解析都需要一定的时间
 *  可调用下此方法刷新一下，把旧数据清除掉
 */
- (void)prepareForReuse;

/**
 *  传入歌词数据
 *
 *  @param lyrics 歌词数组
 */
- (void)startWithLyrics:(NSArray<MXLRCLine *> *)lyrics;

/**
 *  根据音乐总时长修正最后一句歌词的持续时长
 *
 *  @param duration 音乐总时长
 */
- (void)amendDurationForLastLineWithMusicDurationIfNeeded:(NSTimeInterval)duration;

/**
 *  根据音乐时间更新歌词显示进度
 *
 *  @param currentTime 音乐时间
 *  @param timerRate   计时器调用频率
 */
- (void)updateProgressWithMusicCurrentTime:(NSTimeInterval)currentTime;

@end

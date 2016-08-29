//
//  MXLRCSimulator.m
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/6.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import "MXLRCSimulator.h"

#import "MXLRCParser.h"
#import "MXLRCAddition.h"

#pragma mark - MXLRCLabel

@interface MXLRCLabel : UILabel

@property (assign, nonatomic) CGFloat progress; /**< 歌词进度*/

@end

@implementation MXLRCLabel

- (void)setProgress:(CGFloat)progress
{
    /**
     *  稳定进度区间，让它在0.0（未完成）～ 1.0（已完成）之间
     */
    progress = MIN(1.0, MAX(0.0, progress));
    if (_progress == progress) return;
    
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGRect drawRect = self.bounds;
    drawRect.size.width *= self.progress;
    
    [self.highlightedTextColor set];
    UIRectFillUsingBlendMode(drawRect, kCGBlendModeSourceIn);
}

@end


#pragma mark - MXLRCCell

@interface MXLRCCell : UITableViewCell

@property (readonly) MXLRCLabel *lrcLabel;

@end

@implementation MXLRCCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _lrcLabel = [MXLRCLabel new];
        _lrcLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_lrcLabel];
        
        _lrcLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_lrcLabel constraint:NSLayoutAttributeCenterX equalTo:self.contentView];
        [_lrcLabel constraint:NSLayoutAttributeCenterY equalTo:self.contentView];
        
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    _lrcLabel.progress = 0.0;
    _lrcLabel.text = nil;
}

@end


#pragma mark - MXLRCSimulator

@interface MXLRCSimulator () <UITableViewDataSource, UITableViewDelegate>

@property (retain, nonatomic) UITableView *lyricsView;
@property (retain, nonatomic) UIImageView *timeLine;
@property (retain, nonatomic) UILabel *timeLineLabel;
@property (retain, nonatomic) UILabel *stateLabel;

@property (copy, nonatomic) NSArray <MXLRCLine *> *lyrics;
@property (assign, nonatomic) BOOL isUpdating;
@property (assign, nonatomic) NSInteger lyricsCount;

@end

@implementation MXLRCSimulator

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
    self.lyricsView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
    self.lyricsView.backgroundColor = [UIColor clearColor];
    self.lyricsView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.lyricsView.showsVerticalScrollIndicator = NO;
    self.lyricsView.dataSource = self;
    self.lyricsView.delegate = self;
    self.lyricsView.bounces = NO;
    self.lyricsView.rowHeight = 34.0;
    self.lyricsView.tableFooterView = [UIView new];
    [self addSubview:self.lyricsView];
    
    self.lyricsView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.lyricsView constraint:NSLayoutAttributeTop equalTo:self];
    [self.lyricsView constraint:NSLayoutAttributeLeft equalTo:self];
    [self.lyricsView constraint:NSLayoutAttributeBottom equalTo:self];
    [self.lyricsView constraint:NSLayoutAttributeRight equalTo:self];
    
    self.timeLine = [UIImageView new];
    self.timeLine.backgroundColor = [UIColor whiteColor];
    self.timeLine.hidden = YES;
    [self addSubview:self.timeLine];
    
    self.timeLine.translatesAutoresizingMaskIntoConstraints = NO;
    [self.timeLine constraint:NSLayoutAttributeLeft equalTo:self];
    [self.timeLine constraint:NSLayoutAttributeRight equalTo:self];
    [self.timeLine constraint:NSLayoutAttributeCenterY equalTo:self];
    [self.timeLine constraint:NSLayoutAttributeHeight cEqualTo:MXLRCSeparatorHeight()];
    
    self.timeLineLabel = [UILabel new];
    self.timeLineLabel.textColor = [UIColor whiteColor];
    self.timeLineLabel.font = [UIFont systemFontOfSize:14.0];
    self.timeLineLabel.hidden = YES;
    [self addSubview:self.timeLineLabel];
    
    self.timeLineLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.timeLineLabel constraint:NSLayoutAttributeLeft equalTo:self c:5.0];
    [self.timeLineLabel constraint:NSLayoutAttributeRight equalTo:self c:-5.0];
    [self.timeLineLabel constraint:NSLayoutAttributeBottom equalTo:self.timeLine a:NSLayoutAttributeTop];
    [self.timeLineLabel constraint:NSLayoutAttributeHeight cEqualTo:self.timeLineLabel.font.lineHeight];
    
    self.tintColor = [UIColor redColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat offset = CGRectGetHeight(self.lyricsView.bounds) / 2;
    self.lyricsView.contentInset = UIEdgeInsetsMake(offset, 0.0, offset, 0.0);
}

#pragma mark - Getter Method

- (UIFont *)font
{
    if (_font == nil) {
        _font = [UIFont systemFontOfSize:17.0];
    }
    return _font;
}

- (UIColor *)normalTintColor
{
    if (_normalTintColor == nil) {
        _normalTintColor = [UIColor whiteColor];
    }
    return _normalTintColor;
}

- (UIColor *)highlightedTintColor
{
    if (_highlightedTintColor == nil) {
        _highlightedTintColor = [UIColor yellowColor];
    }
    return _highlightedTintColor;
}

- (UILabel *)stateLabel
{
    if (_stateLabel == nil) {
        _stateLabel = [UILabel new];
        _stateLabel.textColor = [UIColor whiteColor];
        _stateLabel.font = [UIFont systemFontOfSize:17.0];
        _stateLabel.textAlignment = NSTextAlignmentCenter;
        _stateLabel.hidden = YES;
        [self addSubview:_stateLabel];
        
        _stateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_stateLabel constraint:NSLayoutAttributeLeft equalTo:self];
        [_stateLabel constraint:NSLayoutAttributeRight equalTo:self];
        [_stateLabel constraint:NSLayoutAttributeCenterY equalTo:self];
        [_stateLabel constraint:NSLayoutAttributeHeight cEqualTo:_stateLabel.font.lineHeight];
    }
    return _stateLabel;
}

#pragma mark - Public Method

/**
 *  在切换歌曲播放时，新歌曲的歌词下载或解析都需要一定的时间
 *  可调用下此方法刷新一下，把旧数据清除掉
 */
- (void)prepareForReuse
{
    CGFloat offset = CGRectGetHeight(self.lyricsView.bounds) / 2;
    self.lyricsView.contentInset = UIEdgeInsetsMake(offset, 0.0, offset, 0.0);
    
    self.lyrics = nil;
    self.lyricsCount = 0;
    [self.lyricsView reloadData];
    
    self.timeLineLabel.hidden = YES;
    self.timeLine.hidden = YES;
    self.stateLabel.hidden = NO;
    
    self.timeLineLabel.text = nil;
    self.stateLabel.text = @"正在获取歌词...";
}

/**
 *  传入歌词数据
 *
 *  @param lyrics 歌词数组
 */
- (void)startWithLyrics:(NSArray<MXLRCLine *> *)lyrics;
{
    [self prepareForReuse];
    
    self.lyrics = lyrics;
    self.lyricsCount = self.lyrics.count;
    
    self.stateLabel.text = (self.lyricsCount) ? nil : @"暂无歌词";
    self.stateLabel.hidden = (self.lyricsCount) ? YES : NO;
    
    [self.lyricsView reloadData];
}

/**
 *  根据音乐总时长修正最后一句歌词的持续时长
 *
 *  @param duration 音乐总时长
 */
- (void)amendDurationForLastLineWithMusicDurationIfNeeded:(NSTimeInterval)duration
{
    MXLRCLine *lastLine = self.lyrics.lastObject;
    if (lastLine && duration > lastLine.time) {
        lastLine.duration = duration - lastLine.time;
    }
}

/**
 *  根据音乐时间更新歌词显示进度
 *
 *  @param currentTime 音乐时间
 */
- (void)updateProgressWithMusicCurrentTime:(NSTimeInterval)currentTime
{
    if (self.isUpdating || self.lyricsCount == 0) return;
    
    // 根据歌曲时间获取对应歌词所在的位置
    NSInteger currentIndex = [self currentIndexWithMusicCurrentTime:currentTime];
    
    // 根据歌曲时间更新滚动距离
    [self updateLyricsViewContentOffsetAtIndex:currentIndex musicCurrentTime:currentTime];
    
    // 根据歌曲时间更新当前行歌词的高亮进度
    [self updateLRCLabelProgressAtIndex:currentIndex musicCurrentTime:currentTime];
}

#pragma mark - Private Method

/**
 *  进入手动滚动模式，可避免与歌词的自动滚动相冲突
 */
- (void)beginUpdates
{
    self.isUpdating = YES;
    
    self.timeLineLabel.hidden = NO;
    self.timeLine.hidden = NO;
}

/**
 *  退出手动滚动模式，进入自动滚动模式
 */
- (void)endUpdates
{
    self.timeLineLabel.hidden = YES;
    self.timeLine.hidden = YES;
    
    self.isUpdating = NO;
}

/**
 *  根据歌曲时间更新歌词整体上或下滚动
 *
 *  @param currentIndex 歌曲时间所对应歌词所在的位置
 *  @param currentTime  歌曲时间
 */
- (void)updateLyricsViewContentOffsetAtIndex:(NSInteger)currentIndex musicCurrentTime:(NSTimeInterval)currentTime
{
    if (0 <= currentIndex && currentIndex < self.lyricsCount) {
        MXLRCLine *currentLine = self.lyrics[currentIndex];
        CGFloat verticalOffset = self.lyricsView.rowHeight * currentIndex;
        CGFloat speed = self.lyricsView.rowHeight / currentLine.duration;
        CGFloat vOffset = (currentTime - currentLine.time) * speed;
        verticalOffset = verticalOffset + vOffset;
        
        CGPoint contentOffset = self.lyricsView.contentOffset;
        contentOffset.y = verticalOffset - self.lyricsView.contentInset.top;
        self.lyricsView.contentOffset = contentOffset;
    }
}

/**
 *  根据歌曲时间更新高亮歌词行的进度
 *
 *  @param currentIndex 高亮歌词所在的位置
 *  @param currentTime  歌曲时间
 */
- (void)updateLRCLabelProgressAtIndex:(NSInteger)currentIndex musicCurrentTime:(NSTimeInterval)currentTime
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:currentIndex inSection:0];
    MXLRCCell *currentCell = [self.lyricsView cellForRowAtIndexPath:indexPath];
    if (currentCell) {
        MXLRCLine *currentLine = self.lyrics[currentIndex];
        currentCell.lrcLabel.progress = (currentTime - currentLine.time) / currentLine.duration;
        
        NSArray <MXLRCCell *> *visibleCells = [self.lyricsView visibleCells];
        for (MXLRCCell *cell in visibleCells) {
            if (cell == currentCell) continue;
            cell.lrcLabel.progress = 0.0;
        }
    }
}

/**
 *  根据歌曲时间获取对应歌词所在的位置
 *
 *  @param currentTime 歌曲时间
 *
 *  @return 对应歌词所在的位置
 */
- (NSInteger)currentIndexWithMusicCurrentTime:(NSTimeInterval)currentTime
{
    __block NSInteger currentIndex = NSIntegerMax;
    [self.lyrics enumerateObjectsWithNextUsingBlock:^(NSUInteger idx, MXLRCLine *object, MXLRCLine *nextObject, BOOL *stop) {
        if (nextObject) {
            if (currentTime >= object.time && currentTime < nextObject.time) {
                currentIndex = idx;
                *stop = YES;
            }
        }
        else if (currentTime >= object.time && currentTime <= object.time + object.duration) {
            currentIndex = idx;
        }
    }];
    return currentIndex;
}

/**
 *  当手动滚动歌词时，获取滚动到的位置所对应的歌词时间和歌词所在的位置
 *
 *  @param musicTime   歌词时间
 *  @param targetIndex 对应歌词所在的位置
 */
- (void)getWhenLyricsViewScrollingMusicTime:(NSTimeInterval *)musicTime targetIndex:(NSInteger *)targetIndex
{
    CGFloat contentOffsetY = self.lyricsView.contentOffset.y + self.lyricsView.contentInset.top;
    contentOffsetY = MIN(self.lyricsView.contentSize.height - MXLRCSeparatorHeight(), contentOffsetY);
    CGFloat scrollingFloatIndex = contentOffsetY / self.lyricsView.rowHeight;
    NSInteger scrollingIndex = floorf(scrollingFloatIndex);
    if (0 <= scrollingIndex && scrollingIndex < self.lyricsCount) {
        MXLRCLine *currentLine = self.lyrics[scrollingIndex];
        NSTimeInterval timeOffset = currentLine.duration * (scrollingFloatIndex - scrollingIndex);
        *musicTime = currentLine.time + timeOffset;
        *targetIndex = scrollingIndex;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.lyricsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const MXLRCCellIdentifier = @"MXLRCCell";
    MXLRCCell *cell = [tableView dequeueReusableCellWithIdentifier:MXLRCCellIdentifier];
    if (cell == nil) {
        cell = [[MXLRCCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MXLRCCellIdentifier];
        cell.lrcLabel.font = self.font;
        cell.lrcLabel.textColor = self.normalTintColor;
        cell.lrcLabel.highlightedTextColor = self.highlightedTintColor;
    }
    
    MXLRCLine *line = self.lyrics[indexPath.row];
    BOOL condition = (line.content.length == 0 && self.linePlaceholder);
    cell.lrcLabel.text = condition ? self.linePlaceholder : line.content;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.isUpdating) {
        NSTimeInterval musicTime = CGFLOAT_MAX;
        NSInteger targetIndex = NSIntegerMax;
        [self getWhenLyricsViewScrollingMusicTime:&musicTime targetIndex:&targetIndex];
        
        self.timeLineLabel.text = [NSString timeFormatFromSecond:musicTime];
        [self updateLRCLabelProgressAtIndex:targetIndex musicCurrentTime:musicTime];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self beginUpdates];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [scrollView setContentOffset:scrollView.contentOffset animated:NO]; /**< 避免scrollView连续滚动影响体验*/
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [scrollView setContentOffset:scrollView.contentOffset animated:NO]; /**< 避免scrollView连续滚动影响体验*/
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    NSTimeInterval musicTime = CGFLOAT_MAX;
    NSInteger targetIndex = NSIntegerMax;
    [self getWhenLyricsViewScrollingMusicTime:&musicTime targetIndex:&targetIndex];
    
    [self updateLyricsViewContentOffsetAtIndex:targetIndex musicCurrentTime:musicTime];
    [self updateLRCLabelProgressAtIndex:targetIndex musicCurrentTime:musicTime];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(simulator:didScrollToLRCTime:)]) {
        [self.delegate simulator:self didScrollToLRCTime:musicTime];
    }
    
    [self endUpdates];
}

@end

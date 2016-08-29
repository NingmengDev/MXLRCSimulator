//
//  MXTrackListView.h
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/8.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OMXTrack;
@class MXTrackListView;

@protocol MXTrackListViewDelegate <NSObject>

@optional
- (void)listView:(MXTrackListView *)listView didSelectTrack:(OMXTrack *)track;

@end

@interface MXTrackListView : UIView

@property (weak, nonatomic) id <MXTrackListViewDelegate> delegate;
@property (copy, nonatomic) NSArray <OMXTrack *> *allTracks;

- (void)showInView:(UIView *)aView;

@end

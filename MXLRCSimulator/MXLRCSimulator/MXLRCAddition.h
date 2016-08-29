//
//  MXLRCAddition.h
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/6.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  遍历数组，同时返回当前对象和下一对象
 */
@interface NSArray (MXLRC)

typedef void (^MXLRCEnumerateWithNextBlock)(NSUInteger idx, id object, id nextObject, BOOL *stop);

- (void)enumerateObjectsWithNextUsingBlock:(MXLRCEnumerateWithNextBlock)block;

@end


/**
 *  将秒数格式化成 00:00 或 00:00:00 形式
 */
@interface NSString (MXLRC)

+ (NSString *)timeFormatFromSecond:(NSTimeInterval)seconds;

@end


/**
 *  利用系统自带的NSLayoutConstraint进行自动布局
 */
@interface UIView (MXLRC)

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)a1 cEqualTo:(CGFloat)constant;
- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)a1 equalTo:(UIView *)view;
- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)a1 equalTo:(UIView *)view a:(NSLayoutAttribute)a2;
- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)a1 equalTo:(UIView *)view c:(CGFloat)constant;
- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)a1 equalTo:(UIView *)view a:(NSLayoutAttribute)a2 c:(CGFloat)constant;

@end


/**
 *  分割线的高度（例如：UITableViewCell中的分割线）
 *
 *  @return 分割线的高度
 */
CG_INLINE CGFloat MXLRCSeparatorHeight()
{
    static CGFloat separatorHeight;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        separatorHeight = 1.0 / [UIScreen mainScreen].scale;
    });
    return separatorHeight;
}

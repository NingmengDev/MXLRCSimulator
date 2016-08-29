//
//  MXLRCAddition.m
//  MXLRCSimulator
//
//  Created by 韦纯航 on 16/8/6.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import "MXLRCAddition.h"

/**
 *  遍历数组，同时返回当前对象和下一对象
 */
@implementation NSArray (MXLRC)

- (void)enumerateObjectsWithNextUsingBlock:(MXLRCEnumerateWithNextBlock)block
{
    BOOL stop = NO;
    NSEnumerator *enumerator = [self objectEnumerator];
    id object = [enumerator nextObject];
    while (object) {
        if (stop) break;
        
        NSUInteger idx = [self indexOfObject:object];
        id nextObject = [enumerator nextObject];
        if (block) block(idx, object, nextObject, &stop);
        object = nextObject;
    }
}

@end


/**
 *  将秒数格式化成 00:00 或 00:00:00 形式
 */
@implementation NSString (MXLRC)

+ (NSString *)timeFormatFromSecond:(NSTimeInterval)seconds
{
    int totals = seconds;
    int totalm = totals / 60;
    int h = totalm / 60;
    int m = totalm % 60;
    int s = totals % 60;
    if (h == 0) {
        return [NSString stringWithFormat:@"%02d:%02d", m, s];
    }
    return [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
}

@end


/**
 *  利用系统自带的NSLayoutConstraint进行自动布局
 */
@implementation UIView (MXLRC)

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)a1 cEqualTo:(CGFloat)constant
{
    return [self constraint:a1 equalTo:nil c:constant];
}

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)a1 equalTo:(UIView *)view
{
    return [self constraint:a1 equalTo:view c:0.0];
}

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)a1 equalTo:(UIView *)view a:(NSLayoutAttribute)a2
{
    return [self constraint:a1 equalTo:view a:a2 c:0.0];
}

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)a1 equalTo:(UIView *)view c:(CGFloat)constant
{
    NSLayoutAttribute a2 = view ? a1 : NSLayoutAttributeNotAnAttribute;
    return [self constraint:a1 equalTo:view a:a2 c:constant];
}

- (NSLayoutConstraint *)constraint:(NSLayoutAttribute)a1 equalTo:(UIView *)view a:(NSLayoutAttribute)a2 c:(CGFloat)constant
{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:a1 relatedBy:NSLayoutRelationEqual toItem:view attribute:a2 multiplier:1.0 constant:constant];
    [self.superview addConstraint:constraint];
    
    return constraint;
}

@end

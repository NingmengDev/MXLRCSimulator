//
//  MXLRCParser.h
//  MXLRCParser
//
//  Created by 韦纯航 on 16/8/3.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MXLRCLine : NSObject

@property (assign, nonatomic) NSTimeInterval time; /**< 开始时间*/
@property (copy, nonatomic) NSString *content; /**< 文本内容*/

/**
 *  歌词持续时长 = 下一句开始时间 - 本句开始时间；
 *  若已是最后一句，若能获取到对应歌曲的时长，则歌词持续时长 = 歌曲时长 - 本句开始时间；
 *  若获取不到对应歌曲的时长，则歌词持续时长取默认值10s
 */
@property (assign, nonatomic) NSTimeInterval duration; /**< 持续时长*/

@end


typedef void (^MXLRCParserObjectsBlock)(NSArray <MXLRCLine *> *lyrics);
typedef void (^MXLRCParserStringBlock)(NSString *string);

@interface MXLRCParser : NSObject

/**
 *  解析歌词文件
 *
 *  @param path       歌词文件路径
 *  @param completion 回调
 */
+ (void)parseLRCWithContentsOfFile:(NSString *)path completion:(MXLRCParserObjectsBlock)completion;

/**
 *  解析歌词数据
 *
 *  @param data       歌词数据
 *  @param completion 回调
 */
+ (void)parseLRCWithData:(NSData *)data completion:(MXLRCParserObjectsBlock)completion;

/**
 *  解析歌词内容
 *
 *  @param contents   歌词内容
 *  @param completion 回调
 */
+ (void)parseLRCWithContents:(NSString *)contents completion:(MXLRCParserObjectsBlock)completion;

@end

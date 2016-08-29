//
//  MXLRCParser.m
//  MXLRCParser
//
//  Created by 韦纯航 on 16/8/3.
//  Copyright © 2016年 韦纯航. All rights reserved.
//

#import "MXLRCParser.h"

#import "MXLRCAddition.h"

#ifndef NSGB2312StringEncoding
    #define NSGB2312StringEncoding CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)
#endif

#pragma mark - MXLRCParserStringAdditions

@interface NSString (MXLRCParserStringAdditions)

- (NSString *)lrc_stringByDecodingXMLEntitiesIfNeeded;

- (NSString *)lrc_stringByRemoveWhiteSpaces;

- (BOOL)lrc_stringIsValid;

@end

@implementation NSString (MXLRCParserStringAdditions)

- (NSString *)lrc_stringByDecodingXMLEntitiesIfNeeded
{
    NSUInteger ampIndex = [self rangeOfString:@"&" options:NSLiteralSearch].location;
    
    // Short-circuit if there are no ampersands.
    if (ampIndex == NSNotFound) return self;
    
    // Make result string with some extra capacity.
    NSMutableString *result = [NSMutableString string];
    
    // First iteration doesn't need to scan to & since we did that already, but for code simplicity's sake we'll do it again with the scanner.
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:nil];
    
    // Make boundary character set.
    NSCharacterSet *boundaryCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r;"];
    
    do {
        // Scan up to the next entity or the end of the string.
        NSString *nonEntityString;
        if ([scanner scanUpToString:@"&" intoString:&nonEntityString]) {
            [result appendString:nonEntityString];
        }
        
        // Goto finish if scanner is at end.
        if ([scanner isAtEnd]) goto finish;
        
        // Scan either a HTML or numeric character entity reference.
        if ([scanner scanString:@"&amp;" intoString:NULL])
            [result appendString:@"&"];
        else if ([scanner scanString:@"&apos;" intoString:NULL])
            [result appendString:@"'"];
        else if ([scanner scanString:@"&quot;" intoString:NULL])
            [result appendString:@"\""];
        else if ([scanner scanString:@"&lt;" intoString:NULL])
            [result appendString:@"<"];
        else if ([scanner scanString:@"&gt;" intoString:NULL])
            [result appendString:@">"];
        else if ([scanner scanString:@"&#" intoString:NULL]) {
            BOOL gotNumber;
            unsigned charCode;
            NSString *xForHex = @"";
            
            // Is it hex or decimal?
            if ([scanner scanString:@"x" intoString:&xForHex]) {
                gotNumber = [scanner scanHexInt:&charCode];
            }
            else {
                gotNumber = [scanner scanInt:(int *)&charCode];
            }
            
            if (gotNumber) {
                [result appendFormat:@"%C", (unichar)charCode];
                [scanner scanString:@";" intoString:NULL];
            }
            else {
                NSString *unknownEntity = @"";
                [scanner scanUpToCharactersFromSet:boundaryCharacterSet intoString:&unknownEntity];
                [result appendFormat:@"&#%@%@", xForHex, unknownEntity];
                
                //[scanner scanUpToString:@";" intoString:&unknownEntity];
                //[result appendFormat:@"&#%@%@;", xForHex, unknownEntity];
                NSLog(@"Expected numeric character entity but got &#%@%@;", xForHex, unknownEntity);
            }
        }
        else {
            NSString *amp;
            [scanner scanString:@"&" intoString:&amp];      //an isolated & symbol
            [result appendString:amp];
            
            /*
             NSString *unknownEntity = @"";
             [scanner scanUpToString:@";" intoString:&unknownEntity];
             NSString *semicolon = @"";
             [scanner scanString:@";" intoString:&semicolon];
             [result appendFormat:@"%@%@", unknownEntity, semicolon];
             NSLog(@"Unsupported XML character entity %@%@", unknownEntity, semicolon);
             */
        }
    }
    while (![scanner isAtEnd]);
    
finish:
    return [result stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
}

- (NSString *)lrc_stringByRemoveWhiteSpaces
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)lrc_stringIsValid
{
    return ([[self lrc_stringByRemoveWhiteSpaces] isEqualToString:@""] || self == nil || [self isEqualToString:@"(null)"]) ? NO : YES;
}

@end


#pragma mark - MXLRCLine

static NSString *const MXLRCLineTimeKey = @"time";

@implementation MXLRCLine

@synthesize time;
@synthesize content;

@end


#pragma mark - MXLRCParser

@implementation MXLRCParser

/**
 *  解析歌词文件
 *
 *  @param path       歌词文件路径
 *  @param completion 回调
 */
+ (void)parseLRCWithContentsOfFile:(NSString *)path completion:(MXLRCParserObjectsBlock)completion
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    [self parseLRCWithData:data completion:completion];
}

/**
 *  解析歌词数据
 *
 *  @param data       歌词数据
 *  @param completion 回调
 */
+ (void)parseLRCWithData:(NSData *)data completion:(MXLRCParserObjectsBlock)completion
{
    NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (contents == nil) {
        contents = [[NSString alloc] initWithData:data encoding:NSGB2312StringEncoding];
    }
    [self parseLRCWithContents:contents completion:completion];
}

/**
 *  解析歌词内容
 *
 *  @param contents   歌词内容
 *  @param completion 回调
 */
+ (void)parseLRCWithContents:(NSString *)contents completion:(MXLRCParserObjectsBlock)completion
{
    if (![contents lrc_stringIsValid]) {
        if (completion) completion([NSArray array]);
    }
    else {
        [self parseLRCInBackgroundWithContents:contents completion:completion];
    }
}

/**
 *  异步解析歌词内容
 *
 *  @param contents   歌词内容
 *  @param completion 回调
 */
+ (void)parseLRCInBackgroundWithContents:(NSString *)contents completion:(MXLRCParserObjectsBlock)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // 先解码歌词内容（部分歌词内容中含有html特殊符号）
        NSString *contentsDecoded = [contents lrc_stringByDecodingXMLEntitiesIfNeeded];
        contentsDecoded = [contentsDecoded lrc_stringByRemoveWhiteSpaces];
        
        // 储存格式化后的歌词内容
        NSMutableString *formattedContents = [NSMutableString string];
        
        // 拆分解码后的歌词，格式化每一行歌词内容
        NSArray <NSString *> *components = [contentsDecoded componentsSeparatedByString:@"\n"];
        for (NSString *component in components) {
            NSString *content = [component lrc_stringByRemoveWhiteSpaces];
            if (content.length < 2) { // 小于两个字符的歌词不符合歌词规范，一行歌词至少两个字符[]，忽略掉此行
                continue;
            }
            
            [self parseComponent:content completion:^(NSString *string) {
                if (string.length) [formattedContents appendFormat:@"\n%@", string];
            }];
        }
        
        // 去掉开头和结尾的多余空格和换行符
        NSString *contentsFormatted = [formattedContents lrc_stringByRemoveWhiteSpaces];
        
        // 格式化歌词后正式解析歌词内容
        NSMutableArray <MXLRCLine *> *lines = [NSMutableArray array];
        components = [contentsFormatted componentsSeparatedByString:@"\n"];
        for (NSString *component in components) {
            if(component.length < 1) continue;
            
            unichar character = [component characterAtIndex:1];
            if (character >= '0' && character <= '9') { //有效的歌词行
                MXLRCLine *lineObject = [self lineObjectWithComponent:component];
                if (lineObject) [lines addObject:lineObject];
            }
        }
        
        // 按时间戳先后顺序排列
        NSSortDescriptor *descriptorForTime = [NSSortDescriptor sortDescriptorWithKey:MXLRCLineTimeKey ascending:YES];
        [lines sortUsingDescriptors:@[descriptorForTime]];
        
        // 计算每一行歌词的持续时长
        [lines enumerateObjectsWithNextUsingBlock:^(NSUInteger idx, MXLRCLine *object, MXLRCLine *nextObject, BOOL *stop) {
            object.duration = 10.0;
            if (nextObject) object.duration = nextObject.time - object.time;
        }];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion([NSArray arrayWithArray:lines]);
        });
    });
}

/**
 *  处理每一行歌词中的特殊部分，并格式化歌词
 *
 *  特殊歌词内容如：
 *  一、作词:XXX[00:05.68]演唱:XXX，此种歌词段中“[00:05.68]演唱:XXX”有效，前部分去掉
 *  二、[00:29.22]XX[00:37.40]XXX[00:49.63]XXXX，此种歌词段中含有多个歌词片段，要拆分出来
 *  三、[01:15.38][02:35.86]XXX，此种歌词段中多个时间标签对应同一歌词内容，也要拆分出来
 *
 *  @param component  要处理的歌词行
 *  @param completion 回调
 */
+ (void)parseComponent:(NSString *)component completion:(MXLRCParserStringBlock)completion
{
    NSRegularExpression *regex = [self timestampRegularExpressionForLRC];
    NSArray <NSTextCheckingResult *> *parseResults = [regex matchesInString:component options:kNilOptions range:NSMakeRange(0, component.length)];
    NSArray *ranges = [parseResults valueForKeyPath:@"range"];
    if (ranges.count == 0) {
        if (completion) completion(nil);
    }
    else {
        NSMutableString *ms = [NSMutableString string];
        if (ranges.count == 1) {
            NSRange range = [ranges.firstObject rangeValue];
            NSString *subcontent = [component substringFromIndex:range.location];
            [ms appendString:subcontent];
        }
        else {
            NSRange lastRange = [ranges.lastObject rangeValue];
            NSString *s = [component substringFromIndex:lastRange.location + lastRange.length];
            NSString *t = [component substringWithRange:lastRange];
            [ms appendFormat:@"%@%@", t, s];
            
            for (NSInteger idx = ranges.count - 2; idx >= 0; idx --) { // 倒序循环
                NSRange nextRange = [ranges[idx] rangeValue];
                t = [component substringWithRange:nextRange];
                
                if (nextRange.location != lastRange.location - nextRange.length) { // 两个不相邻，s内容要修改掉
                    NSUInteger location = nextRange.location + nextRange.length;
                    NSUInteger length = lastRange.location - location;
                    s = [component substringWithRange:NSMakeRange(location, length)];
                }
                [ms appendFormat:@"\n%@%@", t, s];
                
                lastRange = nextRange;
            }
        }
        
        if (completion) completion(ms);
    }
}

/**
 *  解析歌词行，把时间和内容分离
 *
 *  @param component 歌词行
 *
 *  @return 歌词行对象
 */
+ (MXLRCLine *)lineObjectWithComponent:(NSString *)component
{
    MXLRCLine *lineObject;
    NSRegularExpression *regex = [self timestampRegularExpressionForLRC];
    NSTextCheckingResult *result = [regex firstMatchInString:component options:kNilOptions range:NSMakeRange(0, component.length)];
    if (result) {
        NSString *timestamp = [component substringWithRange:result.range];
        NSString *content = [component substringFromIndex:result.range.location + result.range.length];
        
        // 因timestamp是通过匹配正则表达式得来的，符合时间戳的[00:00.00]格式，故可以放心根据":"字符串分割
        NSArray *timestampComponents = [timestamp componentsSeparatedByString:@":"];
        NSString *minuteText = [timestampComponents.firstObject substringFromIndex:1];
        NSString *secondText = timestampComponents.lastObject;
        secondText = [secondText substringToIndex:secondText.length - 1];
        
        NSInteger minute = minuteText.integerValue;
        NSTimeInterval second = secondText.doubleValue;
        
        lineObject = [MXLRCLine new];
        lineObject.time = minute * 60 + second;
        lineObject.content = content;
    }
    
    return lineObject;
}

/**
 *  歌词时间戳正则表达式
 *
 *  @return 时间戳正则表达式
 */
+ (NSRegularExpression *)timestampRegularExpressionForLRC
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\[(\\d{2}:\\d{2}\\.\\d{2})\\]" options:kNilOptions error:NULL];
    });
    return regex;
}

@end

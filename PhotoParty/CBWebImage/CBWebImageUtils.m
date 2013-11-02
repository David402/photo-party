//
//  CBWebImageUtils.m
//  CBWebImage
//
//  Created by yyjim on 12/9/24.
//  Copyright (c) 2012年 cardinalblue. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access
#import "UIScreen+CBWebImageAdditions.h"
#import "CBWebImageUtils.h"

id CBW_SAFE_CAST(Class klass, id obj) {
    return [obj isKindOfClass:klass]? obj : nil;
}

float CBW_SAFE_FLOAT(id obj) {
    if ([obj respondsToSelector:@selector(floatValue)])
        return [obj floatValue];
    return 0;
}

BOOL CBWLogDebugEnabled = YES;

@implementation CBWebImageUtils

+ (NSString *)imageFilePath:(NSString *)filePath
{
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    
    // Find image with device suffix
    NSString *deviceSuffix = @"";
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        deviceSuffix = @"~iphone";
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        deviceSuffix = @"~ipad";
    
    NSString *filePath1xDevice = [filePath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", [filePath pathExtension]]
                                                                     withString:[NSString stringWithFormat:@"%@.%@", deviceSuffix, [filePath pathExtension]]];
    NSString *filePath2xDevice = [filePath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", [filePath pathExtension]]
                                                                     withString:[NSString stringWithFormat:@"@2x%@.%@", deviceSuffix, [filePath pathExtension]]];
    if ([[UIScreen mainScreen] cb_isRetinaDisplay]) {
        if ([fileManager fileExistsAtPath:filePath2xDevice])
            return filePath2xDevice;
    }
    
    if ([fileManager fileExistsAtPath:filePath1xDevice])
        return filePath1xDevice;
    
    // Find image without device suffix
    NSString *filePath1x = [NSString stringWithString:filePath];
    NSString *filePath2x = [filePath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", [filePath pathExtension]]
                                                               withString:[NSString stringWithFormat:@"@2x.%@", [filePath pathExtension]]];
    if ([[UIScreen mainScreen] cb_isRetinaDisplay]) {
        if ([fileManager fileExistsAtPath:filePath2x])
            return filePath2x;
    }
    
    if ([fileManager fileExistsAtPath:filePath1x])
        return filePath1x;
    
    return filePath;
}

@end

@implementation NSString (CBWebImageUtils)

- (NSString *)md5
{
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, strlen(cStr), result); // This is the md5 call
    NSString *md5 = [NSString stringWithFormat:
                     @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                     result[0],  result[1],  result[2],  result[3],
                     result[4],  result[5],  result[6],  result[7],
                     result[8],  result[9],  result[10], result[11],
                     result[12], result[13], result[14], result[15]
                     ];
    return md5;
}

@end
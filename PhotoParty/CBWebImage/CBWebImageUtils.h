//
//  CBWebImageUtils.h
//  CBWebImage
//
//  Created by yyjim on 12/9/24.
//  Copyright (c) 2012年 cardinalblue. All rights reserved.
//

#import <UIKit/UIKit.h>

id CBW_SAFE_CAST(Class klass, id obj);
float CBW_SAFE_FLOAT(id obj);

extern BOOL CBWLogDebugEnabled;

#ifdef DEBUG
#   define CBWLogD_          { if (CBWLogDebugEnabled) NSLog((@"%s:%d"), __PRETTY_FUNCTION__, __LINE__); }
#   define CBWLogD(fmt, ...) { if (CBWLogDebugEnabled) NSLog((@"%s:%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); }
#else
#   define CBWLogD_          {}
#   define CBWLogD(...)      {}
#endif

// ==========================================================================
#pragma mark - Singleton macros

#define CBW_SINGLETON_DEFAULT_INTERFACE(Classname)                            \
+ (Classname *)shared;

#define CBW_SINGLETON_DEFAULT_IMPLEMENTATION(Classname)                       \
static Classname *shared = nil;                                              \
+ (Classname *)shared                                                        \
{                                                                            \
    @synchronized(self) {                                                    \
        if (shared == nil) {                                                 \
            shared = [[super allocWithZone:NULL] init];                      \
        }                                                                    \
    }                                                                        \
    return shared;                                                           \
}                                                                            \
+ (id)allocWithZone:(NSZone *)zone                                           \
{                                                                            \
    return [[self shared] retain];                                           \
}                                                                            \
- (id)copyWithZone:(NSZone *)zone                                            \
{                                                                            \
    return self;                                                             \
}                                                                            \
- (id)retain                                                                 \
{                                                                            \
    return self;                                                             \
}                                                                            \
- (NSUInteger)retainCount                                                    \
{                                                                            \
    return NSUIntegerMax;                                                    \
}                                                                            \
- (oneway void)release                                                       \
{                                                                            \
}                                                                            \
- (id)autorelease                                                            \
{                                                                            \
    return self;                                                             \
}


@interface CBWebImageUtils : NSObject
/* 
    This method will return new image_file_path if main bundle contain  that follow iOS image naming conventions.
    eg.
     *name~iphone.png
     *name@2x~iphone.png
     *name~ipad.png
     *name@2x~ipad.png
*/
+ (NSString *)imageFilePath:(NSString *)filePath;
@end

@interface NSString (CBWebImageUtils)
- (NSString *)md5;
@end


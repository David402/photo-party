//
//  CBImageCache.h
//  PicCollage
//
//  Created by WANG JIM on 12/8/7.
//  Copyright (c) 2012年 Cardinal Blue Software. All rights reserved.
//
// Reference JMImageCache
// https://github.com/jakemarsh/JMImageCache

#import "CBWebImageCompat.h"
#import <UIKit/UIKit.h>

typedef void(^CBImageCacheCompletion)(UIImage *image);

@interface CBImageCache : NSCache

+ (CBImageCache *)shared;
+ (NSInteger)cacheMaxCacheAge;
+ (void)setCacheMaxCacheAge:(NSInteger)second;

#pragma mark - Read methods
- (BOOL)hasCachedForURL:(NSURL *)url;
- (BOOL)hasCachedForKey:(NSString *)key;

- (UIImage *)readImageForURL:(NSURL *)url;

#pragma mark - Write methods
// It will cache data as UIImage in memory.
- (void)storeImageData:(NSData *)data forURL:(NSURL *)url;  // Write to memory and disk
- (void)storeImageData:(NSData *)data forURL:(NSURL *)url
         toMemory:(BOOL)toMemory
           toDisk:(BOOL)toDisk;

#pragma mark - Delete methods
- (void)removeImageForURL:(NSURL *)url;

- (void)clearAll;     // Delete memory and disk caching
- (void)clearMemory;  // Delete all memory cache
- (void)clearDisk;    // Delete all disk cache

- (void)cleanDisk;    // Delete expired file

@end

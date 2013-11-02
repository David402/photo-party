//
//  CBImageCache.m
//  PicCollage
//
//  Created by WANG JIM on 12/8/7.
//  Copyright (c) 2012年 Cardinal Blue Software. All rights reserved.
//
#import "UIImage+GIF.h"
#import "CBWebImageUtils.h"
#import "CBImageCache.h"

#define CBImageCacheFilenamePrefix @"CBImageCache"

#define DEFAULT_COUNT_LIMIT  30

@interface CBImageCache ()
@end

@implementation CBImageCache

static NSInteger g_cacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week

+ (void)setCacheMaxCacheAge:(NSInteger)second
{
    g_cacheMaxCacheAge = second;
}

+ (NSInteger)cacheMaxCacheAge
{
    return g_cacheMaxCacheAge;
}

+ (dispatch_queue_t)sharedDiskQueue
{
    static dispatch_once_t pred;
    static dispatch_queue_t g_diskCacheQueue;
    
    dispatch_once(&pred, ^{
        g_diskCacheQueue = dispatch_queue_create("CBImageCache Disk Queue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_t lowPriQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_set_target_queue(g_diskCacheQueue, lowPriQueue);
    });
    
    return g_diskCacheQueue;
}

static NSString *g_diskCachePath = nil;

+ (NSString *)diskCachePath {
    if (!g_diskCachePath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        g_diskCachePath = [[documentsDirectory stringByAppendingPathComponent:@"CBImageCache"] copy];
    }
    return g_diskCachePath;
}

+ (NSString *)cacheKeyForURL:(NSURL *)url {
	return [url absoluteString];
}

+ (NSString *)cachePathForKey:(NSString *)key {
    NSString *fileName = [self filenameForKey:key];
	return [[self diskCachePath] stringByAppendingPathComponent:fileName];
}

+ (NSString *)filenameForKey:(NSString *)key
{
    // Remove unwanted characters from URL
    NSArray *keyComponents = [key componentsSeparatedByCharactersInSet:
                              [[NSCharacterSet alphanumericCharacterSet] invertedSet]];
    NSMutableArray *newKeyComponents = [NSMutableArray arrayWithCapacity:[keyComponents count]];
    for (id i in keyComponents) {
        // Remove empty strings
        if ([i length] > 0) {
            [newKeyComponents addObject:i];
        }
    }
    
    // Prefix
    const int MAX_FILENAME_LENGTH = 128;
    NSArray *filenameComponents = [NSArray arrayWithObject:CBImageCacheFilenamePrefix];
    filenameComponents = [filenameComponents arrayByAddingObjectsFromArray:newKeyComponents];
    NSString *filenamePre = [filenameComponents componentsJoinedByString:@"_"];
    
    // Max length, leaving room for separator + MD5
    filenamePre = [filenamePre substringToIndex:MIN([filenamePre length],
                                                    MAX_FILENAME_LENGTH - 1 - 32)];
    
    // Add MD5 hash
    return [NSString stringWithFormat:@"%@_%@", filenamePre, [key md5]];
}

+ (void)ensureCachePath
{
    NSString *path = [self diskCachePath];
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
}

static CBImageCache *_shared = nil;

+ (CBImageCache *)shared
{
    @synchronized(self) {
        if (_shared == nil) {
            _shared = [[self alloc] init];
            _shared.name = @"CBImageCache/Shared";
            _shared.countLimit = DEFAULT_COUNT_LIMIT;
        }
    }        
    return _shared;
}

+ (void)clearCachingDirectory
{
    dispatch_async([self sharedDiskQueue], ^{
        NSString *path = [self diskCachePath];
        NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
        [fm removeItemAtPath:path error:NULL];
        [self ensureCachePath];
    });
}

#pragma mark - Object lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        [[self class] ensureCachePath];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - Write methods

- (void)storeImageData:(NSData *)data forURL:(NSURL *)url
{
    [self storeImageData:data forURL:url
                toMemory:YES
                  toDisk:YES];
}
- (void)storeImageData:(NSData *)data forURL:(NSURL *)url
              toMemory:(BOOL)toMemory
                toDisk:(BOOL)toDisk
{
    [self storeImageData:data forKey:[[self class] cacheKeyForURL:url]
                toMemory:toMemory
                  toDisk:toDisk];
}

- (void)storeImageData:(NSData *)data forKey:(NSString *)key
{
    [self storeImageData:data forKey:key toMemory:YES toDisk:YES];
}

- (void)storeImageData:(NSData *)data forKey:(NSString *)key
              toMemory:(BOOL)toMemory
                toDisk:(BOOL)toDisk
{
    if (!data)
        return;
    
    if (toMemory) {
        // Always store UIImage into memory cache.
        UIImage *image = [self imageWithData:data];
        if (image && key)
            [self setObject:image forKey:key];
    }
    
    if (toDisk) {
        NSString *path = [[self class] cachePathForKey:key];
        dispatch_async([[self class] sharedDiskQueue], ^{
            NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
            [fileManager createFileAtPath:path contents:data attributes:nil];
        });
    }
}

#pragma mark - Read methods

- (BOOL)hasCachedForURL:(NSURL *)url
{
    return [self hasCachedForKey:[[self class] cacheKeyForURL:url]];
}

- (BOOL)hasCachedForKey:(NSString *)key
{
    // Memory
    if ([self objectForKey:key])
        return YES;
    
    // Disk
    NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
    return [fm fileExistsAtPath:[[self class] cachePathForKey:key]];
}

- (UIImage *)readImageForURL:(NSURL *)url
{
    CBWLogD(@"url:%@", url);
    return [self readImageForKey:[[self class] cacheKeyForURL:url]];
}

- (UIImage *)readImageForKey:(NSString *)key
{
    CBWLogD(@"key:%@", key);
    if (!key)
        return nil;

    UIImage *image = nil;

    // Read from memory
	image = (UIImage *)[self objectForKey:key];

    // Otherwise Read from Disk
	if (!image)
        image = [self imageFromDiskForKey:key];
    
    // Return
    if ([image isKindOfClass:[UIImage class]])
        return image;
    // else
    return nil;
}

- (UIImage *)imageFromDiskForKey:(NSString *)key
{
    NSData *data = [NSData dataWithContentsOfFile:[[self class] cachePathForKey:key]
                                               options:0 
                                                 error:NULL];
    if (data)
        return [self imageWithData:data];
    
    return nil;
}

- (UIImage *)imageFromDiskForURL:(NSURL *)url {
    return [self imageFromDiskForKey:[[self class] cacheKeyForURL:url]];
}

#pragma mark - Delete methods

- (void)removeImageForKey:(NSString *)key
{
    // Remove memory cache
	[self removeObjectForKey:key];
    
    // Remove disk cache
    dispatch_async([[self class] sharedDiskQueue], ^{
        NSString *path = [[self class] cachePathForKey:key];
        NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
        [fm removeItemAtPath:path error:nil];
    });
}

- (void)removeImageForURL:(NSURL *)url {
    [self removeImageForKey:[[self class] cacheKeyForURL:url]];
}

#pragma mark - Clear/Clean

- (void)clearAll {
    [self clearMemory];
    [self clearDisk];
}

- (void)clearMemory
{
    [self removeAllObjects];
}

- (void)clearDisk
{
    [[self class] clearCachingDirectory];
}

- (void)cleanDisk
{
    dispatch_async([[self class] sharedDiskQueue], ^{
        NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
        
        // Iterate over all the files in the path and delete ones in which
        // modification date is BEFORE the expiration date.
        //
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-[[self class] cacheMaxCacheAge]];
        NSString *path = [[self class] diskCachePath];
        for (NSString *fileName in [fm enumeratorAtPath:path]) {
            NSString *filePath = [path stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [fm attributesOfItemAtPath:filePath error:nil];
            if ([[attrs fileModificationDate] compare:expirationDate] == NSOrderedAscending) {
                [fm removeItemAtPath:filePath error:nil];
            }
        }
    });
}

#pragma mark - Private

- (UIImage *)imageWithData:(NSData *)data
{
#if kSDWebImageGIFSupporting
    return [UIImage cb_imageWithData:data];
#else
    return [UIImage imageWithData:data];
#endif
}

@end

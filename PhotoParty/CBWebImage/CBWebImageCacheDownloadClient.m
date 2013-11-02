//
//  CBWebImageMemcachedDonwloadClient.m
//  CBWebImage
//
//  Created by yyjim on 5/28/13.
//  Copyright (c) 2013 cardinalblue. All rights reserved.
//

#import "CBImageCache.h"
#import "CBWebImageCacheDownloadClient.h"

@interface CBWebImageCacheDownloadClient ()
{
    BOOL _isStopped;
}
@property (nonatomic, copy) void (^completionBlock)(UIImage *image);
@end

@implementation CBWebImageCacheDownloadClient
@synthesize completionBlock = _completionBlock;

- (id)init
{
    self = [super init];
    if (self) {
        // Default to use shared image cache;
        self.imageCache = [CBImageCache shared];
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
       imageCache:(CBImageCache *)imageCache
           target:(id)target
         delegate:(id<CBWebImageDownloadClientDelegate>)delegate
{
    self = [super initWithURL:url target:target delegate:delegate];
    if (self) {
        self.imageCache = imageCache;
    }
    return self;
}

- (void)dealloc
{
    self.imageCache = nil;
    self.completionBlock = nil;
    [super dealloc];
}

- (void)startWithCompletionBlock:(void (^)(UIImage *image))block
{
    self.completionBlock = block;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        UIImage *image = [self.imageCache readImageForURL:self.url];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!_isStopped && self.completionBlock)
                self.completionBlock(image);
            self.completionBlock = nil;
        });
        return;
    });
}

- (void)stop
{
    _isStopped = YES;
    self.completionBlock = nil;
}

@end

@implementation CBImageCache (CBWebImageCacheDownloadClient)

- (CBWebImageCacheDownloadClient *)downloadImageWithURL:(NSURL *)url
                                                 target:(id)target
                                               delegate:(id<CBWebImageDownloadClientDelegate>)delegate
{
    if ([self hasCachedForURL:url]) {
        CBWebImageCacheDownloadClient *client =
            [[[CBWebImageCacheDownloadClient alloc] initWithURL:url
                                                     imageCache:self
                                                         target:target
                                                       delegate:delegate]
             autorelease];
        return client;
    }
    return nil;
}

@end


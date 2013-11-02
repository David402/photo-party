//
//  CBWebImageManager.m
//  CBWebImage
//
//  Created by yyjim on 12/9/24.
//  Copyright (c) 2012年 cardinalblue. All rights reserved.
//

#import "UIImage+GIF.h"
#import "CBWebImageDownloadClient.h"
#import "CBWebImageNetworkDownloadClient.h"
#import "CBWebImageCacheDownloadClient.h"

#import "CBImageCache.h"
#import "CBWebImageManager.h"

@interface CBWebImageManagerDownloadClientStore : NSObject
@property (nonatomic, retain) NSMutableDictionary *dic;
@end

@implementation CBWebImageManagerDownloadClientStore

@synthesize dic = _dic;

#pragma mark - Object initialization
- (id)init
{
    self = [super init];
    if (!self) return nil;
    self.dic = [NSMutableDictionary dictionary];
    return self;
}
- (void)dealloc
{
    self.dic = nil;
    [super dealloc];
}


#pragma mark - Download client mgmt
- (void)addClient:(id<CBWebImageDownloadClient>)client
{
    NSMutableArray *perTargetArray =
        [self.dic objectForKey:[NSValue valueWithNonretainedObject:client.target]];
    
    if (perTargetArray) {
        [perTargetArray addObject:client];
    }
    else {
        perTargetArray = [NSMutableArray arrayWithObject:client];
        [self.dic setObject:perTargetArray forKey:[NSValue valueWithNonretainedObject:client.target]];
    }
}
- (void)removeClient:(id<CBWebImageDownloadClient>)client
{
    NSMutableArray *perTargetArray =
        [self.dic objectForKey:[NSValue valueWithNonretainedObject:client.target]];
    
    if (perTargetArray) {
        [perTargetArray removeObject:client];
        if (perTargetArray.count == 0) {
            [self.dic removeObjectForKey:[NSValue valueWithNonretainedObject:client.target]];
        }
    }
}
- (NSArray *)clientsForTarget:(id)target
{
    NSArray *perTargetArray = [self.dic objectForKey:[NSValue valueWithNonretainedObject:target]];
    return [[perTargetArray copy] autorelease];
}
- (void)removeAllForTarget:(id)target
{
    [self.dic removeObjectForKey:[NSValue valueWithNonretainedObject:target]];
}
- (NSArray *)targets
{
    NSMutableArray *targets = [NSMutableArray arrayWithCapacity:self.dic.count];
    for (NSValue *targetV in [self.dic allKeys])
        [targets addObject:[targetV nonretainedObjectValue]];
    return targets;
}


@end


//==============================================================================
//==============================================================================

@interface CBWebImageManager ()
    <CBWebImageDownloadClientDelegate>

@property (nonatomic, retain) CBImageCache *imageCache;
@property (nonatomic, retain) CBWebImageManagerDownloadClientStore *downloadClients;
    // Dictionary keyed by target

@end

@implementation CBWebImageManager
CBW_SINGLETON_DEFAULT_IMPLEMENTATION(CBWebImageManager);

@synthesize imageCache = _imageCache;
@synthesize downloadClients = _downloadClients;

@synthesize enableCaching = _enableCaching;
@synthesize diskCacheFilter = _diskCacheFilter;

- (id)init
{
    self = [super init];
    if (self) {
        self.imageCache = [CBImageCache shared];
        CBWebImageManagerDownloadClientStore *s = [[CBWebImageManagerDownloadClientStore alloc] init];
        [s autorelease];
        self.downloadClients = [[[CBWebImageManagerDownloadClientStore alloc] init]
                                autorelease];
        self.enableCaching = YES;
    }
    return self;
}

- (void)dealloc
{
    [self cancelAll];
    self.downloadClients = nil;
    self.diskCacheFilter = nil;
    self.memoryCacheFilter = nil;
    self.imageCache = nil;
    [super dealloc];
}

#pragma mark - Setters/Getters

- (void)downloadWithURL:(NSURL *)url
              forTarget:(id)target
                options:(CBWebImageOptions)options
        completionBlock:(CBWebImageCompletionBlock)block;
{
    BOOL enableCaching = self.enableCaching && !(options & CBWebImageOptionsIgnoreCache);
    
    // First try to get from cache
    if (enableCaching) {
        CBWebImageCacheDownloadClient *cacheClient =
            [self.imageCache downloadImageWithURL:url target:target delegate:self];
        if (cacheClient) {
            [self.downloadClients addClient:cacheClient];
            [cacheClient startWithCompletionBlock:^(UIImage *image) {
                block(image, nil);
                [self.downloadClients removeClient:cacheClient];
            }];
            return;
        }
    }
    
    // Otherwise, create a download client
    CBWebImageNetworkDownloadClient *networkClient =
        [[[CBWebImageNetworkDownloadClient alloc] initWithURL:url target:target delegate:self]
         autorelease];
    [self.downloadClients addClient:networkClient];
    
    // Start off download client
    [networkClient startWithCompletionBlock:^(NSData *imageData, NSError *error) {
        if (enableCaching && imageData) {
            
            // Cache if passes filter (by default YES)
            BOOL shouldCacheToDisk = self.diskCacheFilter ? self.diskCacheFilter(url) : YES;
            
            BOOL shouldCacheToMemory = self.memoryCacheFilter ? self.memoryCacheFilter(url) : YES;
            
            dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self.imageCache storeImageData:imageData forURL:url
                                       toMemory:shouldCacheToMemory
                                         toDisk:shouldCacheToDisk];
            });
        }
        UIImage *image = [UIImage cb_imageWithData:imageData];
        block(image, error);
        [self.downloadClients removeClient:networkClient];
    }];
}

- (void)cancelDownloadOperationForTarget:(id)target
{
    NSArray *clients = [self.downloadClients clientsForTarget:target];
    for (id<CBWebImageDownloadClient> client in clients)
        [client stop];
    [self.downloadClients removeAllForTarget:target];
}

- (void)cancelAll
{
    for (id target in [self.downloadClients targets])
        [self cancelDownloadOperationForTarget:target];
}

#pragma mark - CBWebImageManagerDownloadClientDelegate

- (void)downloadClient:(id<CBWebImageDownloadClient>)client
      downloadProgress:(CGFloat)progress
{
    if ([client.target conformsToProtocol:@protocol(CBWebImageManagerProgressDelegate)]) {
        id<CBWebImageManagerProgressDelegate> delegate = client.target;
        
        if (delegate && [delegate respondsToSelector:@selector(webImageManager:downloadImageURL:inProgress:)])
            [delegate webImageManager:self downloadImageURL:client.url inProgress:progress];
    }
}

@end

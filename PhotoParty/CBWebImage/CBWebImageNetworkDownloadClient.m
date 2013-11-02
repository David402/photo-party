//
//  CBWebImageNetworkDownloadClient.m
//  CBWebImage
//
//  Created by yyjim on 5/28/13.
//  Copyright (c) 2013 cardinalblue. All rights reserved.
//

#import "CBWebImageUtils.h"
#import "CBWebImageDownloader.h"
#import "CBWebImageNetworkDownloadClient.h"


@interface CBWebImageNetworkDownloadClient ()
@property (nonatomic, retain) CBWebImageDownloader *downloader;
@end

@implementation CBWebImageNetworkDownloadClient
@synthesize downloader = _downloader;

#pragma mark - Object lifecycle

- (void)dealloc
{
    self.downloader = nil;
    [super dealloc];
}

#pragma mark - Setters/Getters

- (void)setDownloader:(CBWebImageDownloader *)downloader
{
    [_downloader stop];
    [_downloader removeObserver:self forKeyPath:@"progressRatio"];
    
    [_downloader autorelease];
    _downloader = [downloader retain];
    [_downloader addObserver:self forKeyPath:@"progressRatio"
                     options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark -

- (void)startWithCompletionBlock:(void (^)(NSData *, NSError *))block
{
    self.downloader = [[[CBWebImageDownloader alloc] initWithImageURL:self.url] autorelease];
    [self.downloader startWithCompletionBlock:^(NSData *imageData, NSError *error) {
        block(imageData, error);
    }];
}

- (void)stop
{
    [self.downloader stop];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    CGFloat progressRatio = CBW_SAFE_FLOAT([change valueForKey:NSKeyValueChangeNewKey]);
    CBWLogD(@"progress ratio %f", progressRatio);
    [self.delegate downloadClient:self downloadProgress:progressRatio];
}

@end

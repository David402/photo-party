//
//  CBWebImageDownloader.m
//  CBWebImage
//
//  Created by yyjim on 12/9/24.
//  Copyright (c) 2012年 cardinalblue. All rights reserved.
//

#import "CBWebImageUtils.h"
#import "CBWebImageDownloader.h"

static const NSTimeInterval kCBWebImageDownloaderTimeoutInterval = 60;

@interface CBWebImageDownloader ()
    <NSURLConnectionDelegate>

{
    BOOL _isStopped;
    CGFloat _expectedSize;
}

@property (nonatomic, retain, readwrite) NSURL *imageURL;
@property (nonatomic, retain) NSMutableData *imageData;
@property (nonatomic, retain) NSURLConnection *downloadConnection;
@property (nonatomic, copy) CBWebImageDownloaderCompletionBlock completionBlock;
@end

@implementation CBWebImageDownloader

@synthesize progressRatio = _progressRatio;

@synthesize imageURL = _imageURL;
@synthesize imageData = _imageData;
@synthesize downloadConnection = _downloadConnection;
@synthesize completionBlock = _completionBlock;

- (id)initWithImageURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.imageURL = url;
    }
    return self;
}

- (void)dealloc
{
    self.imageURL = nil;
    self.imageData = nil;
    self.downloadConnection = nil;
    self.completionBlock = nil;
    [super dealloc];
}


#pragma mark - Setters/Getters

- (void)setDownloadConnection:(NSURLConnection *)downloadConnection
{
    [_downloadConnection cancel];
    [_downloadConnection autorelease];
    
    _downloadConnection = [downloadConnection retain];
}

#pragma mark -

#pragma mark - Public methods

- (void)start
{
    [self startWithCompletionBlock:nil];
}

- (void)startWithCompletionBlock:(CBWebImageDownloaderCompletionBlock)block
{
    // Start at main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressRatio = 0;
        self.imageData = nil;
        self.completionBlock = block;
        
        NSURL *imageURL = self.imageURL;
        // Handle local image for retian display
        if ([self.imageURL isFileURL]) {
            NSString *origFilePath = [self.imageURL path];
            NSString *newFilePath = [CBWebImageUtils imageFilePath:origFilePath];
            if (newFilePath && ![newFilePath isEqualToString:origFilePath])
                imageURL = [NSURL fileURLWithPath:newFilePath];
        }
        
        NSURLRequest *request = [NSURLRequest requestWithURL:imageURL
                                                 cachePolicy:NSURLRequestReloadIgnoringCacheData
                                             timeoutInterval:kCBWebImageDownloaderTimeoutInterval];
        self.downloadConnection =
        [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO] autorelease];
        
        // Ensure we aren't blocked by UI manipulations (default runloop mode for NSURLConnection is NSEventTrackingRunLoopMode)
        // Reference from SDWebImageDownloader line 82.
        [self.downloadConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self.downloadConnection start];
    });
}

- (void)stop
{
    _isStopped = YES;
    self.downloadConnection = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response
{
    if (![response respondsToSelector:@selector(statusCode)] ||
        [((NSHTTPURLResponse *)response) statusCode] < 400)
    {
        _expectedSize = response.expectedContentLength > 0 ?
                            (NSUInteger)response.expectedContentLength : 0;
        
        self.imageData = [[[NSMutableData alloc] initWithCapacity:_expectedSize] autorelease];
    }
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data
{
    [self.imageData appendData:data];
    self.progressRatio = _expectedSize != 0.0 ?
        ((float)[_imageData length] / (float)_expectedSize) : 0;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    self.downloadConnection = nil;
    if (self.completionBlock && !_isStopped) {
        self.completionBlock(self.imageData, nil);
        self.completionBlock = nil;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.downloadConnection = nil;
    if (self.completionBlock && !_isStopped) {
        self.completionBlock(nil, error);
        self.completionBlock = nil;
    }
}

@end

//
//  CBWebImageDownloader.h
//  CBWebImage
//
//  Created by yyjim on 12/9/24.
//  Copyright (c) 2012年 cardinalblue. All rights reserved.
//
#import <UIKit/UIKit.h>

typedef void(^CBWebImageDownloaderCompletionBlock)(NSData *imageData, NSError *error);

@interface CBWebImageDownloader : NSObject

@property (nonatomic, retain, readonly) NSURL *imageURL;
@property (nonatomic, assign) CGFloat progressRatio;

- (id)initWithImageURL:(NSURL *)url;

- (void)start;
// The complection block will be called on main thread.
- (void)startWithCompletionBlock:(CBWebImageDownloaderCompletionBlock)block;

- (void)stop;

@end

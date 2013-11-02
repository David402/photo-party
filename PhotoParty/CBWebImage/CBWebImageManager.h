//
//  CBWebImageManager.h
//  CBWebImage
//
//  Created by yyjim on 12/9/24.
//  Copyright (c) 2012年 cardinalblue. All rights reserved.
//

#import "CBWebImage.h"
#import "CBWebImageCompat.h"
#import "CBWebImageUtils.h"

// =============================================================================

@class CBWebImageManager;

@protocol CBWebImageManagerProgressDelegate <NSObject>

@optional
- (void)webImageManager:(CBWebImageManager *)imageManager
       downloadImageURL:(NSURL *)url
             inProgress:(CGFloat)progress;
@end

@protocol CBWebImageManagerDelegate <NSObject>

@optional
- (void)webImageManager:(CBWebImageManager *)imageManager
     didFinishWithImage:(UIImage *)image
                 forURL:(NSURL *)url;
@end

// =============================================================================

@interface CBWebImageManager : NSObject
CBW_SINGLETON_DEFAULT_INTERFACE(CBWebImageManager);

@property (nonatomic, assign) BOOL enableCaching;
/*
 The filter is a block used to decide the url's image should write into cache or not.
*/
typedef BOOL(^CBWebImageCacheFilter)(NSURL *url);
@property (nonatomic, copy) CBWebImageCacheFilter diskCacheFilter;
@property (nonatomic, copy) CBWebImageCacheFilter memoryCacheFilter;

// The completionBlock will be call on main thread.
- (void)downloadWithURL:(NSURL *)url
              forTarget:(id)target
                options:(CBWebImageOptions)options
        completionBlock:(CBWebImageCompletionBlock)block;

- (void)cancelDownloadOperationForTarget:(id)target;

@end

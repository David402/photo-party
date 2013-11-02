//
//  CBWebImageMemcachedDonwloadClient.h
//  CBWebImage
//
//  Created by yyjim on 5/28/13.
//  Copyright (c) 2013 cardinalblue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBWebImage.h"
#import "CBWebImageDownloadClientBase.h"

@interface CBWebImageCacheDownloadClient : CBWebImageDownloadClientBase
@property (nonatomic, retain) CBImageCache *imageCache;

- (id)initWithURL:(NSURL *)url
       imageCache:(CBImageCache *)imageCache
           target:(id)target
         delegate:(id<CBWebImageDownloadClientDelegate>)delegate;

- (void)startWithCompletionBlock:(void (^)(UIImage *image))block;
@end

@interface CBImageCache (CBWebImageCacheDownloadClient)
// This method will return nil if there is no cached image.
- (CBWebImageCacheDownloadClient *)downloadImageWithURL:(NSURL *)url
                                                 target:(id)target
                                               delegate:(id<CBWebImageDownloadClientDelegate>)delegate;
@end


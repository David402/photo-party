//
//  CBWebImage.h
//  CBWebImage
//
//  Created by yyjim on 12/9/24.
//  Copyright (c) 2012年 cardinalblue. All rights reserved.
//

typedef void(^CBWebImageCompletionBlock)(UIImage *image, NSError *error);

typedef enum {
    CBWebImageOptionsDefault      = 0,
    CBWebImageOptionsIgnoreCache  = 1 << 0, // It will read image from the source.
    CBWebImageOptionsDontCache    = 1 << 1, // The image won't write into memory/disk cache.
} CBWebImageOptions;

#import "CBWebImageManager.h"
#import "CBImageCache.h"
#import "CBProgressImageView.h"
#import "UIImageView+CBWebImage.h"
#import "UIImageView+CBWebImageAnimation.h"
#import "UIImage+GIF.h"


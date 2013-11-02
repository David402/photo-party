//
//  UIImageView+CBWebImage.h
//  CBWebImage
//
//  Created by yyjim on 12/9/24.
//  Copyright (c) 2012年 cardinalblue. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CBWebImageManager.h"

@interface UIImageView (CBWebImage)

/*
 * @param options The options to use when downloading the image. @see CBWebImageOptions for the possible values.
 */


- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url
        completionBlock:(CBWebImageCompletionBlock)block;
- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholder
                options:(CBWebImageOptions)options
        completionBlock:(CBWebImageCompletionBlock)block;

- (void)cancelImageDownload;

@end

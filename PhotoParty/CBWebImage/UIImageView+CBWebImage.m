//
//  UIImageView+CBWebImage.m
//  CBWebImage
//
//  Created by yyjim on 12/9/24.
//  Copyright (c) 2012年 cardinalblue. All rights reserved.
//

#import "UIImageView+CBWebImage.h"


@interface UIImageView ()
    <CBWebImageManagerProgressDelegate>
@end

@implementation UIImageView (CBWebImage)

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholder
                options:(CBWebImageOptions)options
        completionBlock:(CBWebImageCompletionBlock)block
{
    [self cancelImageDownload];
    
    self.image = placeholder;
    [self downloadImageFromURL:url options:options completionBlock:block];
}

- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url
          completionBlock:nil];
}
- (void)setImageWithURL:(NSURL *)url
        completionBlock:(CBWebImageCompletionBlock)block
{
    [self setImageWithURL:url
         placeholderImage:self.image
                  options:CBWebImageOptionsDefault
          completionBlock:block];
}

- (void)cancelImageDownload
{
    [[CBWebImageManager shared] cancelDownloadOperationForTarget:self];
}

#pragma mark - Private

- (void)downloadImageFromURL:(NSURL *)url
                     options:(CBWebImageOptions)options
             completionBlock:(CBWebImageCompletionBlock)outwardCompletionBlock
{
    [[CBWebImageManager shared] downloadWithURL:url
                                      forTarget:self
                                        options:options
                                completionBlock:^(UIImage *image, NSError *error)
    {
         if (image)
             self.image = image;
         
         if (outwardCompletionBlock) {
             outwardCompletionBlock(image, error);
         }
     }];
}

@end

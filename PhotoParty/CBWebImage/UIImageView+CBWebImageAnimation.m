//
//  UIImageView+DownloadAnimations.m
//  PicCollage
//
//  Created by Tyler Barth on 2013-09-10.
//
//

#import "UIImageView+CBWebImageAnimation.h"

@implementation UIImageView (CBWebImageAnimation)

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
                options:(CBWebImageOptions)options
              animation:(CBWebImageViewAnimationOptions)animationOptions
        completionBlock:(CBWebImageCompletionBlock)completionBlock
{
    [self cancelImageDownload];

    // Look for it in the cache first
    if (animationOptions &
        CBWebImageViewAnimationOptionNoAnimationIfCacheHit) {
        
        UIImage *cacheImage = [[CBImageCache shared] readImageForURL:url];

        // If image is in the cache, don't animate and just show image immediately
        if (cacheImage) {
            placeholderImage = cacheImage;
            animationOptions = CBWebImageViewAnimationOptionTypeNone;
        }
    }

    // Set image and start download
    self.image = placeholderImage;

    [[CBWebImageManager shared] downloadWithURL:url
                                      forTarget:self
                                        options:options
                                completionBlock:^(UIImage *image, NSError *error) {
                                    [self performWithAnimation:animationOptions
                                                         image:image
                                                         error:error
                                               completionBlock:completionBlock];
                                }];
}

- (void)performWithAnimation:(CBWebImageViewAnimationOptions)animationOptions
                        image:(UIImage *)image
                        error:(NSError *)error
              completionBlock:(CBWebImageCompletionBlock)completionBlock
{
    if (animationOptions & CBWebImageViewAnimationOptionTypeFadeIn) {
        [UIView transitionWithView:self
                          duration:0.2f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            if (image)
                                self.image = image;
                        } completion:^(BOOL finished) {
                            if (completionBlock) {
                                completionBlock(image, error);
                            }
                        }];
    }
    else {
        // Default
        if (image)
            self.image = image;
        if (completionBlock)
            completionBlock(image, error);
    }
}


@end

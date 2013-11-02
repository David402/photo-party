//
//  UIImageView+DownloadAnimations.h
//  PicCollage
//
//  Created by Tyler Barth on 2013-09-10.
//
//

#import <UIKit/UIKit.h>
#import "UIImageView+CBWebImage.h"

// Note: We should move to NS_OPTIONS when iOS6 is our lowest supported OS.
// http://nshipster.com/ns_enum-ns_options/
typedef enum {
    // Default behavior is to animate without checking cache
    // This option checks cache, and doesn't animate if there is a hit
    CBWebImageViewAnimationOptionNoAnimationIfCacheHit   = 1 << 0,
    // Reserved for future options, example:             = 1 << 1,
    
    CBWebImageViewAnimationOptionTypeNone                = 0 << 16, //default
    CBWebImageViewAnimationOptionTypeFadeIn              = 1 << 16,
    // Reserved for future animation, example:           = 2 << 16,
} CBWebImageViewAnimationOptions;

@interface UIImageView (CBWebImageAnimation)

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholder
                options:(CBWebImageOptions)options
              animation:(CBWebImageViewAnimationOptions)animationOptions
        completionBlock:(CBWebImageCompletionBlock)completionBlock;
@end

//
//  CBProgressImageView.m
//  CBWebImage
//
//  Created by yyjim on 12/9/25.
//  Copyright (c) 2012年 cardinalblue. All rights reserved.
//

#import "MBRoundProgressView.h"
#import "CBWebImageManager.h"
#import "CBProgressImageView.h"

@interface CBProgressImageView ()
    <CBWebImageManagerProgressDelegate>

@property (nonatomic, retain) MBRoundProgressView *progressView;
@end

@implementation CBProgressImageView

@synthesize progressView = _progressView;

- (MBRoundProgressView *)progressView
{
    if (!_progressView) {
        self.progressView = [[[MBRoundProgressView alloc] init] autorelease];
        [self.progressView setAnnular:YES];
        self.progressView.frame = CGRectMake(0, 0, 50, 50);
        self.progressView.center = CGPointMake(self.frame.size.width / 2,
                                               self.frame.size.height / 2 );
        [self addSubview:_progressView];
    }
    return _progressView;
}

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    
    if (image) {
        [self.progressView removeFromSuperview];
        self.progressView = nil;
    }
}

- (void)webImageManager:(CBWebImageManager *)imageManager
       downloadImageURL:(NSURL *)url inProgress:(CGFloat)progress
{
    self.progressView.progress = progress;
}

@end

//
//  UIImage+GIF.m
//  LBGIFImage
//
//  Created by Laurin Brandner on 06.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  Reference SDWebImage

#import "UIImage+GIF.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ImageIO/ImageIO.h>

@implementation UIImage (GIF)

+ (BOOL)isGIFData:(NSData *)data
{
    if ([data length] > 3) {
        unsigned char buffer[3];
        [data getBytes:&buffer length:3];
        if (buffer[0] == 0x47 && // G
            buffer[1] == 0x49 && // I
            buffer[2] == 0x46) { // F
            return YES;
        }
    }
    return NO;
}

+ (UIImage *)cb_imageWithData:(NSData *)data
{
    if ([self isGIFData:data]) {
        return [self cb_animatedGIFWithData:data];
    }
    return [self imageWithData:data];
}

+ (UIImage *)cb_animatedGIFWithData:(NSData *)data
{
    if (!data)
        return nil;
    
    if (![self isGIFData:data])
        return nil;
    
#if __has_feature(objc_arc)
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
#else
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
#endif
    size_t count = CGImageSourceGetCount(source);
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:count];
    NSTimeInterval duration = 0.0f;
    for (size_t i = 0; i < count; i++)
    {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
        
        NSDictionary *frameProperties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, i, NULL));
        NSDictionary *gifProperties = [frameProperties objectForKey:(NSString *)kCGImagePropertyGIFDictionary];
        NSNumber *delayTime = [gifProperties objectForKey:(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTime)
            duration += [delayTime doubleValue];
        
        UIImage *image = [self imageWithCGImage:imageRef];
        if (image)
            [images addObject:image];
        
        CGImageRelease(imageRef);
    }
    CFRelease(source);
    
    if (!duration)
        duration = (1.0f/10.0f)*count;
    
    return [self animatedImageWithImages:images duration:duration];
}

+ (UIImage *)cb_animatedGIFNamed:(NSString *)name
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:nil];
    // Retina
    if ([UIScreen mainScreen].scale > 1.0f) {
        NSString *retinaPath =
        [path stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", [name pathExtension]]
                                        withString:[NSString stringWithFormat:@"@2x.%@", [name pathExtension]]];
        NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
        if ([fm fileExistsAtPath:retinaPath]) {
            return [self cb_imageWithContentsOfFile:retinaPath];
        }
    }
    // else
    return [self cb_imageWithContentsOfFile:path];
}

+ (UIImage *)cb_imageWithContentsOfFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data && [self isGIFData:data])
        return [self cb_animatedGIFWithData:data];
    // else
    return [self imageWithData:data];
}

- (UIImage *)cb_animatedImageByScalingAndCroppingToSize:(CGSize)size
{
    if (CGSizeEqualToSize(self.size, size) || CGSizeEqualToSize(size, CGSizeZero))
    {
        return self;
    }
    
    CGSize scaledSize = size;
    CGPoint thumbnailPoint = CGPointZero;
    
    CGFloat widthFactor = size.width / self.size.width;
    CGFloat heightFactor = size.height / self.size.height;
    CGFloat scaleFactor = (widthFactor > heightFactor) ? widthFactor :heightFactor;
    scaledSize.width = self.size.width * scaleFactor;
    scaledSize.height = self.size.height * scaleFactor;
    
    if (widthFactor > heightFactor)
    {
        thumbnailPoint.y = (size.height - scaledSize.height) * 0.5;
    }
    else if (widthFactor < heightFactor)
    {
        thumbnailPoint.x = (size.width - scaledSize.width) * 0.5;
    }
    
    NSMutableArray *scaledImages = [NSMutableArray array];
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    for (UIImage *image in self.images)
    {
        [image drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledSize.width, scaledSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        [scaledImages addObject:newImage];
    }
    
    UIGraphicsEndImageContext();
	
	return [UIImage animatedImageWithImages:scaledImages duration:self.duration];
}

- (NSData *)cb_animatedGIFData
{
    NSInteger count = 1;
    NSArray *images = [NSArray arrayWithObject:self];
    NSTimeInterval duration = 0;
    if (self.images) {
        images = self.images;
        count = [self.images count];
        duration = self.duration;
    }
    
    // It's animated image
    // 1. Create temp gif image.
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    NSString *filename = [NSString stringWithFormat:@"temp_image_%f.gif", timestamp];
    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef)tempFileURL, kUTTypeGIF,
                                                                        count, NULL);
    // GIF properties
    NSDictionary *gifProperties = @{(NSString *)kCGImagePropertyGIFDictionary :
                                        @{(NSString *)kCGImagePropertyGIFLoopCount : @0}};
    CGImageDestinationSetProperties(destination, (CFDictionaryRef)gifProperties);
    
    // GIF frame properties
    NSNumber *delayTime = [NSNumber numberWithDouble:duration / count];
    NSDictionary *frameProperties = @{(NSString *)kCGImagePropertyGIFDictionary:
                                          @{(NSString *)kCGImagePropertyGIFDelayTime: delayTime}};
    for (UIImage *image in images) {
        CGImageDestinationAddImage(destination, image.CGImage, (CFDictionaryRef)frameProperties);
    }
    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    // 2. Get data from temp file
    return [NSData dataWithContentsOfURL:tempFileURL];
}

@end

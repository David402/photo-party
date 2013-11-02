//
//  UIImage+GIF.h
//  LBGIFImage
//
//  Created by Laurin Brandner on 06.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (GIF)

+ (BOOL)isGIFData:(NSData *)data;
+ (UIImage *)cb_imageWithData:(NSData *)data;
+ (UIImage *)cb_animatedGIFNamed:(NSString *)name;
+ (UIImage *)cb_animatedGIFWithData:(NSData *)data;
- (UIImage *)cb_animatedImageByScalingAndCroppingToSize:(CGSize)size;
- (NSData *)cb_animatedGIFData;

@end

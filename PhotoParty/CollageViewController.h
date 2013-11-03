//
//  CollageViewController.h
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const kSourceUrl;
extern NSString* const kTransmitterURL;

@interface CollageViewController : UIViewController

@property (nonatomic, retain) NSMutableArray *images;
@property (nonatomic, assign) NSInteger totalImageSize;

- (void)addImage:(UIImage *)image;

@end

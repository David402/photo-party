//
//  CollageViewController.h
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollageViewController : UIViewController

@property (nonatomic, retain) NSMutableArray *images;

- (void)addImage:(UIImage *)image;

@end

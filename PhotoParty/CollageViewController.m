//
//  CollageViewController.m
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import "CollageViewController.h"

@interface CollageViewController ()

@end

@implementation CollageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.images = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addImage:(UIImage *)image
{
    // Add image to collection
    [self.images addObject:image];
    
    // Arrange image to collage
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    float ratio = image.size.width / image.size.height;
    imageView.frame = CGRectMake(100, 100, 200*ratio, 200);
    [self.view addSubview:imageView];
}
@end

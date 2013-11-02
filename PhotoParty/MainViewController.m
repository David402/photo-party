//
//  MainViewController.m
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

UITextField *actionCodeTextField;
UITextField *actionNumberTextField;

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDictionary* textAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                               forKey:UITextAttributeTextColor];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes: textAttributes
                                                forState: UIControlStateNormal];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(-400, 44) forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

    
	// Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor colorWithRed:26.0/255 green:26.0/255 blue:26.0/255 alpha:1];
    UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"im_logo_nav.png"]];
    CGPoint center = view.center;
    center.x = self.view.frame.size.width / 2.0f;
    view.center = center;
    view.tag = 100;
    
    [self.navigationController.navigationBar addSubview:view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

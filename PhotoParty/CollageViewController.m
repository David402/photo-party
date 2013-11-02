//
//  CollageViewController.m
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import "CollageViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "TRVSEventSource.h"
#import "CBWebImage.h"

#define HOST @"http://geochat-awaw.rhcloud.com"
#define IMAGE_VIEW_HEIGHT 200

NSString* const kSourceUrl = HOST @"/yahoo/source";
NSString* const kTransmitterURL = HOST @"/yahoo/transmitter";

@interface CollageViewController ()
<
    TRVSEventSourceDelegate
>
@property (nonatomic, strong) TRVSEventSource* eventSource;


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

- (void)viewDidAppear:(BOOL)animated
{
    [self openEventSource];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self closeEventSource];
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
    float scale = [self calculateScale:image];
    CGRect frame = imageView.frame;
    frame.size = CGSizeMake(image.size.width * scale, image.size.height * scale);
    float x = self.view.frame.size.width / 2;
    float y = self.view.frame.size.height / 2;
    imageView.frame = frame;
    imageView.center = CGPointMake(x, y);
    [self.view addSubview:[self updateShadow:imageView]];
}

- (void)addImageWithUrl:(NSString *)urlString
{
    NSLog(@"addImageWithUrl url: %@", urlString);
    if ([urlString isEqualToString:@""])
        return;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    __weak UIImageView *weakImageView = imageView;
    __weak UIView *thisView = self.view;
    [imageView setImageWithURL:[NSURL URLWithString:urlString]
               completionBlock:^(UIImage *image, NSError *error) {
                   if (!image)
                       return;
                   
                   // Adjsut all image view layout here
                   
                   float x = thisView.frame.size.width / 2;
                   float y = thisView.frame.size.height / 2;
                   float scale = [self calculateScale:image];
                   CGRect frame = weakImageView.frame;
                   frame.size = CGSizeMake(image.size.width * scale,
                                           image.size.height * scale);
                   weakImageView.frame = frame;
                   weakImageView.center = CGPointMake(
                        x + [self randomNegPos] * [self randomNumberInRangeMin:10 Max:200],
                        y + [self randomNegPos] * [self randomNumberInRangeMin:10 Max:200]);
                   
                   [self.view addSubview:[self updateShadow:weakImageView]];
    }];
}


# pragma mark - TRVEventSource Delegate

- (void)eventSourceDidOpen:(TRVSEventSource *)eventSource
{
    NSLog(@"opened");
    dispatch_async(dispatch_get_main_queue(), ^{
//        self.button.enabled = YES;
//        [self.button setTitle:@"Stop" forState:UIControlStateNormal];
    });
}

- (void)eventSourceDidClose:(TRVSEventSource *)eventSource
{
    NSLog(@"closed");
    dispatch_async(dispatch_get_main_queue(), ^{
//        self.button.enabled = YES;
//        [self.button setTitle:@"Start" forState:UIControlStateNormal];
    });
}

- (void)eventSource:(TRVSEventSource *)eventSource didReceiveEvent:(TRVSServerSentEvent *)event
{
    // NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:event.data options:0 error:NULL];
    if (!event.data) {
        return;
    }
    NSString *urlString = [[NSString alloc] initWithData:event.data encoding:NSUTF8StringEncoding];
    NSLog(@"received: %@", urlString);
    
    if (![urlString hasPrefix:@"http"])
        return;

    // Update image in UI thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self addImageWithUrl:urlString];
    });
}

- (void)eventSource:(TRVSEventSource *)eventSource didFailWithError:(NSError *)error
{
    [self closeEventSource];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network error"
                                                    message:[NSString stringWithFormat:@"%@", error]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)openEventSource
{
    if (!self.eventSource) {
        self.eventSource = [[TRVSEventSource alloc] initWithURL:[NSURL URLWithString:kSourceUrl] delegate:self];
    }
    
    NSError* err;
    [self.eventSource open:&err];
}

- (void)closeEventSource
{
    NSError* err;
    [self.eventSource close:&err];
    self.eventSource = nil;
}

- (double)randomNumberInRangeMin:(NSInteger)min Max:(NSInteger)max
{
    //create the random number.
    return (rand() % (max - min)) + min;
}

- (NSInteger)randomNegPos
{
    return ((rand() & 0x1) == 1) ? 1 : -1;
}

- (UIImageView *)updateShadow:(UIImageView *)imageView
{
    CALayer *layer = imageView.layer;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowRadius = 5;
    layer.shadowOpacity = 0.5;
    layer.shadowOffset = CGSizeMake(5, 5);
    
    // Setup the shadowPath
    layer.shadowPath = [UIBezierPath bezierPathWithRect:imageView.bounds].CGPath;
    
    return imageView;
}

- (float)calculateScale:(UIImage *)image
{
    float ratio = 1;
    if (image.size.height > image.size.width) {
        ratio = IMAGE_VIEW_HEIGHT / image.size.height;
    } else {
        ratio = IMAGE_VIEW_HEIGHT / image.size.width;
    }
    return ratio;
}
@end

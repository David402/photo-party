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
#import "Utils.h"

#define HOST @"http://geochat-awaw.rhcloud.com"
#define IMAGE_VIEW_HEIGHT 200

NSString* const kSourceUrl = HOST @"/yahoo/source";
NSString* const kTransmitterURL = HOST @"/yahoo/transmitter";

@interface CollageViewController ()
<
    TRVSEventSourceDelegate
>
@property (nonatomic, strong) TRVSEventSource* eventSource;
@property (nonatomic, copy) NSString *uploadedImageUrl;

@property (nonatomic, retain) NSMutableArray *imageViews;

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
        self.imageViews = [NSMutableArray array];
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
    // Async Upload image
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *urlString = [Utils upload_to_s3:image];
        if (!urlString) {
            NSLog(@"upload failed, url: %@", urlString);
            return ;
        }
        
        self.uploadedImageUrl = urlString;
        NSMutableURLRequest* req = [[NSMutableURLRequest alloc] init];
        [req setURL:[NSURL URLWithString:kTransmitterURL]];
        [req setHTTPMethod:@"POST"];
        [req setHTTPBody:[urlString dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLResponse* resp = nil;
        NSError* err = nil;
        NSData* respData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
        if (err) {
            NSLog(@"[Create Mission] upload image %@", err);
        } else {
            NSLog(@"[Create Mission] upload image %@", [NSString stringWithUTF8String:(char*)[respData bytes]]);
        }
    });
    
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
//    imageView.transform = [self randomRotationBetweenDegrees:30];
    [self.view addSubview:[self updateShadow:imageView]];
    
    [self.imageViews addObject:imageView];
}

- (void)addImageWithUrl:(NSString *)urlString
{
    NSLog(@"addImageWithUrl url: %@", urlString);
    if ([urlString isEqualToString:@""])
        return;
    
    // Skipped self-uploaded image
    if ([self.uploadedImageUrl isEqualToString:urlString])
        return;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    __weak UIImageView *weakImageView = imageView;
    __weak UIView *thisView = self.view;
    [imageView setImageWithURL:[NSURL URLWithString:urlString]
               completionBlock:^(UIImage *image, NSError *error) {
                   if (!image)
                       return;
                   
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
                   
//                   weakImageView.transform = [self randomRotationBetweenDegrees:30];
                   [self.view addSubview:[self updateShadow:weakImageView]];
                   
                   [self.imageViews addObject:weakImageView];
                   
                   // Adjsut all image view layout here
                   [self updateView];
    }];
}


# pragma mark - TRVEventSource Delegate

- (void)eventSourceDidOpen:(TRVSEventSource *)eventSource
{
    NSLog(@"opened");
}

- (void)eventSourceDidClose:(TRVSEventSource *)eventSource
{
    NSLog(@"closed");
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


# pragma mark - Utils

- (double)randomNumberInRangeMin:(NSInteger)min Max:(NSInteger)max
{
    if (min == max) return min;
    //create the random number.
    return (rand() % (max - min)) + min;
}

- (NSInteger)randomNegPos
{
    return ((rand() & 0x1) == 1) ? 1 : -1;
}

- (void)updateView
{
    NSArray *grids = [self randomGrid];
    int gridIndex = [self randomNumberInRangeMin:0 Max:grids.count-1];
    NSDictionary *gridDict = grids[gridIndex];
    NSMutableArray *slots = [NSMutableArray arrayWithArray:[gridDict valueForKey:@"slots"]];
    for (UIImageView *imageView in self.imageViews) {
        int slotIndex = [self randomNumberInRangeMin:0 Max:slots.count-1];
        CGRect slotRect = [self rectFromSlot:slots[slotIndex]];
        [self fillRect:slotRect withImageView:imageView];
        [slots removeObjectAtIndex:slotIndex];
    }
}

- (void)fillRect:(CGRect)rect withImageView:(UIImageView *)imageView
{
    CGFloat sizeFudge = 7;
    CGSize slotSize = rect.size;
    CGFloat scaling = 1;    // Default
    CGSize imageViewSize = imageView.frame.size;
    if (MIN(imageViewSize.width, imageViewSize.height) >= 1) {
        scaling = MAX((rect.size.width  + sizeFudge) / imageViewSize.width,
                      (rect.size.height + sizeFudge) / imageViewSize.height);
    }
    CGAffineTransform transform = CGAffineTransformScale(imageView.transform, scaling, scaling);
    
    // Figure out position (centered)
    CGPoint slotOrigin = rect.origin;
    CGPoint slotCenter = CGPointMake(slotOrigin.x + slotSize.width / 2,
                                     slotOrigin.y + slotSize.height / 2);
    
    // Do animation
    [UIView animateWithDuration:0.5 animations:^{
        
        // Place into slot
        imageView.center = slotCenter;
        imageView.transform = transform;
        
    } completion:^(BOOL finished) {
        
        // Re-setup the view
//        [self setupView];
        NSLog(@"fillRect completed");
    }];
}

- (CGRect)rectFromSlot:(NSDictionary *)slotDict
{
    if ([slotDict isKindOfClass:[NSString class]]) {
        return CGRectFromString((NSString *)slotDict);
    } else {
        NSDictionary *originDict = [slotDict valueForKeyPath:@"rect.origin"];
        NSDictionary *sizeDict = [slotDict valueForKeyPath:@"rect.size"];
        return CGRectMake(self.view.frame.size.width * [[originDict valueForKey:@"x"] floatValue],
                          self.view.frame.size.height * [[originDict valueForKey:@"y"] floatValue],
                          self.view.frame.size.width * [[sizeDict valueForKey:@"width"] floatValue],
                          self.view.frame.size.height * [[sizeDict valueForKey:@"height"] floatValue]);
    }
}

- (NSArray *)randomGrid
{
    int count = self.imageViews.count;
    NSString *filename = [NSString stringWithFormat:@"Grids%d%@", count, @".plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:
                          [[NSBundle mainBundle] pathForResource:filename
                                                          ofType:nil]];
    NSArray *grids = [dict valueForKey:@"grids"];
    return grids;
}

- (UIImageView *)updateShadow:(UIImageView *)imageView
{
    CALayer *layer = imageView.layer;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowRadius = 5;
    layer.shadowOpacity = 0.5;
    layer.shadowOffset = CGSizeMake(5, 5);
    
    layer.borderColor = [UIColor whiteColor].CGColor;
    layer.borderWidth = 5;
    
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

- (CGAffineTransform)randomRotationBetweenDegrees:(int)degrees
{
    int rotationDeg = (arc4random() % degrees) - (degrees / 2);
    float rotationRad = (rotationDeg / 180.0f) * M_PI;
    return CGAffineTransformMakeRotation(rotationRad);
    
}

@end

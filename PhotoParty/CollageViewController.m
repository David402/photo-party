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
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
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
    [super viewDidAppear:animated];
    [self openEventSource];
    
//    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:NO];
//    [[UIApplication sharedApplication] setStatusBarHidden:![[UIApplication sharedApplication] isStatusBarHidden] withAnimation:UIStatusBarAnimationNone];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:![[UIApplication sharedApplication] isStatusBarHidden] withAnimation:UIStatusBarAnimationNone];
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

// Self-captured image
//
- (void)addImage:(UIImage *)image
{
    // Async Upload image
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *urlString = [Utils upload_to_s3:image];
        if (!urlString) {
            NSLog(@"upload failed, url: %@", urlString);
            return ;
        }
        
        // Remember our own image
        self.uploadedImageUrl = urlString;
        
        // Send image URL
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
    
    // Add imageView
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;

    // Insert imageView
    [self.view addSubview:[self updateShadow:imageView]];
    [self.imageViews addObject:imageView];
    [self updateView];
}

// Incoming server image
//
- (void)addImageWithUrl:(NSString *)urlString
{
    NSLog(@"addImageWithUrl url: %@", urlString);
    if ([urlString isEqualToString:@""])
        return;
    
    // Skipped self-uploaded image
    if ([self.uploadedImageUrl isEqualToString:urlString])
        return;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    __weak UIImageView *_imageView = imageView;
    [imageView setImageWithURL:[NSURL URLWithString:urlString]
               completionBlock:^(UIImage *image, NSError *error) {
                   if (!image)
                       return;
                   
                   // Add image to collection
                   [self.images addObject:image];

                   // Insert imageView
                   [self.view addSubview:[self updateShadow:_imageView]];
                   [self.imageViews addObject:_imageView];
                   [self updateView];
               }
     ];
}


- (IBAction)cameraButtonPressed:(id)sender
{
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}

# pragma mark - UIView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:![[UIApplication sharedApplication] isStatusBarHidden] withAnimation:UIStatusBarAnimationFade];
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
        if (self.images.count < self.totalImageSize)
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

#pragma mark - Collage view

- (void)updateView
{
    NSMutableArray *slots = [NSMutableArray arrayWithArray:[self generateSlots:self.imageViews.count]];
    for (UIImageView *imageView in self.imageViews) {
        
        int slotIndex = [self randomNumberInRangeMin:0 max:slots.count-1];
        CGRect slotRect = [slots[slotIndex] CGRectValue];
        [self fillRect:slotRect withImageView:imageView];
        
        [slots removeObjectAtIndex:slotIndex];
    }
    
    // Check added image size
    if (self.totalImageSize == self.images.count) {
        NSLog(@"---------------------");
        [self handleMissionCompleted];
    }
}

- (void)fillRect:(CGRect)rect withImageView:(UIImageView *)imageView
{
    // Do animation
    [UIView animateWithDuration:0.5 animations:^{
        
        // Place into slot
        imageView.frame = rect;
        
    } completion:^(BOOL finished) {
    }];
}

# pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Get the image out
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (!image)
        return;
    
    [self addImage:image];
    
    // Dismiss Camera
    [self dismissViewControllerAnimated:YES completion:nil];
}


# pragma mark - Utils

// min/max are INCLUSIVE
- (double)randomNumberInRangeMin:(NSInteger)min max:(NSInteger)max
{
    if (min == max) return min;
    return (rand() % (max - min + 1)) + min;
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

- (void)handleMissionCompleted
{
    UIImage *image = [UIImage imageNamed:@"MissionAccomplished.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.alpha = 0;
    float scale = 2 * self.view.frame.size.width / imageView.frame.size.width;
    CGRect frame = imageView.frame;
    frame.size.width *= scale;
    frame.size.height *= scale;
    imageView.frame = frame;
    imageView.center = self.view.center;
    [self.view addSubview:imageView];
    
    __weak UIImageView *weakView = imageView;
    [UIView animateWithDuration:1.0 animations:^{
        weakView.alpha = 1.0;
        CGRect frame = imageView.frame;
        frame.size.width *= 0.375;
        frame.size.height *= 0.375;
        weakView.frame = frame;
        weakView.center = self.view.center;
    } completion:^(BOOL finished) {
        UIGraphicsBeginImageContext(CGSizeMake(320,480));
        CGContextRef context = UIGraphicsGetCurrentContext();
        [self.view.layer renderInContext:context];
        UIImage *screenShot = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext();
        [self shareToFlickrWithImage:screenShot];
    }];
}

- (void)shareToFlickrWithImage:(UIImage *)image
{
    UIImage *shareImage = image;
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareImage, [NSString stringWithFormat:@"#%@", self.actionCode], nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeSaveToCameraRoll, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeMessage, UIActivityTypeAirDrop];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
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

#pragma mark - Grids

- (NSArray *)generateSlots:(NSInteger)numSlots
{
    NSArray *slots = @[ [NSValue valueWithCGRect:self.view.bounds] ];
    while (slots.count < numSlots) {
        slots = [self growSlots:slots];
    }
    return slots;
}
- (NSArray *)growSlots:(NSArray *)_slots
{
    NSMutableArray *slots = [NSMutableArray arrayWithArray:_slots];
    
    // Find biggest slot
    NSInteger maxIndex = -1;
    CGFloat   maxDim = 0;
    BOOL      maxIsWidth;
    for (NSInteger i=0; i<slots.count; i++) {
        CGRect rect = [[slots objectAtIndex:i] CGRectValue];
        if (rect.size.width > maxDim) {
            maxIndex = i;
            maxDim = rect.size.width;
            maxIsWidth = YES;
        }
        if (rect.size.height > maxDim) {
            maxIndex = i;
            maxDim = rect.size.height;
            maxIsWidth = NO;
        }
    }
    
    assert(maxIndex != -1);
    

    CGRect oldR = [[slots objectAtIndex:maxIndex] CGRectValue];
    CGRect newR = oldR;
    if (maxIsWidth) {
        CGFloat modWidth = randomSplit(oldR.size.width, oldR.size.width / 4, 3);
        newR.size.width = oldR.size.width - modWidth;
        oldR.size.width = modWidth;
        newR.origin.x += modWidth;
    }
    else {
        CGFloat modHeight = randomSplit(oldR.size.height, oldR.size.height / 4, 3);
        newR.size.height = oldR.size.height - modHeight;
        oldR.size.height = modHeight;
        newR.origin.y += modHeight;
    }
    [slots replaceObjectAtIndex:maxIndex withObject:[NSValue valueWithCGRect:oldR]];
    [slots addObject:[NSValue valueWithCGRect:newR]];

    return slots;
}


static CGFloat randomSpread(NSUInteger randomFactor)
{
    if (randomFactor == 0)
        return 0.5;
    CGFloat ret = 0;
    const NSUInteger RANDOM_RESOLUTION = 1024;
    for (NSUInteger i=0; i<randomFactor; i++)
        ret += (CGFloat)(arc4random() % RANDOM_RESOLUTION) / RANDOM_RESOLUTION;
    ret /= randomFactor;
    return ret;
}
static CGFloat randomSplit(CGFloat x, CGFloat min, NSUInteger randomFactor)
{
    CGFloat range = x - (min * 2);
    if (range <= 0)
        return x / 2;
    return min + range * randomSpread(randomFactor);
}


@end

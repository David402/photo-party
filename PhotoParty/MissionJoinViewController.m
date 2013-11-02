//
//  MissionJoinViewController.m
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import "MissionJoinViewController.h"
#import "CollageViewController.h"

#import "Utils.h"

@interface MissionJoinViewController ()
<
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate
>
@property (weak, nonatomic) IBOutlet UITextField *actionCodeTextField;
@property (nonatomic, retain) UIImage *capturedImage;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@end

@implementation MissionJoinViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.actionCodeTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)joinButtionPressed:(id)sender
{
    if ([self.actionCodeTextField.text isEqual:@""]) {
        return;
    }
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}


# pragma mark - UIView delegate

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Dismiss keyboard
    [self.actionCodeTextField resignFirstResponder];
}


# pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Get the image out
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.capturedImage = image;
    
    // Async Upload image
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *urlString = [Utils upload_to_s3:image];
        
        NSMutableURLRequest* req = [[NSMutableURLRequest alloc] init];
        [req setURL:[NSURL URLWithString:kTransmitterURL]];
        [req setHTTPMethod:@"POST"];
        [req setHTTPBody:[urlString dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLResponse* resp = nil;
        NSError* err = nil;
        NSData* respData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
        if (err) {
            NSLog(@"[Join Mission] upload image %@", err);
        } else {
            NSLog(@"[Join Mission] upload image %@", [NSString stringWithUTF8String:(char*)[respData bytes]]);
        }
        
    });
    
    // Show collage
    [self performSegueWithIdentifier:@"CameraToCollageSegue" sender:self];
    
    // Dismiss Camera
    [self dismissViewControllerAnimated:YES completion:nil];
}


# pragma mark - Actions

- (IBAction)actionCodeDidChange:(id)sender
{
    if (![self.actionCodeTextField.text isEqualToString:@""]) {
        self.actionButton.hidden = NO;
        self.actionButton.enabled = YES;
    }
}
- (IBAction)actionCodeChanged:(id)sender
{
    if (![self.actionCodeTextField.text isEqualToString:@""]) {
        self.actionButton.hidden = NO;
        self.actionButton.enabled = YES;
    }
}


#pragma mark - Storyboard control

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"CameraToCollageSegue"])
    {
        CollageViewController *vc = segue.destinationViewController;
        [vc addImage:self.capturedImage];
    }
}
@end

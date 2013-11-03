//
//  MissionCreateViewController.m
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import "MissionCreateViewController.h"
#import "CollageViewController.h"

#import "Utils.h"

@interface MissionCreateViewController ()
<
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate
>
@property (weak, nonatomic) IBOutlet UITextField *actionCodeTextField;
@property (weak, nonatomic) IBOutlet UITextField *actionNumberTextField;
@property (nonatomic, retain) UIImage *capturedImage;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@end

@implementation MissionCreateViewController

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
    
//    self.navigationItem.rightBarButtonItem = nil;
    self.actionButton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.actionCodeTextField becomeFirstResponder];
    
    [[self.navigationController.navigationBar viewWithTag:100] setHidden:YES];
    self.title = @"New Mission";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark - Actions

- (IBAction)createButtonPressed:(id)sender
{
    if ([self.actionNumberTextField.text isEqual:@""] ||
        [self.actionCodeTextField.text isEqual:@""]) {
        return;
    }
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:^{
        NSLog(@"capture photo finished!");
    }];
}


# pragma mark - UIView delegate

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self dismissKeyboard];
}


# pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Get the image out
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.capturedImage = image;
    
    // Show collage
    [self performSegueWithIdentifier:@"CameraToCollageSegue" sender:self];
    
    // Dismiss Camera
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)actionCodeTextDidChange:(id)sender
{
    if ([self validateTextFields]) {
        self.navigationItem.rightBarButtonItem = self.actionButton;
        self.actionButton.enabled = YES;
    }
    else {
//        self.navigationItem.rightBarButtonItem = nil;
        self.actionButton.enabled = NO;
    }
}
- (IBAction)actionCodeChanged:(id)sender
{
    if ([self validateTextFields]) {
        self.navigationItem.rightBarButtonItem = self.actionButton;
        self.actionButton.enabled = YES;
    }
    else {
//        self.navigationItem.rightBarButtonItem = nil;
        self.actionButton.enabled = NO;
    }
}

- (IBAction)actionNumberTextDidChange:(id)sender
{
    if ([self validateTextFields]) {
        self.navigationItem.rightBarButtonItem = self.actionButton;
        self.actionButton.enabled = YES;
    }
    else {
//        self.navigationItem.rightBarButtonItem = nil;
        self.actionButton.enabled = NO;
    }
}
- (IBAction)actionNumberChanged:(id)sender
{
    if ([self validateTextFields]) {
        self.navigationItem.rightBarButtonItem = self.actionButton;
        self.actionButton.enabled = YES;
    }
    else {
//        self.navigationItem.rightBarButtonItem = nil;
        self.actionButton.enabled = NO;
    }
}

- (BOOL)validateTextFields
{
    if ([self.actionNumberTextField.text isEqual:@""] ||
        [self.actionCodeTextField.text isEqual:@""]) {
        return NO;
    }
    return YES;
}

- (void)dismissKeyboard
{
    // Dismiss keyboard
    [self.actionCodeTextField resignFirstResponder];
    [self.actionNumberTextField resignFirstResponder];
}

#pragma mark - Storyboard control

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"CameraToCollageSegue"])
    {
        [self dismissKeyboard];
        
        CollageViewController *vc = segue.destinationViewController;
        [vc addImage:self.capturedImage];
        vc.totalImageSize = [self.actionNumberTextField.text integerValue];
    }
}
@end

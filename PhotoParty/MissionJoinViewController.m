//
//  MissionJoinViewController.m
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import "MissionJoinViewController.h"
#import "CollageViewController.h"

@interface MissionJoinViewController ()
<
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate
>
@property (weak, nonatomic) IBOutlet UITextField *actionCodeTextField;
@property (nonatomic, retain) UIImage *capturedImage;
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
    
    // Show collage
    [self performSegueWithIdentifier:@"CameraToCollageSegue" sender:self];
    
    // Dismiss Camera
    [self dismissViewControllerAnimated:YES completion:nil];
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

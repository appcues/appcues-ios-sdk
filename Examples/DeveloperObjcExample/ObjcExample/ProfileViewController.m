//
//  ProfileViewController.m
//  AppcuesObjcExample
//
//  Created by Matt on 2022-06-01.
//

#import "ProfileViewController.h"
#import "Appcues+Shared.h"
#import "SignInViewController.h"

@interface ProfileViewController ()
@property (weak, nonatomic) IBOutlet UITextField *givenNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *familyNameTextField;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[Appcues shared] screenWithTitle:@"Update Profile" properties:nil];
}

- (IBAction)saveButtonTapped:(UIButton *)sender {
    [self.view endEditing:YES];

    NSMutableDictionary<NSString *, NSString *> *properties = [NSMutableDictionary dictionary];

    if (_givenNameTextField.text != nil && _givenNameTextField.text.length != 0) {
        properties[@"givenName"] = _givenNameTextField.text;
    }

    if (_familyNameTextField.text != nil && _familyNameTextField.text.length != 0) {
        properties[@"familyName"] = _familyNameTextField.text;
    }


    [[Appcues shared] identifyWithUserID:currentUserID properties:properties];

    _givenNameTextField.text = nil;
    _familyNameTextField.text = nil;
}

@end

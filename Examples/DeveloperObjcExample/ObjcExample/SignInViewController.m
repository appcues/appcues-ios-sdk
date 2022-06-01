//
//  SignInViewController.m
//  AppcuesObjcExample
//
//  Created by Matt on 2022-06-01.
//

#import "SignInViewController.h"
#import "Appcues+Shared.h"

NSString *currentUserID = @"default-00000";

@interface SignInViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userIDTextField;

@end

@implementation SignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _userIDTextField.text = currentUserID;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[Appcues shared] screenWithTitle:@"Sign In" properties:nil];
}

- (IBAction)signInTapped:(UIButton *)sender {
    NSString *userID = _userIDTextField.text;

    [[Appcues shared] identifyWithUserID:userID properties:nil];

    currentUserID = userID;
}

- (IBAction)signOutAction:(UIStoryboardSegue *)unwindSegue {
    // Unwind to Sign In
    [[Appcues shared] reset];
}

- (IBAction)anonymousUserTapped:(UIButton *)sender {
    [[Appcues shared] anonymousWithProperties:nil];
}

@end

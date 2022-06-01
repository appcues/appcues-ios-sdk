//
//  GroupViewController.m
//  AppcuesObjcExample
//
//  Created by Matt on 2022-06-01.
//

#import "GroupViewController.h"
#import "Appcues+Shared.h"

@interface GroupViewController ()
@property (weak, nonatomic) IBOutlet UITextField *groupIDTextField;

@end

@implementation GroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[Appcues shared] screenWithTitle:@"Update Group" properties:nil];
}

- (IBAction)saveGroupTapped:(UIButton *)sender {
    [self.view endEditing:YES];
    [[Appcues shared] groupWithGroupID: _groupIDTextField.text properties:@{@"test_user":@YES}];
}

@end

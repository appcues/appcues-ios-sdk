//
//  EventsViewController.m
//  AppcuesObjcExample
//
//  Created by Matt on 2022-06-01.
//

#import "EventsViewController.h"
#import "Appcues+Shared.h"

@interface EventsViewController ()

@end

@implementation EventsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[Appcues shared] screenWithTitle:@"Trigger Events" properties:nil];
}

- (IBAction)buttonOneTapped:(UIButton *)sender {
    [[Appcues shared] trackWithName:@"event1" properties:nil];
}

- (IBAction)buttonTwoTapped:(UIButton *)sender {
    [[Appcues shared] trackWithName:@"event2" properties:nil];
}

- (IBAction)debugTapped:(UIBarButtonItem *)sender {
    [[Appcues shared] debug];
}

@end

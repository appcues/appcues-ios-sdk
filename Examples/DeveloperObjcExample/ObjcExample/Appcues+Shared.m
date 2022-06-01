//
//  Appcues+Shared.m
//  AppcuesObjcExample
//
//  Created by Matt on 2022-06-01.
//

#import "Appcues+Shared.h"

static Appcues *sharedInstance = nil;

@implementation Appcues (Shared)

+ (Appcues *)shared
{
    if (sharedInstance == nil) {
        Config *config = [[Config alloc] initWithAccountID:<#APPCUES_ACCOUNT_ID#> applicationID:<#APPCUES_APPLICATION_ID#>];
        
        sharedInstance = [[Appcues alloc] initWithConfig:config];
    }

    return sharedInstance;
}
@end

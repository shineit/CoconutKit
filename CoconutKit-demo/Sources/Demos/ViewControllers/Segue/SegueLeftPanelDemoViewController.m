//
//  SegueLeftPanelDemoViewController.m
//  CoconutKit-demo
//
//  Created by Samuel Défago on 02.07.12.
//  Copyright (c) 2012 Hortis. All rights reserved.
//

#import "SegueLeftPanelDemoViewController.h"

@implementation SegueLeftPanelDemoViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor randomColor];
}

#pragma mark Localization

- (void)localize
{
    [super localize];
    
    // Just to suppress localization warnings
}

#pragma mark Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue isKindOfClass:[HLSPlaceholderInsetSegue class]]) {
        HLSPlaceholderInsetSegue *placeholderInsetSegue = (HLSPlaceholderInsetSegue *)segue;
        placeholderInsetSegue.index = 1;
        if ([placeholderInsetSegue.identifier isEqualToString:@"firstPanel"]) {
            placeholderInsetSegue.transitionClass = [HLSTransitionCrossDissolve class];
        }
        else if ([placeholderInsetSegue.identifier isEqualToString:@"secondPanel"]) {
            placeholderInsetSegue.transitionClass = [HLSTransitionCoverFromRight class];
        }
    }
}

@end

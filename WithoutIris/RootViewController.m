//
//  RootViewController.m
//  WithoutIris
//
//  Created by Sacchy on 2013/10/28.
//  Copyright (c) 2013年 sacchy. All rights reserved.
//

#import "RootViewController.h"
#import "AppMacro.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (id)initWithFrame:(CGRect)frame
{
    self   = [super init];
    if (self)
    {
        //タップイベントを検知
        self.view.userInteractionEnabled = NO;
        
        UIImage *splashImage;
        if([[UIScreen mainScreen]bounds].size.height == 568)
            splashImage = [UIImage imageNamed:@"Default-h568.png"];
        else
            splashImage = [UIImage imageNamed:@"Default.png"];
        
        UIImageView *splashImageView = [[UIImageView alloc] initWithImage:splashImage];
        splashImageView.frame = CGRectMake(0, 0, WIN_SIZE.width, WIN_SIZE.height);
        [self.view addSubview:splashImageView];
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        [UIView beginAnimations:nil context:context];
        [UIView setAnimationDuration:0.5f];
        [UIView setAnimationDelay:2.0f];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(buttonEnable)];
        
        splashImageView.alpha = 0.0f;
        [UIView commitAnimations];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)buttonEnable
{
    [[[self.view subviews] lastObject] removeFromSuperview];
    
    //タップイベントを検知
    self.view.userInteractionEnabled = YES;
    
}

@end

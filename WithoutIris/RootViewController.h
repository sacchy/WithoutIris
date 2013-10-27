//
//  RootViewController.h
//  WithoutIris
//
//  Created by Sacchy on 2013/10/28.
//  Copyright (c) 2013年 sacchy. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CameraViewController;

@interface RootViewController : UIViewController

- (void)buttonEnable;
- (id)initWithFrame:(CGRect)frame;

@property (strong, nonatomic) CameraViewController *cameraViewController;

@end

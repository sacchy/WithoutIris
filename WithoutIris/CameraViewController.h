//
//  CameraViewController.h
//  WithoutIris
//
//  Created by Sacchy on 2013/10/28.
//  Copyright (c) 2013年 sacchy. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

@class AVCamCaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer;

@interface CameraViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    UIView *view;
    CGRect bounds;
    CGRect viewframe;
    
    UIView *rootView;
    UIImageView *imageView;
    UIImagePickerController *imagePicker;
    
    //撮影後の画像表示用
    UIImage *pictImage;
    UIImage *saveImage;
    UIImageView *tempImageView;
}

@property (nonatomic,retain) AVCamCaptureManager *captureManager;
@property (nonatomic,retain) IBOutlet UIView *videoPreviewView;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *cameraToggleButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *recordButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *stillButton;
@property (nonatomic,retain) IBOutlet UILabel *focusModeLabel;

@end

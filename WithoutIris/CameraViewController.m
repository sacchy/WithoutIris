//
//  CameraViewController.m
//  WithoutIris
//
//  Created by Sacchy on 2013/10/28.
//  Copyright (c) 2013年 sacchy. All rights reserved.
//

#import "CameraViewController.h"
#import "AVCamCaptureManager.h"
#import "AVCamRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import "AppMacro.h"

static void *AVCamFocusModeObserverContext = &AVCamFocusModeObserverContext;

@interface CameraViewController () <UIGestureRecognizerDelegate>
@end

@interface CameraViewController (InternalMethods)
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)updateButtonStates;
@end

@interface CameraViewController (AVCamCaptureManagerDelegate) <AVCamCaptureManagerDelegate>
@end

@implementation CameraViewController
@synthesize captureManager, videoPreviewView, captureVideoPreviewLayer;
@synthesize cameraToggleButton, recordButton, stillButton, focusModeLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];

	if ([self captureManager] == nil)
    {
		AVCamCaptureManager *manager = [[AVCamCaptureManager alloc] init];
		[self setCaptureManager:manager];
        
        [[self captureManager] setDelegate:self];
        
		if ([[self captureManager] setupSession])
        {
            // Create video preview layer and add it to the UI
			AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[[self captureManager] session]];

            view = [self videoPreviewView];
			CALayer *viewLayer = [view layer];
			[viewLayer setMasksToBounds:YES];
            
            // Camera Window Size
            bounds = [view bounds];
			[newCaptureVideoPreviewLayer setFrame:bounds];
            
            // iOS6.0
            if ([newCaptureVideoPreviewLayer isOrientationSupported])
            {
				[newCaptureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
			}
            
            [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
			[viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
			[self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];

            // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[[[self captureManager] session] startRunning];
			});
            
            [self updateButtonStates];

            // Create the focus mode UI overlay
			UILabel *newFocusModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, viewLayer.bounds.size.width - 20, 20)];
			[newFocusModeLabel setBackgroundColor:[UIColor clearColor]];
			[newFocusModeLabel setTextColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.50]];
			AVCaptureFocusMode initialFocusMode = [[[captureManager videoInput] device] focusMode];
			[newFocusModeLabel setText:[NSString stringWithFormat:@"focus: %@", [self stringForFocusMode:initialFocusMode]]];
			//[view addSubview:newFocusModeLabel];
			
            [self addObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode" options:NSKeyValueObservingOptionNew context:AVCamFocusModeObserverContext];
			[self setFocusModeLabel:newFocusModeLabel];
            
            // Add a single tap gesture to focus on the point tapped, then lock focus
			UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
			[singleTap setDelegate:self];
			[singleTap setNumberOfTapsRequired:1];
			[view addGestureRecognizer:singleTap];
			
            // Add a double tap gesture to reset the focus mode to continuous auto focus
			UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
			[doubleTap setDelegate:self];
			[doubleTap setNumberOfTapsRequired:2];
			[singleTap requireGestureRecognizerToFail:doubleTap];
			[view addGestureRecognizer:doubleTap];
            
            /* ルートビュー */
            rootView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIN_SIZE.width, WIN_SIZE.height - 20)];
            rootView.backgroundColor = [UIColor clearColor];
            [self.view addSubview:rootView];
            
            tempImageView = [[UIImageView alloc] init];
            bounds.origin.y = bounds.origin.y + 74;
            tempImageView.frame = CGRectMake(0,74,320,320);
            [rootView addSubview:tempImageView];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)stringForFocusMode:(AVCaptureFocusMode)focusMode
{
	NSString *focusString = @"";
	
	switch (focusMode) {
		case AVCaptureFocusModeLocked:
			focusString = @"locked";
			break;
		case AVCaptureFocusModeAutoFocus:
			focusString = @"auto";
			break;
		case AVCaptureFocusModeContinuousAutoFocus:
			focusString = @"continuous";
			break;
	}
	
	return focusString;
}

#pragma mark - -カメラ-
- (void)Camera
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        NSLog(@"このデバイスではカメラを使用できません。");
        return;
    }
    
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.allowsEditing = NO;
    imagePicker.delegate = self;
    imagePicker.showsCameraControls = NO;
    imagePicker.view.userInteractionEnabled = YES;
    imagePicker.view.frame = CGRectMake(0, 0, WIN_SIZE.width, WIN_SIZE.height);
    [self.view addSubview:imagePicker.view];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    tempImageView.image = [info objectForKey:UIImagePickerControllerOriginalImage];

    [self dismissViewControllerAnimated:YES completion:nil];

}

- (void)targetImage:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
    if ( error )
    {
        NSLog(@"save error");
    }
    else
    {
        NSLog(@"save success");
    }
}

@end

@implementation CameraViewController (InternalMethods)

// Convert from view coordinates to camera coordinates, where {0,0} represents the top left of the picture area, and {1,1} represents
// the bottom right in landscape mode with the home button on the right.
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [[self videoPreviewView] frame].size;
    
    // iOS6.0
    if ([captureVideoPreviewLayer isMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    
    if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
		// Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[self captureManager] videoInput] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:[self videoPreviewView]];
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
        [captureManager autoFocusAtPoint:convertedFocusPoint];
    }
}

// Change to continuous auto focus. The camera will constantly focus at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported])
        [captureManager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

// Update button states based on the number of available cameras and mics
- (void)updateButtonStates
{
	NSUInteger cameraCount = [[self captureManager] cameraCount];
	NSUInteger micCount = [[self captureManager] micCount];
    
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        if (cameraCount < 2) {
            [[self cameraToggleButton] setEnabled:NO];
            
            if (cameraCount < 1) {
                [[self stillButton] setEnabled:NO];
                
                if (micCount < 1)
                    [[self recordButton] setEnabled:NO];
                else
                    [[self recordButton] setEnabled:YES];
            } else {
                [[self stillButton] setEnabled:YES];
                [[self recordButton] setEnabled:YES];
            }
        } else {
            [[self cameraToggleButton] setEnabled:YES];
            [[self stillButton] setEnabled:YES];
            [[self recordButton] setEnabled:YES];
        }
    });
}

@end

@implementation CameraViewController (AVCamCaptureManagerDelegate)

- (void)captureManager:(AVCamCaptureManager *)captureManager didFailWithError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title")
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

- (void)captureManagerRecordingBegan:(AVCamCaptureManager *)captureManager
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [[self recordButton] setTitle:NSLocalizedString(@"Stop", @"Toggle recording button stop title")];
        [[self recordButton] setEnabled:YES];
    });
}

- (void)captureManagerRecordingFinished:(AVCamCaptureManager *)captureManager
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [[self recordButton] setTitle:NSLocalizedString(@"Record", @"Toggle recording button record title")];
        [[self recordButton] setEnabled:YES];
    });
}

- (void)captureManagerStillImageCaptured:(AVCamCaptureManager *)captureManager
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        [[self stillButton] setEnabled:YES];
    });
}

- (void)captureManagerDeviceConfigurationChanged:(AVCamCaptureManager *)captureManager
{
	[self updateButtonStates];
    
}

@end



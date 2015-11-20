//
//  CCKCameraPreviewView.h
//  CCKCameraCore
//
//  Created by Tony on 11/21/15.
//  Copyright © 2015 tony. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface CCKCameraPreviewView : UIView

@property (nonatomic, strong) AVCaptureSession *session;

@end
//
//  CCKCameraPreviewView.m
//  CCKCameraCore
//
//  Created by Tony on 11/21/15.
//  Copyright © 2015 tony. All rights reserved.
//

@import AVFoundation;

#import "CCKCameraPreviewView.h"

@implementation CCKCameraPreviewView

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    return previewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    previewLayer.session = session;
}

@end

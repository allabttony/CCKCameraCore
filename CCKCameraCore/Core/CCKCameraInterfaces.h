//
//  CCKCameraInterfaces.h
//  CCKCameraCore
//
//  Created by Tony on 11/15/15.
//  Copyright © 2015 tony. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CCKCameraTypes.h"

@class CCKCamman;

@protocol CCKCameraDelegate;

@protocol CCKCameraInterfaces <NSObject>

/**
 *  The delegate of CCKCamera
 */

@property (nonatomic, weak) id<CCKCameraDelegate> delegate;

@property (nonatomic, readonly, getter=isSessionRunning) BOOL sessionRunning;

/**
 *  Get and set flashMode of the camera
 */
@property (nonatomic) CCKCameraFlashMode flashMode;

/**
 *  Get and set torchMode of the camera
 */
@property (nonatomic) CCKCameraTorchMode torchMode;

/**
 *  Get current device position
 */
@property (nonatomic, readonly) CCKCameraDevicePosition devicePosition;

- (instancetype)initCammanWithPreview:(UIView *)previewView;

- (void)startRunning;

- (void)stopRunning;

- (void)snap;

- (void)switchCameraDevicePosition;

#pragma mark - Adjust Configurations of Snapping Still Image

- (void)adjustFocusAndExposureAtPoint:(CGPoint)point;

- (void)adjustExposureBias:(float)bias;

/**
 *  Check whether flashMode is supported
 *
 *  @param flashMode
 *
 *  @return YES for supported, NO for not supported
 */
- (BOOL)isFlashModeAvailableForCurrentDevice:(CCKCameraFlashMode)flashMode;

/**
 *  Check whether torchMode is supported
 *
 *  @param torchMode
 *
 *  @return YES for supported, NO for not supported
 */
- (BOOL)isTorchModeAvailableForCurrentDevice:(CCKCameraTorchMode)torchMode;

@end

@protocol CCKCameraDelegate <NSObject>

@optional

#pragma mark - Snap

- (void)cammanWillSnapStillImage:(CCKCamman *)camman;
- (void)cammanSnappingStillImage:(CCKCamman *)camman;
- (void)camman:(CCKCamman *)camman didSnappedStillImage:(UIImage *)image;

#pragma mark - Flash, Torch, Device

- (void)camman:(CCKCamman *)camman didChangedFlashMode:(CCKCameraFlashMode)flashMode;
- (void)camman:(CCKCamman *)camman didChangedTorchMode:(CCKCameraTorchMode)torchMode;
- (void)camman:(CCKCamman *)camman didChangedDevicePosition:(CCKCameraDevicePosition)devicePosition;

#pragma mark - Focus, Exposure

- (void)cammanWillChangeFocus:(CCKCamman *)camman;
- (void)cammanDidChangedFocus:(CCKCamman *)camman;

- (void)cammanWillChangeExposure:(CCKCamman *)camman;
- (void)cammanDidChangedExposure:(CCKCamman *)camman;

#pragma mark - area

- (void)cammanAreaDidChange:(CCKCamman *)camman;

@end
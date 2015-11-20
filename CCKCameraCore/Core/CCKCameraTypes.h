//
//  CCKCameraTypes.h
//  CCKCameraCore
//
//  Created by Tony on 11/16/15.
//  Copyright © 2015 tony. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CCKCameraSetupResult) {
    CCKCameraSetupResultSuccess,
    CCKCameraSetupResultCameraNotAuthorized,
    CCKCameraSetupResultSessionConfigurationFailed
};

typedef NS_ENUM(NSInteger, CCKCameraFlashMode) {
    CCKCameraFlashModeOff,
    CCKCameraFlashModeOn,
    CCKCameraFlashModeAuto
};

typedef NS_ENUM(NSInteger, CCKCameraTorchMode) {
    CCKCameraTorchModeOff,
    CCKCameraTorchModeOn,
    CCKCameraTorchModeAuto
};

typedef NS_ENUM(NSInteger, CCKCameraDevicePosition) {
    CCKCameraDevicePositionUnsepcified,
    CCKCameraDevicePositionFront,
    CCKCameraDevicePositionBack
};

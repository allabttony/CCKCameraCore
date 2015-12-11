//
//  CCKCamman.m
//  CCKCameraCore
//
//  Created by Tony on 11/16/15.
//  Copyright © 2015 tony. All rights reserved.
//

@import AVFoundation;
@import Photos;

#import "CCKCamman.h"
#import "CCKCameraPreviewView.h"

static void * CCKCapturingStillImageContext = &CCKCapturingStillImageContext;
static void * CCKSessionRunningContext = &CCKSessionRunningContext;
static void * CCKAdjustingFocusContext = &CCKAdjustingFocusContext;
static void * CCKAdjustingExposureContext = &CCKAdjustingExposureContext;

static void * CCKFlashModeContext = &CCKFlashModeContext;
static void * CCKTorchModeContext = &CCKTorchModeContext;
static void * CCKDevicePositionContext = &CCKDevicePositionContext;

// not use temperarily
static void * CCKWhiteBalanceModeContext = &CCKWhiteBalanceModeContext;
static void * CCKLensPositionContext = &CCKLensPositionContext;
static void * CCKExposureDurationContext = &CCKExposureDurationContext;
static void * CCKISOContext = &CCKISOContext;
static void * CCKExposureTargetOffsetContext = &CCKExposureTargetOffsetContext;
static void * CCKDeviceWhiteBalanceGainsContext = &CCKDeviceWhiteBalanceGainsContext;
static void * CCKLensStabilizationContext = &CCKLensStabilizationContext;

@interface CCKCamman ()

@property (nonatomic, weak) CCKCameraPreviewView *previewView;

@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@property (nonatomic) CCKCameraSetupResult setupResult;

@property (nonatomic, readwrite) BOOL sessionRunning;

@end

@implementation CCKCamman

@synthesize delegate  = _delegate,
            flashMode = _flashMode,
            torchMode = _torchMode,
            sessionRunning = _sessionRunning;



- (instancetype)initCammanWithPreview:(CCKCameraPreviewView *)previewView
{
    if (!(self = [super init])) return nil;
    
    // session
    self.session = [[AVCaptureSession alloc] init];

    // preview
    self.previewView = previewView;
    self.previewView.session = self.session;
    
    // queue
    self.sessionQueue = dispatch_queue_create("cc.SessionQueue", DISPATCH_QUEUE_SERIAL);
    
    // result
    self.setupResult = CCKCameraSetupResultSuccess;
    
    // authorize
    [self _authorize];
    [self _setupCaptureSession];
    
    return self;
}

- (void)setDelegate:(id<CCKCameraDelegate>)delegate
{
    _delegate = delegate;
}

#pragma mark - Setup and Configurations

- (void)_authorize {
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized: {break;}
        case AVAuthorizationStatusNotDetermined:
        {
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    self.setupResult = CCKCameraSetupResultSessionConfigurationFailed ;
                }
                dispatch_resume( self.sessionQueue );
            }];
            break;
        }
        default:
        {
            self.setupResult = CCKCameraSetupResultCameraNotAuthorized;
            break;
        }
    }
}

- (void)_setupCaptureSession
{
    dispatch_async( self.sessionQueue, ^{
        if (self.setupResult != CCKCameraSetupResultSuccess) {
            return;
        }
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [self _deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        
        
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if (!videoDeviceInput) {
            NSLog( @"Could not create video device input: %@", error );
        }
        
        [self.session beginConfiguration];
        
        if ( [self.session canAddInput:videoDeviceInput] ) {
            [self.session addInput:videoDeviceInput];
            self.videoDeviceInput = videoDeviceInput;
            self.videoDevice = videoDevice;
    
            dispatch_async( dispatch_get_main_queue(), ^{
                // Why are we dispatching this to the main queue?
                // Because AVCaptureVideoPreviewLayer is the backing layer for AAPLPreviewView and UIView
                // can only be manipulated on the main thread.
                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                // on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                
                // Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
                // -[viewWillTransitionToSize:withTransitionCoordinator:].
                UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                    initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                }
                
                AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
                previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                previewLayer.connection.videoOrientation = initialVideoOrientation;
            } );
        }
        else {
            NSLog( @"Could not add video device input to the session" );
            self.setupResult = CCKCameraSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ( [self.session canAddOutput:stillImageOutput] ) {
            [self.session addOutput:stillImageOutput];
            self.stillImageOutput = stillImageOutput;
            self.stillImageOutput.outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG };
            self.stillImageOutput.highResolutionStillImageOutputEnabled = YES;
        }
        else {
            NSLog( @"Could not add still image output to the session" );
            self.setupResult = CCKCameraSetupResultSessionConfigurationFailed;
        }
        
        [self.session commitConfiguration];
    } );
}

#pragma mark - KVO and NSNotifications

- (void)addObservers {
    [self addObserver:self forKeyPath:@"session.running" options:NSKeyValueObservingOptionNew context:CCKSessionRunningContext];
    [self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:NSKeyValueObservingOptionNew context:CCKCapturingStillImageContext];
    
    [self addObserver:self forKeyPath:@"videoDevice.adjustingFocus" options:NSKeyValueObservingOptionNew context:CCKAdjustingFocusContext];
    [self addObserver:self forKeyPath:@"videoDevice.adjustingExposure" options:NSKeyValueObservingOptionNew context:CCKAdjustingExposureContext];
    
    [self addObserver:self forKeyPath:@"videoDevice.flashMode" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CCKFlashModeContext];
    [self addObserver:self forKeyPath:@"videoDevice.torchMode" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CCKTorchModeContext];
    [self addObserver:self forKeyPath:@"videoDevice.position" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CCKDevicePositionContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDevice];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    // A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
    // see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
    // and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
    // interruption reasons.
    //[[symotion-sn)NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}

- (void)removeObservers {
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self removeObserver:self forKeyPath:@"session.running" context:CCKSessionRunningContext];
    [self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CCKCapturingStillImageContext];
    
    [self removeObserver:self forKeyPath:@"videoDevice.adjustingFocus" context:CCKAdjustingFocusContext];
    [self removeObserver:self forKeyPath:@"videoDevice.adjustingExposure" context:CCKAdjustingExposureContext];
    
    [self removeObserver:self forKeyPath:@"videoDevice.flashMode" context:CCKFlashModeContext];
    [self removeObserver:self forKeyPath:@"videoDevice.torchMode" context:CCKTorchModeContext];
    [self removeObserver:self forKeyPath:@"videoDevice.position" context:CCKDevicePositionContext];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDevice];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    id oldValue = change[NSKeyValueChangeOldKey];
    id newValue = change[NSKeyValueChangeNewKey];
    
    if (context == CCKFlashModeContext) {
        if (newValue && newValue != [NSNull null]) {
            CCKCameraFlashMode newMode = [newValue intValue];
            
            
            if (![self.delegate respondsToSelector:@selector(camman:didChangedFlashMode:)]) return;
            [self.delegate camman:self didChangedFlashMode:newMode];
        }
    }
    else if (context == CCKTorchModeContext) {
        if (newValue && newValue != [NSNull null]) {
            CCKCameraTorchMode newMode = [newValue intValue];
            if (![self.delegate respondsToSelector:@selector(camman:didChangedTorchMode:)]) return;
            [self.delegate camman:self didChangedTorchMode:newMode];
        }
    }
    else if (context == CCKDevicePositionContext) {
        if (newValue && newValue != [NSNull null]) {
            CCKCameraDevicePosition newPosition = [newValue intValue];
            if (![self.delegate respondsToSelector:@selector(camman:didChangedDevicePosition:)]) return;
            [self.delegate camman:self didChangedDevicePosition:newPosition];
        }
    }
    else if (context == CCKAdjustingFocusContext) {
        if (newValue && newValue != [NSNull null]) {
            if ([newValue boolValue]) {
                [self _focusStart];
            }
            else {
                [self _focusChanged];
            }
        }
    }
    else if (context == CCKAdjustingExposureContext) {
        if (newValue && newValue != [NSNull null]) {
            if ([newValue boolValue]) {
                [self _exposureStart];
            }
            else {
                [self _exposureChanged];
            }
        }
    }
    else if (context == CCKCapturingStillImageContext ) {
        BOOL isCapturingStillImage = NO;
        if ( newValue && newValue != [NSNull null] ) {
            isCapturingStillImage = [newValue boolValue];
        }
        
        if (isCapturingStillImage) {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.previewView.layer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.previewView.layer.opacity = 1.0;
                }];
            } );
        }
    }
    else if (context == CCKSessionRunningContext) {
        BOOL isRunning = NO;
        if ( newValue && newValue != [NSNull null] ) {
            isRunning = [newValue boolValue];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    if ([self.delegate respondsToSelector:@selector(cammanAreaDidChange:)])
    {
        [self.delegate cammanAreaDidChange:self];
    }
    
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    [self _focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

#pragma mark - flash

- (BOOL)isFlashModeAvailableForCurrentDevice:(CCKCameraFlashMode)flashMode
{
    return [self.videoDevice isFlashModeSupported:(AVCaptureFlashMode)flashMode];
}

- (void)setFlashMode:(CCKCameraFlashMode)flashMode
{
    NSError *error;
    if ([self isFlashModeAvailableForCurrentDevice:flashMode] && [self.videoDevice lockForConfiguration:&error]) {
        
        if (self.videoDevice.position != AVCaptureDevicePositionBack)
        {
            self.videoDevice.flashMode = AVCaptureFlashModeOff;
            _flashMode = CCKCameraFlashModeOff;
            return;
        }
        
        self.videoDevice.flashMode = (AVCaptureFlashMode)flashMode;
        [self.videoDevice unlockForConfiguration];
        _flashMode = flashMode;
        
        NSLog(@"current flashMode: %d", (int)_flashMode);
    }
}

- (BOOL)isTorchModeAvailableForCurrentDevice:(CCKCameraTorchMode)torchMode
{
    return [self.videoDevice isTorchModeSupported:(AVCaptureTorchMode)torchMode];
}

- (void)setTorchMode:(CCKCameraTorchMode)torchMode
{
    NSError *error;
    if ([self isTorchModeAvailableForCurrentDevice:torchMode] && [self.videoDevice lockForConfiguration:&error]) {
        
        self.videoDevice.torchMode = (AVCaptureTorchMode)torchMode;
        self.videoDevice.flashMode = (torchMode == CCKCameraTorchModeOn ? AVCaptureFlashModeOff : AVCaptureFlashModeOn);
        _flashMode = (CCKCameraFlashMode)self.videoDevice.flashMode;
        [self.videoDevice unlockForConfiguration];
        _torchMode = torchMode;
        
        NSLog(@"current flashMode: %d", (int)_flashMode);
    }
}

#pragma mark - Start and Stop

- (void)startRunning {
    
    if (self.session.isRunning) return;
    
    dispatch_async( self.sessionQueue, ^{
        switch (self.setupResult)
        {
            case CCKCameraSetupResultSuccess:
            {
                [self addObservers];
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case CCKCameraSetupResultCameraNotAuthorized: {break;}
            case CCKCameraSetupResultSessionConfigurationFailed: {break;}
        }
    } );
}

- (void)stopRunning {
    
    if (!self.session.isRunning) return;
    
   	dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == CCKCameraSetupResultSuccess ) {
            [self.session stopRunning];
            self.sessionRunning = self.session.isRunning;
            [self removeObservers];
        }
    } );
}

#pragma mark - Switch camera

- (void)switchCameraDevicePosition {
    
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        switch (self.videoDevice.position)
        {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
        }
        
        AVCaptureDevice *newVideoDevice = [self _deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:nil];
        
        [self.session beginConfiguration];
        
        // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
        [self.session removeInput:self.videoDeviceInput];
        if ( [self.session canAddInput:newVideoDeviceInput] ) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDevice];
            
            //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:newVideoDevice];
            
            [self.session addInput:newVideoDeviceInput];
            self.videoDeviceInput = newVideoDeviceInput;
            self.videoDevice = newVideoDevice;
        }
        else {
            [self.session addInput:self.videoDeviceInput];
        }
        
        [self.session commitConfiguration];
        
        if (![self.delegate respondsToSelector:@selector(camman:didChangedDevicePosition:)]) return ;
        [self.delegate camman:self didChangedDevicePosition:(CCKCameraDevicePosition)preferredPosition];
    } );
}

- (void)snap
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
        
        // Update the orientation on the still image output video connection before capturing.
        stillImageConnection.videoOrientation = previewLayer.connection.videoOrientation;
        
        // Flash set to Auto for Still Capture
//        if ( self.videoDevice.exposureMode == AVCaptureExposureModeCustom ) {
//            [AAPLCameraViewController setFlashMode:AVCaptureFlashModeOff forDevice:self.videoDevice];
//        }
//        else {
//            [AAPLCameraViewController setFlashMode:AVCaptureFlashModeAuto forDevice:self.videoDevice];
//        }
        
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            if ( error ) {
                NSLog( @"Error capture still image %@", error );
            }
            else if ( imageDataSampleBuffer ) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
//                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//                    [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
//                } completionHandler:^( BOOL success, NSError *error ) {
//                    if ( ! success ) {
//                        NSLog( @"Error occured while saving image to photo library: %@", error );
//                    }
//                }];
                UIImage *image = [UIImage imageWithData:imageData];
                if (![self.delegate respondsToSelector:@selector(camman:didSnappedStillImage:)]) return;
                [self.delegate camman:self didSnappedStillImage:image];
            }
        }];
    });
}

#pragma mark - Parameters

- (void)adjustFocusAndExposureAtPoint:(CGPoint)point
{
    if (self.videoDevice.exposureMode != AVCaptureExposureModeCustom ) {
        [self _focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:point monitorSubjectAreaChange:YES];
    }
}

- (void)adjustExposureBias:(float)bias
{
    // - 8.0 ~ 8.0
    float value = 0.f;
    if (bias < - 8.f)
    {
        value = - 8.0;
    }
    
    if (bias > 8.f)
    {
        value = 8.f;
    }
    
    NSError *error;
    if ([self.videoDevice lockForConfiguration:&error]) {
        [self.videoDevice setExposureTargetBias:value completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
    }
    else {
        NSLog( @"Could not lock device for configuration: %@", error );
    }
}

#pragma mark - Utilities

- (AVCaptureDevice *)_deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
   
    NSError *error;
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    AVCaptureFlashMode flashMode = AVCaptureFlashModeOff;
    
    _flashMode = CCKCameraFlashModeOff;
    
    if ( [captureDevice lockForConfiguration:&error] ) {
        if ([captureDevice isFocusModeSupported:focusMode] ) {
            captureDevice.focusMode = focusMode;
        }
        
        if ([captureDevice isExposureModeSupported:exposureMode] ) {
            captureDevice.exposureMode = exposureMode;
        }
        
        captureDevice.subjectAreaChangeMonitoringEnabled = YES;
        
        if ([captureDevice isFlashModeSupported:flashMode])
        {
            captureDevice.flashMode = flashMode;
        }
        
        [captureDevice unlockForConfiguration];
    }
    else {
        NSLog( @"Could not lock device for configuration: %@", error );
    }
    
    return captureDevice;
}

#pragma mark - Device Configurations

- (void)_focusStart {
    if (![self.delegate respondsToSelector:@selector(cammanWillChangeFocus:)]) return;
    [self.delegate cammanWillChangeFocus:self];
}

- (void)_focusChanged {
    if (![self.delegate respondsToSelector:@selector(cammanDidChangedFocus:)]) return;
    [self.delegate cammanDidChangedFocus:self];
}

- (void)_exposureStart {
    if (![self.delegate respondsToSelector:@selector(cammanWillChangeExposure:)]) return;
    [self.delegate cammanWillChangeExposure:self];
}

- (void)_exposureChanged {
    if (![self.delegate respondsToSelector:@selector(cammanDidChangedExposure:)]) return;
    [self.delegate cammanDidChangedExposure:self];
}

- (void)_focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDevice;
        
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

@end

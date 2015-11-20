
@import AVFoundation;
@import Photos;

#import "CCKViewController.h"
#import "CCKCamman.h"
#import "CCKCameraPreviewView.h"
#import <Masonry/Masonry.h>
#import "UIImage+CCKImageProccess.h"
#import "CCKControlPanelBindingHelper.h"

@interface CCKViewController () <CCKCameraDelegate, UICollectionViewDelegate>

@property (nonatomic) CCKCamman *camman;

@property (nonatomic) CCKCameraPreviewView *previewView;
@property (nonatomic) UICollectionView *panelView;

@property (nonatomic) CCKControlPanelBindingHelper *bindingHelper;

@end

@implementation CCKViewController

- (void)didReceiveMemoryWarning {[super didReceiveMemoryWarning];};
- (BOOL)prefersStatusBarHidden {return YES;};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.previewView = [[CCKCameraPreviewView alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame))];
    [self.view addSubview:self.previewView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tap:)];
    [self.previewView addGestureRecognizer:tap];
    
    self.camman = [[CCKCamman alloc] initCammanWithPreview:self.previewView];
    self.camman.delegate = self;
    
    [self.view addSubview:self.panelView];
    [self.panelView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self.view);
        make.centerX.mas_equalTo(self.view);
        make.width.mas_equalTo(self.view);
        make.height.mas_equalTo(50.f);
    }];
    
    self.bindingHelper = [[CCKControlPanelBindingHelper alloc] initWithCollectionView:_panelView dataSource:nil];
    self.bindingHelper.delegate = self;
    
    NSLog(@"%@", [UIView layerClass]);
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.camman startRunning];
    
    [super viewWillAppear:animated];
}

- (void)cammanWillChangeFocus:(CCKCamman *)camman
{
    
}

- (void)cammanDidChangedFocus:(CCKCamman *)camman
{

}

- (void)cammanWillChangeExposure:(CCKCamman *)camman
{

}

- (void)cammanDidChangedExposure:(CCKCamman *)camman
{
    
}

- (void)cammanAreaDidChange:(CCKCamman *)camman
{
    
}

- (void)camman:(CCKCamman *)camman didSnappedStillImage:(UIImage *)image
{
    [self.camman stopRunning];
    
    NSLog(@"snapped");
    
    [UIImage processOriginalImage:image widthResolution:1080.f whRadio:1.f success:^(UIImage *image, NSData *imageData) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
        } completionHandler:^( BOOL success, NSError *error ) {
            if ( ! success ) {
                NSLog( @"Error occured while saving image to photo library: %@", error );
            }
        }];
    }];
}

- (void)_tap:(UITapGestureRecognizer *)tap
{
    CGPoint focusPoint = [tap locationInView:tap.view];
    CGFloat focusX = focusPoint.x / tap.view.frame.size.width;
    CGFloat focusY = focusPoint.y / tap.view.frame.size.height;
    
    NSLog(@"Focus (%f, %f)", focusX, focusY);
    
    [self.camman adjustFocusAndExposureAtPoint:CGPointMake(focusX, focusY)];
}

#pragma mark - delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.item)
    {
        case 0:
            if (!self.camman) return;
            [self.camman snap];
            break;
        case 1:
        {
            switch (self.camman.flashMode)
            {
                case CCKCameraFlashModeOff:
                    self.camman.flashMode = CCKCameraFlashModeOn;
                    break;
                case CCKCameraFlashModeOn:
                    self.camman.flashMode = CCKCameraFlashModeAuto;
                    break;
                default:
                    self.camman.flashMode = CCKCameraFlashModeOff;
                    break;
            }
        }
            break;
        case 2:
            [self.camman switchCameraDevicePosition];
            break;
        case 3:
            switch (self.camman.torchMode) {
                case CCKCameraTorchModeOff: {
                    self.camman.torchMode = CCKCameraTorchModeOn;
                    break;
                }
                case CCKCameraTorchModeOn: {
                    self.camman.torchMode = CCKCameraFlashModeOff;
                    break;
                }
                default:
                    break;
            }
    }
}

- (UICollectionView *)panelView
{
    if (_panelView) return _panelView;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _panelView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    return _panelView;
}

@end

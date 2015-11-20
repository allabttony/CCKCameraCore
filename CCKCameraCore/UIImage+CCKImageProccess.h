//
//  UIImage+CCKImageProccess.h
//  CCKCameraCore
//
//  Created by Tony on 11/17/15.
//  Copyright © 2015 tony. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (CCKImageProccess)

typedef void (^CCKSnapSuccessBlock)(UIImage *image, NSData *imageData);

+ (void)processOriginalImage:(UIImage *)originalImage widthResolution:(CGFloat)widthResolution whRadio:(CGFloat)radio success:(CCKSnapSuccessBlock)success;

- (UIImage *)croppedImage:(CGRect)bounds;

- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;

- (CGAffineTransform)transformForOrientation:(CGSize)newSize;

@end

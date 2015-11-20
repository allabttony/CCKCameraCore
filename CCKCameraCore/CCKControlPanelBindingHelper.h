//
//  CCKControlPanelBindingHelper.h
//  CCKCameraCore
//
//  Created by Tony on 11/18/15.
//  Copyright © 2015 tony. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CCKControlPanelBindingHelper : NSObject

@property (nonatomic, weak) id<UICollectionViewDelegate> delegate;

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView dataSource:(NSArray *)data;

@end

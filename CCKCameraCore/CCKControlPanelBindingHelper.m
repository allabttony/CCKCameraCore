//
//  CCKControlPanelBindingHelper.m
//  CCKCameraCore
//
//  Created by Tony on 11/18/15.
//  Copyright © 2015 tony. All rights reserved.
//

#import "CCKControlPanelBindingHelper.h"
#import "CCKControlPanelCell.h"

@interface CCKControlPanelBindingHelper () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, readwrite, assign) struct delegateMethodsCaching {

// UITableViewDelegate
//Configuring Rows for the Table View
uint heightForRowAtIndexPath:1;
uint estimatedHeightForRowAtIndexPath:1;
uint indentationLevelForRowAtIndexPath:1;
uint willDisplayCellForRowAtIndexPath:1;

//Managing Accessory Views
uint editActionsForRowAtIndexPath:1;
uint accessoryButtonTappedForRowWithIndexPath:1;

//Managing Selections
uint willSelectRowAtIndexPath:1;
uint didSelectItemAtIndexPath:1;
uint willDeselectRowAtIndexPath:1;
uint didDeselectRowAtIndexPath:1;

//Modifying the Header and Footer of Sections
uint viewForHeaderInSection:1;
uint viewForFooterInSection:1;
uint heightForHeaderInSection:1;
uint estimatedHeightForHeaderInSection:1;
uint heightForFooterInSection:1;
uint estimatedHeightForFooterInSection:1;
uint willDisplayHeaderViewForSection:1;
uint willDisplayFooterViewForSection:1;

//Editing Table Rows
uint willBeginEditingRowAtIndexPath:1;
uint didEndEditingRowAtIndexPath:1;
uint editingStyleForRowAtIndexPath:1;
uint titleForDeleteConfirmationButtonForRowAtIndexPath:1;
uint shouldIndentWhileEditingRowAtIndexPath:1;

//Reordering Table Rows
uint targetIndexPathForMoveFromRowAtIndexPathToProposedIndexPath:1;

//Tracking the Removal of Views
uint didEndDisplayingCellForRowAtIndexPath:1;
uint didEndDisplayingHeaderViewForSection:1;
uint didEndDisplayingFooterViewForSection:1;

//Copying and Pasting Row Content
uint shouldShowMenuForRowAtIndexPath:1;
uint canPerformActionForRowAtIndexPathWithSender:1;
uint performActionForRowAtIndexPathWithSender:1;

//Managing Table View Highlighting
uint shouldHighlightRowAtIndexPath:1;
uint didHighlightRowAtIndexPath:1;
uint didUnhighlightRowAtIndexPath:1;


// UIScrollViewDelegate
//Responding to Scrolling and Dragging
uint scrollViewDidScroll:1;
uint scrollViewWillBeginDragging:1;
uint scrollViewWillEndDraggingWithVelocityTargetContentOffset:1;
uint scrollViewDidEndDraggingWillDecelerate:1;
uint scrollViewShouldScrollToTop:1;
uint scrollViewDidScrollToTop:1;
uint scrollViewWillBeginDecelerating:1;
uint scrollViewDidEndDecelerating:1;

//Managing Zooming
uint viewForZoomingInScrollView:1;
uint scrollViewWillBeginZoomingWithView:1;
uint scrollViewDidEndZoomingWithViewAtScale:1;
uint scrollViewDidZoom:1;

//Responding to Scrolling Animations
uint scrollViewDidEndScrollingAnimation:1;
} delegateRespondsTo;

@end

@implementation CCKControlPanelBindingHelper
{
    UICollectionView *_panelView;
    NSArray *_data;
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView dataSource:(NSArray *)data
{
    if (!(self = [super init])) return nil;
    
    _panelView = collectionView;
    _panelView.delegate = self;
    _panelView.dataSource = self;
    _data = data;
    
    [_panelView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    
    return self;
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
    if (self.delegate) return;
    
    _delegate = delegate;
    
    struct delegateMethodsCaching newMethodCaching;
    
    newMethodCaching.didSelectItemAtIndexPath = [_delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)];
    
    self.delegateRespondsTo = newMethodCaching;
}

#pragma mark - 

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 4;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor whiteColor];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(100.f, 50.f);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.delegateRespondsTo.didSelectItemAtIndexPath) return;
    [self.delegate collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}
@end

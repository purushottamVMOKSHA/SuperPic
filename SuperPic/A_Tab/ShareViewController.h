//
//  HomeViewController.h
//  SuperPic
//
//  Created by Syed Hyder Zubair on 14/04/15.
//  Copyright (c) 2015 Vmoksha Technologies Pvt Ltd. All rights reserved.
//

#import "BaseViewController.h"
#import <QuartzCore/QuartzCore.h>
//#import "FriendsTableViewCell.h"

@interface ShareViewController : BaseViewController
{
    
    int nDiscardedImages;
}
@property (weak, nonatomic) IBOutlet UILabel *requestNotificationLabel;
@property (assign, nonatomic) BOOL isCommingFormCamera;
@property (strong, nonatomic) NSIndexPath* confirmIndexPath;

@property (strong, nonatomic) NSMutableArray *shareImageArray;

@property (nonatomic, strong) NSMutableArray *stagingFriendstableData, *notToShareImagesArr;//, *sharedImageURLsListsArr;


@end

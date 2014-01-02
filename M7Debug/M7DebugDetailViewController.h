//
//  M7DebugDetailViewController.h
//  M7Debug
//
//  Created by Kevin on 1/2/14.
//  Copyright (c) 2014 Kevin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface M7DebugDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end

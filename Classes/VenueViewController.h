//
//  VenueViewController.h
//  Kngroo
//
//  Created by Aubrey Goodman on 10/23/11.
//  Copyright (c) 2011 Migrant Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Hop.h"
#import "Venue.h"
#import "Assignment.h"
#import "HudViewController.h"

// Check-in radius 500m
#define kCheckinRadius 500

@interface VenueViewController : HudViewController <RKObjectLoaderDelegate,CLLocationManagerDelegate> {
    
    IBOutlet UIImageView* imageView;
    IBOutlet UILabel* titleLabel;
    IBOutlet UILabel* descriptionLabel;
    IBOutlet UIButton* checkInButton;
    IBOutlet UILabel* checkedInLabel;
    
    Hop* hop;
    Venue* venue;
    Assignment* assignment;
    
    BOOL checkedIn;
    
}

@property (retain) UIImageView* imageView;
@property (retain) UILabel* titleLabel;
@property (retain) UILabel* descriptionLabel;
@property (retain) UIButton* checkInButton;
@property (retain) UILabel* checkedInLabel;
 
@property (retain) Hop* hop;
@property (retain) Venue* venue;
@property (retain) Assignment* assignment;

-(IBAction)showTrivia:(id)sender;
-(void)checkIn;

@end

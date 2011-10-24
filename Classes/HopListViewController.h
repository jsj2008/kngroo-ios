//
//  HopListViewController.h
//  Kngroo
//
//  Created by Aubrey Goodman on 10/19/11.
//  Copyright (c) 2011 Migrant Studios. All rights reserved.
//

@interface HopListViewController : UIViewController <RKObjectLoaderDelegate> {
    
    IBOutlet UISegmentedControl* modeSelect;
	IBOutlet UITableView* tableView;
	
    NSArray* hops;
    NSArray* allHops;
    
}

@property (retain) UISegmentedControl* modeSelect;
@property (retain) UITableView* tableView;
@property (retain) NSArray* hops;
@property (retain) NSArray* allHops;

@end

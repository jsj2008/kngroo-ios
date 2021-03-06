//
//  HopListViewController.m
//  Kngroo
//
//  Created by Aubrey Goodman on 10/19/11.
//  Copyright (c) 2011 Migrant Studios. All rights reserved.
//

#import "HopListViewController.h"
#import "HopViewController.h"
#import "ImageManager.h"
#import "Venue.h"
#import "Category.h"
#import "HopCell.h"


static int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation HopListViewController

@synthesize modeSelect, tableView, categoryPicker, hops, allHops, categories;

- (void)refreshHops
{
    [self showHud:@"Loading"];
	[[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/hops" delegate:self];
}

- (void)refreshCategories
{
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/categories" delegate:self];
}

- (void)modeChanged
{
    BOOL tByCategory = [modeSelect selectedSegmentIndex]==1;
    if( tByCategory ) {
        [self showHops:^(Hop* aHop) {
            return (BOOL)([aHop.categoryId intValue]==selectedCategoryId);
        }];
        if( !categoryPickerVisible ) {
            [self showCategoryPicker];
        }
    }else{
        [self showHops:^(Hop* aHop) {
            return [aHop.featured boolValue];
        }];
        if( categoryPickerVisible ) {
            [self hideCategoryPicker];
        }
    }
    [tableView reloadData];
}

- (void)showHops:(HopSelectorBlock)selectBlock
{
    NSMutableArray* tHops = [NSMutableArray array];
    for (Hop* hop in self.allHops) {
        if( selectBlock(hop) ) {
            [tHops addObject:hop];
        }
    }
    self.hops = tHops;
}

- (void)showCategoryPicker
{
    [UIView animateWithDuration:0.5 
                     animations:^{
        CGRect tPickerFrame = categoryPicker.frame;
        tPickerFrame.origin.y = 44;
        categoryPicker.frame = tPickerFrame;
        
        CGRect tTableViewFrame = tableView.frame;
        tTableViewFrame.origin.y += 44;
        tTableViewFrame.size.height -= 44;
        tableView.frame = tTableViewFrame;
    } 
                     completion:^(BOOL aFinished) { categoryPickerVisible = aFinished; }];
}

- (void)hideCategoryPicker
{
    [UIView animateWithDuration:0.5 
                     animations:^{
        CGRect tPickerFrame = categoryPicker.frame;
        tPickerFrame.origin.y = 0;
        categoryPicker.frame = tPickerFrame;
        
        CGRect tTableViewFrame = tableView.frame;
        tTableViewFrame.origin.y -= 44;
        tTableViewFrame.size.height += 44;
        tableView.frame = tTableViewFrame;
                     } completion:^(BOOL aFinished) { categoryPickerVisible = !aFinished; }];
}

- (void)assignmentCreated:(NSNotification*)notif
{
    async_main(^{
        [self.navigationController popToRootViewControllerAnimated:YES];
        [self refreshHops];
    });
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.categoryPicker = [[[V8HorizontalPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
    categoryPicker.dataSource = self;
    categoryPicker.delegate = self;
    categoryPicker.backgroundColor = [UIColor colorWithRed:0.0586 green:0.1523 blue:0.1758 alpha:1.0];
    categoryPicker.textColor = [UIColor whiteColor];
    categoryPicker.selectedTextColor = [UIColor colorWithRed:0.6562 green:0.93 blue:1.0 alpha:1.0];
    categoryPicker.selectionPoint = CGPointMake(160, 0);
    categoryPicker.elementFont = [UIFont boldSystemFontOfSize:14];

    UIImageView *indicator = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"indicator"]] autorelease];
    categoryPicker.selectionIndicatorView = indicator;
    [self.view addSubview:categoryPicker];
    [self.view sendSubviewToBack:categoryPicker];
        
    // refresh categories
    [self refreshCategories];
    
	// refresh hops
	[self refreshHops];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshHops)] autorelease];    
    
    [modeSelect addTarget:self action:@selector(modeChanged) forControlEvents:UIControlEventValueChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(assignmentCreated:)
                                                 name:@"AssignmentCreated" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(assignmentCreated:) 
                                                 name:@"AssignmentDeleted"
                                               object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [categoryPicker scrollToElement:0 animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	return hops.count;
}

- (UITableViewCell*)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString* sCellIdentifier = @"HopCell";
	HopCell* tCell = (HopCell*)[aTableView dequeueReusableCellWithIdentifier:sCellIdentifier];
	if( tCell==nil ) {
        NSArray* tCells = [[NSBundle mainBundle] loadNibNamed:@"HopCell" owner:self options:nil];
		tCell = [tCells objectAtIndex:0];
	}
	
	Hop* tHop = [hops objectAtIndex:indexPath.row];
    [[ImageManager sharedManager] loadImageNamed:tHop.imageUrl
                                    successBlock:^(UIImage* aImage) {
                                        async_main(^{ tCell.imageView.image = aImage; });
                                    }
                                    failureBlock:^{
                                        async_main(^{ tCell.imageView.image = [UIImage imageNamed:@"hop-image"]; });
                                    }];
	tCell.titleLabel.text = tHop.title;
	tCell.countLabel.text = [NSString stringWithFormat:@"%d Locations",tHop.venues.count];
	
	return tCell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Hop* tHop = [hops objectAtIndex:indexPath.row];
    HopViewController* tHopView = [[[HopViewController alloc] initWithNibName:@"HopView" bundle:[NSBundle mainBundle]] autorelease];
    tHopView.hop = tHop;
    tHopView.active = NO;
    
    [self.navigationController pushViewController:tHopView animated:YES];
    
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark V8HorizontalPickerView methods

- (NSInteger)numberOfElementsInHorizontalPickerView:(V8HorizontalPickerView *)picker
{
    return categories.count;
}

- (NSInteger)horizontalPickerView:(V8HorizontalPickerView *)picker widthForElementAtIndex:(NSInteger)index
{
    CGSize constrainedSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
    Category* tCategory = [categories objectAtIndex:index];
    CGSize textSize = [tCategory.title sizeWithFont:[UIFont boldSystemFontOfSize:14.0f]
                       constrainedToSize:constrainedSize
                           lineBreakMode:UILineBreakModeWordWrap];
    return textSize.width + 20.0f; // 20px padding on each side
//    
//    return picker.frame.size.height;
}

- (NSString*)horizontalPickerView:(V8HorizontalPickerView *)picker titleForElementAtIndex:(NSInteger)index
{
    Category* tCategory = [categories objectAtIndex:index];
    return tCategory.title;
}

//- (UIView*)horizontalPickerView:(V8HorizontalPickerView *)picker viewForElementAtIndex:(NSInteger)index
//{
//    Category* tCategory = [categories objectAtIndex:index];
//    
//    UIImageView* tImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, picker.frame.size.height, picker.frame.size.height)] autorelease];
//    tImageView.contentMode = UIViewContentModeCenter;
//    [[ImageManager sharedManager] loadImageNamed:tCategory.icon 
//                                    successBlock:^(UIImage* aImage) { dispatch_async(dispatch_get_main_queue(), ^{ tImageView.image = aImage; [categoryPicker reloadData]; }); } 
//                                     failureBlock:^{ dispatch_async(dispatch_get_main_queue(), ^{ tImageView.image = [UIImage imageNamed:@"category.png"]; [categoryPicker reloadData]; }); }];
//    return tImageView;
//}

- (void)horizontalPickerView:(V8HorizontalPickerView *)picker didSelectElementAtIndex:(NSInteger)index
{
    Category* tCategory = [categories objectAtIndex:index];
    selectedCategoryId = [tCategory.categoryId intValue];
    [self modeChanged];
}

#pragma mark -
#pragma mark RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    [self hideHud];
	DDLogVerbose(@"HopListView - objects loaded: %@",objects);
    if( objects && objects.count>0 ) {
        if( [[objects lastObject] isKindOfClass:[Hop class]] ) {
            self.allHops = objects;

            [self modeChanged];
            
            async_main(^{ [self.tableView reloadData]; });
        }else if( [[objects lastObject] isKindOfClass:[Category class]] ) {
            self.categories = objects;
            async_main(^{ 
                [categoryPicker reloadData];
                [categoryPicker scrollToElement:0 animated:YES];
            });
        }
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object
{
	DDLogVerbose(@"HopListView - object loaded: %@",object);
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    [self hideHud];
	DDLogVerbose(@"Encountered an error: %@", error);
    Alert(@"Unable to load", [error localizedDescription]);
//    if( error.code==1004 ) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"SessionDestroyed" object:nil];
//    }
}



@end

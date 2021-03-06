//
//  VenueViewController.m
//  Kngroo
//
//  Created by Aubrey Goodman on 10/23/11.
//  Copyright (c) 2011 Migrant Studios. All rights reserved.
//

#import "VenueViewController.h"
#import "Checkin.h"
#import "TriviaViewController.h"
#import "Attempt.h"
#import "LocationManager.h"
#import "BrandedNavigationController.h"


@implementation VenueViewController

@synthesize imageView, titleLabel, addressLabel, phoneLabel, distanceLabel, descriptionLabel, checkInButton, checkedInLabel, mapView, hop, venue, assignment;

//- (void)showMap
//{
//    MapViewController* tMapView = [[[MapViewController alloc] init] autorelease];
//    tMapView.hop = hop;
//    UINavigationController* tNav = [[[UINavigationController alloc] initWithRootViewController:tMapView] autorelease];
//    [self.navigationController presentModalViewController:tNav animated:YES];
//}

- (IBAction)showTrivia:(id)sender
{
    [self showHud:@"Loading"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/user/assignments/%@/venues/%@/trivias",assignment.assignmentId,venue.venueId] delegate:self];
}

- (void)checkIn
{
    [self showHud:@"Checking In"];
    Checkin* tCheckin = [[[Checkin alloc] init] autorelease];
    tCheckin.assignmentId = assignment.assignmentId;
    tCheckin.venueId = venue.venueId;
    [[RKObjectManager sharedManager] postObject:tCheckin delegate:self];
}

- (void)updateLocation:(CLLocation*)aLocation
{
    CLLocation* tVenueLocation = [[[CLLocation alloc] initWithLatitude:[venue.lat doubleValue] longitude:[venue.lng doubleValue]] autorelease];
    float tDist = [tVenueLocation distanceFromLocation:aLocation];
    dispatch_block_t tBlock = ^{
        if( tDist<kCheckinRadius ) {
            checkInButton.hidden = NO;
        }else{
            checkInButton.hidden = YES;
            distanceLabel.text = [NSString stringWithFormat:@"%3.1f miles",tDist*3.2808/5280.0];
        }        
    };
    async_main(tBlock);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    titleLabel.text = venue.name;
    addressLabel.text = venue.address;
    phoneLabel.text = venue.phone;
    distanceLabel.text = @"-";
    descriptionLabel.text = venue.summary;
    checkInButton.hidden = YES;
    
    [mapView setRegion:MKCoordinateRegionMake(CLLocationCoordinate2DMake([venue.lat doubleValue], [venue.lng doubleValue]), MKCoordinateSpanMake(0.1, 0.1))];
    mapView.userInteractionEnabled = NO;

    if( assignment==nil ) {
        checkedInLabel.hidden = YES;
        checkInButton.hidden = YES;
    }else{
        checkedIn = NO;
        for (Checkin* checkin in assignment.checkins) {
            if( [checkin.venueId intValue]==[venue.venueId intValue] ) {
                checkInButton.hidden = YES;
                NSDateFormatter* tFormat = [[[NSDateFormatter alloc] init] autorelease];
                tFormat.dateStyle = NSDateFormatterShortStyle;
                tFormat.timeStyle = NSDateFormatterShortStyle;
                checkedInLabel.text = [NSString stringWithFormat:@"Checked In: %@",[tFormat stringFromDate:checkin.createdAt]];
                checkedIn = YES;
                break;
            }
        }
        if( !checkedIn ) {
            [self updateLocation:[[LocationManager sharedManager] location]];
        }
    }

//    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(showMap)] autorelease];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if( !checkedIn ) {
        CLLocationManager* tMgr = [LocationManager sharedManager];
        tMgr.delegate = self;
        [tMgr startUpdatingLocation];
//        [tMgr startMonitoringSignificantLocationChanges];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if( !checkedIn ) {
        CLLocationManager* tMgr = [LocationManager sharedManager];
        [tMgr stopUpdatingLocation];
//        [tMgr stopMonitoringSignificantLocationChanges];
        tMgr.delegate = nil;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    [self hideHud];
    if( objects && objects.count>0 && [[objects lastObject] isKindOfClass:[Trivia class]] ) {
        Trivia* tTrivia = [objects objectAtIndex:0];
        NSMutableArray* tAnswers = [NSMutableArray array];
        [tAnswers addObjectsFromArray:objects];
        for (int k=0,K=tAnswers.count;k<K;k++) {
            [tAnswers exchangeObjectAtIndex:k withObjectAtIndex:random() % (k + 1)];
        }
        async_main(^{
            TriviaViewController* tTriviaView = [[[TriviaViewController alloc] initWithNibName:@"TriviaView" bundle:[NSBundle mainBundle]] autorelease];
            tTriviaView.venue = self.venue;
            tTriviaView.trivia = tTrivia;
            tTriviaView.possibleAnswers = tAnswers;
            
            tTriviaView.cancelBlock = ^{ 
                async_main(^{ [self.navigationController dismissModalViewControllerAnimated:YES]; });
            };
            tTriviaView.successBlock = ^(Trivia* aTrivia, BOOL aCorrectAnswer) {
                [self showHud:@"Saving"];
                Attempt* tAttempt = [[[Attempt alloc] init] autorelease];
                tAttempt.triviaId = aTrivia.triviaId;
                tAttempt.correctAnswer = [NSNumber numberWithBool:aCorrectAnswer];
                [[RKObjectManager sharedManager] postObject:tAttempt delegate:self];
                async_main(^{ [self.navigationController dismissModalViewControllerAnimated:YES]; });
            };
            BrandedNavigationController* tNav = [[[BrandedNavigationController alloc] initWithRootViewController:tTriviaView] autorelease];
            [self.navigationController presentModalViewController:tNav animated:YES];
        });
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object
{
    [self hideHud];
    if( [object isKindOfClass:[Checkin class]] ) {
        Checkin* tCheckin = (Checkin*)object;
        NSMutableArray* tCheckins = [NSMutableArray arrayWithArray:assignment.checkins];
        [tCheckins addObject:tCheckin];
        assignment.checkins = [NSArray arrayWithArray:tCheckins];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"CheckinSuccessful" object:nil];
        if( [tCheckin.trophyAwarded boolValue] ) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TrophyAwarded" object:nil];
        }
    }else if( [object isKindOfClass:[Attempt class]] ) {
        Attempt* tAttempt = (Attempt*)object;
        if( [tAttempt.correctAnswer boolValue] ) {
            [self checkIn];
        }else{
            Alert(@"Incorrect Answer", @"Sorry, but that's not correct");
        }
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    [self hideHud];
//    Alert(@"Unable to checkin", [[error userInfo] objectForKey:@"NSLocalizedDescription"]);
    Alert(@"Unable to checkin", [error localizedDescription]);
//    if( error.code==1004 ) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"SessionDestroyed" object:nil];
//    }
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [self updateLocation:newLocation];
}

@end

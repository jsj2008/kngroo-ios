//
//  SignInViewController.h
//  Kngroo
//
//  Created by Aubrey Goodman on 11/1/11.
//  Copyright (c) 2011 Migrant Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignInViewController : UIViewController <RKObjectLoaderDelegate> {
    
    IBOutlet UITextField* email;
    IBOutlet UITextField* password;
    
}

@end
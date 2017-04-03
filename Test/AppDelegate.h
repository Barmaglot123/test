//
//  AppDelegate.h
//  Test
//
//  Created by Денислям Ибраим on 02.04.17.
//  Copyright © 2017 Денислям Ибраим. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end


//
//  AppDelegate.h
//  WordpressConnect
//
//  Created by Moritz Eberhard on 1/21/15.
//  Copyright (c) 2015 Moritz Eberhard. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSMutableArray *allPosts;
@property (strong) NSMutableArray *allComments;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end


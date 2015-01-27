//
//  AppDelegate.m
//  WordpressConnect
//
//  Created by Moritz Eberhard on 1/21/15.
//  Copyright (c) 2015 Moritz Eberhard. All rights reserved.
//

#import "AppDelegate.h"
#import "Post.h"
#import "PostComment.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flushData) name:@"flushData" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncData) name:@"syncData" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCommentsForPostId:) name:@"getComments" object:nil];
    
    [self showPostsInView];
    }

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)syncData {
    [self receivePostsFromBlog];
}

- (void)receivePostsFromBlog {
    //@Todo write json url for receiving posts here:
    NSString *baseUrl = @"";
    
    NSURL *url = [NSURL URLWithString:baseUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *repsone, NSData *data, NSError *connectionError) {
        if (data.length > 0 && connectionError == nil) {
            NSDictionary *wpPosts = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            for (id key in wpPosts) {
                NSNumber *postId = [NSNumber numberWithInt:((int)[[key objectForKey:@"ID"] integerValue])];
                if (![self checkIfPostIdExists:postId]) {
                    NSString *postTitle = [key objectForKey:@"title"];
                    NSManagedObjectContext *context = [self managedObjectContext];
                    Post *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:context];
                    post.postId = postId;
                    post.title = postTitle;
                    NSError *error;
                    if (![context save:&error]) {
                        NSLog(@"Something went wrong: %@", [error localizedDescription]);
                    } else {
                        [self receiveCommentsFromBlogForPost:post];
                    }
                } else {
                    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:[self managedObjectContext]];
                    [fetchRequest setEntity:entity];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"postId == %@", postId];
                    [fetchRequest setPredicate:predicate];
                    NSError *error;
                    NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                    Post *post = [items objectAtIndex:0];
                    [self receiveCommentsFromBlogForPost:post];
                    NSLog(@"Post with id %@ exists in DB, skipping", postId);
                }
            }
        }
        [self showPostsInView];
    }];
}

- (void)receiveCommentsFromBlogForPost:(Post *)post {
    //@Todo write json url for receiving posts here:
    NSString *baseUrl = @"";
    
    NSString *restUrl = [NSString stringWithFormat:@"%@/%ld/comments", baseUrl, [post.postId integerValue]];
    NSURL *url = [NSURL URLWithString:restUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (data.length > 0 && connectionError == nil) {
            NSDictionary *wpComments = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            for (id key in wpComments) {
                NSNumber *commentId = [NSNumber numberWithInt:((int)[[key objectForKey:@"ID"] integerValue])];
                if (![self checkIfCommentIdExists:commentId]) {
                    NSMutableString *commentText = [[NSMutableString alloc] init];
                    [commentText appendString:[key objectForKey:@"content"]];
                    
                    NSManagedObjectContext *context = [self managedObjectContext];
                    PostComment *pcom = [NSEntityDescription insertNewObjectForEntityForName:@"PostComment" inManagedObjectContext:context];
                    pcom.comId = commentId;
                    pcom.text = commentText;
                    pcom.post = post;
                    [post addCommentsObject:pcom];
                    NSError *error;
                    if (![context save:&error]) {
                        NSLog(@"Something went wrong: %@", [error localizedDescription]);
                    }
                } else {
                    NSLog(@"Comment with comment id %@ exists, skipping", commentId);
                }
            }
        }
    }];
}

- (void)showPostsInView {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showPosts" object:fetchedObjects];
}

- (void)flushData {
    NSArray *entities = self.managedObjectModel.entities;
    for (NSEntityDescription *entityDescription in entities) {
        [self deleteAllObjectsWithEntityName:entityDescription.name];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showPosts" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showComments" object:nil];
}

- (void)deleteAllObjectsWithEntityName:(NSString*)entityName {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.includesPropertyValues = NO;
    fetchRequest.includesSubentities = NO;
    NSError *error;
    NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *managedObject in items) {
        [self.managedObjectContext deleteObject:managedObject];
    }
}

- (void)getCommentsForPostId:(NSNotification *)notification {
    NSNumber *postId = [notification object];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"postId == %@", postId];
    [fetchRequest setPredicate:predicate];
    NSError *error;
    NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    Post *post = [items objectAtIndex:0];
    NSArray *comments = [[post comments] allObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showComments" object:comments];
}

- (BOOL)checkIfPostIdExists:(NSNumber*)postId {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"postId == %@", postId];
    [fetchRequest setPredicate:predicate];
    NSError *error;
    NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    return ([items count] > 0);
}

- (BOOL)checkIfCommentIdExists:(NSNumber*)commentId {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"PostComment" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"comId == %@", commentId];
    [fetchRequest setPredicate:predicate];
    NSError *error;
    NSArray *items = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    return ([items count] > 0);
}

#pragma mark - Core Data stack

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "me.meberhard.AnotherText" in the user's Application Support directory.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"me.meberhard.WordpressConnect"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"wpconnect" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    // Make sure the application files directory is there
    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
            shouldFail = YES;
        }
    } else if ([error code] == NSFileReadNoSuchFileError) {
        error = nil;
        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!shouldFail && !error) {
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *url = [applicationDocumentsDirectory URLByAppendingPathComponent:@"OSXCoreDataObjC.storedata"];
        if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
            coordinator = nil;
        }
        _persistentStoreCoordinator = coordinator;
    }
    
    if (shouldFail || error) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error) {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

#pragma mark - Core Data Saving and Undo support

- (IBAction)saveAction:(id)sender {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSError *error = nil;
    if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertFirstButtonReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

@end

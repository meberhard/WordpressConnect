//
//  Post.h
//  WordpressConnect
//
//  Created by Moritz Eberhard on 1/26/15.
//  Copyright (c) 2015 Moritz Eberhard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PostComment;

@interface Post : NSManagedObject

@property (nonatomic, retain) NSNumber * postId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *comments;
@end

@interface Post (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(PostComment *)value;
- (void)removeCommentsObject:(PostComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end

//
//  PostComment.h
//  WordpressConnect
//
//  Created by Moritz Eberhard on 1/26/15.
//  Copyright (c) 2015 Moritz Eberhard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Post;

@interface PostComment : NSManagedObject

@property (nonatomic, retain) NSNumber * comId;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) Post *post;

@end

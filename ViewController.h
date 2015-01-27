//
//  ViewController.h
//  WordpressConnect
//
//  Created by Moritz Eberhard on 1/21/15.
//  Copyright (c) 2015 Moritz Eberhard. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) IBOutlet NSTableView *tablePosts;
@property (nonatomic, strong) IBOutlet NSTableView *tableComments;
@property (nonatomic, strong) IBOutlet NSButton *deleteData;
@property (nonatomic, strong) IBOutlet NSButton *syncButton;

@property (strong) NSMutableArray *displayPosts;
@property (strong) NSMutableArray *displayComments;

@end


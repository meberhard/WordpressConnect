//
//  ViewController.m
//  WordpressConnect
//
//  Created by Moritz Eberhard on 1/21/15.
//  Copyright (c) 2015 Moritz Eberhard. All rights reserved.
//

#import "ViewController.h"
#import "Post.h"
#import "PostComment.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self.tablePosts setDelegate:self];
    [self.tablePosts setDataSource:self];
    [self.tableComments setDelegate:self];
    [self.tableComments setDataSource:self];
    
    [self.deleteData setTarget:self];
    [self.deleteData setAction:@selector(buttonDeleteDataClick)];
    [self.syncButton setTarget:self];
    [self.syncButton setAction:@selector(syncButtonClick)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setPostsToDisplay:) name:@"showPosts" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCommentsToDisplay:) name:@"showComments" object:nil];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)setPostsToDisplay:(NSNotification*)notification {
    self.displayPosts = [notification object];
    [self.tablePosts reloadData];
}

- (void)setCommentsToDisplay:(NSNotification*)notification {
    self.displayComments = [notification object];
    [self.tableComments reloadData];
}

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if ([tableView.identifier isEqualToString:@"TablePosts"]) {
        Post *post = [self.displayPosts objectAtIndex:row];
        if ([tableColumn.identifier isEqualToString:@"ColumnPostId"]) {
            cellView.textField.integerValue = [post.postId integerValue];
        }
        else if ([tableColumn.identifier isEqualToString:@"ColumnPostTitle"]) {
            cellView.textField.stringValue = post.title;
        }
    } else if ([tableView.identifier isEqualToString:@"TableComments"]) {
        PostComment *pcom = [self.displayComments objectAtIndex:row];
        if ([tableColumn.identifier isEqualToString:@"ColumnCommentId"]) {
            cellView.textField.integerValue = [pcom.comId integerValue];
        } else if ([tableColumn.identifier isEqualToString:@"ColumnCommentText"]) {
            cellView.textField.stringValue = pcom.text;
        }
    }
    return cellView;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if ([tableView.identifier isEqualToString:@"TablePosts"]) {
        return [self.displayPosts count];
    } else if ([tableView.identifier isEqualToString:@"TableComments"]) {
        return [self.displayComments count];
    }
    return 0;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if ([[notification.object identifier] isEqualToString:@"TablePosts"]) {
        NSInteger row = [notification.object selectedRow];
        NSTextField *tf = [[[notification.object viewAtColumn:0 row:row makeIfNecessary:NO] subviews] lastObject];
        NSNumber *postId = [NSNumber numberWithInt:(int)[tf integerValue]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"getComments" object:postId];
    }
}

- (void)buttonDeleteDataClick {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"flushData" object:nil];
}

- (void)syncButtonClick {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"syncData" object:nil];
}

@end

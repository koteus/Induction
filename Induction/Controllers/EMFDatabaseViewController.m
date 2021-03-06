// EMFDatabaseViewController.m
//
// Copyright (c) 2012 Mattt Thompson (http://mattt.me)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "EMFDatabaseViewController.h"

#import "EMFExploreTableViewController.h"
#import "EMFQueryViewController.h"
#import "EMFVisualizeViewController.h"

#import "DBAdapter.h"
#import "SQLAdapter.h"

@interface EMFDatabaseViewController ()
@property (strong, nonatomic, readwrite) NSArray *sourceListNodes;
@end

@implementation EMFDatabaseViewController
@synthesize database = _database;
@synthesize outlineView = _outlineView;
@synthesize tabView = _tabView;
@synthesize toolbar = _toolbar;
@synthesize databasesToolbarItem = _databasesToolbarItem;
@synthesize exploreViewController = _exploreViewController;
@synthesize queryViewController = _queryViewController;
@synthesize visualizeViewController = _visualizeViewController;
@synthesize sourceListNodes = _sourceListNodes;

- (void)awakeFromNib {
    NSTabViewItem *exploreTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"Explore"];
    exploreTabViewItem.view = self.exploreViewController.view;
    [self.tabView addTabViewItem:exploreTabViewItem];
    
    NSTabViewItem *queryTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"Query"];
    queryTabViewItem.view = self.queryViewController.view;
    [self.tabView addTabViewItem:queryTabViewItem];
    
    NSTabViewItem *visualizeTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"Visualize"];
    visualizeTabViewItem.view = self.visualizeViewController.view;
    [self.tabView addTabViewItem:visualizeTabViewItem];
    
    @try {
        [self.outlineView expandItem:nil expandChildren:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception: %@", exception);
    }
}

- (void)setDatabase:(id <DBDatabase>)database {
    _database = database;    
    
    NSMutableArray *mutableNodes = [NSMutableArray array];
    [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_database numberOfDataSourceGroups])] enumerateIndexesUsingBlock:^(NSUInteger groupIndex, BOOL *stop) {
        NSString *group = [_database dataSourceGroupAtIndex:groupIndex];
        NSTreeNode *groupRootNode = [NSTreeNode treeNodeWithRepresentedObject:group];
        
        [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_database numberOfDataSourcesInGroup:group])] enumerateIndexesUsingBlock:^(NSUInteger dataSourceIndex, BOOL *stop) {
            id <DBDataSource> dataSource = [_database dataSourceInGroup:group atIndex:dataSourceIndex];
            NSTreeNode *dataSourceNode = [NSTreeNode treeNodeWithRepresentedObject:dataSource];
            [[groupRootNode mutableChildNodes] addObject:dataSourceNode];
        }];
        [mutableNodes addObject:groupRootNode];
    }];
    
    self.sourceListNodes = [NSArray arrayWithArray:mutableNodes];
    [self.outlineView expandItem:nil expandChildren:YES];
    
    [self explore:nil];
}

#pragma mark - IBAction

- (IBAction)explore:(id)sender {
    [self.tabView selectTabViewItemWithIdentifier:@"Explore"];
    [self.toolbar setSelectedItemIdentifier:@"Explore"];
}

- (IBAction)query:(id)sender {
    [self.tabView selectTabViewItemWithIdentifier:@"Query"];
    [self.toolbar setSelectedItemIdentifier:@"Query"];
}

- (IBAction)visualize:(id)sender {
    [self.tabView selectTabViewItemWithIdentifier:@"Visualize"];
    [self.toolbar setSelectedItemIdentifier:@"Visualize"];
}

#pragma mark - NSOutlineViewDelegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSOutlineView *outlineView = [notification object];
    
    id <DBDataSource> dataSource = [[[outlineView itemAtRow:[outlineView selectedRow]] representedObject] representedObject];
    self.exploreViewController.representedObject = dataSource;
    self.queryViewController.representedObject = dataSource;
    self.visualizeViewController.representedObject = dataSource;
    
    [self explore:nil];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSString *identifier = [[(NSTreeNode *)item childNodes] count] > 0 ? @"HeaderCell" : @"DataCell";
    return [outlineView makeViewWithIdentifier:identifier owner:self];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [[(NSTreeNode *)item childNodes] count] > 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return ![self outlineView:outlineView isGroupItem:item];
}

#pragma mark - NSSplitViewDelegate

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    NSSplitView *splitView = (NSSplitView *)self.view;
    NSRect frame = [[splitView.subviews objectAtIndex:0] frame];
    NSSize minSize = [self.databasesToolbarItem minSize];
    [self.databasesToolbarItem setMinSize:NSMakeSize(frame.size.width - 10.0f, minSize.height)];
}

@end

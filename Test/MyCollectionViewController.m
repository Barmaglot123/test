//
//  MyCollectionViewController.m
//  Test
//
//  Created by Денислям Ибраим on 02.04.17.
//  Copyright © 2017 Денислям Ибраим. All rights reserved.
//

#import "MyCollectionViewController.h"
#import "AFNetworking.h"
#import "MyCell.h"
#import "AppDelegate.h"
#import "Test+CoreDataModel.h"


@interface MyCollectionViewController () <NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSMutableArray * reloadSongs;
@property (strong, nonatomic) NSMutableArray * songs;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) NSFetchedResultsController * fetchedResultController;
@end

@implementation MyCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"SongsEntity"];
    //fetchRequest.resultType = NSDictionaryResultType;
    NSSortDescriptor *idSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES];
    fetchRequest.sortDescriptors = @[idSortDescriptor];
    
    self.fetchedResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.context sectionNameKeyPath:nil cacheName:nil];
    [[self fetchedResultController] setDelegate:self];
    NSError *error = nil;
    if (![self.fetchedResultController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    //self.songs = [[self.context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.collectionView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(loadData) forControlEvents:UIControlEventValueChanged];
    
    [self loadData];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
   // return self.songs.count;
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MyCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.layer.borderWidth=1.0f;
    cell.layer.borderColor=[UIColor blackColor].CGColor;

    cell.artistNameLabel.text = [[self.fetchedResultController objectAtIndexPath:indexPath]valueForKey:@"author"];
    cell.songNameLabel.text = [[self.fetchedResultController objectAtIndexPath:indexPath]valueForKey:@"label"];
    
    return cell;
}

#pragma mark Load Data
-(void)loadData{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:@"http://tomcat.kilograpp.com/songs/api/songs" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"SongsEntity"];
        fetchRequest.resultType = NSDictionaryResultType;
        NSArray * tempArray = [[self.context executeFetchRequest:fetchRequest error:nil] mutableCopy];
        
        
        for (int i = 0; i < [responseObject count]; i++ ){
        
            if(![tempArray containsObject:[responseObject objectAtIndex:i]]){
                NSManagedObject * newSong = [NSEntityDescription insertNewObjectForEntityForName:@"SongsEntity" inManagedObjectContext: self.context];
                [newSong setValue:[[responseObject objectAtIndex:i] objectForKey:@"label"] forKey:@"label"];
                [newSong setValue:[[responseObject objectAtIndex:i] objectForKey:@"author"] forKey:@"author"];
                [newSong setValue:[[responseObject objectAtIndex:i] objectForKey:@"id"] forKey:@"id"];
                [newSong setValue:[[responseObject objectAtIndex:i] objectForKey:@"version"] forKey:@"version"];
                
                [self saveContext];

                NSLog(@"%@",[responseObject objectAtIndex:i]);
                

            }
            if(i < tempArray.count){
                if(![responseObject containsObject:[tempArray objectAtIndex:i]]){
                               
                    NSManagedObject *object = [self.fetchedResultController objectAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                    NSManagedObjectContext *myContext = object.managedObjectContext;
                    [myContext deleteObject:object];

                    [self saveContext];
                }
            }
        }
        [self.refreshControl endRefreshing];

    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
}


- (void)clearEntity:(NSString *)entity{
    NSManagedObjectContext *myContext = self.context;
    NSFetchRequest *fetchAllObjects = [[NSFetchRequest alloc] init];
    [fetchAllObjects setEntity:[NSEntityDescription entityForName:entity inManagedObjectContext:myContext]];
    [fetchAllObjects setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *allObjects = [myContext executeFetchRequest:fetchAllObjects error:&error];
    // uncomment next line if you're NOT using ARC
    // [allObjects release];
 
    
    for (NSManagedObject *object in allObjects) {
        [myContext deleteObject:object];
    }
    
    
}
- (void)saveContext {
    NSManagedObjectContext *context = self.context;
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark NSFetchedResultsController
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    //UITableView *tableView = self.tableView;
    UICollectionView * collectionView = self.collectionView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [collectionView insertItemsAtIndexPaths:@[newIndexPath] ];
            break;
            
        case NSFetchedResultsChangeDelete:
            [collectionView deleteItemsAtIndexPaths:@[indexPath]];
            break;
            
        case NSFetchedResultsChangeMove:
            break;
            
        case NSFetchedResultsChangeUpdate:
            break;

    }
}


@end

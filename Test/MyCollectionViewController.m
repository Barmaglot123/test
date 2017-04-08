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
//#import <Realm/Realm.h>


@interface MyCollectionViewController ()
@property (strong, nonatomic) NSMutableArray * reloadSongs;
@property (strong, nonatomic) NSMutableArray * songs;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSManagedObjectContext *context;
@end

@implementation MyCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"SongsEntity"];
    fetchRequest.resultType = NSDictionaryResultType;
    self.songs = [[self.context executeFetchRequest:fetchRequest error:nil] mutableCopy];
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
    return self.songs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MyCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.layer.borderWidth=1.0f;
    cell.layer.borderColor=[UIColor blackColor].CGColor;

    cell.artistNameLabel.text = [[self.songs objectAtIndex:indexPath.row] objectForKey:@"author"];
    cell.songNameLabel.text = [[self.songs objectAtIndex:indexPath.row]objectForKey:@"label"];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>
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
                NSLog(@"%@",[responseObject objectAtIndex:i]);
                
                
                [self.songs insertObject:[responseObject objectAtIndex:i] atIndex:0];
                
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
            }
            if(i < tempArray.count){
                if(![responseObject containsObject:[tempArray objectAtIndex:i]]){
                    
                    NSPredicate *predicateID = [NSPredicate predicateWithFormat:@"id == %d",[[tempArray objectAtIndex:i]objectForKey:@"id"]];
                    
                    NSManagedObjectContext *myContext = self.context;
                    NSFetchRequest *fetchToDeleteRequest = [[NSFetchRequest alloc] init];
                    [fetchToDeleteRequest setEntity:[NSEntityDescription entityForName:@"SongsEntity" inManagedObjectContext:myContext]];
                    [fetchToDeleteRequest setIncludesPropertyValues:NO];
                    [fetchToDeleteRequest setPredicate:predicateID];

                    NSError *error = nil;
                    NSArray *deleteObject = [myContext executeFetchRequest:fetchToDeleteRequest error:&error];
                    
                    for (NSManagedObject *object in deleteObject) {
                        [myContext deleteObject:object];
                    }
                    
                    
                    [self.songs removeObject:[tempArray objectAtIndex:i]];
                    
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
                }
            }
            
        }

       NSLog(@"JSON: %@", responseObject);
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

@end

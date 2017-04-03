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

@interface MyCollectionViewController ()
@property (strong, nonatomic) NSMutableArray * reloadSongs;
@property (strong, nonatomic) NSArray * songs;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@end

@implementation MyCollectionViewController

static NSString * const reuseIdentifier = @"Cell";
-(NSManagedObjectContext *) manageObjectContext{

    NSManagedObjectContext * context = nil;
    id delegate = [[UIApplication sharedApplication]delegate];
    if([delegate performSelector:@selector(manageObjectContext)]){
        context = [delegate manageObjectContext];
        
    }
    return context;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadData];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.collectionView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(reloadCollectionView) forControlEvents:UIControlEventValueChanged];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.songs.count-1 ;
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
        self.songs = responseObject;
       NSLog(@"JSON: %@", responseObject);
        [self setToCoreData: self.songs];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    
}

-(void)reloadCollectionView{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:@"http://tomcat.kilograpp.com/songs/api/songs" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        self.reloadSongs = responseObject;

        for (int i = 0; i < self.songs.count; i++){
            if(![self.reloadSongs containsObject:[self.songs objectAtIndex:i]]){
                //Удалить эту ячейку из таблицы
                [self.collectionView performBatchUpdates:^{
                    [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow: i inSection:0]]];
  
                } completion:nil];
            }
        }
        
        for (int i = 0; i < self.reloadSongs.count; i++){
            if(![self.songs containsObject:[self.reloadSongs objectAtIndex:i]]){
                
                //Добавить эту ячейку в таблицу
                [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.songs count]-1 inSection:0]]];
            }
        }
        
       self.songs = self.reloadSongs;
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    
  
    
    [self.refreshControl endRefreshing];
    
}
-(void)setToCoreData: (NSArray *)dataArray{
    NSManagedObjectContext *context = [self manageObjectContext];
    
    NSManagedObject * songsManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"SongsEntity" inManagedObjectContext:context];
    for (NSDictionary * dict in dataArray){
    
        [songsManagedObject setValue:[dict objectForKey:@"author"] forKey:@"authorName"];
        [songsManagedObject setValue:[dict objectForKey:@"label"]forKey:@"songName"];
        [songsManagedObject setValue:[dict valueForKey:@"id"]forKey:@"id"];

    }
  

    
}
/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end

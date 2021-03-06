//
//  BSCoreDataManager.m
//

#import "BSCoreDataManager.h"

@implementation BSCoreDataManager

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

static BSCoreDataManager *sharedCoreDataManager = nil;

+ (BSCoreDataManager *)sharedManager {
    if (!sharedCoreDataManager) {
        sharedCoreDataManager = [[BSCoreDataManager alloc] init];
    }
    return sharedCoreDataManager;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

- (NSManagedObject *) addNewObjectOfClass:(Class)objectClass {
    return [NSEntityDescription insertNewObjectForEntityForName:[objectClass description]
                                         inManagedObjectContext:self.managedObjectContext];
}

- (NSArray *) getObjectsOfClass:(Class)objectClass
                      predicate:(NSPredicate *)predicate
                        orderBy:(NSString *)key
                      ascending:(BOOL)ascending {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:[objectClass description] 
                                              inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    [request setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key
                                                                   ascending:ascending];
    
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request 
                                                                                    error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        // Handle the error.
        //NSLog(@"FetchRequest error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return mutableFetchResults;
}

- (NSArray *) getObjectsOfClass:(Class)objectClass
                      predicate:(NSPredicate *)predicate {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:[objectClass description] 
                                              inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request 
                                                                                    error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        // Handle the error.
        NSLog(@"FetchRequest error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return mutableFetchResults;
}

- (NSManagedObject *)getObjectOfClass:(Class)objectClass 
                            predicate:(NSPredicate *)predicate
                              orderBy:(NSString *)key
                            ascending:(BOOL)ascending {
    NSArray *results = [self getObjectsOfClass:objectClass
                                     predicate:predicate
                                       orderBy:key
                                     ascending:ascending];
    if ([results count] > 0) {
        return [results objectAtIndex:0];
    }
    else {
        return nil;
    }
}

- (NSManagedObject *) getObjectOfClass:(Class)objectClass {
    NSArray *results = [self getAllObjectOfClass:objectClass];
    if ([results count] == 0) {
        return nil;
    }
    else {
        return [results objectAtIndex:0];
    }
}

- (NSManagedObject *)getObjectOfClass:(Class)objectClass 
                            predicate:(NSPredicate *)predicate {
    NSArray *results = [self getObjectsOfClass:objectClass
                                     predicate:predicate];
    if ([results count] == 1) {
        return [results objectAtIndex:0];
    }
    else if ([results count] > 1) {
        NSLog(@"CoreDataManager getObjectOfClass error: object has more than one!");
        return [results objectAtIndex:0];
    }
    else {
        return nil;
    }
}

- (NSArray *) getAllObjectOfClass:(Class)objectClass {
    return [self getObjectsOfClass:objectClass
                         predicate:nil];
}

- (NSArray *) getAllObjectOfClass:(Class)objectClass
                          orderBy:(NSString *)key
                        ascending:(BOOL)ascending {
    return [self getObjectsOfClass:objectClass
                         predicate:nil
                           orderBy:key
                         ascending:ascending];
}

- (void) deleteObject:(NSManagedObject *)object {
    if (object) {
        [self.managedObjectContext deleteObject:object];
        [self saveContext];
    }
}

- (void) deleteObjects: (NSArray *)objects {
    for (NSManagedObject *object in objects) {
        [self.managedObjectContext deleteObject:object];
    }
    [self saveContext];
}

- (void) clearDatabase {
    NSURL *mainDocumentURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory 
                                                                     inDomains:NSUserDomainMask] lastObject];
    
    NSString *sqlFile = [NSString stringWithFormat:@"%@.sqlite", self.modelName];
    NSURL *storeURL = [mainDocumentURL URLByAppendingPathComponent:sqlFile]; 
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error];
    
    if (error) {
        NSLog(@"clearDatabase error %@, %@", error, [error userInfo]);
        abort();
    }
    
    __managedObjectContext = nil;
    __managedObjectModel = nil;
    __persistentStoreCoordinator = nil;
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.modelName withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *mainDocumentURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory 
                                                                     inDomains:NSUserDomainMask] lastObject];
    
    NSString *sqlFile = [NSString stringWithFormat:@"%@.sqlite", self.modelName];
    NSURL *storeURL = [mainDocumentURL URLByAppendingPathComponent:sqlFile]; 
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:  
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,  
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
                             
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        [self clearDatabase];
        [self persistentStoreCoordinator];
//        abort();
    }
    
    return __persistentStoreCoordinator;
}



@end

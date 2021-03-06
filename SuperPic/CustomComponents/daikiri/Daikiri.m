//
//  Daikiri.m
//  daikiri
//
//  Created by Jordi Puigdellívol on 15/4/16.
//  Copyright © 2016 revo. All rights reserved.
//

#import "Daikiri.h"
#import "DaikiriCoreData.h"
#import "QueryBuilder.h"

@implementation Daikiri

//==================================================================
#pragma mark - Create / Save / Update / Destroy
//==================================================================
+(id)create:(Daikiri*)toCreate{
//    
    if(toCreate.sharedcode == nil){
        NSLog(@"model without id");
        return nil;
    }
    
    Daikiri* previous = [self.class find:toCreate.sharedcode];
    if(previous) {
        NSLog(@"Model already exists with id: %@, returning the one from the DB",toCreate.sharedcode);
        return previous;
    }
    
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:self.class.entityName inManagedObjectContext:[self.class managedObjectContext]];
    
    [toCreate valuesToManaged:object];
    [self.class saveCoreData];
    
    return toCreate;
}
-(bool)save{
    Daikiri* previous = [self.class find:self.sharedcode];
    if(previous) {
        return [self update];
    }
    else{
        return [self.class create:self];
    }
}

-(bool)update{
    if(_managed){
        [self valuesToManaged:_managed];
        return [self.class saveCoreData];
    }
    else{
        Daikiri* previous = [self.class find:self.sharedcode];
        if(!previous){
            NSLog(@"Model not in database");
            return false;
        }
        else{
            [previous destroy];
            [self save];
        }
        
    }
    return true;    
}


-(bool)destroy{
    if(_managed){
        [[self.class managedObjectContext] deleteObject:_managed];
        return [self.class saveCoreData];
    }
    else{
        Daikiri *toDelete = [self.class find:self.sharedcode];
        return [toDelete destroy];
    }
}

//==================================================================
#pragma mark - Convenience methods
#pragma mark -
//==================================================================
+(bool)updateWith:(NSDictionary*)dict{
    Daikiri* object = [self.class fromDictionary:dict];
    return [object update];
}

+(id)createWith:(NSDictionary*)dict{
    Daikiri* object = [self.class fromDictionary:dict];
    return [self.class create:object];
}

+(bool)destroyWith:(NSNumber*)id{
    Daikiri * object = [self.class find:id];
    return [object destroy];
}

+(void)destroyWithArray:(NSArray*)idsArray{
    for(NSNumber* objectId in idsArray){
        [self.class destroyWith:objectId];
    }
}

//==================================================================
#pragma mark - Active record
#pragma mark -
//==================================================================
+(id)find:(NSNumber*)id{
    if(id == nil) return nil;
    return [self.query where:@"sharedcode" is:id].first;
}

+(NSArray*)findIn:(NSArray*)identifiers{
    return [self.query where:@"sharedcode" in:identifiers].get;
}

+(id)first{
    return [self first:@"sharedcode"];
}
+(id)first:(NSString*)sort{
    return [self.query orderBy:sort].first;
}

+(NSArray*)all{
    return [self all:nil];
}

+(NSArray*)all:(NSString*)sort{
    return [self.query orderBy:sort].get;
}

-(Daikiri*)belongsTo:(NSString*)model localKey:(NSString*)localKey{
    return [NSClassFromString(model) find:[self valueForKey:localKey]];
}

-(NSArray*)hasMany:(NSString*)model foreignKey:(NSString*)foreignKey{
    return [self hasMany:model foreignKey:foreignKey sort:nil];
}

-(NSArray*)hasMany:(NSString*)model foreignKey:(NSString*)foreignKey sort:(NSString *)sort{
    return [[NSClassFromString(model).query where:foreignKey is:self.sharedcode] orderBy:sort].get;
}

-(NSArray*)belongsToMany:(NSString*)model pivot:(NSString*)pivotModel localKey:(NSString*)localKey foreignKey:(NSString*)foreingKey{
    
    return [self belongsToMany:model pivot:pivotModel localKey:localKey foreignKey:foreingKey pivotSort:nil];
}

-(NSArray*)belongsToMany:(NSString*)model pivot:(NSString*)pivotModel localKey:(NSString*)localKey foreignKey:(NSString*)foreingKey pivotSort:(NSString *)pivotSort{
    
    //Pivots
    NSArray *pivots = [[NSClassFromString(pivotModel).query where:localKey is:self.sharedcode] orderBy:pivotSort].get;
    
    //Objects (attaching pivots)
    NSMutableArray* finalResults = [NSMutableArray new];
    for(id pivot in pivots){
        id object = [NSClassFromString(model) find:[pivot valueForKey:foreingKey]];
        [object setPivot:pivot];
        [finalResults addObject:object];
    }
    
    return finalResults;
}

+(QueryBuilder*)query{
    return [QueryBuilder query:NSStringFromClass(self.class)];
}


//==================================================================
#pragma mark - HELPERS
//==================================================================
-(void)valuesToManaged:(NSManagedObject*)managedObject{
    
//    [managedObject setValue:[self valueForKey:@"code"] forKey:@"code"];
    
    [self.class properties:^(NSString *name) {
        
        id value    = [self valueForKey:name];
        
        if([value isKindOfClass:[NSString class]]){
            [managedObject setValue:value forKey:[name lowercaseString]];
        }
        else if([value isKindOfClass:[NSNumber class]]){
            [managedObject setValue:value forKey:[name lowercaseString]];
        }
    }];
    
}

+(id)fromManaged:(NSManagedObject*)managedObject{
    Daikiri *newObject = [[self class ] new];
    
//    [newObject setValue:[managedObject valueForKey:@"code"] forKey:@"code"];
    
    [self.class properties:^(NSString *name) {
        @try{
            id value = [managedObject valueForKey:[name lowercaseString]];
            
            if([value isKindOfClass:[NSString class]]){
                [newObject setValue:value forKey:[name lowercaseString]];
            }
            else if([value isKindOfClass:[NSNumber class]]){
                [newObject setValue:value forKey:[name lowercaseString]];
            }
        }@catch (NSException * e) {
            //NSLog(@"Model value not in core data entity: %@", e);
        }
    }];
    [newObject setManaged:managedObject];
    return newObject;
}

+(NSArray*)managedArrayToDaikiriArray:(NSArray*)results{
    NSMutableArray* daikiriObjects = [NSMutableArray new];
    for(NSManagedObject* managed in results){
        [daikiriObjects addObject:[self.class fromManaged:managed]];
    }
    return daikiriObjects;
}

-(void)setManaged:(NSManagedObject *)managed{
    _managed = managed;
}

-(Daikiri*)pivot{
    return _pivot;
}

-(void)setPivot:(Daikiri*)pivot{
    _pivot = pivot;
}

//==================================================================
#pragma mark - Core data
//==================================================================
+(NSString*)entityName{
    NSString* entityName = NSStringFromClass(self.class);
    if(self.class.usesPrefix){
        return [entityName substringFromIndex:2];
    }
    return entityName;
}

+(NSManagedObjectContext*)managedObjectContext{
    NSManagedObjectContext * context = [DaikiriCoreData manager].managedObjectContext;
    return context;
}

+(BOOL)usesPrefix{
    return false;
}

+(BOOL)saveCoreData{
    NSError* error = nil;
    if(![[self.class managedObjectContext] save:&error]){
        NSLog(@"Error: %@", [error localizedDescription]);
        return false;
    }
    return true;
}

@end

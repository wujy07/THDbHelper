//
//  THBaseModel.m
//  THDbOrm
//
//  Created by Junyan Wu on 16/12/15.
//  Copyright © 2016年 THU. All rights reserved.
//

#import "THBaseModel.h"
#import "THDbManager.h"
#import "FMResultSet.h"
#import <objc/runtime.h>

@implementation THBaseModel

#pragma mark - must override -

+ (NSString *)tableName {
    NSAssert(false, @"don't call this super method!");
    return nil;
}

+ (NSString *)primaryKeyName {
    NSAssert(false, @"don't call this super method!");
    return nil;
}

+ (NSDictionary *)columnPropertyMapping {
    NSAssert(false, @"don't call this super method!");
    return nil;
}

+ (NSString *)autoincrementKey {
    return @"rowid";
}

- (id)primaryKeyValue {
    NSDictionary *mapping = [self.class columnPropertyMapping];
    return [self valueForKey:mapping[[self.class primaryKeyName]]];
}

#pragma mark - insert -

- (BOOL)insert {
    NSString *sql = [self.class insertSql];
    NSArray *args = [self insertArgs];
    return [THDbManager insert:sql withArgs:args];
}

- (void)insertAsync:(THInsertCallBack)callback {
    NSString *sql = [self.class insertSql];
    NSArray *args = [self insertArgs];
    [THDbManager insertAsync:sql withArgs:args callback:callback];
}

+ (BOOL)insertBatch:(NSArray *)models {
    NSString *insert = [self insertSql];
    NSMutableArray *argsArray = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *args = [obj insertArgs];
        [argsArray addObject:args];
    }];
    return [THDbManager insertBatch:insert withArgsArray:argsArray];
}

+ (void)insertBatchAsync:(NSArray *)models callback:(THInsertBatchCallBack)callback {
    NSString *insert = [self insertSql];
    NSMutableArray *argsArray = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *args = [obj insertArgs];
        [argsArray addObject:args];
    }];
    [THDbManager insertBatchAsync:insert withArgsArray:argsArray callback:callback];
}

+ (NSString *)insertSql {
    //insert 须忽略rowid 等自增键
    NSDictionary *mapping = [self.class columnPropertyMapping];
    NSArray *allColumns = mapping.allKeys;
    NSArray *allColumnsExceptAutoIncrementKey = [allColumns filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *columnName, NSDictionary *bindings) {
        return ![columnName isEqualToString:[self.class autoincrementKey]];
    }]];
    NSString *sql = [NSString stringWithFormat:@"INSERT OR IGNORE INTO %@ (%@) VALUES (", [self.class tableName], [allColumnsExceptAutoIncrementKey componentsJoinedByString:@", "]];
    for (NSInteger i = 0;i < allColumnsExceptAutoIncrementKey.count;i++) {
        if ( 0 != i ) {
            sql = [sql stringByAppendingString:@", "];
        }
        sql = [sql stringByAppendingString:@"?"];
    }
    sql = [sql stringByAppendingString:@")"];
    return sql;
}

- (NSArray *)insertArgs {
    NSDictionary *mapping = [self.class columnPropertyMapping];
    NSArray *allColumns = mapping.allKeys;
    NSMutableArray *args = [NSMutableArray array];
    for (NSInteger i = 0;i < allColumns.count;i++) {
        NSString * columnName = [allColumns objectAtIndex:i];
        id columnValue = [self valueForKey:mapping[columnName]];
        [args addObject:[self.class objOrNull:columnValue]];
    }
    return args;
}

#pragma mark - update -

- (BOOL)update {
    NSString *sql = [self.class updateSql];
    NSArray *args = [self updateArgs];
    return [THDbManager update:sql withArgs:args];
}

- (void)updateAsync:(THDbCallBack)callback {
    NSString *sql = [self.class updateSql];
    NSArray *args = [self updateArgs];
    [THDbManager updateAsync:sql withArgs:args callback:callback];
}

+ (BOOL)updateBatch:(NSArray *)models {
    NSString *sql = [self.class updateSql];
    NSMutableArray *argsArray = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *args = [obj updateArgs];
        [argsArray addObject:args];
    }];
    return [THDbManager updateBatch:sql withArgsArray:argsArray];
}

+ (void)updateBatchAsync:(NSArray *)models callback:(THDbCallBack)callback {
    NSString *sql = [self.class updateSql];
    NSMutableArray *argsArray = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *args = [obj updateArgs];
        [argsArray addObject:args];
    }];
    [THDbManager updateBatchAsync:sql withArgsArray:argsArray callback:callback];
}

+ (NSString *)updateSql {
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET ", [self tableName]];
    NSDictionary *mapping = [self columnPropertyMapping];
    NSArray *columnsExceptPrimaryKey = [mapping.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *columnName, NSDictionary *bindings) {
        return ![columnName isEqualToString:[self primaryKeyName]];
    }]];
    sql = [sql stringByAppendingString:[columnsExceptPrimaryKey componentsJoinedByString:@"=?, "]];
    sql = [sql stringByAppendingFormat:@"=? where %@=?", [self primaryKeyName]];
    return sql;
}

- (NSArray *)updateArgs {
    NSDictionary *mapping = [self.class columnPropertyMapping];
    NSArray *columnsExceptPrimaryKey = [mapping.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *columnName, NSDictionary *bindings) {
        return ![columnName isEqualToString:[self.class primaryKeyName]];
    }]];
    NSMutableArray *args = [NSMutableArray array];
    for (NSInteger i = 0;i < columnsExceptPrimaryKey.count;i++) {
        NSString * columnName = [columnsExceptPrimaryKey objectAtIndex:i];
        id columnValue = [self valueForKey:mapping[columnName]];
        [args addObject:[self.class objOrNull:columnValue]];
    }
    id primaryKeyValue = [self primaryKeyValue];
    [args addObject:primaryKeyValue];
    return args;
}

#pragma mark - delete -

- (BOOL)remove {
    NSDictionary *mapping = [self.class columnPropertyMapping];
    id columnValue = [self valueForKey:mapping[[self.class primaryKeyName]]];
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", [self.class tableName], [self.class primaryKeyName]];
    return [THDbManager execute:deleteSQL withArgs:@[columnValue]];
}

- (void)removeAsync:(THDbCallBack)callback {
    NSDictionary *mapping = [self.class columnPropertyMapping];
    id columnValue = [self valueForKey:mapping[[self.class primaryKeyName]]];
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", [self.class tableName], [self.class primaryKeyName]];
    [THDbManager executeAsync:deleteSQL withArgs:@[columnValue] callback:callback];
}

+ (BOOL)removeBatch:(NSArray *)models {
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", [self.class tableName], [self.class primaryKeyName]];
    NSMutableArray *argsArray = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *args = @[[obj primaryKeyValue]];
        [argsArray addObject:args];
    }];
    return [THDbManager executeBatch:deleteSQL withArgsArray:argsArray];
}

+ (void)removeBatchAsync:(NSArray *)models callback:(THDbCallBack)callback {
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?", [self.class tableName], [self.class primaryKeyName]];
    NSMutableArray *argsArray = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *args = @[[obj primaryKeyValue]];
        [argsArray addObject:args];
    }];
    [THDbManager executeBatchAsync:deleteSQL withArgsArray:argsArray callback:callback];
}

#pragma mark - Query -

+ (NSArray *)query:(NSString *)query withArgs:(NSArray *)args {
    __block NSMutableArray *modelArray;
    [THDbManager query:query withArgs:args resultSetBlock:^(FMResultSet *result, NSError *err) {
        if (err) {
            return;
        }
        NSDictionary *mapping = [self columnPropertyMapping];
        while ([result next]) {
            id model = [[self alloc] init];
            for (int i = 0; i < [result columnCount]; i++) {
                NSString *columnName = [result columnNameForIndex:i];
                //进行数据库列名到model属性名之间的映射转换
                NSString *propertyName;
                if(mapping) {
                    propertyName = mapping[columnName];
                }
                if (![result columnIndexIsNull:i] && propertyName) {
                    [self setPropertyFor:model value:result columnName:columnName propertyName:propertyName];
                }
                NSAssert(![propertyName isEqualToString:@"description"], @"description为自带方法，不能对description进行赋值，请使用其他属性名");
            }
            if (!modelArray) {
                modelArray = [NSMutableArray array];
            }
            [modelArray addObject:model];
        }
    }];
    return modelArray;
}

+ (void)setPropertyFor:(id)model value:(FMResultSet *)rs columnName:(NSString *)columnName propertyName:(NSString *)propertyName {
    //    @"c" : @"char",
    //    @"i" : @"int",
    //    @"s":@"short",
    //    @"l":@"long",
    //    @"q":@"long long",
    //    @"f":@"float",
    //    @"d":@"double",
    //    @"C":@"unsigned char",
    //    @"I" : @"unsigned int",
    //    @"S":@"unsigned short",
    //    @"L":@"unsigned long",
    //    @"Q":@"unsigned long long",
    //    @"B":@"BOOL",
    objc_property_t objProperty = class_getProperty(self, propertyName.UTF8String);
    if (!objProperty) {
        return;
    }
    NSString *typeString = [NSString stringWithUTF8String:property_getAttributes(objProperty)];
    NSString *firstType = [[[typeString componentsSeparatedByString:@","] firstObject] substringFromIndex:1];
    NSArray *propertyLikeInt = [@"c, i, s, l, q, C, I, S, L, Q, B" componentsSeparatedByString:@", "];
    NSArray *propertyLikeDouble = @[@"f", @"d"];
    if ([propertyLikeInt containsObject:firstType]) {
        NSNumber *number = [rs objectForColumnName:columnName];
        long long numberValue = [number longLongValue];
        [model setValue:@(numberValue) forKey:propertyName];
    } else if([propertyLikeDouble containsObject:firstType]) {
        NSNumber *number = [rs objectForColumnName:columnName];
        double numberValue = [number doubleValue];
        [model setValue:@(numberValue) forKey:propertyName];
    }else if([firstType isEqualToString:@"@\"NSData\""]){
        NSData *value = [rs dataForColumn:columnName];
        [model setValue:value forKey:propertyName];
    } else if([firstType isEqualToString:@"@\"NSDate\""]){
        NSDate *value = [rs dateForColumn:columnName];
        [model setValue:value forKey:propertyName];
    } else if([firstType isEqualToString:@"@\"NSString\""]){
        NSString *value = [rs stringForColumn:columnName];
        [model setValue:value forKey:propertyName];
    } else {
        [model setValue:[rs objectForColumnName:columnName] forKey:propertyName];
    }
}

+ (id)objOrNull:(id)value {
    return value ? value : [NSNull null];
}

@end

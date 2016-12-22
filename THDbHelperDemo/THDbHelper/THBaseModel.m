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
    return [self insertWithOption:THInsertOptionIgnore];
}

- (void)insertAsync:(THInsertCallBack)callback {
    [self insertAsync:callback withOption:THInsertOptionIgnore];
}

+ (BOOL)insertBatch:(NSArray *)models {
    return [self insertBatch:models withOption:THInsertOptionIgnore];
}

+ (void)insertBatchAsync:(NSArray *)models callback:(THInsertBatchCallBack)callback {
    [self insertBatchAsync:models callback:callback withOption:THInsertOptionIgnore];
}

- (BOOL)insertWithOption:(THInsertOption)insertOption {
    NSString *sql = [self.class insertSqlWithOption:insertOption];
    NSArray *args = [self insertArgs];
    return [THDbManager execute:sql withArgs:args];
}

- (void)insertAsync:(THInsertCallBack)callback withOption:(THInsertOption)insertOption {
    NSString *sql = [self.class insertSqlWithOption:insertOption];
    NSArray *args = [self insertArgs];
    [THDbManager insertAsync:sql withArgs:args callback:callback];
}

+ (BOOL)insertBatch:(NSArray *)models withOption:(THInsertOption)insertOption {
    NSString *insert = [self insertSqlWithOption:insertOption];
    NSMutableArray *argsArray = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *args = [obj insertArgs];
        [argsArray addObject:args];
    }];
    return [THDbManager executeBatch:insert withArgsArray:argsArray];
}

+ (void)insertBatchAsync:(NSArray *)models callback:(THInsertBatchCallBack)callback withOption:(THInsertOption)insertOption {
    NSString *insert = [self insertSqlWithOption:insertOption];
    NSMutableArray *argsArray = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *args = [obj insertArgs];
        [argsArray addObject:args];
    }];
    [THDbManager insertBatchAsync:insert withArgsArray:argsArray callback:callback];
}

+ (NSString *)insertSqlWithOption:(THInsertOption)insertOption {
    //insert 须忽略rowid 等自增键
    NSDictionary *mapping = [self.class columnPropertyMapping];
    NSArray *allColumns = mapping.allKeys;
    NSArray *allColumnsExceptAutoIncrementKey = [allColumns filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *columnName, NSDictionary *bindings) {
        return ![columnName isEqualToString:[self.class autoincrementKey]];
    }]];
    NSString *sql;
    if (insertOption == THInsertOptionUpdate) {
        sql = [NSString stringWithFormat:@"REPLACE INTO %@ (%@) VALUES (", [self.class tableName], [allColumnsExceptAutoIncrementKey componentsJoinedByString:@", "]];
    } else {
        sql = [NSString stringWithFormat:@"INSERT OR IGNORE INTO %@ (%@) VALUES (", [self.class tableName], [allColumnsExceptAutoIncrementKey componentsJoinedByString:@", "]];
    }
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
    return [THDbManager execute:sql withArgs:args];
}

- (void)updateAsync:(THDbCallBack)callback {
    NSString *sql = [self.class updateSql];
    NSArray *args = [self updateArgs];
    [THDbManager executeAsync:sql withArgs:args callback:callback];
}

+ (BOOL)updateBatch:(NSArray *)models {
    NSString *sql = [self.class updateSql];
    NSMutableArray *argsArray = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *args = [obj updateArgs];
        [argsArray addObject:args];
    }];
    return [THDbManager executeBatch:sql withArgsArray:argsArray];
}

+ (void)updateBatchAsync:(NSArray *)models callback:(THDbCallBack)callback {
    NSString *sql = [self.class updateSql];
    NSMutableArray *argsArray = [NSMutableArray array];
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *args = [obj updateArgs];
        [argsArray addObject:args];
    }];
    [THDbManager executeBatchAsync:sql withArgsArray:argsArray callback:callback];
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

#pragma mark - query sync -

+ (NSArray *)query {
    return [self queryWithWhere:nil args:nil];
}

+ (NSArray *)queryWithWhere:(NSString *)where args:(NSArray *)args {
    return [self queryWithWhere:where columns:nil args:args];
}

+ (NSArray *)queryWithWhere:(NSString *)where columns:(NSArray<NSString *> *)columns args:(NSArray *)args {
    return [self queryWithWhere:where orderBy:nil limit:-1 offset:0 columns:columns args:args];
}

+ (NSArray *)queryWithWhere:(NSString *)where orderBy:(NSString *)orderBy limit:(SInt64)limit offset:(SInt64)offset columns:(NSArray<NSString *> *)columns args:(NSArray *)args {
    NSString *query = [self querySqlWithWhere:where orderBy:orderBy limit:limit offset:offset columns:columns];
    return [self query:query withArgs:args];
}

+ (NSString *)querySqlWithWhere:(NSString *)where orderBy:(NSString *)orderBy limit:(SInt64)limit offset:(SInt64)offset columns:(NSArray<NSString *> *)columns {
    NSMutableString *query;
    if (columns && columns.count > 0) {
        NSString *columnsSql = [columns componentsJoinedByString:@", "];
        query = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@ ", columnsSql, [self tableName]];
    } else {
        query = [NSMutableString stringWithFormat:@"SELECT * FROM %@ ", [self tableName]];
    }
    if (where) {
        [query appendString:[NSString stringWithFormat:@"where %@ ", where]];
    }
    if (orderBy) {
        [query appendString:[NSString stringWithFormat:@"order by %@ ", orderBy]];
    }
    NSString *limitSql = [NSString stringWithFormat:@"limit %lld offset %lld ", limit, offset];
    [query appendString:limitSql];
    return query;
}

#pragma mark - query async -

+ (void)queryAsync:(THDbQueryCallBack)callback {
    [self queryAsync:callback where:nil args:nil];
}

+ (void)queryAsync:(THDbQueryCallBack)callback where:(NSString *)where args:(NSArray *)args {
    [self queryAsync:callback where:where columns:nil args:args];
}

+ (void)queryAsync:(THDbQueryCallBack)callback where:(NSString *)where columns:(NSArray<NSString *> *)columns args:(NSArray *)args {
    [self queryAsync:callback where:where orderBy:nil limit:-1 offset:0 columns:columns args:args];
}

+ (void)queryAsync:(THDbQueryCallBack)callback where:(NSString *)where orderBy:(NSString *)orderBy limit:(SInt64)limit offset:(SInt64)offset columns:(NSArray<NSString *> *)columns args:(NSArray *)args {
    NSString *query = [self querySqlWithWhere:where orderBy:orderBy limit:limit offset:offset columns:columns];
    [self queryAsync:query withArgs:args callback:callback];
}

#pragma mark - query lower method -

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
                NSString *propertyName;
                if(mapping) {
                    propertyName = mapping[columnName];
                }
                if (![result columnIndexIsNull:i] && propertyName) {
                    [self setPropertyFor:model value:result columnName:columnName propertyName:propertyName];
                }
                NSAssert(![propertyName isEqualToString:@"description"], @"can not set description, please use other property name");
            }
            if (!modelArray) {
                modelArray = [NSMutableArray array];
            }
            [modelArray addObject:model];
        }
    }];
    return modelArray;
}

+ (void)queryAsync:(NSString *)query withArgs:(NSArray *)args callback:(THDbQueryCallBack)callback {
    [THDbManager queryAsync:query withArgs:args resultSetBlock:^(FMResultSet *result, NSError *err) {
        if (err) {
            callback(nil, err);
            return;
        }
        NSMutableArray *modelArray;
        NSDictionary *mapping = [self columnPropertyMapping];
        while ([result next]) {
            id model = [[self alloc] init];
            for (int i = 0; i < [result columnCount]; i++) {
                NSString *columnName = [result columnNameForIndex:i];
                NSString *propertyName;
                if(mapping) {
                    propertyName = mapping[columnName];
                }
                if (![result columnIndexIsNull:i] && propertyName) {
                    [self setPropertyFor:model value:result columnName:columnName propertyName:propertyName];
                }
                NSAssert(![propertyName isEqualToString:@"description"], @"can not set description, please use other property name");
            }
            if (!modelArray) {
                modelArray = [NSMutableArray array];
            }
            [modelArray addObject:model];
        }
        callback(modelArray, nil);
    }];
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

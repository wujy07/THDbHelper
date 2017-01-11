//
//  THBaseModel.h
//  THDbHelper
//
//  Created by Junyan Wu on 16/12/15.
//  Copyright © 2016年 THU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "THDbHelperConsts.h"

@interface THBaseModel : NSObject

#pragma mark - must override -

+ (NSString *)tableName;
+ (NSString *)primaryKeyName;
+ (NSDictionary *)columnPropertyMapping;

#pragma mark - optional override -

+ (NSString *)autoincrementKey;
- (id)primaryKeyValue;


#pragma mark - insert -
//default insert option:ignore when exists
- (BOOL)insert;
- (void)insertAsync:(THInsertCallBack)callback;
+ (BOOL)insertBatch:(NSArray *)models;
+ (void)insertBatchAsync:(NSArray *)models callback:(THInsertBatchCallBack)callback;

//insert option:update when exists
- (BOOL)insertWithOption:(THInsertOption)insertOption;
- (void)insertAsync:(THInsertCallBack)callback withOption:(THInsertOption)insertOption;
+ (BOOL)insertBatch:(NSArray *)models withOption:(THInsertOption)insertOption;
+ (void)insertBatchAsync:(NSArray *)models callback:(THInsertBatchCallBack)callback withOption:(THInsertOption)insertOption;

#pragma mark - update -

- (BOOL)update;
- (void)updateAsync:(THDbCallBack)callback;
+ (BOOL)updateBatch:(NSArray *)models;
+ (void)updateBatchAsync:(NSArray *)models callback:(THDbCallBack)callback;

//support where clause 
- (BOOL)updateWithWhere:(NSString *)where args:(NSArray *)whereArgs;
- (void)updateAsync:(THDbCallBack)callback where:(NSString *)where args:(NSArray *)whereArgs;
+ (BOOL)updateBatch:(NSArray *)models where:(NSString *)where args:(NSArray *)whereArgs;
+ (void)updateBatchAsync:(NSArray *)models callback:(THDbCallBack)callback where:(NSString *)where args:(NSArray *)whereArgs;

//support only filter needupdate columns
- (BOOL)updateWithWhere:(NSString *)where args:(NSArray *)whereArgs needUpdateColumns:(NSArray *)columns;
- (void)updateAsync:(THDbCallBack)callback where:(NSString *)where args:(NSArray *)whereArgs needUpdateColumns:(NSArray *)columns;
+ (BOOL)updateBatch:(NSArray *)models where:(NSString *)where args:(NSArray *)whereArgs needUpdateColumns:(NSArray *)columns;
+ (void)updateBatchAsync:(NSArray *)models callback:(THDbCallBack)callback where:(NSString *)where args:(NSArray *)whereArgs needUpdateColumns:(NSArray *)columns;

#pragma mark - delete -

- (BOOL)remove;
- (void)removeAsync:(THDbCallBack)callback;
+ (BOOL)removeBatch:(NSArray *)models;
+ (void)removeBatchAsync:(NSArray *)models callback:(THDbCallBack)callback;

#pragma mark - query -
//query sync
+ (NSArray *)query;
+ (NSArray *)queryWithWhere:(NSString *)where args:(NSArray *)args;
+ (NSArray *)queryWithWhere:(NSString *)where columns:(NSArray<NSString *> *)columns args:(NSArray *)args;
+ (NSArray *)queryWithWhere:(NSString *)where orderBy:(NSString *)orderBy limit:(SInt64)limit offset:(SInt64)offset columns:(NSArray<NSString *> *)columns args:(NSArray *)args;

//query async
+ (void)queryAsync:(THDbQueryCallBack)callback;
+ (void)queryAsync:(THDbQueryCallBack)callback where:(NSString *)where args:(NSArray *)args;
+ (void)queryAsync:(THDbQueryCallBack)callback where:(NSString *)where columns:(NSArray<NSString *> *)columns args:(NSArray *)args;
+ (void)queryAsync:(THDbQueryCallBack)callback where:(NSString *)where orderBy:(NSString *)orderBy limit:(SInt64)limit offset:(SInt64)offset columns:(NSArray<NSString *> *)columns args:(NSArray *)args;

//lower method: custom query sql
+ (NSArray *)query:(NSString *)query withArgs:(NSArray *)args;
+ (void)queryAsync:(NSString *)query withArgs:(NSArray *)args callback:(THDbQueryCallBack)callback;

@end

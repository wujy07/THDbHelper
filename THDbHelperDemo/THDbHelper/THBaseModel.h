//
//  THBaseModel.h
//  THDbOrm
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
+ (NSString *)autoincrementKey;


#pragma mark - insert -
//to do insert option:ignore or update when exists
- (BOOL)insert;
- (void)insertAsync:(THInsertCallBack)callback;
+ (BOOL)insertBatch:(NSArray *)models;
+ (void)insertBatchAsync:(NSArray *)models callback:(THInsertBatchCallBack)callback;

#pragma mark - update -

- (BOOL)update;
- (void)updateAsync:(THDbCallBack)callback;
+ (BOOL)updateBatch:(NSArray *)models;
+ (void)updateBatchAsync:(NSArray *)models callback:(THDbCallBack)callback;

#pragma mark - delete -
- (BOOL)remove;
- (void)removeAsync:(THDbCallBack)callback;
+ (BOOL)removeBatch:(NSArray *)models;
+ (void)removeBatchAsync:(NSArray *)models callback:(THDbCallBack)callback;

+ (NSArray *)query:(NSString *)query withArgs:(NSArray *)args;

@end

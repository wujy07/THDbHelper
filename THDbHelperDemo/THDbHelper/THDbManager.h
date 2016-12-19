//
//  THDbManager.h
//  THDbOrm
//
//  Created by Junyan Wu on 16/12/15.
//  Copyright © 2016年 THU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "THDbHelperConsts.h"

@class FMDatabaseQueue, FMResultSet;

@interface THDbManager : NSObject

+ (void)openWithPath:(NSString *)path andTableCreateSQL:(NSString *)sql;
+ (void)closeDb;

//insert
+ (BOOL)insert:(NSString *)insert withArgs:(NSArray *)args;
+ (void)insertAsync:(NSString *)insert withArgs:(NSArray *)args callback:(THInsertCallBack)callback;
+ (BOOL)insertBatch:(NSString *)insert withArgsArray:(NSArray *)argsArray;
+ (void)insertBatchAsync:(NSString *)insert withArgsArray:(NSArray *)argsArray callback:(THInsertBatchCallBack)callback;

//update
+ (BOOL)update:(NSString *)update withArgs:(NSArray *)args;
+ (void)updateAsync:(NSString *)update withArgs:(NSArray *)args callback:(THDbCallBack)callback;
+ (BOOL)updateBatch:(NSString *)update withArgsArray:(NSArray *)argsArray;
+ (void)updateBatchAsync:(NSString *)update withArgsArray:(NSArray *)argsArray callback:(THDbCallBack)callback;

//query
+ (void)query:(NSString *)query withArgs:(NSArray *)args resultSetBlock:(void (^)(FMResultSet *result, NSError *err))resultSetBlock;

//utility
+ (BOOL)execute:(NSString *)sql withArgs:(NSArray *)args;
+ (void)executeAsync:(NSString *)sql withArgs:(NSArray *)args callback:(THDbCallBack)callback;
+ (BOOL)executeBatch:(NSString *)sql withArgsArray:(NSArray *)argsArray;
+ (void)executeBatchAsync:(NSString *)sql withArgsArray:(NSArray *)argsArray callback:(THDbCallBack)callback;

@end

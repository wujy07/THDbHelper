//
//  THDbManager.h
//  THDbHelper
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
+ (void)insertAsync:(NSString *)insert withArgs:(NSArray *)args callback:(THInsertCallBack)callback;
+ (void)insertBatchAsync:(NSString *)insert withArgsArray:(NSArray *)argsArray callback:(THInsertBatchCallBack)callback;

//query
+ (void)query:(NSString *)query withArgs:(NSArray *)args resultSetBlock:(void (^)(FMResultSet *result, NSError *err))resultSetBlock;
+ (void)queryAsync:(NSString *)query withArgs:(NSArray *)args resultSetBlock:(void(^)(FMResultSet *result, NSError *err))resultSetBlock;
//utility
+ (BOOL)execute:(NSString *)sql withArgs:(NSArray *)args;
+ (void)executeAsync:(NSString *)sql withArgs:(NSArray *)args callback:(THDbCallBack)callback;
+ (BOOL)executeBatch:(NSString *)sql withArgsArray:(NSArray *)argsArray;
+ (void)executeBatchAsync:(NSString *)sql withArgsArray:(NSArray *)argsArray callback:(THDbCallBack)callback;

@end

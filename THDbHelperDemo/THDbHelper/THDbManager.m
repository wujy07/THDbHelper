//
//  THDbManager.m
//  THDbHelper
//
//  Created by Junyan Wu on 16/12/15.
//  Copyright © 2016年 THU. All rights reserved.
//

#import "THDbManager.h"
#import "FMDB.h"

const char *kAsynQueueUniqId = "com.tsinghua.dbAsynQueueUniqId";

@interface THDbManager ()

@property (nonatomic, strong) dispatch_queue_t thAsynQueue;
@property (nonatomic, strong) FMDatabaseQueue *fmdbQueue;

@end

@implementation THDbManager

+ (instancetype)sharedManager {
    static THDbManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[THDbManager alloc] init];
    });
    return _sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        self.thAsynQueue = dispatch_queue_create(kAsynQueueUniqId, DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (void)openWithPath:(NSString *)path andTableCreateSQL:(NSString *)sql {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isExists = [manager fileExistsAtPath:path isDirectory:nil];
    if (!isExists) {
        BOOL success = [manager createFileAtPath:path contents:nil attributes:@{}];
        if (!success) {
            NSLog(@"cannot create db file at db path!");
            return;
        }
    }
    THDbManager *shareManager = [self sharedManager];
    shareManager.fmdbQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    [self setupTablesWithSql:sql];
}

+ (void)closeDb {
    THDbManager *shareManager = [self sharedManager];
    if (shareManager.fmdbQueue) {
        [shareManager.fmdbQueue close];
        shareManager.fmdbQueue = nil;
    }
}

+ (void)setupTablesWithSql:(NSString *)sql {
    THDbManager *shareManager = [self sharedManager];
    [shareManager.fmdbQueue inDatabase:^(FMDatabase *db) {
#if DEBUG
        db.logsErrors = YES;
#endif
        BOOL success = [db executeStatements:sql];
        if (!success) {
            NSLog(@"create table: %@", db.lastError);
        }
    }];
}

#pragma mark - insert -

+ (void)insertAsync:(NSString *)insert withArgs:(NSArray *)args callback:(THInsertCallBack)callback {
    THDbManager *sharedManager = [self sharedManager];
    __block NSError *err;
    __block SInt64 rowid;
    dispatch_async(sharedManager.thAsynQueue, ^{
        [sharedManager.fmdbQueue inDatabase:^(FMDatabase *db) {
            BOOL success = [db executeUpdate:insert withArgumentsInArray:args];
            if (!success) {
                err = db.lastError;
            } else {
                rowid = db.lastInsertRowId;
            }
        }];
        if (callback) {
            callback(rowid, err);
        }
    });
}

+ (void)insertBatchAsync:(NSString *)insert withArgsArray:(NSArray *)argsArray callback:(THInsertBatchCallBack)callback {
    THDbManager *sharedManager = [self sharedManager];
    dispatch_async(sharedManager.thAsynQueue, ^{
        __block NSError *err;
        __block NSMutableArray *ids;
        [sharedManager.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (NSArray *args in argsArray) {
                BOOL success = [db executeUpdate:insert withArgumentsInArray:args];
                if (!success) {
                    err = db.lastError;
                    NSLog(@"insert error: %@", err);
                    *rollback = YES;
                    return;
                } else {
                    if (!ids) {
                        ids = [NSMutableArray array];
                    }
                    [ids addObject:@(db.lastInsertRowId)];
                }
            }
        }];
        if (callback) {
            callback(ids, err);
        }
    });
}

#pragma mark - query -

+ (void)query:(NSString *)query withArgs:(NSArray *)args resultSetBlock:(void (^)(FMResultSet *result, NSError *err))resultSetBlock {
    THDbManager *shareManager = [self sharedManager];
    if (!shareManager.fmdbQueue) {
        NSError *err;
        resultSetBlock(nil, err);
        return;
    }
    [shareManager.fmdbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:query withArgumentsInArray:args];
        NSError *err = nil;
        if (!result) {
            err = db.lastError;
        }
        if (resultSetBlock) {
            resultSetBlock(result, err);
        }
        [result close];
    }];
}

+ (void)queryAsync:(NSString *)query withArgs:(NSArray *)args resultSetBlock:(void(^)(FMResultSet *result, NSError *err))resultSetBlock {
    THDbManager *sharedManager = [self sharedManager];
    dispatch_async(sharedManager.thAsynQueue, ^{
        if (!sharedManager.fmdbQueue) {
            NSError *err;
            resultSetBlock(nil, err);
        }
        [sharedManager.fmdbQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *result = [db executeQuery:query withArgumentsInArray:args];
            NSError *err = nil;
            if (!result) {
                err = db.lastError;
            }
            if (resultSetBlock) {
                resultSetBlock(result, err);
            }
            [result close];
        }];
        
    });
}

#pragma mark - utility -

+ (BOOL)execute:(NSString *)sql withArgs:(NSArray *)args {
    THDbManager *shareManager = [self sharedManager];
    __block BOOL success = NO;
    [shareManager.fmdbQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:sql withArgumentsInArray:args];
        if (!success) {
            NSLog(@"sync execute error: %@", db.lastError);
        }
    }];
    return success;
}

+ (void)executeAsync:(NSString *)sql withArgs:(NSArray *)args callback:(THDbCallBack)callback {
    THDbManager *sharedManager = [self sharedManager];
    __block NSError *err;
    dispatch_async(sharedManager.thAsynQueue, ^{
        [sharedManager.fmdbQueue inDatabase:^(FMDatabase *db) {
            BOOL success = [db executeUpdate:sql withArgumentsInArray:args];
            if (!success) {
                err = db.lastError;
            }
        }];
        if (callback) {
            callback(err);
        }
    });
}

+ (BOOL)executeBatch:(NSString *)sql withArgsArray:(NSArray *)argsArray {
    THDbManager *sharedManager = [self sharedManager];
    __block BOOL success;
    [sharedManager.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSArray *args in argsArray) {
            success = [db executeUpdate:sql withArgumentsInArray:args];
            if (!success) {
                NSLog(@"execute batch error: %@", db.lastError);
                *rollback = YES;
                return;
            }
        }
    }];
    return success;
}

+ (void)executeBatchAsync:(NSString *)sql withArgsArray:(NSArray *)argsArray callback:(THDbCallBack)callback {
    THDbManager *sharedManager = [self sharedManager];
    __block NSError *err;
    dispatch_async(sharedManager.thAsynQueue, ^{
        [sharedManager.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (NSArray *args in argsArray) {
                BOOL success = [db executeUpdate:sql withArgumentsInArray:args];
                if (!success) {
                    err = db.lastError;
                    NSLog(@"excute batch error: %@", err);
                    *rollback = YES;
                    return;
                }
            }
        }];
        if (callback) {
            callback(err);
        }
    });
}

@end


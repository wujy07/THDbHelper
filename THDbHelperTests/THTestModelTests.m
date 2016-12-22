//
//  THTestModelTests.m
//  THDbHelperDemo
//
//  Created by Junyan Wu on 16/12/15.
//  Copyright © 2016年 THU. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "THTestModel.h"
#import "THDbManager.h"
#import "THBaseModel+Tests.h"

@interface THTestModelTests : XCTestCase

@end

@implementation THTestModelTests

#pragma mark - setup and teardown -

- (void)setUp {
    [super setUp];
    NSString *dir = [[self documentsDirectory] stringByAppendingPathComponent:@"test"];
    NSString *fileName = @"test.db";
    NSString *path = [dir stringByAppendingPathComponent:fileName];
    NSString *createTableSql =
    @"CREATE TABLE IF NOT EXISTS test (name TEXT, age INTEGER, birth_date REAL);";
    [THDbManager openWithPath:path andTableCreateSQL:createTableSql];
}

- (void)tearDown {
    [THTestModel clearTable];
    [THDbManager closeDb];
    [super tearDown];
}

- (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths.count > 0) {
        return [paths objectAtIndex:0];
    } else {
        return nil;
    }
}

#pragma mark - test insert -

- (void)testInsertAndQuery {
    THTestModel *testModel = [[THTestModel alloc] init];
    testModel.name = @"test";
    testModel.age = 17;
    testModel.birthDate = [NSDate date];
    BOOL success = [testModel insert];
    XCTAssertTrue(success);
    NSString *sql = @"SELECT * FROM test";
    THTestModel *queryModel = [[THTestModel query:sql withArgs:nil] firstObject];
    XCTAssertNotNil(queryModel);
}

- (void)testInsertAsync {
    XCTestExpectation *expectation = [self expectationWithDescription:@"insert async"];
    THTestModel *testModel = [[THTestModel alloc] init];
    testModel.name = @"test";
    testModel.age = 17;
    testModel.birthDate = [NSDate date];
    [testModel insertAsync:^(SInt64 rowid, NSError *err) {
        XCTAssertNil(err);
        XCTAssertEqual(rowid, 1);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"time out!");
        }
    }];
}

- (void)testInsertBatch {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 10;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    BOOL succeess = [THTestModel insertBatch:models];
    XCTAssertTrue(succeess);
    NSArray *queryModels = [THTestModel query:@"SELECT * FROM test" withArgs:nil];
    XCTAssertTrue([models isEqualToArray:queryModels]);
}

- (void)testInsertBatchAsync {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 10;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    XCTestExpectation *expectation = [self expectationWithDescription:@"insert batch async"];
    [THTestModel insertBatchAsync:models callback:^(NSArray *ids, NSError *err) {
        XCTAssertEqual(ids.count, 10);
        XCTAssertNil(err);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"time out:%@", error);
        }
    }];
}

#pragma mark - test query -

- (void)testQuery {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 100;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    [THTestModel insertBatch:models];
    NSArray *queryModels = [THTestModel queryWithWhere:@"age <= ? AND name LIKE 'test1%' " orderBy:@"age desc"
                                                 limit:5
                                                offset:1
                                               columns:@[@"name", @"age"]
                                                  args:@[@34]];
    [models removeAllObjects];
    for (int i = 16;i > 11;i--) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        [models addObject:testModel];
    }
    XCTAssertNotNil(queryModels);
    XCTAssertTrue([queryModels isEqualToArray:models]);
}

- (void)testQueryAsync {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 100;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    [THTestModel insertBatch:models];
    XCTestExpectation *expectation = [self expectationWithDescription:@"query async"];
    [THTestModel queryAsync:^(NSArray *result, NSError *err) {
                                [models removeAllObjects];
                                for (int i = 16;i > 11;i--) {
                                    THTestModel *testModel = [[THTestModel alloc] init];
                                    testModel.name = [NSString stringWithFormat:@"test%d", i];
                                    testModel.age = 17 + i;
                                    [models addObject:testModel];
                                }
                                XCTAssertNotNil(result);
                                XCTAssertTrue([result isEqualToArray:models]);
                                [expectation fulfill];
                            }
                      where:@"age <= ? AND name LIKE 'test1%' " orderBy:@"age desc"
                      limit:5
                     offset:1
                    columns:@[@"name", @"age"]
                       args:@[@34]];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"time out:%@", error);
        }
    }];
}

#pragma mark - test update -

- (void)testUpdate {
    THTestModel *testModel = [[THTestModel alloc] init];
    testModel.name = @"test";
    testModel.age = 17;
    testModel.birthDate = [NSDate date];
    [testModel insert];
    testModel.age = 19;
    BOOL success = [testModel update];
    XCTAssertTrue(success);
    THTestModel *queryModel = [THTestModel query:@"SELECT * FROM test" withArgs:nil].firstObject;
    XCTAssertTrue([queryModel isEqual:testModel]);
}

- (void)testUpdateAsync {
    THTestModel *testModel = [[THTestModel alloc] init];
    testModel.name = @"test";
    testModel.age = 17;
    testModel.birthDate = [NSDate date];
    [testModel insert];
    testModel.age = 19;
    XCTestExpectation *expectation = [self expectationWithDescription:@"update async"];
    [testModel updateAsync:^(NSError *err) {
        XCTAssertNil(err);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"time out:%@", error);
        }
    }];
}

- (void)testUpdateBatch {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 10;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    [THTestModel insertBatch:models];
    [models enumerateObjectsUsingBlock:^(THTestModel  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.age = 60 + idx;
    }];
    [THTestModel updateBatch:models];
    NSArray *queryModels = [THTestModel query:@"SELECT * FROM test" withArgs:nil];
    XCTAssertTrue([queryModels isEqualToArray:models]);
}

- (void)testUpdateBatchAsync {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 10;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    [THTestModel insertBatch:models];
    [models enumerateObjectsUsingBlock:^(THTestModel  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.age = 60 + idx;
    }];
    XCTestExpectation *expectation = [self expectationWithDescription:@"update batch"];
    [THTestModel updateBatchAsync:models callback:^(NSError *err) {
        XCTAssertNil(err);
        NSArray *queryModels = [THTestModel query:@"SELECT * FROM test" withArgs:nil];
        XCTAssertTrue([queryModels isEqualToArray:models]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"time out:%@", error);
        }
    }];
}

#pragma mark - test delete -

- (void)testDelete {
    THTestModel *testModel = [[THTestModel alloc] init];
    testModel.name = @"test";
    testModel.age = 17;
    testModel.birthDate = [NSDate date];
    [testModel insert];
    BOOL success = [testModel remove];
    XCTAssertTrue(success);
    THTestModel *queryModel = [THTestModel query:@"SELECT * FROM test WHERE name = ?" withArgs:@[testModel.name]].firstObject;
    XCTAssertNil(queryModel);
}

- (void)testDeleteAsync {
    THTestModel *testModel = [[THTestModel alloc] init];
    testModel.name = @"test";
    testModel.age = 17;
    testModel.birthDate = [NSDate date];
    [testModel insert];
    XCTestExpectation *expectation = [self expectationWithDescription:@"delete async"];
    [testModel removeAsync:^(NSError *err) {
        XCTAssertNil(err);
        THTestModel *queryModel = [THTestModel query:@"SELECT * FROM test WHERE name = ?" withArgs:@[testModel.name]].firstObject;
        XCTAssertNil(queryModel);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"time out error:%@", error);
        }
    }];
}

- (void)testDeleteBatch {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 10;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    [THTestModel insertBatch:models];
    BOOL success = [THTestModel removeBatch:models];
    XCTAssertTrue(success);
    NSArray *queryModels = [THTestModel query:@"SELECT * FROM test" withArgs:nil];
    XCTAssertNil(queryModels);
}

- (void)testDeleteBatchAsync {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 10;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    [THTestModel insertBatch:models];
    XCTestExpectation *expectation = [self expectationWithDescription:@"delete batch async"];
    [THTestModel removeBatchAsync:models callback:^(NSError *err) {
        XCTAssertNil(err);
        NSArray *queryModels = [THTestModel query:@"SELECT * FROM test" withArgs:nil];
        XCTAssertNil(queryModels);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"time out error:%@", error);
        }
    }];
}

#pragma mark - test performance -

- (void)testInsertPerformance {
    [self measureBlock:^{
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = @"test";
        testModel.age = 17;
        testModel.birthDate = [NSDate date];
        [testModel insert];
    }];
}

- (void)testInsertBatchPerformance {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 3000;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    [self measureBlock:^{
        [THTestModel insertBatch:models];
    }];
}

- (void)testUpdatePerformance {
    THTestModel *testModel = [[THTestModel alloc] init];
    testModel.name = @"test";
    testModel.age = 17;
    testModel.birthDate = [NSDate date];
    [testModel insert];
    testModel.age = 19;
    [self measureBlock:^{
        [testModel update];
    }];
}

- (void)testUpdateBatchPerformance {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 3000;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    [THTestModel insertBatch:models];
    [models enumerateObjectsUsingBlock:^(THTestModel  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.age = 60 + idx;
    }];
    [self measureBlock:^{
        [THTestModel updateBatch:models];
    }];
    NSArray *queryModels = [THTestModel query:@"SELECT * FROM test" withArgs:nil];
    XCTAssertTrue([queryModels isEqualToArray:models]);
}

- (void)testDeletePerformance {
    THTestModel *testModel = [[THTestModel alloc] init];
    testModel.name = @"test";
    testModel.age = 17;
    testModel.birthDate = [NSDate date];
    [testModel insert];
    [self measureBlock:^{
        [testModel remove];
    }];
}

- (void)testDeleteBatchPerformance {
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 3000;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    [THTestModel insertBatch:models];
    [self measureBlock:^{
         [THTestModel removeBatch:models];
    }];
}

- (void)testQueryPerformance {
    
    NSMutableArray *models = [NSMutableArray array];
    for(int i = 0;i < 100000;i++) {
        THTestModel *testModel = [[THTestModel alloc] init];
        testModel.name = [NSString stringWithFormat:@"test%d", i];
        testModel.age = 17 + i;
        testModel.birthDate = [NSDate date];
        [models addObject:testModel];
    }
    [THTestModel insertBatch:models];
    
    [self measureBlock:^{
        NSArray *queryModels = [THTestModel queryWithWhere:@"age <= ? AND name LIKE 'test1%' "
                                                   orderBy:@"age desc"
                                                     limit:5
                                                    offset:1
                                                   columns:@[@"name", @"age"]
                                                      args:@[@200]];
        XCTAssertNotNil(queryModels);
    }];
}

@end

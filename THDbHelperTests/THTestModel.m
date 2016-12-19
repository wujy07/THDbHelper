//
//  THTestModel.m
//  THDbHelperDemo
//
//  Created by Junyan Wu on 16/12/15.
//  Copyright © 2016年 THU. All rights reserved.
//

#import "THTestModel.h"

@implementation THTestModel

+ (NSString *)tableName {
    return @"test";
}

+ (NSDictionary *)columnPropertyMapping {
    return @{
             @"name"        :@"name",
             @"age"         :@"age",
             @"birth_date"  :@"birthDate"
             };
}

+ (NSString *)primaryKeyName {
    return @"name";
}

@end

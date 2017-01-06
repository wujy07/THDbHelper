//
//  THBaseModel+Tests.m
//  THDbHelperDemo
//
//  Created by Junyan Wu on 16/10/18.
//  Copyright © 2016年 THU. All rights reserved.
//

#import "THBaseModel+Tests.h"
#import "THDbManager.h"
#import <objc/runtime.h>

@implementation THBaseModel (Tests)

- (BOOL)isEqualToModel:(id)otherModel {
    if (self == otherModel) {
        return YES;
    }
    if ([self class] != [otherModel class]) {
        return NO;
    }
    NSDictionary *mapping = [self.class columnPropertyMapping];
    if (!mapping) {
        return YES;
    }
    __block BOOL isTheSame = YES;
    [mapping.allValues enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *propertyName = (NSString *)obj;
        objc_property_t objProperty = class_getProperty(self.class, propertyName.UTF8String);
        if (!objProperty) {
            return;
        }
        NSString *typeString = [NSString stringWithUTF8String:property_getAttributes(objProperty)];
        NSString *firstType = [[[typeString componentsSeparatedByString:@","] firstObject] substringFromIndex:1];
        NSArray *propertyLikeInt = [@"c, i, s, l, q, C, I, S, L, Q" componentsSeparatedByString:@", "];
        NSArray *propertyLikeDouble = @[@"f", @"d"];
        if ([propertyLikeInt containsObject:firstType]) {
            long long value1 = [[self valueForKey:propertyName] longLongValue];
            long long value2 = [[otherModel valueForKey:propertyName] longLongValue];
            if (value1 != value2) {
                isTheSame = NO;
                *stop = YES;
            }
        } else if ([propertyLikeDouble containsObject:firstType]) {
            double value1 = [[self valueForKey:propertyName] doubleValue];
            double value2 = [[otherModel valueForKey:propertyName] doubleValue];
            if (!(fabs(value1 - value2) < DBL_EPSILON)) {
                isTheSame = NO;
                *stop = YES;
            }
        } else if([firstType isEqualToString:@"B"]){
            BOOL value1 = [[self valueForKey:propertyName] boolValue];
            BOOL value2 = [[otherModel valueForKey:propertyName] boolValue];
            if (value1 != value2) {
                isTheSame = NO;
                *stop = YES;
            }
        } else if([firstType isEqualToString:@"@\"NSData\""]){
            NSData *value1 = [self valueForKey:propertyName];
            NSData *value2 = [otherModel valueForKey:propertyName];
            if ((value1 && ![value1 isEqualToData:value2] )|| (!value1 && value2)) {
                isTheSame = NO;
                *stop = YES;
            }
        } else if([firstType isEqualToString:@"@\"NSDate\""]){
            NSDate *value1 = [self valueForKey:propertyName];
            NSDate *value2 = [otherModel valueForKey:propertyName];
            if ((value1 && !(fabs(value1.timeIntervalSince1970 - value2.timeIntervalSince1970) < DBL_EPSILON ))
                || (!value1 && value2)) {
                isTheSame = NO;
                *stop = YES;
            }
        } else if([firstType isEqualToString:@"@\"NSString\""]){
            NSString *value1 = [self valueForKey:propertyName];
            NSString *value2 = [otherModel valueForKey:propertyName];
            if ((value1 && ![value1 isEqualToString:value2] )|| (!value1 && value2)) {
                isTheSame = NO;
                *stop = YES;
            }
        } else {
            //未知类型只比较指针
            id value1 = [self valueForKey:propertyName];
            id value2 = [otherModel valueForKey:propertyName];
            if (value1 != value2) {
                isTheSame = NO;
                *stop = YES;
            }
        }
        
    }];
    return isTheSame;
}

- (BOOL)isEqual:(id)object {
    return [self isEqualToModel:object];
}

+ (BOOL)clearTable {
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@", [self tableName]];
    return [THDbManager execute:sql withArgs:nil];
}

@end

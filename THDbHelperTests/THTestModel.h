//
//  THTestModel.h
//  THDbHelperDemo
//
//  Created by Junyan Wu on 16/12/15.
//  Copyright © 2016年 THU. All rights reserved.
//

#import "THBaseModel.h"

@interface THTestModel : THBaseModel

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSUInteger age;
@property (nonatomic, strong) NSDate *birthDate;

@end

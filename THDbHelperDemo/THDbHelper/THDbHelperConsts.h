//
//  THDbHelperConsts.h
//  THDbHelperDemo
//
//  Created by Junyan Wu on 16/12/15.
//  Copyright © 2016年 THU. All rights reserved.
//

#ifndef THDbHelperConsts_h
#define THDbHelperConsts_h

typedef void (^THInsertCallBack)(SInt64 rowid, NSError *err);
typedef void (^THInsertBatchCallBack)(NSArray *ids, NSError *err);
typedef void (^THDbCallBack)(NSError *err);

typedef NS_ENUM(NSInteger, THInsertOption) {
    THInsertOptionIgnore = 0, //default
    THInsertOptionUpdate
};


#endif /* THDbHelperConsts_h */

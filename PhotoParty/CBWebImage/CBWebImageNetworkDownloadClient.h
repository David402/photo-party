//
//  CBWebImageNetworkDownloadClient.h
//  CBWebImage
//
//  Created by yyjim on 5/28/13.
//  Copyright (c) 2013 cardinalblue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBWebImageDownloadClientBase.h"

@interface CBWebImageNetworkDownloadClient : CBWebImageDownloadClientBase
- (void)startWithCompletionBlock:(void (^)(NSData *data, NSError *error))block;
@end

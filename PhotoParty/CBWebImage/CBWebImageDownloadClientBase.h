//
//  CBWebImageDownloadClientBase.h
//  CBWebImage
//
//  Created by yyjim on 5/28/13.
//  Copyright (c) 2013 cardinalblue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBWebImageDownloadClient.h"

@interface CBWebImageDownloadClientBase : NSObject
    <CBWebImageDownloadClient>
- (id)initWithURL:(NSURL *)url target:(id)target delegate:(id<CBWebImageDownloadClientDelegate>)delegate;
@end

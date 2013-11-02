//
//  CBWebImageDownloadClient.h
//  CBWebImage
//
//  Created by yyjim on 5/28/13.
//  Copyright (c) 2013 cardinalblue. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CBWebImageDownloadClient;
@protocol CBWebImageDownloadClientDelegate <NSObject>
- (void)downloadClient:(id<CBWebImageDownloadClient>)client
      downloadProgress:(CGFloat)progress;;
@end

@protocol CBWebImageDownloadClient <NSObject>
@property (nonatomic, assign) id<CBWebImageDownloadClientDelegate> delegate;
@property (nonatomic, assign) id target;
@property (nonatomic, copy) NSURL *url;
- (void)stop;
@end

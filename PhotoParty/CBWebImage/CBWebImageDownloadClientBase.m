//
//  CBWebImageDownloadClientBase.m
//  CBWebImage
//
//  Created by yyjim on 5/28/13.
//  Copyright (c) 2013 cardinalblue. All rights reserved.
//

#import "CBWebImageDownloadClientBase.h"

@implementation CBWebImageDownloadClientBase
@synthesize delegate = _delegate;
@synthesize target = _target;
@synthesize url = _url;

- (id)initWithURL:(NSURL *)url target:(id)target delegate:(id<CBWebImageDownloadClientDelegate>)delegate
{
    self = [self init];
    if (self) {
        self.url = url;
        self.target = target;
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    self.delegate = nil;
    self.target = nil;
    self.url = nil;
    [super dealloc];
}

- (void)stop
{
    
}

@end


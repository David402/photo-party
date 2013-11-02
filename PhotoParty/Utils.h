//
//  Utils.h
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject
+ (NSString *)upload_to_s3:(UIImage*)img;
@end

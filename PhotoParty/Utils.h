//
//  Utils.h
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import <Foundation/Foundation.h>

id SAFE_CAST(Class klass, id obj);
id SAFE_CALL(id obj, SEL selector);
id SAFE_PROTOCOL(id obj, Protocol *protocol);
float SAFE_FLOAT(id obj);

@interface Utils : NSObject
+ (NSString *)upload_to_s3:(UIImage*)img;

@end

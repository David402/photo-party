//
//  UIScreen+Additions.m
//  PicCollage
//
//  Created by yyjim on 5/20/13.
//
//

#import "UIScreen+CBWebImageAdditions.h"

@implementation UIScreen (CBWebImageAdditions)

- (BOOL)cb_isRetinaDisplay {
	static dispatch_once_t predicate;
	static BOOL answer;
    
	dispatch_once(&predicate, ^{
		answer = ([self respondsToSelector:@selector(scale)] && [self scale] == 2);
	});
	return answer;
}

@end

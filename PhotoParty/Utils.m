//
//  Utils.m
//  PhotoParty
//
//  Created by David Liu on 11/2/13.
//  Copyright (c) 2013 David Lliu. All rights reserved.
//

#import "Utils.h"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

// =============================================================================

id SAFE_CAST(Class klass, id obj) {
    return [obj isKindOfClass:klass]? obj : nil;
}
id SAFE_CALL(id obj, SEL selector) {
    if ([obj respondsToSelector:selector])
        return [obj performSelector:selector];
    return nil;
}
id SAFE_PROTOCOL(id obj, Protocol *protocol) {
    return [obj conformsToProtocol:protocol]? obj : nil;
}
float SAFE_FLOAT(id obj) {
    if ([obj respondsToSelector:@selector(floatValue)])
        return [obj floatValue];
    return 0;
}

// =============================================================================

@interface NSData (HMAC_SHA1)
- (NSData*)HMAC_SHA1_with_secret:(NSString*)secret;
@end

@implementation NSData (HMAC_SHA1)
- (NSData*)HMAC_SHA1_with_secret:(NSString*)secret
{
    CCHmacContext context;
    const char* keyCString = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    CCHmacInit(&context, kCCHmacAlgSHA1, keyCString, strlen(keyCString));
    CCHmacUpdate(&context, [self bytes], [self length]);
    
    unsigned char digestRaw[CC_SHA1_DIGEST_LENGTH];
    CCHmacFinal(&context, digestRaw);
    return [NSData dataWithBytes:digestRaw length:CC_SHA1_DIGEST_LENGTH];
    
    /*
     const char *cKey  = [secret cStringUsingEncoding:NSASCIIStringEncoding];
     const char *cData = (char*)[self bytes];
     
     unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
     
     CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
     
     return [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];*/
}
@end

@interface NSData (Base64)
- (NSString *)base64EncodedString;
@end

@implementation NSData (Base64)

- (NSString *)base64EncodedStringWithWrapWidth:(NSUInteger)wrapWidth
{
    //ensure wrapWidth is a multiple of 4
    wrapWidth = (wrapWidth / 4) * 4;
    
    const char lookup[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    long long inputLength = [self length];
    const unsigned char *inputBytes = (unsigned char*)[self bytes];
    
    long long maxOutputLength = (inputLength / 3 + 1) * 4;
    maxOutputLength += wrapWidth? (maxOutputLength / wrapWidth) * 2: 0;
    unsigned char *outputBytes = (unsigned char *)malloc(maxOutputLength);
    
    long long i;
    long long outputLength = 0;
    for (i = 0; i < inputLength - 2; i += 3)
    {
        outputBytes[outputLength++] = lookup[(inputBytes[i] & 0xFC) >> 2];
        outputBytes[outputLength++] = lookup[((inputBytes[i] & 0x03) << 4) | ((inputBytes[i + 1] & 0xF0) >> 4)];
        outputBytes[outputLength++] = lookup[((inputBytes[i + 1] & 0x0F) << 2) | ((inputBytes[i + 2] & 0xC0) >> 6)];
        outputBytes[outputLength++] = lookup[inputBytes[i + 2] & 0x3F];
        
        //add line break
        if (wrapWidth && (outputLength + 2) % (wrapWidth + 2) == 0)
        {
            outputBytes[outputLength++] = '\r';
            outputBytes[outputLength++] = '\n';
        }
    }
    
    //handle left-over data
    if (i == inputLength - 2)
    {
        // = terminator
        outputBytes[outputLength++] = lookup[(inputBytes[i] & 0xFC) >> 2];
        outputBytes[outputLength++] = lookup[((inputBytes[i] & 0x03) << 4) | ((inputBytes[i + 1] & 0xF0) >> 4)];
        outputBytes[outputLength++] = lookup[(inputBytes[i + 1] & 0x0F) << 2];
        outputBytes[outputLength++] =   '=';
    }
    else if (i == inputLength - 1)
    {
        // == terminator
        outputBytes[outputLength++] = lookup[(inputBytes[i] & 0xFC) >> 2];
        outputBytes[outputLength++] = lookup[(inputBytes[i] & 0x03) << 4];
        outputBytes[outputLength++] = '=';
        outputBytes[outputLength++] = '=';
    }
    
    if (outputLength >= 4)
    {
        //truncate data to match actual output length
        outputBytes = (unsigned char*)realloc(outputBytes, outputLength);
        return [[NSString alloc] initWithBytesNoCopy:outputBytes
                                              length:outputLength
                                            encoding:NSASCIIStringEncoding
                                        freeWhenDone:YES];
    }
    else if (outputBytes)
    {
        free(outputBytes);
    }
    return nil;
}

- (NSString *)base64EncodedString
{
    return [self base64EncodedStringWithWrapWidth:0];
}

@end

@implementation Utils

+ (NSDictionary *)readS3Credentials
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"credentials" ofType:@"txt"];
    NSString* fileContents = [NSString stringWithContentsOfFile:path
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    NSCharacterSet *newlineCharSet = [NSCharacterSet newlineCharacterSet];
    NSArray *lines = [fileContents componentsSeparatedByCharactersInSet:newlineCharSet];
    
    NSDictionary *dict = @{@"s3bucket":lines[0], @"s3accesskeyid": lines[1], @"s3secrectaccesskey": lines[2]};
    
    return dict;
}

+ (NSString *)upload_to_s3:(UIImage*)img
{
    NSString* image_quality_str = [[NSUserDefaults standardUserDefaults] stringForKey:@"image_quality"];
    if (!image_quality_str) {
        image_quality_str = @"640";
    }
    int image_quality = [image_quality_str intValue];
    image_quality = image_quality > 4096 ? 4096 : image_quality;
    image_quality = image_quality < 512 ? 512 : image_quality;
    
    // Convert img to NSData
    CGSize size = [img size];
    CGFloat ratio = image_quality / (size.width > size.height ? size.width : size.height);
    ratio = (ratio > 1.0 ? 1.0 : ratio);
    UIGraphicsBeginImageContext(CGSizeMake(size.width*ratio, size.height*ratio));
    [img drawInRect:CGRectMake(0, 0, size.width*ratio, size.height*ratio)];
    UIImage* newImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData* data = UIImageJPEGRepresentation(newImg, 0.5);
    
    NSDictionary *dict = [self readS3Credentials];
    NSString* bucket_name = [dict valueForKey:@"s3bucket"];
    NSString* access_key_id = [dict valueForKey:@"s3accesskeyid"];
    NSString* secret_access_key = [dict valueForKey:@"s3secrectaccesskey"];
    
    // Prepare dateString
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z"; //RFC2822-Format
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    
    // Prepare authorization header
    NSString* filename = [self stringFromRandomStrWithLength];
    NSString* stringToSign = [NSString stringWithFormat:@"PUT\n\nimage/jpeg\n%@\nx-amz-acl:public-read\n/%@/expires_in_days/7/bulu/%@.jpg", dateString, bucket_name, filename];
    NSString* signature = [[[stringToSign dataUsingEncoding:NSStringEncodingConversionAllowLossy]
                            HMAC_SHA1_with_secret:secret_access_key] base64EncodedString];
    
    // Prepare the NSURLRequest
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] init];
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [req setHTTPShouldHandleCookies:NO];
    [req setTimeoutInterval:30];
    [req setHTTPMethod:@"PUT"];
    [req setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
    [req setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
    [req setValue:dateString forHTTPHeaderField:@"Date"];
    [req setValue:[NSString stringWithFormat:@"AWS %@:%@", access_key_id, signature] forHTTPHeaderField:@"Authorization"];
    [req setValue:@"public-read" forHTTPHeaderField:@"x-amz-acl"];
    [req setHTTPBody:data];
    [req setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://s3.amazonaws.com/%@/expires_in_days/7/bulu/%@.jpg", bucket_name, filename]]];
    
    // Start the connection
    NSURLResponse* resp = nil;
    NSError* err = nil;
    NSData* respData = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&err];
    if (err) {
        NSLog(@"%@", err);
        return nil;
    } else {
        NSLog(@"%@", [NSString stringWithUTF8String:(char*)[respData bytes]]);
        return [NSString stringWithFormat:@"http://d1a7rh4nd2ow65.cloudfront.net/expires_in_days/7/bulu/%@.jpg", filename];
    }
}

+ (NSString *)stringFromRandomStrWithLength
{
    NSString *randomString = @"";
    int len = 8;
    for (int x=0;x<len;x++) {
        randomString = [randomString stringByAppendingFormat:@"%c", (char)(65 + (arc4random() % 25))];
    }
    return randomString;
}

@end

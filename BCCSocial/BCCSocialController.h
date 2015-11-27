//
//  BCCSocialController.h
//
//  Created by Buzz Andersen on 1/15/14.
//  Copyright (c) 2014 Brooklyn Computer Club. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Social/Social.h>

extern NSString * const BCCSocialControllerTwitterRequestTokenEndpoint;
extern NSString * const BCCSocialControllerTwitterOAuthTokenEndpoint;

typedef void (^BCCSocialControllerAccountAccessCompletionBlock)(BOOL granted, NSArray *accountList, NSError *error);
typedef void (^BCCSocialControllerTwitterAuthCompletionBlock)(NSDictionary *OAuthParameterDictionary, NSError *error);
typedef void (^BCCSocialControllerTwitterReverseAuthCompletionBlock)(NSString *OAuthReverseAuthCredentialString, NSError *error);

@interface BCCSocialController : NSObject

@property (nonatomic, readonly) ACAccountStore *socialAccountStore;

// Facebook
- (void)requestAccessToSystemFacebookAccountWithAppID:(NSString *)facebookAppID completionBlock:(BCCSocialControllerAccountAccessCompletionBlock)completionBlock;

// Twitter
- (void)requestAccessToSystemTwitterAccountListWithCompletionBlock:(BCCSocialControllerAccountAccessCompletionBlock)completionBlock;

- (void)requestTwitterRequestTokenWithConsumerKey:(NSString *)consumerKey secretKey:(NSString *)secretKey callbackURL:(NSString *)callbackURL completionBlock:(BCCSocialControllerTwitterAuthCompletionBlock)completionBlock;
- (void)requestTwitterReverseAuthCredentialsWithConsumerKey:(NSString *)consumerKey secretKey:(NSString *)secretKey completionBlock:(BCCSocialControllerTwitterReverseAuthCompletionBlock)completionBlock;

- (void)requestTwitterAuthCredentialsForAccount:(ACAccount *)twitterAccount withConsumerKey:(NSString *)consumerKey reverseAuthCredentials:(NSString *)credentialString completionBlock:(BCCSocialControllerTwitterAuthCompletionBlock)completionBlock;
- (void)requestTwitterAuthCredentialsWithUsername:(NSString *)username password:(NSString *)password consumerKey:(NSString *)consumerKey secretKey:(NSString *)secretKey completionBlock:(BCCSocialControllerTwitterAuthCompletionBlock)completionBlock;
- (void)requestTwitterAuthCredentialsWithToken:(NSString *)token verifier:(NSString *)verifier consumerKey:(NSString *)consumerKey secretKey:(NSString *)secretKey completionBlock:(BCCSocialControllerTwitterAuthCompletionBlock)completionBlock;

+ (NSMutableURLRequest *)twitterBrowserAuthURLRequestForToken:(NSString *)twitterAuthToken;

@end


@interface NSDictionary (BCCTwitterAuthConveniences)

+ (NSDictionary *)dictionaryFromTwitterOAuthCredentialString:(NSString *)OAuthCredentialString;

@property (nonatomic, readonly) NSString *BCC_twitterOAuthToken;
@property (nonatomic, readonly) NSString *BCC_twitterOAuthVerifier;
@property (nonatomic, readonly) NSString *BCC_twitterOAuthSecret;
@property (nonatomic, readonly) NSString *BCC_twitterScreenName;
@property (nonatomic, readonly) NSString *BCC_twitterUserID;

@end
//
//  BCCSocialController.m
//
//  Created by Buzz Andersen on 1/15/14.
//  Copyright (c) 2014 Brooklyn Computer Club. All rights reserved.
//

#import "BCCSocialController.h"
#import "BCCHTTPRequestQueue.h"
#import "NSString+BCCAdditions.h"

NSString * const BCCSocialControllerTwitterOAuthBaseURL = @"https://api.twitter.com/oauth";
NSString * const BCCSocialControllerTwitterRequestTokenEndpoint = @"request_token";
NSString * const BCCSocialControllerTwitterOAuthTokenEndpoint = @"access_token";
NSString * const BCCSocialControllerTwitterOAuthAuthenticateEndpoint = @"authenticate";


@interface BCCSocialController ()

@property (strong, nonatomic) BCCHTTPRequestQueue *twitterRequestQueue;

@property (strong, nonatomic) ACAccountStore *socialAccountStore;

@end


@implementation BCCSocialController

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    BCCHTTPRequestQueue *twitterRequestQueue = [[BCCHTTPRequestQueue alloc] initWithQueueName:@"com.brooklyncomputerclub.BCCSocialController"];
    twitterRequestQueue.baseURL = BCCSocialControllerTwitterOAuthBaseURL;
    _twitterRequestQueue = twitterRequestQueue;
    
    self.socialAccountStore = [[ACAccountStore alloc] init];
    
    return self;
}

#pragma mark - Facebook

- (void)requestAccessToSystemFacebookAccountWithAppID:(NSString *)facebookAppID completionBlock:(BCCSocialControllerAccountAccessCompletionBlock)completionBlock
{
    ACAccountStore *accountStore = self.socialAccountStore;
    ACAccountType *facebookAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    NSDictionary *facebookAuthOptions = @{ACFacebookAppIdKey: facebookAppID, ACFacebookPermissionsKey: @[@"email", @"manage_pages"]};
    
    [self.socialAccountStore requestAccessToAccountsWithType:facebookAccountType options:facebookAuthOptions completion:^(BOOL granted, NSError *error) {
        NSLog(@"Facebook Error: %@", error);
        
        if (!granted) {
            completionBlock(granted, nil, error);
            return;
        }
        
        NSArray *facebookAccounts = [accountStore accountsWithAccountType:facebookAccountType];
        
        completionBlock(granted, facebookAccounts, nil);
    }];
}

#pragma mark - Twitter

- (void)requestAccessToSystemTwitterAccountListWithCompletionBlock:(BCCSocialControllerAccountAccessCompletionBlock)completionBlock
{
    ACAccountStore *accountStore = self.socialAccountStore;
    ACAccountType *twitterAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [self.socialAccountStore requestAccessToAccountsWithType:twitterAccountType options:NULL completion:^(BOOL granted, NSError *error) {
        if (!granted) {
            completionBlock(granted, nil, error);
            return;
        }
        
        NSArray *twitterAccounts = [self.socialAccountStore accountsWithAccountType:twitterAccountType];
        
        completionBlock(granted, twitterAccounts, error);
    }];
}

- (void)requestTwitterRequestTokenWithConsumerKey:(NSString *)consumerKey secretKey:(NSString *)secretKey callbackURL:(NSString *)callbackURL completionBlock:(BCCSocialControllerTwitterAuthCompletionBlock)completionBlock
{
    if (!consumerKey || !secretKey) {
        return;
    }
    
    BCCHTTPRequest *twitterTokenRequest = [self.twitterRequestQueue requestWithCommand:BCCSocialControllerTwitterRequestTokenEndpoint];
    twitterTokenRequest.requestMethod = BCCHTTPRequestMethodPOST;
    
    twitterTokenRequest.authenticationType = BCCHTTPRequestAuthenticationTypeOAuth1;
    twitterTokenRequest.OAuthConsumerKey = consumerKey;
    twitterTokenRequest.OAuthSecretKey = secretKey;
    twitterTokenRequest.OAuthCallbackURL = callbackURL;
    
    twitterTokenRequest.requestDidFinishBlock = ^(BCCHTTPRequest *request) {
        if (completionBlock) {
            NSString *OAuthCredentialsString = request.responseString;
            NSDictionary *OAuthParameterDictionary = [NSDictionary dictionaryFromTwitterOAuthCredentialString:OAuthCredentialsString];
            
            completionBlock(OAuthParameterDictionary, nil);
        }
    };
    
    twitterTokenRequest.requestDidFailBlock = ^(BCCHTTPRequest *request) {
        if (completionBlock) {
            completionBlock(nil, request.error);
        }
    };
    
    [self.twitterRequestQueue addRequest:twitterTokenRequest];
}

- (void)requestTwitterReverseAuthCredentialsWithConsumerKey:(NSString *)consumerKey secretKey:(NSString *)secretKey completionBlock:(BCCSocialControllerTwitterReverseAuthCompletionBlock)completionBlock
{
    if (!consumerKey || !secretKey) {
        return;
    }
    
    BCCHTTPRequest *specialRequestTokenRequest = [self.twitterRequestQueue xAuthReverseAuthRequestWithCommand:BCCSocialControllerTwitterRequestTokenEndpoint consumerKey:consumerKey secretKey:secretKey];
    
    specialRequestTokenRequest.requestDidFinishBlock = ^(BCCHTTPRequest *request) {
        if (completionBlock) {
            NSString *OAuthReverseAuthCredentialString = request.responseString;
            
            completionBlock(OAuthReverseAuthCredentialString, nil);
        }
    };
    
    specialRequestTokenRequest.requestDidFailBlock = ^(BCCHTTPRequest *request) {
        if (completionBlock) {
            completionBlock(nil, request.error);
        }
    };
    
    [self.twitterRequestQueue addRequest:specialRequestTokenRequest];
}

- (void)requestTwitterAuthCredentialsForAccount:(ACAccount *)twitterAccount withConsumerKey:(NSString *)consumerKey reverseAuthCredentials:(NSString *)credentialString completionBlock:(BCCSocialControllerTwitterAuthCompletionBlock)completionBlock
{
    if (!twitterAccount || ![twitterAccount.accountType.identifier isEqualToString:ACAccountTypeIdentifierTwitter] || !credentialString || !consumerKey) {
        return;
    }
    
    NSMutableDictionary *tokenRequestParameters = [[NSMutableDictionary alloc] init];
    [tokenRequestParameters setObject:consumerKey forKey:@"x_reverse_auth_target"];
    [tokenRequestParameters setObject:credentialString forKey:@"x_reverse_auth_parameters"];
    
    NSMutableString *tokenRequestURLString = [[NSMutableString alloc] initWithString:BCCSocialControllerTwitterOAuthBaseURL];
    [tokenRequestURLString BCC_appendURLPathComponent:BCCSocialControllerTwitterOAuthTokenEndpoint];
    NSURL *tokenRequestEndpoint = [NSURL URLWithString:tokenRequestURLString];
    
    SLRequest *tokenRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:tokenRequestEndpoint parameters:tokenRequestParameters];
    [tokenRequest setAccount:twitterAccount];
    
    [tokenRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSString *OAuthCredentialsString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSDictionary *OAuthParameterDictionary = [NSDictionary dictionaryFromTwitterOAuthCredentialString:OAuthCredentialsString];
        
        if (completionBlock) {
            completionBlock(OAuthParameterDictionary, error);
        }
    }];
}

- (void)requestTwitterAuthCredentialsWithUsername:(NSString *)username password:(NSString *)password consumerKey:(NSString *)consumerKey secretKey:(NSString *)secretKey completionBlock:(BCCSocialControllerTwitterAuthCompletionBlock)completionBlock
{
    if (!username || !password || !consumerKey || !secretKey) {
        return;
    }
    
    BCCHTTPRequest *authRequest = [self.twitterRequestQueue xAuthAccessTokenRequestWithCommand:BCCSocialControllerTwitterRequestTokenEndpoint username:username password:password consumerKey:consumerKey secretKey:secretKey];
    
    authRequest.requestDidFinishBlock = ^(BCCHTTPRequest *request) {
        if (completionBlock) {
            NSString *OAuthCredentialsString = request.responseString;
            NSDictionary *OAuthParameterDictionary = [NSDictionary dictionaryFromTwitterOAuthCredentialString:OAuthCredentialsString];
            
            completionBlock(OAuthParameterDictionary, nil);
        }
    };
    
    authRequest.requestDidFailBlock = ^(BCCHTTPRequest *request) {
        if (completionBlock) {
            completionBlock(nil, request.error);
        }
    };
    
    [self.twitterRequestQueue addRequest:authRequest];
}

- (void)requestTwitterAuthCredentialsWithToken:(NSString *)token verifier:(NSString *)verifier consumerKey:(NSString *)consumerKey secretKey:(NSString *)secretKey completionBlock:(BCCSocialControllerTwitterAuthCompletionBlock)completionBlock
{
    if (!token || !verifier || !consumerKey || !secretKey) {
        return;
    }
    
    BCCHTTPRequest *authRequest = [self.twitterRequestQueue requestWithCommand:BCCSocialControllerTwitterOAuthTokenEndpoint];
    authRequest.requestMethod = BCCHTTPRequestMethodPOST;
    authRequest.authenticationType = BCCHTTPRequestAuthenticationTypeOAuth1;
    
    authRequest.OAuthConsumerKey = consumerKey;
    authRequest.OAuthSecretKey = secretKey;
    authRequest.OAuthToken = token;
    
    [authRequest setBodyParameterValue:verifier forKey:@"oauth_verifier"];
    
    authRequest.requestDidFinishBlock = ^(BCCHTTPRequest *request) {
        if (completionBlock) {
            NSString *OAuthCredentialsString = request.responseString;
            NSDictionary *OAuthParameterDictionary = [NSDictionary dictionaryFromTwitterOAuthCredentialString:OAuthCredentialsString];
            
            completionBlock(OAuthParameterDictionary, nil);
        }
    };
    
    authRequest.requestDidFailBlock = ^(BCCHTTPRequest *request) {
        if (completionBlock) {
            completionBlock(nil, request.error);
        }
    };
    
    [self.twitterRequestQueue addRequest:authRequest];

}

+ (NSMutableURLRequest *)twitterBrowserAuthURLRequestForToken:(NSString *)twitterAuthToken
{
    if (!twitterAuthToken) {
        return nil;
    }
    
    NSMutableString *twitterAuthURLString = [[NSMutableString alloc] initWithString:BCCSocialControllerTwitterOAuthBaseURL];
    [twitterAuthURLString BCC_appendURLPathComponent:BCCSocialControllerTwitterOAuthAuthenticateEndpoint];
    [twitterAuthURLString appendFormat:@"?%@=%@", @"oauth_token", twitterAuthToken];
    
    NSURL *twitterAuthURL = [NSURL URLWithString:twitterAuthURLString];
    
    return [[NSMutableURLRequest alloc] initWithURL:twitterAuthURL];
}

@end


@implementation NSDictionary (BCCTwitterAuthConveniences)

+ (NSDictionary *)dictionaryFromTwitterOAuthCredentialString:(NSString *)OAuthCredentialString
{
    if (!OAuthCredentialString) {
        return nil;
    }
    
    NSMutableDictionary *OAuthParameterDictionary = [[NSMutableDictionary alloc] init];
    
    NSArray *OAuthParameters = [OAuthCredentialString componentsSeparatedByString:@"&"];
    
    for (NSString *currentParameterString in OAuthParameters) {
        NSArray *parameterComponents = [currentParameterString componentsSeparatedByString:@"="];
        if (!parameterComponents || parameterComponents.count < 1) {
            continue;
        }
        
        [OAuthParameterDictionary setObject:[parameterComponents objectAtIndex:1] forKey:[parameterComponents objectAtIndex:0]];
    }
    
    return OAuthParameterDictionary;
}

- (NSString *)BCC_twitterOAuthToken
{
    return [self objectForKey:@"oauth_token"];
}

- (NSString *)BCC_twitterOAuthSecret
{
    return [self objectForKey:@"oauth_token_secret"];
}

- (NSString *)BCC_twitterOAuthVerifier
{
    return [self objectForKey:@"oauth_verifier"];
}

- (NSString *)BCC_twitterScreenName
{
    return [self objectForKey:@"screen_name"];
}

- (NSString *)BCC_twitterUserID
{
    return [self objectForKey:@"user_id"];
}

@end

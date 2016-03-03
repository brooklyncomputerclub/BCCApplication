//
//  STAccountController.h
//
//  Created by Buzz Andersen on 12/17/12.
//  Copyright (c) 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

@protocol BCCAccount;

extern NSString * BCCAccountControllerWillChangeCurrentAccountNotification;
extern NSString * BCCAccountControllerDidChangeCurrentAccountNotification;

extern NSString *BCCAccountControllerWillClearAccountsNotification;
extern NSString *BCCAccountControllerDidClearAccountsNotification;

extern NSString *BCCAccountControllerWillClearCurrentAccountNotification;
extern NSString *BCCAccountControllerDidClearCurrentAccountNotification;

extern NSString *BCCAccountControllerDidUpdateAuthCredentialNotification;

extern NSString *BCCAccountControllerNewCurrentAccountNotificationKey;


typedef enum {
    BCCAccountControllerAccountManagementModeSingle,
    BCCAccountControllerAccountManagementModeMultiple,
} BCCAccountControllerAccountManagementMode;


@interface BCCAccountController : NSObject

@property (nonatomic, readonly) Class accountClass;

@property (nonatomic) BCCAccountControllerAccountManagementMode accountManagementMode;

@property (strong, nonatomic) id<BCCAccount> currentAccount;
@property (nonatomic, readonly) NSArray<BCCAccount> *accountList;

// Class Methods
+ (NSString *)keychainServiceName;

// Initialization
- (instancetype)initWithWithAccountClass:(Class)accountClass;

// Accounts
- (id<BCCAccount>)newAccount;

- (id<BCCAccount>)accountForIdentifier:(NSString *)identifier;
- (id<BCCAccount>)accountForUserID:(NSString *)userID;

- (void)removeAccountWithIdentifier:(NSString *)indentifier;
- (void)removeAllAccounts;

- (void)clearAuthCredentialForAccountWithIdentifier:(NSString *)identifier;

@end


@protocol BCCAccount <NSObject>

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *environmentKey;

// Initialization
- (instancetype)initWithIdentifier:(NSString *)inIdentifier;

// Property Values
- (id)accountValueForKey:(NSString *)defaultsKey;
- (id)accountValueForKey:(NSString *)defaultsKey environment:(NSString *)environment;
- (void)setAccountValue:(id)value forKey:(NSString *)defaultsKey;
- (void)setAccountValue:(id)value forKey:(NSString *)defaultsKey environment:(NSString *)environment;

@end


@interface BCCDefaultsAccount : NSObject <BCCAccount>

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *environmentKey;

@property (nonatomic) NSString *userID;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *email;
@property (nonatomic) NSData *authCredential;
@property (nonatomic) NSString *fullName;
@property (nonatomic) NSString *firstName;
@property (nonatomic) NSString *lastName;
@property (nonatomic) NSString *accountDescription;
@property (nonatomic) NSString *personalURL;
@property (nonatomic) NSString *locationDescription;
@property (nonatomic) NSString *phoneNumber;
@property (nonatomic) NSString *avatarURL;
@property (nonatomic, readonly) NSString *HTTPEndpoint;
@property (nonatomic) NSString *userHTTPEndpoint;
@property (nonatomic, readonly) NSString *APIVersion;
@property (nonatomic) NSString *userAPIVersion;

// Class Methods
+ (NSDictionary *)defaultHTTPEndpoints;
+ (NSString *)defaultAPIVersion;

// Initialization
- (instancetype)initWithIdentifier:(NSString *)inIdentifier;

// Auth Credentials
- (void)clearAuthCredential;

// Property Values
- (id)accountValueForKey:(NSString *)defaultsKey;
- (id)accountValueForKey:(NSString *)defaultsKey environment:(NSString *)environment;
- (void)setAccountValue:(id)value forKey:(NSString *)defaultsKey;
- (void)setAccountValue:(id)value forKey:(NSString *)defaultsKey environment:(NSString *)environment;

- (NSString *)accountStringValueForKey:(NSString *)defaultsKey;
- (NSString *)accountStringValueForKey:(NSString *)defaultsKey environment:(NSString *)environment;

- (BOOL)accountBoolValueForKey:(NSString *)defaultsKey;
- (BOOL)accountBoolValueForKey:(NSString *)defaultsKey environment:(NSString *)environment;
- (void)setAccountBoolValue:(BOOL)value forKey:(NSString *)defaultsKey;
- (void)setAccountBoolValue:(BOOL)value forKey:(NSString *)defaultsKey environment:(NSString *)environment;

- (id)serializedAccountValueForKey:(NSString *)defaultsKey;
- (id)serializedAccountValueForKey:(NSString *)defaultsKey environment:(NSString *)environment;
- (void)setSerializedAccountValue:(id)value forKey:(NSString *)defaultsKey;
- (void)setSerializedAccountValue:(id)value forKey:(NSString *)defaultsKey  environment:(NSString *)environment;
@end


@interface NSUserDefaults (BCCAccountControllerExtensions)

- (id)BCC_objectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (id)BCC_objectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (void)BCC_setObject:(id)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (void)BCC_setObject:(id)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (id)BCC_serializedObjectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (id)BCC_serializedObjectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (void)BCC_setSerializedObjectWithValue:(id)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (void)BCC_setSerializedObjectWithValue:(id)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (void)BCC_removeObjectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (void)BCC_removeObjectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (void)BCC_setBool:(BOOL)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (void)BCC_setBool:(BOOL)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (void)BCC_setDouble:(double)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (void)BCC_setDouble:(double)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (void)BCC_setFloat:(float)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (void)BCC_setFloat:(float)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (void)BCC_setInteger:(NSInteger)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (void)BCC_setInteger:(NSInteger)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (BOOL)BCC_boolForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (BOOL)BCC_boolForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (double)BCC_doubleForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (double)BCC_doubleForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (float)BCC_floatForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (float)BCC_floatForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (NSInteger)BCC_integerForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (NSInteger)BCC_integerForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (NSString *)BCC_stringForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (NSString *)BCC_stringForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (NSNumber *)BCC_numberForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (NSNumber *)BCC_numberForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (NSDictionary *)BCC_dictionaryForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (NSDictionary *)BCC_dictionaryForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (NSArray *)BCC_arrayForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (NSArray *)BCC_arrayForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (NSData *)BCC_dataForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier;
- (NSData *)BCC_dataForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment;

- (void)BCC_addObserver:(id)observer selector:(SEL)selector;
- (void)BCC_addObserver:(id)observer selector:(SEL)selector forDefaultsKey:(NSString *)defaultsKey;
- (void)BCC_addObserver:(id)observer selector:(SEL)selector forDefaultsKey:(NSString *)defaultsKey accountIdentifier:(NSString *)accountIdentifer;
- (void)BCC_removeObserver:(id)observer;

@end

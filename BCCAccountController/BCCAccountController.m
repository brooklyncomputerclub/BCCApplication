//
// BCCAccountController.m
//
//  Created by Buzz Andersen on 12/17/12.
//  Copyright (c) 2013 Brooklyn Computer Club. All rights reserved.
//

#import "BCCAccountController.h"
#import "BCCKeychain.h"
#import "BCCTargetActionQueue.h"


// Info.plist Constants
static NSString * const BCCAccountControllerDefaultHTTPEndpointsInfoKey = @"BCCHTTPEndpoints";
static NSString * const BCCAccountControllerDefaultAPIVersionInfoKey = @"BCCDefaultAPIVersion";
static NSString * const BCCAccountControllerKeychainServiceNameInfoKey = @"BCCKeychainServiceName";

// Defaults Key Constants
static NSString * const BCCAccountControllerAccountsInfoDefaultsKey = @"BCCAccountControllerAccountsInfo";
static NSString * const BCCAccountControllerCurrentAccountIdentifierDefaultsKey = @"BCCAccountControllerCurrentAccountIdentifier";
static NSString * const BCCAccountControllerValueInfoDefaultsKey = @"BCCAccountControllerValueInfo";
static NSString * const BCCAccountControllerDefaultEnvironmentDefaultsKey = @"default";

static NSString * const BCCAccountIdentifierDefaultsKey = @"Identifier";
static NSString * const BCCAccountUserIDDefaultsKey = @"UserID";
static NSString * const BCCAccountUsernameDefaultsKey = @"Username";
static NSString * const BCCAccountEmailDefaultsKey = @"Email";
static NSString * const BCCAccountFullNameDefaultsKey = @"FullName";
static NSString * const BCCAccountFirstNameDefaultsKey = @"FirstName";
static NSString * const BCCAccountLastNameDefaultsKey = @"LastName";
static NSString * const BCCAccountDescriptionDefaultsKey = @"Description";
static NSString * const BCCAccountLocationDescriptionDefaultsKey = @"Location";
static NSString * const BCCPersonalURLDefaultsKey = @"PersonalURL";
static NSString * const BCCAccountPhoneNumberDefaultsKey = @"PhoneNumber";
static NSString * const BCCAccountAvatarURLDefaultsKey = @"AvatarURL";
static NSString * const BCCAccountHTTPEndpointDefaultsKey = @"HTTPEndpoint";
static NSString * const BCCAccountAPIVersionDefaultsKey = @"APIVersion";

// Keychain Constants
static NSString * const BCCAccountAuthCredential = @"BCCAccountAuthCredential";

// Observation
static BCCTargetActionQueue *defaultsObserverInfo = nil;
static NSString * const BCCAccountControllerAllKeysObservationKey = @"BCCAccountControllerAllKeysObservationKey";

// Notification Constants
NSString * BCCAccountControllerWillChangeCurrentAccountNotification = @"BCCAccountControllerWillChangeCurrentAccountNotification";
NSString * BCCAccountControllerDidChangeCurrentAccountNotification = @"BCCAccountControllerDidChangeCurrentAccountNotification";

NSString *BCCAccountControllerWillClearAccountsNotification = @"BCCAccountControllerWillClearAccountsNotification";
NSString *BCCAccountControllerDidClearAccountsNotification = @"BCCAccountControllerDidClearAccountsNotification";

NSString *BCCAccountControllerWillClearCurrentAccountNotification = @"BCCAccountControllerWillClearCurrentAccountNotification";
NSString *BCCAccountControllerDidClearCurrentAccountNotification = @"BCCAccountControllerDidClearCurrentAccountNotification";

NSString * BCCAccountControllerKeyModifiedNotification = @"BCCAccountControllerKeyModifiedNotification";

NSString * BCCAccountControllerDidUpdateAuthCredentialNotification = @"BCCAccountControllerKeyModifiedNotification";

NSString *BCCAccountControllerNotificationUserInfoKeyAccountIdentifier = @"AccountIdentifier";
NSString *BCCAccountControllerNotificationUserInfoKeyDefaultsKey = @"DefaultsKey";

NSString *BCCAccountControllerNewCurrentAccountNotificationKey = @"BCCAccountControllerNewCurrentAccountKey";


@interface BCCAccountController ()

@property (nonatomic) Class<BCCAccount> accountClass;

+ (NSString *)currentAccountIdentifier;
+ (void)setCurrentAccountIdentifer:(NSString *)accountIdentifier;

- (void)initializeForCurrentAccount;
- (void)initializeForAccountIdentifier:(NSString *)accountIdentifier;

- (NSArray *)accountsMatchingPredicate:(NSPredicate *)predicate;

- (void)clearCurrentAccount;

@end


@interface NSUserDefaults (BCCAccountControllerExtensionsPrivate)

- (NSMutableDictionary *)BCC_mutableAccountsInfo;
- (NSMutableDictionary *)BCC_mutableAccountInfoForIdentifier:(NSString *)identifier;
- (NSMutableDictionary *)BCC_mutableValueInfoForKey:(NSString *)key forAccountWithIdentifier:(NSString *)identifier;
- (void)BCC_setAccountsInfo:(NSDictionary *)newAccountsInfo;
- (void)BCC_setAccountInfo:(NSDictionary *)accountInfo forIdentifier:(NSString *)identifier;
- (BOOL)BCC_accountInfoExistsForIdentifier:(NSString *)identifier;
- (void)BCC_removeAccountInfoWithIdentifier:(NSString *)identifier;
- (void)BCC_clearAccountsInfo;


+ (BCCTargetActionQueue *)BCC_defaultsObserverInfo;
- (void)BCC_performObserverActionsForKey:(NSString *)key forAccountWithIdentifier:(NSString *)identifier;
- (void)BCC_sendNotificationWithName:(NSString *)name forKey:(NSString *)key accountIdentifier:(NSString *)identifier;

@end


@implementation BCCAccountController

#pragma mark - Class Methods

+ (NSString *)keychainServiceName
{
    NSString *defaultsKeychainServiceName = [[NSBundle mainBundle] objectForInfoDictionaryKey:BCCAccountControllerKeychainServiceNameInfoKey];
    return defaultsKeychainServiceName ? defaultsKeychainServiceName : [[NSBundle mainBundle] bundleIdentifier];
}

+ (NSString *)currentAccountIdentifier
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:BCCAccountControllerCurrentAccountIdentifierDefaultsKey];
}

+ (void)setCurrentAccountIdentifer:(NSString *)accountIdentifier
{
    if (!accountIdentifier) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:BCCAccountControllerCurrentAccountIdentifierDefaultsKey];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:accountIdentifier forKey:BCCAccountControllerCurrentAccountIdentifierDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Initialization

- (instancetype)initWithWithAccountClass:(Class)accountClass
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _accountClass = accountClass;
    [self initializeForCurrentAccount];

    return self;
}

- (id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _accountClass = [BCCDefaultsAccount class];
    [self initializeForCurrentAccount];
    
    return self;
}

- (void)commonInit
{
    _currentAccount = nil;
    _accountManagementMode = BCCAccountControllerAccountManagementModeSingle;
}

#pragma mark - Life Cycle

- (void)initializeForCurrentAccount
{
    NSString *currentAccountID = [BCCAccountController currentAccountIdentifier];
    [self initializeForAccountIdentifier:currentAccountID];
}

- (void)initializeForAccountIdentifier:(NSString *)accountIdentifier
{
    if (!accountIdentifier) {
        return;
    }
    
    id<BCCAccount> account = [[self.accountClass alloc] initWithIdentifier:accountIdentifier];
    _currentAccount = account;
}

#pragma mark - Accounts

- (id<BCCAccount>)newAccount
{
    id<BCCAccount> account = [[self.accountClass alloc] initWithIdentifier:[[NSUUID UUID] UUIDString]];
    return account;
}

- (NSArray *)accountList
{
    return [self accountsMatchingPredicate:nil];
}

- (id<BCCAccount>)accountForIdentifier:(NSString *)identifier
{
    if (!identifier) {
        return nil;
    }
    
    NSDictionary *accountsInfo = [[NSUserDefaults standardUserDefaults] BCC_mutableAccountsInfo];
    return [accountsInfo objectForKey:identifier];
}

- (id<BCCAccount>)accountForUserID:(NSString *)userID
{
    if (!userID) {
        return nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", BCCAccountUserIDDefaultsKey, userID];
    NSArray *results = [self accountsMatchingPredicate:predicate];
    
    return [results firstObject];
}

- (NSArray *)accountsMatchingPredicate:(NSPredicate *)predicate
{
    NSDictionary *accountsInfo = [[NSUserDefaults standardUserDefaults] BCC_mutableAccountsInfo];
    
    NSArray *filteredInfo = nil;
    
    if (predicate) {
        filteredInfo = [[accountsInfo allValues] filteredArrayUsingPredicate:predicate];
    } else {
        filteredInfo = [accountsInfo allValues];
    }
    
    NSMutableArray *accounts = [[NSMutableArray alloc] init];
    
    for (NSDictionary *currentAccountInfo in filteredInfo) {
        NSString *currentIdentifier = [currentAccountInfo objectForKey:BCCAccountIdentifierDefaultsKey];
        if (!currentIdentifier) {
            continue;
        }
        
        id currentAccount = [[self.accountClass alloc] initWithIdentifier:currentIdentifier];
        [accounts addObject:currentAccount];
    }
    
    return accounts;
}

- (void)setCurrentAccount:(id <BCCAccount>)newCurrentAccount
{
    NSString *oldCurrentAccountIdentifier = self.currentAccount.identifier;
    NSString *newAccountIdentifier = newCurrentAccount.identifier;
    
    // If we're setting the account to the same account
    // bail out.
    if ([newAccountIdentifier isEqualToString:oldCurrentAccountIdentifier]) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BCCAccountControllerWillChangeCurrentAccountNotification object:nil userInfo:newCurrentAccount ? @{BCCAccountControllerNewCurrentAccountNotificationKey: newCurrentAccount} : nil];
    
    if (newCurrentAccount) {
        [BCCAccountController setCurrentAccountIdentifer:newAccountIdentifier];
        _currentAccount = newCurrentAccount;
    } else {
        [self clearCurrentAccount];
    }
    
    if (oldCurrentAccountIdentifier && (self.accountManagementMode == BCCAccountControllerAccountManagementModeSingle)) {
        [self removeAccountWithIdentifier:oldCurrentAccountIdentifier];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BCCAccountControllerDidChangeCurrentAccountNotification object:nil userInfo:newCurrentAccount ? @{BCCAccountControllerNewCurrentAccountNotificationKey: newCurrentAccount} : nil];
}

- (void)clearCurrentAccount
{
    [self removeAccountWithIdentifier:[BCCAccountController currentAccountIdentifier]];
}

- (void)removeAccountWithIdentifier:(NSString *)identifier
{
    if (!identifier) {
        return;
    }

    BOOL clearingCurrentAccount = NO;
    if ([identifier isEqualToString:[BCCAccountController currentAccountIdentifier]]) {
        [BCCAccountController setCurrentAccountIdentifer:nil];
        clearingCurrentAccount = YES;
    }
    
    if (clearingCurrentAccount) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BCCAccountControllerWillClearCurrentAccountNotification object:nil];
    }
    
    [self clearAuthCredentialForAccountWithIdentifier:identifier];
    [[NSUserDefaults standardUserDefaults] BCC_removeAccountInfoWithIdentifier:identifier];
    
    if (clearingCurrentAccount) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BCCAccountControllerDidClearCurrentAccountNotification object:nil];
    }
}

- (void)clearAuthCredentialForAccountWithIdentifier:(NSString *)identifier
{
    NSError *error = nil;
    [BCCKeychain deleteItemForUsername:identifier andServiceName:[BCCAccountController keychainServiceName] error:&error];
    if (error) {
        NSLog(@"Unable to clear auth credentials due to error: %@", error);
    }
}

- (void)removeAllAccounts
{
    [[NSNotificationCenter defaultCenter] postNotificationName:BCCAccountControllerWillClearAccountsNotification object:nil];
    
    NSDictionary *accountsInfo = [[NSUserDefaults standardUserDefaults] BCC_mutableAccountsInfo];
    NSArray *allIdentifiers = [accountsInfo allKeys];
    for (NSString *currentIdentifier in allIdentifiers) {
        [self removeAccountWithIdentifier:currentIdentifier];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:BCCAccountControllerDidClearAccountsNotification object:nil];
}

@end

                           
#pragma mark -

@implementation BCCDefaultsAccount

#pragma mark - Class Methods

+ (NSDictionary *)defaultHTTPEndpoints
{
    NSDictionary *defaultHTTPEndpoints = (NSDictionary *)[[NSBundle mainBundle] objectForInfoDictionaryKey:BCCAccountControllerDefaultHTTPEndpointsInfoKey];
    if (!defaultHTTPEndpoints || ![defaultHTTPEndpoints isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return defaultHTTPEndpoints;
}

+ (NSString *)defaultAPIVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:BCCAccountControllerDefaultAPIVersionInfoKey];
}

#pragma mark - Initialization

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    if (!(self = [super init])) {
        return nil;
    }
    
    self.identifier = identifier;
    self.environmentKey = BCCAccountControllerDefaultEnvironmentDefaultsKey;
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (identifier: %@; user ID: %@; username: %@)>", NSStringFromClass([self class]), self, self.identifier, self.userID, self.username];
}

#pragma mark - Accessors

- (void)setIdentifier:(NSString *)identifier
{
    _identifier = identifier;
    
    [self setAccountValue:identifier forKey:BCCAccountIdentifierDefaultsKey];
}

- (NSString *)userID
{
    return [self accountStringValueForKey:BCCAccountUserIDDefaultsKey];
}

- (void)setUserID:(NSString *)userID
{
    [self setAccountValue:userID forKey:BCCAccountUserIDDefaultsKey];
}

- (NSString *)username
{
    return [self accountStringValueForKey:BCCAccountUsernameDefaultsKey];
}

- (void)setUsername:(NSString *)username
{
    [self setAccountValue:username forKey:BCCAccountUsernameDefaultsKey];
}

- (NSString *)email;
{
    return [self accountStringValueForKey:BCCAccountEmailDefaultsKey];
}

- (void)setEmail:(NSString *)email
{
    [self setAccountValue:email forKey:BCCAccountEmailDefaultsKey];
}

- (NSString *)fullName
{
    return [self accountStringValueForKey:BCCAccountFullNameDefaultsKey];
}

- (void)setFullName:(NSString *)fullName
{
    [self setAccountValue:fullName forKey:BCCAccountFullNameDefaultsKey];
}

- (NSString *)firstName
{
    return [self accountStringValueForKey:BCCAccountFirstNameDefaultsKey];
}

- (void)setFirstName:(NSString *)firstName
{
    [self setAccountValue:firstName forKey:BCCAccountFirstNameDefaultsKey];
}

- (NSString *)lastName
{
    return [self accountStringValueForKey:BCCAccountLastNameDefaultsKey];
}

- (void)setLastName:(NSString *)lastName
{
    [self setAccountValue:lastName forKey:BCCAccountLastNameDefaultsKey];
}

- (NSString *)accountDescription
{
    return [self accountStringValueForKey:BCCAccountDescriptionDefaultsKey];
}

- (void)setAccountDescription:(NSString *)bio
{
    [self setAccountValue:bio forKey:BCCAccountDescriptionDefaultsKey];
}

- (NSString *)locationDescription
{
    return [self accountStringValueForKey:BCCAccountLocationDescriptionDefaultsKey];
}

- (void)setLocationDescription:(NSString *)locationDescription
{
    [self setAccountValue:locationDescription forKey:BCCAccountLocationDescriptionDefaultsKey];
}

- (NSString *)personalURL
{
    return [self accountStringValueForKey:BCCPersonalURLDefaultsKey];
}

- (void)setPersonalURL:(NSString *)personalURL
{
    [self setAccountValue:personalURL forKey:BCCPersonalURLDefaultsKey];
}

- (NSString *)phoneNumber
{
    return [self accountStringValueForKey:BCCAccountPhoneNumberDefaultsKey];
}

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    [self setAccountValue:phoneNumber forKey:BCCAccountPhoneNumberDefaultsKey];
}

- (NSString *)avatarURL
{
    return [self accountStringValueForKey:BCCAccountAvatarURLDefaultsKey];
}

- (void)setAvatarURL:(NSString *)avatarURL
{
    [self setAccountValue:avatarURL forKey:BCCAccountAvatarURLDefaultsKey];
}

- (NSString *)HTTPEndpoint
{
    NSString *endpoint = self.userHTTPEndpoint;
    
    if (!endpoint) {
        NSDictionary *defaultEndpoints = [BCCDefaultsAccount defaultHTTPEndpoints];
        if (!defaultEndpoints) {
            return nil;
        }
        
        endpoint = [defaultEndpoints objectForKey:self.environmentKey];
    }
    
    return endpoint;
}

- (NSString *)userHTTPEndpoint
{
    return [self accountStringValueForKey:BCCAccountHTTPEndpointDefaultsKey];
}

- (void)setUserHTTPEndpoint:(NSString *)HTTPEndpoint
{
    [self setAccountValue:HTTPEndpoint forKey:BCCAccountHTTPEndpointDefaultsKey];
}

- (NSString *)APIVersion
{
    NSString *version = self.userAPIVersion;
    
    if (!version) {
        version = [BCCDefaultsAccount defaultAPIVersion];
    }
    
    return version;
}

- (NSString *)userAPIVersion
{
    return [self accountStringValueForKey:BCCAccountAPIVersionDefaultsKey];
}

- (void)setUserAPIVersion:(NSString *)APIVersion
{
    [self setAccountValue:APIVersion forKey:BCCAccountAPIVersionDefaultsKey];
}

- (NSData *)authCredential
{
    if (!self.identifier) {
        return nil;
    }
    
    NSString *identifier = self.identifier;
    NSString *keychainServiceName = [BCCAccountController keychainServiceName];
    NSData *keychainData = [BCCKeychain getPasswordDataForUsername:identifier andServiceName:keychainServiceName error:NULL];
    
    //NSLog(@"KEYCHAIN REQUEST: %@ - %@ - %d", keychainServiceName, identifier, (keychainData != nil));
    
    return keychainData;
}

- (void)setAuthCredential:(NSData *)authCredential
{
    if (!self.identifier) {
        return;
    }
    
    if (!authCredential) {
        //NSLog(@"CLEAR AUTH CREDENTIAL");
        
        [self clearAuthCredential];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:BCCAccountControllerDidUpdateAuthCredentialNotification object:self];
        
        return;
    }
    
    NSString *identifier = self.identifier;
    NSString *keychainServiceName = [BCCAccountController keychainServiceName];
    
    //NSLog(@"KEYCHAIN SET: %@ - %@", keychainServiceName, identifier);
    
    NSError *error = nil;
    [BCCKeychain storeUsername:identifier andPasswordData:authCredential forServiceName:keychainServiceName updateExisting:YES error:NULL];
    if (error) {
        NSLog(@"Unable to store auth credentials due to error: %@", error);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:BCCAccountControllerDidUpdateAuthCredentialNotification object:self];
    }
}

#pragma mark - Defaults Conveniences

- (id)accountValueForKey:(NSString *)defaultsKey
{
    return [self accountValueForKey:defaultsKey environment:nil];
}

- (id)accountValueForKey:(NSString *)defaultsKey environment:(NSString *)environment
{
    if (!defaultsKey || !self.identifier) {
        return nil;
    }
    
    return [[NSUserDefaults standardUserDefaults] BCC_objectForKey:defaultsKey forAccountWithIdentifier:self.identifier environment:environment];
}

- (void)setAccountValue:(id)value forKey:(NSString *)defaultsKey
{
    [self setAccountValue:value forKey:defaultsKey environment:nil];
}

- (void)setAccountValue:(id)value forKey:(NSString *)defaultsKey environment:(NSString *)environment
{
    if (!value || [value isKindOfClass:[NSNull class]] || !defaultsKey || !self.identifier) {
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] BCC_setObject:value forKey:defaultsKey forAccountWithIdentifier:self.identifier environment:environment];
}

- (id)serializedAccountValueForKey:(NSString *)defaultsKey
{
    return [self serializedAccountValueForKey:defaultsKey environment:nil];
}

- (id)serializedAccountValueForKey:(NSString *)defaultsKey environment:(NSString *)environment
{
    if (!defaultsKey || !self.identifier) {
        return nil;
    }
    
    return [[NSUserDefaults standardUserDefaults] BCC_serializedObjectForKey:defaultsKey forAccountWithIdentifier:self.identifier environment:environment];
}

- (void)setSerializedAccountValue:(id)value forKey:(NSString *)defaultsKey
{
    [self setSerializedAccountValue:value forKey:defaultsKey environment:nil];
}

- (void)setSerializedAccountValue:(id)value forKey:(NSString *)defaultsKey environment:(NSString *)environment
{
    if (!value || !defaultsKey || !self.identifier) {
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] BCC_setSerializedObjectWithValue:value forKey:defaultsKey forAccountWithIdentifier:self.identifier environment:environment];
}

- (NSString *)accountStringValueForKey:(NSString *)defaultsKey
{
    return [self accountStringValueForKey:defaultsKey environment:nil];
}

- (NSString *)accountStringValueForKey:(NSString *)defaultsKey environment:(NSString *)environment
{
    if (!defaultsKey || !self.identifier) {
        return nil;
    }
    
    return [[NSUserDefaults standardUserDefaults] BCC_stringForKey:defaultsKey forAccountWithIdentifier:self.identifier environment:environment];
}

- (BOOL)accountBoolValueForKey:(NSString *)defaultsKey
{
    return [self accountBoolValueForKey:defaultsKey environment:nil];
}

- (BOOL)accountBoolValueForKey:(NSString *)defaultsKey environment:(NSString *)environment
{
    if (!defaultsKey || !self.identifier) {
        return NO;
    }
    
    return [[NSUserDefaults standardUserDefaults] BCC_boolForKey:defaultsKey forAccountWithIdentifier:self.identifier environment:environment];
}

- (void)setAccountBoolValue:(BOOL)value forKey:(NSString *)defaultsKey
{
    return [self setAccountBoolValue:value forKey:defaultsKey environment:nil];
}

- (void)setAccountBoolValue:(BOOL)value forKey:(NSString *)defaultsKey environment:(NSString *)environment
{
    if (!defaultsKey || !self.identifier) {
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] BCC_setBool:value forKey:defaultsKey forAccountWithIdentifier:self.identifier environment:environment];
}

#pragma mark - Auth Credentials

- (void)clearAuthCredential
{
    if (!self.authCredential) {
        return;
    }
 
    NSError *error = nil;
    [BCCKeychain deleteItemForUsername:self.identifier andServiceName:[BCCAccountController keychainServiceName] error:&error];
    if (error) {
        NSLog(@"Unable to clear auth credentials due to error: %@", error);
    }
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    if (object == self) {
        return YES;
    }
    
    return [((BCCDefaultsAccount *)object).identifier isEqualToString:self.identifier];
}

@end


#pragma mark -

@implementation NSUserDefaults (BCCAccountControllerExtensionsPrivate)

#pragma mark - Defaults Observation/Notification

+ (BCCTargetActionQueue *)BCC_defaultsObserverInfo
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultsObserverInfo = [[BCCTargetActionQueue alloc] initWithIdentifier:@"com.brooklyncomputerclub.BCCAccountController.DefaultsObserverInfo"];
    });
    
    return defaultsObserverInfo;
}

- (void)BCC_performObserverActionsForKey:(NSString *)key forAccountWithIdentifier:(NSString *)identifier
{
    if (!key) {
        return;
    }
    
    [[NSUserDefaults BCC_defaultsObserverInfo] performActionsForKey:key withObject:identifier];
    [defaultsObserverInfo performActionsForKey:BCCAccountControllerAllKeysObservationKey withObject:self];
}

- (void)BCC_sendNotificationWithName:(NSString *)name forKey:(NSString *)key accountIdentifier:(NSString *)identifier
{
    if (!name || !key) {
        return;
    }
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithObjects:@[key] forKeys:@[BCCAccountControllerNotificationUserInfoKeyDefaultsKey]];
    
    if (identifier) {
        [userInfo setObject:identifier forKey:BCCAccountControllerNotificationUserInfoKeyAccountIdentifier];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:userInfo];
}

#pragma mark - Defaults Account Info

- (NSMutableDictionary *)BCC_mutableAccountsInfo
{
	NSMutableDictionary *accountsInfo = [[self dictionaryForKey:BCCAccountControllerAccountsInfoDefaultsKey] mutableCopy];
    
    if (!accountsInfo) {
        accountsInfo = [[NSMutableDictionary alloc] init];
    }
    
    return accountsInfo;
}

- (void)BCC_setAccountsInfo:(NSDictionary *)newAccountsInfo
{
    [self setObject:newAccountsInfo forKey:BCCAccountControllerAccountsInfoDefaultsKey];
    [self synchronize];
}

- (NSMutableDictionary *)BCC_mutableValueInfoForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    if (!defaultKey) {
        return nil;
    }
    
    NSDictionary *valueInfo = nil;
    
    if (identifier) {
        NSDictionary *accountInfo = [self BCC_mutableAccountInfoForIdentifier:identifier];
        valueInfo = [accountInfo objectForKey:defaultKey];
    } else {
        valueInfo = [self objectForKey:defaultKey];
    }
    
    return [valueInfo mutableCopy];
}

- (NSMutableDictionary *)BCC_mutableAccountInfoForIdentifier:(NSString *)identifier
{
    if (!identifier) {
        return nil;
    }
    
    NSMutableDictionary *accountDefaults = [[[self BCC_mutableAccountsInfo] objectForKey:identifier] mutableCopy];
    return accountDefaults;
}

- (void)BCC_clearAccountsInfo
{
    [self removeObjectForKey:BCCAccountControllerAccountsInfoDefaultsKey];
}

- (void)BCC_setAccountInfo:(NSDictionary *)accountInfo forIdentifier:(NSString *)identifier
{
    NSMutableDictionary *accountsInfo = [self BCC_mutableAccountsInfo];
    
    if (!accountsInfo) {
        accountsInfo = [[NSMutableDictionary alloc] init];
    }
    
    [accountsInfo setObject:accountInfo forKey:identifier];
    [self BCC_setAccountsInfo:accountsInfo];
}

- (BOOL)BCC_accountInfoExistsForIdentifier:(NSString *)identifier
{
    NSDictionary *accountInfo = [self BCC_mutableAccountInfoForIdentifier:identifier];
    return (accountInfo != nil);
}

- (void)BCC_removeAccountInfoWithIdentifier:(NSString *)identifier
{
    if (!identifier) {
        return;
    }
    
    NSMutableDictionary *accountsInfo = [self BCC_mutableAccountsInfo];
    [accountsInfo removeObjectForKey:identifier];
    [self BCC_setAccountsInfo:accountsInfo];
}

@end


@implementation NSUserDefaults (BCCAccountControllerExtensions)

#pragma mark - Defaults Observation/Notification

- (void)BCC_addObserver:(id)observer selector:(SEL)selector
{
    if (!observer || selector == NULL) {
        return;
    }
    
    [[NSUserDefaults BCC_defaultsObserverInfo] addTarget:observer action:selector forKey:BCCAccountControllerAllKeysObservationKey];
}

- (void)BCC_addObserver:(id)observer selector:(SEL)selector forDefaultsKey:(NSString *)defaultsKey
{
    if (!observer || !defaultsKey || selector == NULL) {
        return;
    }
    
    [[NSUserDefaults BCC_defaultsObserverInfo] addTarget:observer action:selector forKey:defaultsKey];
}

- (void)BCC_addObserver:(id)observer selector:(SEL)selector forDefaultsKey:(NSString *)defaultsKey accountIdentifier:(NSString *)accountIdentifer
{

}

- (void)BCC_removeObserver:(id)observer
{
    if (!observer) {
        return;
    }
    
    [[NSUserDefaults BCC_defaultsObserverInfo] removeTarget:observer];
}

#pragma mark - Object Getters/Setters

- (void)BCC_setObject:(id)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    [self BCC_setObject:value forKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (void)BCC_setObject:(id)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    if (!defaultKey) {
        return;
    }

    NSMutableDictionary *valueInfo = [self BCC_mutableValueInfoForKey:defaultKey forAccountWithIdentifier:identifier];
    if (!valueInfo) {
        valueInfo = [[NSMutableDictionary alloc] init];
    }
    
    if (!environment) {
        environment = BCCAccountControllerDefaultEnvironmentDefaultsKey;
    }
    
    if (value) {
        [valueInfo setObject:value forKey:environment];
    } else {
        [valueInfo removeObjectForKey:environment];
    }
    
    if (identifier) {
        NSMutableDictionary *accountInfo = [self BCC_mutableAccountInfoForIdentifier:identifier];
        if (!accountInfo) {
            accountInfo = [[NSMutableDictionary alloc] init];
        }
        
        [accountInfo setObject:valueInfo forKey:defaultKey];
        [self BCC_setAccountInfo:accountInfo forIdentifier:identifier];
    } else {
        [self setObject:valueInfo forKey:defaultKey];
    }
    
    [self synchronize];
    
    // Send key change notifications and perform key change
    // target/actions
    [self BCC_performObserverActionsForKey:defaultKey forAccountWithIdentifier:identifier];
    [self BCC_sendNotificationWithName:BCCAccountControllerKeyModifiedNotification forKey:defaultKey accountIdentifier:identifier];
}

- (id)BCC_objectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (id)BCC_objectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    if (!defaultKey) {
        return nil;
    }
    
    NSDictionary *valueInfo = [self BCC_mutableValueInfoForKey:defaultKey forAccountWithIdentifier:identifier];
    if (!valueInfo) {
        return nil;
    }
    
    return [valueInfo objectForKey:environment ? environment : BCCAccountControllerDefaultEnvironmentDefaultsKey];
}

- (void)BCC_removeObjectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    [self BCC_removeObjectForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (void)BCC_removeObjectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    if (!defaultKey) {
        return;
    }
    
    if (identifier) {
        NSMutableDictionary *accountInfo = [self BCC_mutableAccountInfoForIdentifier:identifier];
        if (!accountInfo) {
            return;
        }
        
        NSMutableDictionary *keyInfo = [(NSDictionary *)[accountInfo objectForKey:defaultKey] mutableCopy];
        if (!keyInfo) {
            return;
        }
        
        if (environment) {
            [keyInfo removeObjectForKey:environment];
        } else {
            [accountInfo removeObjectForKey:defaultKey];
        }
        
        [self BCC_setAccountInfo:accountInfo forIdentifier:identifier];
    } else {
        if (environment) {
            NSMutableDictionary *keyInfo = [(NSDictionary *)[self objectForKey:defaultKey] mutableCopy];
            [keyInfo removeObjectForKey:environment];
            [self setObject:keyInfo forKey:defaultKey];
        } else {
            [self removeObjectForKey:defaultKey];
        }
    }
    
    [self synchronize];
}

#pragma mark - Serialized Object Getters/Setters

- (id)BCC_serializedObjectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_serializedObjectForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (id)BCC_serializedObjectForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    if (!defaultKey) {
        return nil;
    }
    
    id value = [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
    
    if (!value || ![value isKindOfClass:[NSData class]]) {
        return nil;
    }
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:(NSData *)value];
    return [unarchiver decodeObjectForKey:defaultKey];
}

- (void)BCC_setSerializedObjectWithValue:(id)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    [self BCC_setSerializedObjectWithValue:value forKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (void)BCC_setSerializedObjectWithValue:(id)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    if (!value) {
        [self BCC_removeObjectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
        return;
    }
    
    NSMutableData *valueData = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:valueData];
    [archiver encodeObject:value forKey:defaultKey];
    [archiver finishEncoding];

    [self BCC_setObject:valueData forKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
}

#pragma mark - Convenience Primitive Setters

- (void)BCC_setBool:(BOOL)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    [self BCC_setBool:value forKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (void)BCC_setBool:(BOOL)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    NSNumber *numberValue = [NSNumber numberWithBool:value];
    [self BCC_setObject:numberValue forKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
}

- (void)BCC_setDouble:(double)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    [self BCC_setDouble:value forKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (void)BCC_setDouble:(double)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    NSNumber *numberValue = [NSNumber numberWithDouble:value];
    [self BCC_setObject:numberValue forKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
}

- (void)BCC_setFloat:(float)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    [self BCC_setFloat:value forKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (void)BCC_setFloat:(float)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    NSNumber *numberValue = [NSNumber numberWithFloat:value];
    [self BCC_setObject:numberValue forKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
}

- (void)BCC_setInteger:(NSInteger)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    [self BCC_setInteger:value forKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (void)BCC_setInteger:(NSInteger)value forKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    NSNumber *numberValue = [NSNumber numberWithInteger:value];
    [self BCC_setObject:numberValue forKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
}

#pragma mark - Convenience Primitive Getters

- (BOOL)BCC_boolForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_boolForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (BOOL)BCC_boolForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    id value = [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
    
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    
    return [(NSNumber *)value boolValue];
}

- (double)BCC_doubleForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_doubleForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (double)BCC_doubleForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    id value = [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
    
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return 0.0;
    }
    
    return [(NSNumber *)value doubleValue];
}

- (float)BCC_floatForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_floatForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (float)BCC_floatForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    id value = [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
    
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return 0.0F;
    }
    
    return [(NSNumber *)value floatValue];
}

- (NSInteger)BCC_integerForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_integerForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (NSInteger)BCC_integerForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    id value = [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
    
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return 0;
    }
    
    return [(NSNumber *)value integerValue];
}

#pragma mark - Convenience Object Getters

- (NSString *)BCC_stringForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_stringForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (NSString *)BCC_stringForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    id value = [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
    
    if (!value || ![value isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    return (NSString *)value;
}

- (NSNumber *)BCC_numberForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_numberForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (NSNumber *)BCC_numberForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    id value = [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
    
    if (!value || ![value isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    return (NSNumber *)value;
}

- (NSDictionary *)BCC_dictionaryForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_dictionaryForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (NSDictionary *)BCC_dictionaryForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    id value = [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
    
    if (!value || ![value isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    return (NSDictionary *)value;
}

- (NSArray *)BCC_arrayForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_arrayForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (NSArray *)BCC_arrayForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    id value = [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
    
    if (!value || ![value isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    return (NSArray *)value;
}

- (NSData *)BCC_dataForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier
{
    return [self BCC_dataForKey:defaultKey forAccountWithIdentifier:identifier environment:nil];
}

- (NSData *)BCC_dataForKey:(NSString *)defaultKey forAccountWithIdentifier:(NSString *)identifier environment:(NSString *)environment
{
    id value = [self BCC_objectForKey:defaultKey forAccountWithIdentifier:identifier environment:environment];
    
    if (!value || ![value isKindOfClass:[NSData class]]) {
        return nil;
    }
    
    return (NSData *)value;
}

@end

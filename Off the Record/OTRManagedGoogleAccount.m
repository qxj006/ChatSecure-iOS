#import "OTRManagedGoogleAccount.h"
#import "GTMOAuth2Authentication.h"
#import "Strings.h"

#define kExpirationDateKey @"kExpirationDateKey"
#define kExpiresInKey @"expires_in"

@interface OTRManagedGoogleAccount ()

// Private interface goes here.

@end


@implementation OTRManagedGoogleAccount

-(OTRAccountType)accountType
{
    return OTRAccountTypeGoogleTalk;
}

-(NSString *)imageName
{
    return kGTalkImageName;
}
-(BOOL)shouldAllowSSLHostNameMismatch
{
    return NO;
}

-(NSString *)providerName
{
    return GOOGLE_TALK_STRING;
}

-(BOOL)shouldAllowPlainTextAuthentication
{
    return NO;
}

-(BOOL)shouldAllowSelfSignedSSL
{
    return NO;
}
- (BOOL) shouldRequireTLS
{
    return NO;
}

-(void)refreshToken:(void (^)(NSError *error))completionBlock
{
    [[self authToken] authorizeRequest:nil completionHandler:completionBlock];
}

-(void)refreshTokenIfNeeded:(void (^)(NSError *error))completion
{
    if ([self needsRefresh] ) {
        [self refreshToken:completion];
    }
    else {
        completion(nil);
    }
}

-(NSString *)accessTokenString {
    return [self authToken].accessToken;
}

-(BOOL)needsRefresh
{
    GTMOAuth2Authentication * auth = [self authToken];
    BOOL shouldRefresh = NO;
    if ([auth.refreshToken length] || [auth.assertion length] || [auth.code length]) {
        if (![auth.accessToken length]) {
            shouldRefresh = YES;
        } else {
            // We'll consider the token expired if it expires 60 seconds from now
            // or earlier
            
            /////Dumb google needs to refesh expirationDate
            [auth setExpiresIn:auth.expiresIn];
            /////////
            
            NSDate *expirationDate = auth.expirationDate;
            NSTimeInterval timeToExpire = [expirationDate timeIntervalSinceNow];
            if (expirationDate == nil || timeToExpire < 60.0) {
                // access token has expired, or will in a few seconds
                shouldRefresh = YES;
            }
        }
    }
    return shouldRefresh;
}

-(void)setTokenDictionary:(NSDictionary *)tokenDictionary
{
    if ([tokenDictionary count]) {
        NSMutableDictionary * mutableTokenDictionary = [tokenDictionary mutableCopy];
        NSNumber * expiresIn = [mutableTokenDictionary objectForKey:kExpiresInKey];
        [mutableTokenDictionary removeObjectForKey:kExpiresInKey];
        NSDate *date = nil;
        if (expiresIn) {
            unsigned long deltaSeconds = [expiresIn unsignedLongValue];
            if (deltaSeconds > 0) {
                date = [NSDate dateWithTimeIntervalSinceNow:deltaSeconds];
            }
        }
        [mutableTokenDictionary setObject:date forKey:kExpirationDateKey];
        tokenDictionary = mutableTokenDictionary;
    }
    [super setTokenDictionary:tokenDictionary];
}

-(NSDictionary *)tokenDictionary
{
    NSMutableDictionary * mutableTokenDictionary = [[super tokenDictionary] mutableCopy];
    NSDate * expirationDate = [mutableTokenDictionary objectForKey:kExpirationDateKey];
    
    NSTimeInterval timeInterval  = [expirationDate timeIntervalSinceDate:[NSDate date]];
    mutableTokenDictionary[kExpiresInKey] = @(timeInterval);
    return mutableTokenDictionary;
}

-(GTMOAuth2Authentication *)authToken
{
    GTMOAuth2Authentication * auth = nil;
    NSDictionary * tokenDictionary = [self tokenDictionary];
    if ([tokenDictionary count]) {
        auth = [[GTMOAuth2Authentication alloc] init];
        [auth setParameters:[tokenDictionary mutableCopy]];
    }
    return auth;
}

@end

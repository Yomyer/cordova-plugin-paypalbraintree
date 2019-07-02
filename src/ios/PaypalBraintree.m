#import "PaypalBraintree.h"
#import <objc/runtime.h>

#import <BraintreeCore/BTAPIClient.h>
#import <BraintreePayPal/BraintreePayPal.h>

#import "AppDelegate.h"

@interface PaypalBraintree() <BTAppSwitchDelegate, BTViewControllerPresentingDelegate>

@property (nonatomic, strong) NSDictionary* options;
// @property (nonatomic, strong) BTAPIClient *braintreeClient;
// @property NSString* token;

@end

@implementation AppDelegate(BraintreePlugin)

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {

    NSString *bundle_id = [NSBundle mainBundle].bundleIdentifier;
    bundle_id = [bundle_id stringByAppendingString:@".payments"];

    if ([url.scheme localizedCaseInsensitiveCompare:bundle_id] == NSOrderedSame) {
        return [BTAppSwitch handleOpenURL:url options:options];
    }

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];

    return NO;
}

@end



@implementation PaypalBraintree

- (void)pluginInitialize {
    NSString *bundle_id = [NSBundle mainBundle].bundleIdentifier;
    bundle_id = [bundle_id stringByAppendingString:@".payments"];

    [BTAppSwitch setReturnURLScheme:bundle_id];
}

- (void)initialize:(CDVInvokedUrlCommand*)command {
    self.options = [[NSDictionary alloc]init];
    self.options = [command.arguments objectAtIndex:0];
}

- (void)refresh:(CDVInvokedUrlCommand*)command {
    [self.options setValue:[command.arguments objectAtIndex:0] forKey:@"token"];
}

- (void)checkout:(CDVInvokedUrlCommand*)command {
    
    NSString* token = (NSString *)[self.options objectForKey:@"token"];
    NSString* amount = [(NSNumber *)(NSString *)[self.options objectForKey:@"amount"] stringValue];
    NSString* description = (NSString *)[self.options objectForKey:@"description"];
    NSString* currency = (NSString *)[self.options objectForKey:@"currency"];
    NSString* name = (NSString *)[self.options objectForKey:@"name"];
    NSArray* items = (NSArray *)[self.options objectForKey:@"items"];

    if (!token || token == nil || token == (id)[NSNull null]) {
        CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"A token is required."];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
        
        [self evalJs:@"onError" object:@{ @"error": @"A token is required." }];
        
        return;
    }
    if (!amount || amount == nil || amount == (id)[NSNull null]) {
        CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"A amount is required"];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
        
        [self evalJs:@"onError" object:@{ @"error": @"A amount is required" }];
        
        return;
    }
    if (!description || description == nil || description == (id)[NSNull null]) {
        CDVPluginResult *res = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"A description is required"];
        [self.commandDelegate sendPluginResult:res callbackId:command.callbackId];
        
        [self evalJs:@"onError" object:@{ @"error": @"A amount is required" }];
        
        return;
    }

    BTAPIClient *braintreeClient =  [[BTAPIClient alloc] initWithAuthorization:token];
    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithAPIClient:braintreeClient];
    payPalDriver.viewControllerPresentingDelegate = self;
    payPalDriver.appSwitchDelegate = self;
    
    BTPayPalRequest *request= [[BTPayPalRequest alloc] initWithAmount:amount];
    [request setBillingAgreementDescription:description];
    [request setCurrencyCode:currency];
    if(name){
        [request setDisplayName:name];
    }
    
    if(items.count){
        NSMutableArray *lineItems = [[NSMutableArray alloc] init];

        for (id object in items) {
            NSString* quantity = (NSString *)[object objectForKey:@"quantity"];
            NSString* amount = (NSString *)[object objectForKey:@"unitAmount"];
            NSString* name = (NSString *)[object objectForKey:@"name"];
            NSString* description = (NSString *)[object objectForKey:@"description"];
            NSString* taxAmount = (NSString *)[object objectForKey:@"unitTaxAmount"];
            NSString* url = (NSString *)[object objectForKey:@"url"];
            NSString* productCode = (NSString *)[object objectForKey:@"productCode"];
            NSString* kind = (NSString *)[object objectForKey:@"kind"];
            
            int kindItem = [kind isEqualToString:@"credit"] ? BTPayPalLineItemKindCredit: BTPayPalLineItemKindDebit;
            
            BTPayPalLineItem* item = [[BTPayPalLineItem alloc] initWithQuantity:quantity unitAmount:amount name:name kind:kindItem];

            if(description){
               [item setItemDescription:description];
            }
            
            if(taxAmount){
                [item setUnitTaxAmount:taxAmount];
            }
            
            if(productCode){
                [item setProductCode:productCode];
            }
            
            if(url){
                [item setUrl:[NSURL URLWithString:url]];
            }
            
            [lineItems addObject:item];
        }
        [request setLineItems:lineItems];
    }

    [payPalDriver requestOneTimePayment:request completion:^(BTPayPalAccountNonce * _Nullable tokenizedPayPalAccount, NSError * _Nullable error) {
        if (tokenizedPayPalAccount) {

            NSDictionary *dictionary = [self getPaymentUINonceResult:tokenizedPayPalAccount];
            CDVPluginResult* result = [CDVPluginResult
                                resultWithStatus:CDVCommandStatus_OK
                                messageAsDictionary:dictionary];

            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            [self evalJs:@"onAuthorize" object:dictionary];
            
        } else if (error) {
            NSLog(@"Error: %@", error);
            NSDictionary *dictionary = @{ @"error": [error localizedDescription] };
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                        messageAsDictionary:dictionary];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            
            [self evalJs:@"onError" object:@{ @"error": [error localizedDescription] }];
            
        } else {
            NSDictionary *dictionary = @{ @"userCancelled": @YES };
            CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                        messageAsDictionary:dictionary];
            
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            
            [self evalJs:@"onAuthorize" object:@{ @"userCancelled": @YES }];
        }
    }];
}

- (Boolean) evalJs:(NSString*)method object:(NSObject*) object{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
              options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *js = [NSString stringWithFormat:@"PaypalBraintree.%@(%@)",
                    method, json];
                    
    [self.commandDelegate evalJs:js];
    
    return true;
}

- (NSDictionary*)getPaymentUINonceResult:(BTPayPalAccountNonce *)payPalAccountNonce {
    
    NSDictionary *dictionary = @{ @"userCancelled": @NO,
                                  @"error": [NSNull null],
                                  @"nonce": payPalAccountNonce.nonce,
                                  @"type": payPalAccountNonce.type,
                                  @"localizedDescription": payPalAccountNonce.localizedDescription,
                                  @"email": payPalAccountNonce.email,
                                  @"firstName": (payPalAccountNonce.firstName == nil ? [NSNull null] : payPalAccountNonce.firstName),
                                  @"lastName": (payPalAccountNonce.lastName == nil ? [NSNull null] : payPalAccountNonce.lastName),
                                  @"phone": (payPalAccountNonce.phone == nil ? [NSNull null] : payPalAccountNonce.phone),
                                  //@"billingAddress" //TODO
                                  //@"shippingAddress" //TODO
                                  @"clientMetadataId":  (payPalAccountNonce.clientMetadataId == nil ? [NSNull null] : payPalAccountNonce.clientMetadataId),
                                  @"payerId": (payPalAccountNonce.payerId == nil ? [NSNull null] : payPalAccountNonce.payerId),
                                  };
    return dictionary;
}

@end

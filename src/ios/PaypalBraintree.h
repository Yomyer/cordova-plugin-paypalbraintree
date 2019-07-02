#import <Cordova/CDVPlugin.h>

@interface PaypalBraintree : CDVPlugin {
}

- (void)initialize:(CDVInvokedUrlCommand*)command;
- (void)refresh:(CDVInvokedUrlCommand*)command;
- (void)checkout:(CDVInvokedUrlCommand*)command;

@end
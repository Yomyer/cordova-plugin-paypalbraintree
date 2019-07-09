# Paypal Braintree Cordova Plugin

This is a [Cordova](http://cordova.apache.org/) plugin for the implementation of [Paypal Checkout](https://developer.paypal.com/docs/accept-payments/express-checkout/ec-braintree-sdk/get-started/) Client using the [Braintree](https://www.braintreepayments.com/) SDK.

This version of the plugin uses versions 4.23.1 (iOS), 2.22.0 (Android) , 3.46.0 (Browser) of the Braintree mobile SDK. Braintree SDK documentation can be found [here](https://developers.braintreepayments.com/start/overview).

This plugin is still in development.

# Install

To add the plugin to your Cordova project, simply add the plugin from the npm registry:

```
$ ionic cordova plugin add https://github.com/Yomyer/cordova-plugin-paypalbraintree.git
```

If you use ionic, you can install the ionic native module from [paypal-braintree](https://www.npmjs.com/package/@yomyer/paypal-braintree)
```
$ npm install @yomyer/paypal-braintree
```

# Usage

The plugin is available through a global variable called PaypalBraintree. It exposes the following properties and functions.

All functions accept optional successful and error callbacks as their last two arguments, where the error callback will receive an error string as an argument unless otherwise indicated.

## Initialize Paypal Checkout Client

Paypal Checkout Braintree SDK works differently in Browser than in iOs / Android. The initiator in browser starts the client Braintree or Paypal.Button and does not use checkout as it generates a button at this point. For ios and android it is only used to store the information that will be used to start the Braintree SDK at checkout. 

For a correct operation of the plugin, the callbacks have been moved as a parameter within options, the cordova callbacks continue working but only to communicate the correct operation of the plugin, you can leave them empty.

```
onError: response => {
   console.log(response.error);     
},
onAuthorize: response => {
    console.log(response.nonce);
}
```

Method Signature:

`initialize(token, options, successCallback, failureCallback)`

Parameters:

* `token` (string): The unique client token or static tokenization key to use.
* `options` (object): The Paypal configuration

Example Usage:

```
var token = "YOUR_TOKEN";

PaypalBraintree.initialize(token, {
        amount: '20',
        description: 'Description',
        name: 'Vendor',
        // If you are going to use it in a browser
        element: this.button.nativeElement, 
        // If you want to hide the default Paypal button and use a custom button element
        customButton: true, 
        env: 'sandbox',
        items: [
            {
                quantity: '1',
                unitAmount: '20',
                name: 'Text of item',
                productCode: 'UC-43493-23',
            }
        ],
        onError: response => {
          console.log(response.error);
        },
        onAuthorize: response => {
          if (!response.userCancelled) {
            // Submit `payload.nonce` to your server.
          } else {
            // Cacelled user callback
          }
        }
    },
    function () { console.log("init OK!"); },
    function (error) { console.error(error); }
);
```

## Trigger Checkout (ios, android)

To start Express Checkout flow. Depending on the action of the user will launch onError or onAuthorize the configuration in initialize

`checkout(successCallback, failureCallback)`

Example Usage:

```
PaypalBraintree.checkout(
    function () { console.log("init OK!"); },
    function (error) { console.error(error); }
)

```

## Supported platforms
- Android
- iOS
- Browser




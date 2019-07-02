var exec = require('cordova/exec');

var PLUGUIN_NAME = 'PaypalBraintree';

var PaypalBraintree = {
    error: null,
    authorize: null,
    onAuthorize: function (response) {
        if(this.authorize){
            this.authorize(response);
        }
    },

    onError: function (response) {
        if(this.error){
            this.error(response);
        }
    },

    initialize: function (token, options, success, error) {
        if(options.onError){
            this.error = options.onError;
        }
        if(options.onAuthorize){
            this.authorize = options.onAuthorize;
        }

        options = {
            token: token,
            amount: Number(options.amount).toFixed(2),
            description: options.description,
            currency: options.currency || "EUR",
            name: options.name || null,
            items: options.items || [],
            element: options.element || null,
            env: options.env || 'sandbox',
            customButton: options.customButton === 'null' ? true : options.customButton
        }

        exec(success, error, PLUGUIN_NAME, "initialize", [options]);
    },

    refresh: function (token, success, error) {
        exec(success, error, PLUGUIN_NAME, "refresh", [token]);
    },
    
    checkout: function (success, error) {
        exec(success, error, PLUGUIN_NAME, "checkout");
    }
    

}

module.exports = PaypalBraintree;

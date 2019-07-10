var exec = require('cordova/exec');

var PLUGUIN_NAME = 'PaypalBraintree';

var locales = {
    'en': 'en_US', 
    'es': 'es_ES', 
    'it': 'it_IT', 
    'fr': 'fr_FR', 
    'de': 'de_DE', 
    'da': 'da_DK', 
    'zh': 'zh_HK', 
    'id': 'id_ID', 
    'he': 'he_IL', 
    'ja': 'ja_JP', 
    'nl': 'nl_NL', 
    'no': 'no_NO', 
    'pl': 'pl_PL', 
    'pt': 'pt_PT', 
    'ru': 'ru_RU', 
    'sv': 'sv_SE', 
    'th': 'th_TH', 
    'zh': 'zh_TW'
}

var PaypalBraintree = {
    error: null,
    authorize: null,
    render: null,
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

    onRender: function (response) {
        if(this.render){
            this.render(response);
        }
    },

    initialize: function (token, options, success, error) {
        if(options.onError){
            this.error = options.onError;
        }
        if(options.onAuthorize){
            this.authorize = options.onAuthorize;
        }
        if(options.onRender){
            this.render = options.onRender;
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
            locale: options.locale ? locales[options.locale] || 'en_US' : 'en_US',
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

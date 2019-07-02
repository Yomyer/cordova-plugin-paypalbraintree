

var PaypalBraintree = {
  initialize: function (success, error, opts) {
    var options = opts[0];

    paypal.Button.render({
      braintree: braintree,
      client: {
        production: options.token,
        sandbox: options.token
      },
      env: options.env,
      commit: false,
      style: {
        shape: 'rect',
        size: 'large'
      },
      payment: function (data, actions) {
        var data = {
          flow: 'checkout', // Required
          amount: options.amount, // Required
          currency: options.currency // Required
        };

        if(options.name){
          data.displayName = options.name
        }
        
        if(options.items){
          data.lineItems = options.items.map(element => {
            element.kind = element.kind || 'debit';
            return element;
          })
        }

        return actions.braintree.create(data);
      },

      onAuthorize: function (data, actions) {
        return actions.payment.tokenize()
          .then(function (data) {
            success(data);
            window.PaypalBraintree.onAuthorize(data);
          });
      },

      onError: function (err) {
        window.PaypalBraintree.onError({ error: err });
        error({ error: err });

      },

      onCancel: function (data, actions) {
        window.PaypalBraintree.onAuthorize({ userCancelled: true });
        success({ userCancelled: true });
      },

      onRender: function (data, actions) {
        if(options.customButton){
          options.element.style.position = 'relative';
          setTimeout(_ => {
            var context = options.element.querySelector('.paypal-button');
            context.style.position = 'absolute';
            context.style.top = 0;
            context.style.left = 0;
            context.style.bottom = 0;
            context.style.right = 0;
            context.style.opacity = 0.000001;
          });
        }
      }
    }, options.element);

  },

  checkout: function (success, error) {


  },
}


module.exports = PaypalBraintree;

require('cordova/exec/proxy').add('PaypalBraintree', module.exports);
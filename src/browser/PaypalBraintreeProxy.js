

var PaypalBraintree = {
  initialize: function (success, error, opts) {
    var options = opts[0];

    if (options.customButton) {
      options.element.style.height = options.element.clientHeight + 'px';
      options.element.style.overflow = 'hidden';
    }

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
      locale: options.locale,
      payment: function (data, actions) {
        var data = {
          flow: 'checkout', // Required
          amount: options.amount, // Required
          currency: options.currency // Required
        };

        if (options.name) {
          data.displayName = options.name
        }

        if (options.items) {
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

      onCancel: function () {
        window.PaypalBraintree.onAuthorize({ userCancelled: true });
        success({ userCancelled: true });
      },

      onClick: function(){
        window.PaypalBraintree.onClick();
      },

      onRender: function () {
        if (options.customButton) {
          options.element.style.position = 'relative';
          setTimeout(_ => {
            var context = options.element.querySelector('.paypal-button');
            context.style.position = 'absolute';
            context.style.top = 0;
            context.style.left = 0;
            context.style.bottom = 0;
            context.style.right = 0;
            context.style.opacity = 0.000001;

            var outlet = options.element.querySelector('.zoid-outlet');
            outlet.style.width = '100%';
            outlet.style.display = 'block';
            outlet.style.margin = 'auto';
            
            window.PaypalBraintree.onRender();
          });
        }else{
          window.PaypalBraintree.onRender();
        }
      }
    }, options.element);

  },

  checkout: function (success, error) {


  }
}


module.exports = PaypalBraintree;

require('cordova/exec/proxy').add('PaypalBraintree', module.exports);
package yomyer;

import android.nfc.Tag;
import android.util.Log;

import java.util.Collection;
import java.util.Date;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

import com.braintreepayments.api.BraintreeFragment;
import com.braintreepayments.api.DataCollector;
import com.braintreepayments.api.PayPal;
import com.braintreepayments.api.exceptions.InvalidArgumentException;
import com.braintreepayments.api.interfaces.BraintreeCancelListener;
import com.braintreepayments.api.interfaces.PaymentMethodNonceCreatedListener;
import com.braintreepayments.api.interfaces.BraintreeErrorListener;
import com.braintreepayments.api.models.PayPalAccountNonce;
import com.braintreepayments.api.models.PayPalLineItem;
import com.braintreepayments.api.models.PayPalRequest;
import com.braintreepayments.api.models.PaymentMethodNonce;
import com.braintreepayments.api.models.ThreeDSecureInfo;

/**
 * This class echoes a string called from JavaScript.
 */
public class PaypalBraintree extends CordovaPlugin implements PaymentMethodNonceCreatedListener, BraintreeErrorListener, BraintreeCancelListener {
    private static final String TAG = "PaypalBraintree";
    private CallbackContext _callbackContext = null;
    private JSONObject _options = null;
    private BraintreeFragment braintreeFragment = null;

    @Override
    public synchronized boolean execute(String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (action == null) {
            Log.e(TAG, "execute ==> exiting for bad action");
            return false;
        }

        _callbackContext = callbackContext;

        try {
            if (action.equals("initialize")) {
                this.initialize(args);
            }
            else if (action.equals("checkout")) {
                cordova.getThreadPool().execute(new Runnable() {
                    @Override
                    public void run(){
                        _callbackContext.sendPluginResult(checkout());
                    }
                });
            }
            else {
                // The given action was not handled above.
                return false;
            }
        } catch (Exception exception) {
            callbackContext.error("BraintreePlugin uncaught exception: " + exception.getMessage());
        }

        return true;
    }

    @Override
    public void onError(Exception error) {
        String e = "Caught error from BraintreeSDK:: " + error.getMessage();

        _callbackContext.error(e);
        this.evalJs("onError", this.error(e));
    }

    @Override
    public void onCancel(int requestCode) {
        JSONObject object = new JSONObject();

        try{
            object.put("userCancelled", true);
        } catch(JSONException exception){

        }

        _callbackContext.success(object);
        this.evalJs("onAuthorize", object);
    }

    @Override
    public void onPaymentMethodNonceCreated(PaymentMethodNonce paymentMethodNonce) {
        if (paymentMethodNonce instanceof PayPalAccountNonce) {
            PayPalAccountNonce payPalAccountNonce = (PayPalAccountNonce)paymentMethodNonce;
            JSONObject result = new JSONObject(this.getPaymentUINonceResult(payPalAccountNonce));

            _callbackContext.success(result);
            this.evalJs("onAuthorize", result);
        }

    }

    private synchronized void initialize(final JSONArray args) throws JSONException {
        _options = args.getJSONObject(0);
        this.evalJs("onRender", new JSONObject());
        
    }
    private PluginResult checkout() {
        this.evalJs("onClick", new JSONObject());
        try {
            String token = _options.getString("token");
            String amount = _options.getString("amount");
            String description = _options.getString("description");
            String currency = _options.getString("currency");
            String name = _options.getString("name");
            String locale = _options.getString("locale");
            JSONArray items = _options.getJSONArray("items");


            if (token == null || token.equals("")) {
                _callbackContext.error("A token is required.");

                this.evalJs("onError", this.error("A token is required."));
                return new PluginResult(PluginResult.Status.JSON_EXCEPTION);
            }

            if (amount == null || amount.equals("")) {
                _callbackContext.error("A amount is required.");
                this.evalJs("onError", this.error("A amount is required."));
                return new PluginResult(PluginResult.Status.JSON_EXCEPTION);
            }

            if (description == null || description.equals("")) {
                _callbackContext.error("A description is required.");
                this.evalJs("onError", this.error("A description is required."));
                return new PluginResult(PluginResult.Status.JSON_EXCEPTION);
            }


            braintreeFragment = BraintreeFragment.newInstance(cordova.getActivity(), token);
            braintreeFragment.addListener(this);

            PayPalRequest request = new PayPalRequest(amount)
                    .currencyCode(currency)
                    .localeCode(locale)
                    .intent(PayPalRequest.INTENT_AUTHORIZE);

            if(name == null || name.equals("")){
                request.displayName(name);
            }

            if(items.length() != 0){
                ArrayList<PayPalLineItem> lineItems = new ArrayList<>();

                for (int i=0; i<items.length(); i++) {

                    JSONObject object =  (JSONObject) items.get(i);
                    String itemQuantity = object.getString("quantity");
                    String itemAmount = object.getString("unitAmount");
                    String itemName = object.getString("name");
                    String kind = object.has("kind") ? object.getString("kind") : "debit";

                    String itemDescription = object.has("description") ? object.getString("description") : null;
                    String taxAmount = object.has("unitTaxAmount") ? object.getString("unitTaxAmount") : null;
                    String url = object.has("url") ? object.getString("url") : null;
                    String productCode = object.has("productCode") ? object.getString("productCode") : null;

                    String itemKind = kind.equals("credit") ? PayPalLineItem.KIND_CREDIT : PayPalLineItem.KIND_DEBIT;

                    PayPalLineItem item = new PayPalLineItem(itemKind, itemName, itemQuantity, itemAmount);

                    if (itemDescription != null && !itemDescription.equals("")) {
                        item.setDescription(itemDescription);
                    }
                    if (taxAmount != null && !taxAmount.equals("")) {
                        item.setUnitTaxAmount(taxAmount);
                    }
                    if (productCode != null && !productCode.equals("")) {
                        item.setProductCode(productCode);
                    }
                    if (url != null && !url.equals("")) {
                        item.setUrl(url);
                    }

                    lineItems.add(item);

                }

                request.lineItems(lineItems);
            }

            PayPal.requestOneTimePayment(braintreeFragment, request);

            return new PluginResult(PluginResult.Status.OK);
        }
        catch (Exception e) {//     // There was an issue with your authorization string.
            String error = "Error creating PayPal interface: " + e.getMessage();
            _callbackContext.error(TAG + error);
            this.evalJs("onError", this.error(error));
            return new PluginResult(PluginResult.Status.JSON_EXCEPTION);
        }
    }


    private JSONObject error(final String error) {
        JSONObject object = new JSONObject();

        try{
            object.put("error", error);
        } catch(JSONException exception){

        }

        return object;
    }

    private synchronized void evalJs(final String method, final JSONObject object){
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                webView.loadUrl("javascript:PaypalBraintree." + method + "("+object.toString()+")");
            }
        });
    }

    private Map<String, Object> getPaymentUINonceResult(PayPalAccountNonce payPalAccountNonce) {
        Map<String, Object> resultMap = new HashMap<String, Object>();

        resultMap.put("userCancelled", false);
        resultMap.put("error", null);
        resultMap.put("nonce", payPalAccountNonce.getNonce());
        resultMap.put("type", payPalAccountNonce.getTypeLabel());
        resultMap.put("localizedDescription", payPalAccountNonce.getDescription());
        resultMap.put("email", payPalAccountNonce.getEmail());
        resultMap.put("firstName", payPalAccountNonce.getFirstName());
        resultMap.put("lastName", payPalAccountNonce.getLastName());
        resultMap.put("phone", payPalAccountNonce.getPhone());
        //resultMap.put("billingAddress", paypalAccountNonce.getBillingAddress()); //TODO
        //resultMap.put("shippingAddress", paypalAccountNonce.getShippingAddress()); //TODO
        resultMap.put("clientMetadataId", payPalAccountNonce.getClientMetadataId());
        resultMap.put("payerId", payPalAccountNonce.getPayerId());

        return resultMap;
    }
}

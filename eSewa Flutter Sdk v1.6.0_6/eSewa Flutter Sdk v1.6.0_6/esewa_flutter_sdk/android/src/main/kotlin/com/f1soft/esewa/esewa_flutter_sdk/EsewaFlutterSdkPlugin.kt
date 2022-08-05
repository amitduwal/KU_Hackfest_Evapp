package com.f1soft.esewa.esewa_flutter_sdk

import android.app.Activity
import android.content.Intent
import android.util.Log
import android.widget.Toast
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import com.f1soft.esewa.esewa_flutter_sdk.Constants.ARGS_KEY_CONFIG
import com.f1soft.esewa.esewa_flutter_sdk.Constants.ARGS_KEY_PAYMENT
import com.f1soft.esewa.esewa_flutter_sdk.Constants.METHOD_CHANNEL_NAME
import com.f1soft.esewa.esewa_flutter_sdk.Constants.PAYMENT_METHOD_CANCELLATION
import com.f1soft.esewa.esewa_flutter_sdk.Constants.PAYMENT_METHOD_FAILURE
import com.f1soft.esewa.esewa_flutter_sdk.Constants.PAYMENT_METHOD_NAME
import com.f1soft.esewa.esewa_flutter_sdk.Constants.PAYMENT_METHOD_SUCCESS
import com.f1soft.esewa.esewa_flutter_sdk.Constants.PAYMENT_REQ_CODE
import com.f1soft.esewasdk.ESewaConfiguration
import com.f1soft.esewasdk.ESewaPayment
import com.f1soft.esewasdk.ui.ESewaPaymentActivity

/** EsewaFlutterSdkPlugin */

class EsewaFlutterSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var config: ESewaConfiguration? = null
    private var payment: ESewaPayment? = null
    private var _result : MethodChannel.Result? = null
    private val TAG = this::class.java.simpleName

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        _result = result
        when (call.method) {
            PAYMENT_METHOD_NAME -> {
                initPayment(call)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        _result = null
    }

    private fun showToast(call: MethodCall, result: Result) {
        val message = call.argument<String>("message")
        Toast.makeText(activity, message, Toast.LENGTH_LONG).show()
        result.success("TOAST DISPLAYED")
    }

    private fun initPayment(call: MethodCall) {
        val configMap: HashMap<String, String> = call.argument(ARGS_KEY_CONFIG)!!
        Log.d(TAG, "configMap: $configMap ")

        val paymentMap: HashMap<String, String> = call.argument(ARGS_KEY_PAYMENT)!!
        Log.d(TAG, "paymentMap: $paymentMap ")

        Log.d(TAG, "config: ${PaymentUtils.initConfig(configMap)}")
        Log.d(TAG, "payment: ${PaymentUtils.initPayment(paymentMap)}")

        Intent(activity, ESewaPaymentActivity::class.java).apply {
            putExtra(ESewaConfiguration.ESEWA_CONFIGURATION,PaymentUtils.initConfig(configMap))
            putExtra(ESewaPayment.ESEWA_PAYMENT, PaymentUtils.initPayment(paymentMap))
        }.also {
            activity?.startActivityForResult(it, PAYMENT_REQ_CODE)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        _result = null

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
        _result = null
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        when (requestCode) {
            PAYMENT_REQ_CODE -> {
                when (resultCode) {
                    Activity.RESULT_OK -> {
                        val paymentResult = data?.getStringExtra(ESewaPayment.EXTRA_RESULT_MESSAGE)
                        channel.invokeMethod(PAYMENT_METHOD_SUCCESS,paymentResult)
                        Log.d(TAG, "Payment Result Data: $paymentResult")

                    }
                    Activity.RESULT_CANCELED -> {
                        channel.invokeMethod(PAYMENT_METHOD_CANCELLATION,"Payment Cancelled By User")
                        Log.d(TAG, "Canceled By User")
                    }
                    ESewaPayment.RESULT_EXTRAS_INVALID -> {
                        val paymentResult = data?.getStringExtra(ESewaPayment.EXTRA_RESULT_MESSAGE)
                        channel.invokeMethod(PAYMENT_METHOD_FAILURE,paymentResult)
                        Log.d(TAG, "Payment Result Data: $paymentResult")
                    }
                }
            }
        }
        return false
    }
}

import 'dart:convert';
import 'dart:io';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

class EsewaFlutterSdk {
  static const MethodChannel _channel =
      const MethodChannel(METHOD_CHANNEL_NAME);

  static void showToast(String message) {
    _channel.invokeMethod('showToast', {"message": message});
  }

  static void initPayment({
    required EsewaConfig esewaConfig,
    required EsewaPayment esewaPayment,
    required Function(EsewaPaymentSuccessResult) onPaymentSuccess,
    required Function onPaymentFailure,
    required Function onPaymentCancellation,
  }) {
    _channel.invokeMethod(
        'initPayment', _buildArgs(esewaConfig, esewaPayment));
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case PAYMENT_METHOD_SUCCESS:
          print(":::METHOD CALL RESULT SUCCESS");
          final Map<String, dynamic> result;
          if (Platform.isIOS) {
            result = Map<String, dynamic>.from(call.arguments);
          } else {
            result = json.decode(call.arguments);
          }
          final EsewaPaymentSuccessResult paymentResult = EsewaPaymentSuccessResult(
            productId: result["productID"] ?? result["productId"],
            productName: result["productName"],
            totalAmount: result["totalAmount"],
            environment: result["environment"],
            code: result["code"],
            merchantName: result["merchantName"],
            message: result["message"]["successMessage"],
            status: result["transactionDetails"]["status"],
            date: result["transactionDetails"]["date"],
            refId: result["transactionDetails"]["referenceId"],
          );
          onPaymentSuccess(paymentResult);
          break;
        case PAYMENT_METHOD_FAILURE:
          print(":::METHOD CALL RESULT FAILURE");
          onPaymentFailure(call.arguments);
          break;
        case PAYMENT_METHOD_CANCELLATION:
          print(":::METHOD CALL RESULT CANCELLATION");
          onPaymentCancellation(call.arguments);
          break;
      }
    });
  }

  static Map<String, dynamic> _buildArgs(
    EsewaConfig esewaConfig,
    EsewaPayment esewaPayment,
  ) =>
      {
        ARGS_KEY_CONFIG: esewaConfig.toMap(),
        ARGS_KEY_PAYMENT: esewaPayment.toMap(),
      };
}

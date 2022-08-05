import 'package:flutter/foundation.dart';

class EsewaPayment {
  final String productId;
  final String productName;
  final String productPrice;
  final String callbackUrl;
  final String? ebpNo;

  EsewaPayment({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.callbackUrl,
    this.ebpNo
  });
}

extension PaymentExt on EsewaPayment {
  Map<String, dynamic> toMap() => {
        "product_id": this.productId,
        "product_name": this.productName,
        "product_price": this.productPrice,
        "callback_url": this.callbackUrl,
        "ebp_no" : ebpNo
      };
}

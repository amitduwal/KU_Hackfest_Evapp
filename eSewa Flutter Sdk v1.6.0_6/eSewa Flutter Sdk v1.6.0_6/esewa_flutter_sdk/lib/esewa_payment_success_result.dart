import 'dart:convert';

import 'dart:io';

EsewaPaymentSuccessResult esewaPaymentResultFromJson(String str) =>
    EsewaPaymentSuccessResult.fromJson(json.decode(str));

String esewaPaymentResultToJson(EsewaPaymentSuccessResult data) =>
    json.encode(data.toJson());

class EsewaPaymentSuccessResult {
  EsewaPaymentSuccessResult({
    required this.productId,
    required this.productName,
    required this.totalAmount,
    required this.environment,
    required this.code,
    required this.merchantName,
    required this.message,
    required this.date,
    required this.status,
    required this.refId,
  });

  String productId;
  String productName;
  String totalAmount;
  String environment;
  String code;
  String merchantName;
  String message;
  String date;
  String status;
  String refId;

  factory EsewaPaymentSuccessResult.fromJson(Map<String, dynamic> json) =>
      EsewaPaymentSuccessResult(
        productId: json["productID"] ?? json["productId"],
        productName: json["productName"],
        totalAmount: json["totalAmount"],
        environment: json["environment"],
        code: json["code"],
        merchantName: json["merchantName"],
        message: json["message"],
        date: json["date"],
        status: json["status"],
        refId: json["referenceId"],
      );

  Map<String, dynamic> toJson() => {
        "productId": productId,
        "productName": productName,
        "totalAmount": totalAmount,
        "environment": environment,
        "code": code,
        "merchantName": merchantName,
        "message": message,
        "date": date,
        "status": status,
        "refId": refId,
      };

  @override
  String toString()=>'''
        "productId": $productId,
        "productName": $productName,
        "totalAmount": $totalAmount,
        "environment": $environment,
        "code": $code,
        "merchantName": $merchantName,
        "message": $message,
        "date": $date,
        "status": $status,
        "refId": $refId,
  ''';
}

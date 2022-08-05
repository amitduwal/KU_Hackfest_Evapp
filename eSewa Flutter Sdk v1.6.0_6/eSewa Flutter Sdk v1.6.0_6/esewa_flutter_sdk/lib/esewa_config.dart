import 'package:flutter/material.dart';

class EsewaConfig {
  final String clientId;
  final String secretId;
  final Environment environment;

  EsewaConfig({
    required this.clientId,
    required this.secretId,
    required this.environment,
  });

}

extension ConfigExt on EsewaConfig {
  Map<String, dynamic> toMap() => {
        "client_id": this.clientId,
        "client_secret": this.secretId,
        "environment": this.environment.parse(),
      };
}

enum Environment { test, live }

extension EnvExt on Environment {
  String parse() => this == Environment.live ? 'live' : 'test';
}

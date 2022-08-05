import 'package:flutter/material.dart';
import 'package:khalti_app/payment_page.dart';
import 'package:khalti_flutter/khalti_flutter.dart';

void main() => runApp(const Khalti());

class Khalti extends StatelessWidget {
  const Khalti({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KhaltiScope(
        publicKey: "test_public_key_d1483eb3d04c40bdaccc586006f2f7a7",
        builder: (context, navigatorKey) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('ne', 'NP'),
            ],
            localizationsDelegates: const [
              KhaltiLocalizations.delegate,
            ],
            theme: ThemeData(
                primaryColor: const Color(0xFF56328c),
                appBarTheme: const AppBarTheme(
                  color: Color(0xFF56328c),
                )),
            title: "Khalti",
            home: const PaymentPage(),
          );
        });
  }
}

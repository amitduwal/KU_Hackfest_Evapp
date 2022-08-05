import 'package:final_app/pages/home.dart';
import 'package:final_app/pages/info.dart';
import 'package:final_app/pages/loading.dart';
import 'package:final_app/screens/login_screen.dart';
import 'package:final_app/screens/screens.dart';
import 'package:flutter/material.dart';

//import 'package:ev_app/pages/info.dart';
// import 'package:final_app/pages/home.dart';
// import 'package:final_app/pages/loading.dart';
// import 'package:final_app/pages/info.dart';
// import 'package:final_app/screens/login_screen.dart';
// import 'package:final_app/screens/signup_screen.dart';

void main() => runApp(MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const Loading(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => Home(),
        '/info': (context) => Info(),
      },
    ));

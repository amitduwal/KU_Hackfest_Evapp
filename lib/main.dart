import 'package:flutter/material.dart';


//import 'package:ev_app/pages/info.dart';
import 'package:ev_app/pages/home.dart';
import 'package:ev_app/pages/loading.dart';
import 'package:ev_app/pages/info.dart';

void main() => runApp(MaterialApp(
  initialRoute: '/',
  routes: {
    '/':(context) =>const Loading(),
    '/home' : (context) => Home(),
    '/info': (context) => Info(),
  },
));
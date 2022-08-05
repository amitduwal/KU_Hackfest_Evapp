import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  GoogleMapController? mapController;

  String? searchAddr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition:  CameraPosition(
                  target: LatLng(27.700769, 85.300140),
                zoom: 10.0
            ),
            onMapCreated: onMapCreated,
            ),
            Positioned(
              top: 30.0,
              right: 15.0,
              left: 15.0,
              child: Container(
                height: 50.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color:Colors.white
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter Address',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: searchandNavigate,
                      iconSize: 30.0,
                    )
                  ),
                  onChanged: (val){
                    setState(() {
                      searchAddr = val;
                    });
                  },
                ),
              ),
            )
        ],
      ),
    );
  }

  searchandNavigate(){
    locationFromAddress(searchAddr!).then((result) {
      mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(result[0].latitude, result[0].longitude),
        zoom: 20,
      )));
    });
  }

  void onMapCreated(controller){
    setState(() {
      mapController = controller;
    });
  }
}

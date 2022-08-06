import 'dart:async';
import 'dart:typed_data';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:final_app/Maps/providers/search_places.dart';
import 'package:final_app/payment/khalti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' show cos, sqrt, asin;

import 'dart:ui' as ui;

import '../models/auto_complete_result.dart';
import '../services/map_services.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Completer<GoogleMapController> _controller = Completer();

//Debounce to throttle async calls during search
  Timer? _debounce;

//Toggling UI as we need;
  bool searchToggle = false;

  // bool radiusSlider = false;
  bool cardTapped = false;
  bool pressedNear = false;
  bool getDirections = false;

//Markers set
  Set<Marker> _markers = Set<Marker>();
  Set<Marker> _markersDupe = Set<Marker>();

  Set<Polyline> _polylines = Set<Polyline>();
  int markerIdCounter = 1;
  int polylineIdCounter = 1;

  var radiusValue = 3000.0;

  var tappedPoint;

  List allFavoritePlaces = [];

  String tokenKey = '';

  final key = 'AIzaSyDf5GmOWGjc3gBqOAqhVjH5VhU2CZPa-eI';

  var selectedPlaceDetails;

//Text Editing Controllers
  TextEditingController searchController = TextEditingController();
  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();

//Initial map position on load
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(27.7172, 85.3240),
    zoom: 14.4746,
  );

  void _setMarker(point) {
    var counter = markerIdCounter++;

    final Marker marker = Marker(
        markerId: MarkerId('marker_$counter'),
        position: point,
        onTap: () {},
        icon: BitmapDescriptor.defaultMarker);

    setState(() {
      _markers.add(marker);
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  void _setMarkerEv(point, String text) async {
    var counter = markerIdCounter++;
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/mapicons/automotive.png', 75);

    final Marker marker = Marker(
        markerId: MarkerId('markerev_$counter'),
        position: point,
        onTap: () => {
              getUserCurrentLocation().then((value) async {
                _setMarker(LatLng(value.latitude, value.longitude));

                // double calculateDistance(value.latitude, value.longitude, point.latitude, point.longitude){
                var p = 0.017453292519943295;
                var c = cos;
                var a = 0.5 -
                    c((point.latitude - value.latitude) * p) / 2 +
                    c(value.latitude * p) *
                        c(point.latitude * p) *
                        (1 - c((point.longitude - value.longitude) * p)) /
                        2;
                double totalDistance = 12742 * asin(sqrt(a));
                print("-----------------------------");
                print(totalDistance);
                print("------------------------------");
                // }

                // double totalDistance = 0;
                // for(var i = 0; i < data.length-1; i++){
                //   totalDistance += calculateDistance(data[i]["lat"], data[i]["lng"], data[i+1]["lat"], data[i+1]["lng"]);
                // }
                // print(totalDistance);

                List<Placemark> user_placemarks =
                    await placemarkFromCoordinates(
                        value.latitude, value.longitude);
                List<Placemark> selected_placemarks =
                    await placemarkFromCoordinates(
                        point.latitude, point.longitude);

                var directions = await MapServices().getDirections(
                    user_placemarks.first.toString(),
                    selected_placemarks.first.toString());
                _markers = {};
                _polylines = {};
                gotoPlace(
                    directions['start_location']['lat'],
                    directions['start_location']['lng'],
                    directions['end_location']['lat'],
                    directions['end_location']['lng'],
                    directions['bounds_ne'],
                    directions['bounds_sw']);
                _setPolyline(directions['polyline_decoded']);

                showAlertDialog(context, text, totalDistance);
                loadMarkerEv();
              }),
            },
        infoWindow: InfoWindow(title: text),
        icon: BitmapDescriptor.fromBytes(markerIcon));

    setState(() {
      _markers.add(marker);
    });
  }

  loadMarkerEv() {
    _setMarkerEv(LatLng(27.7172, 85.3240), 'Kathmandu Ev Station');
    _setMarkerEv(
        LatLng(27.68459852890479, 85.41120564749042), 'KMC EV station');
    _setMarkerEv(LatLng(27.68656625538563, 85.33866987195383),
        'Civil Service EV station');
    _setMarkerEv(
        LatLng(26.679091070440393, 87.6867315522346), 'New Amda EV station');
    _setMarkerEv(LatLng(26.576475130500278, 88.07778683051427),
        'Chandragiri EV station');
    _setMarkerEv(
        LatLng(26.57499655512588, 87.8302896869024), 'Pathivara EV station');
    _setMarkerEv(
        LatLng(26.491221894767232, 87.26459476011038), 'Biratnagar EV station');
    _setMarkerEv(
        LatLng(26.680029761745857, 87.2356711873441), 'Itahari EV station');
    _setMarkerEv(
        LatLng(27.046464795619425, 84.90042375193129), 'Birgunj EV station');
    _setMarkerEv(
        LatLng(27.163705338305512, 84.97952866274093), 'Simara EV station');
    _setMarkerEv(LatLng(27.16805704267558, 85.35731328974694),
        'Chandranigahapur EV station');
    _setMarkerEv(
        LatLng(26.9508791376429, 85.80012870516057), 'Dhalkebar EV station');
    _setMarkerEv(
        LatLng(26.727328651509946, 85.94059939552218), 'Janakpur EV station');
    _setMarkerEv(
        LatLng(26.99095524026789, 85.89382463795106), 'Bardibas  EV station');
    _setMarkerEv(
        LatLng(26.510844742581412, 86.73792836446434), 'Rajbiraj EV station');
    _setMarkerEv(LatLng(27.80970731264833, 84.8330241586965),
        'Malekhu Bazar EV station');
    _setMarkerEv(
        LatLng(27.800341730468094, 84.87290522768122), 'Dhading EV station');
    _setMarkerEv(LatLng(27.280737479801832, 85.95503839738389),
        'Sindhuli Gadhi EV staion');
    _setMarkerEv(LatLng(27.267396539222965, 85.9501353197192),
        'Selfie Danda EV station');
    _setMarkerEv(LatLng(27.442248069766745, 84.9990221635553),
        'Hetauda Park EV station');
    _setMarkerEv(
        LatLng(27.466801778887962, 84.91729719293386), 'Tapoban EV station');
    _setMarkerEv(
        LatLng(27.678442970573236, 84.43086771539187), 'Bharatpur EV station');
    _setMarkerEv(LatLng(27.686091103349753, 84.42996649319537),
        'Chitwan Medical College EV station');
    _setMarkerEv(
        LatLng(27.767280637327623, 84.4697639108882), 'Muglin EV station');
    _setMarkerEv(
        LatLng(27.76092938063862, 84.47507468475278), 'Pathivara EV station');
    _setMarkerEv(
        LatLng(27.877909887316335, 84.62122931089075), 'Kurintar EV station');
    _setMarkerEv(
        LatLng(27.872323837250203, 84.60081233598251), 'Manakamana EV station');
    _setMarkerEv(
        LatLng(27.62983788196194, 85.52509728587273), 'Banepa EV station');
    _setMarkerEv(
        LatLng(27.6884687462591, 85.33402919609276), 'Nawalpur EV station');
    _setMarkerEv(
        LatLng(27.97647398709559, 84.26769592286155), 'Damauli EV station');
    _setMarkerEv(
        LatLng(28.099805586494945, 83.871481900019), 'Syangja EV station');
    _setMarkerEv(LatLng(28.19958844610147, 83.97830010904902),
        'Pokhara Airport EV station');
    _setMarkerEv(LatLng(28.210177826416693, 83.95571135322726),
        'Pokhara Lakeside EV station');
    _setMarkerEv(
        LatLng(28.23801787463195, 83.98417831089921), 'Bindabasini EV station');
    _setMarkerEv(
        LatLng(28.101179195379782, 81.66737268390958), 'Nepalgunj EV station');
    _setMarkerEv(
        LatLng(27.842128785741902, 82.76582462823465), 'Bhalubang EV station');
    _setMarkerEv(
        LatLng(28.034308636052618, 82.48604478755949), 'Dang EV station');
    _setMarkerEv(
        LatLng(27.513738375195498, 83.45152909164501), 'Rupandehi EV station');
    _setMarkerEv(
        LatLng(27.552341336382344, 83.79820806855443), 'Bardaghat EV station');
    _setMarkerEv(
        LatLng(27.58172136875496, 83.64733279923995), 'Sunawala EV station');
    _setMarkerEv(
        LatLng(28.581117281051363, 81.63198733139176), 'Surkhet EV station');
    _setMarkerEv(LatLng(28.961240687373536, 80.14780479742312),
        'Mahendranagar EV station');
    _setMarkerEv(
        LatLng(28.752933230343572, 80.58324459926736), 'Dhangadhi EV station');
    _setMarkerEv(
        LatLng(29.297330285530542, 80.5905532844028), 'Dadeldhura EV station');
  }

  Future<Position> getUserCurrentLocation() async {
    await Geolocator.requestPermission()
        .then((value) {})
        .onError((error, stackTrace) {
      print("error" + error.toString());
    });

    return await Geolocator.getCurrentPosition();
  }

  void _setPolyline(List<PointLatLng> points) {
    final String polylineIdVal = 'polyline_$polylineIdCounter';

    polylineIdCounter++;

    _polylines.add(Polyline(
        polylineId: PolylineId(polylineIdVal),
        width: 2,
        color: Colors.blue,
        points: points.map((e) => LatLng(e.latitude, e.longitude)).toList()));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadMarkerEv();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    //Providers
    final allSearchResults = ref.watch(placeResultsProvider);
    final searchFlag = ref.watch(searchToggleProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: screenHeight,
                  width: screenWidth,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    markers: _markers,
                    polylines: _polylines,
                    initialCameraPosition: _kGooglePlex,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                ),
                searchToggle
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(15.0, 40.0, 15.0, 5.0),
                        child: Column(children: [
                          Container(
                            height: 50.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                            ),
                            child: TextFormField(
                              controller: searchController,
                              decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 15.0),
                                  border: InputBorder.none,
                                  hintText: 'Search',
                                  suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          searchToggle = false;

                                          searchController.text = '';
                                          _markers = {};
                                          if (searchFlag.searchToggle)
                                            searchFlag.toggleSearch();
                              
                                        });
                                      },
                                      icon: Icon(Icons.close))),
                              onChanged: (value) {
                                if (_debounce?.isActive ?? false)
                                  _debounce?.cancel();
                                _debounce = Timer(Duration(milliseconds: 700),
                                    () async {
                                  if (value.length > 2) {
                                    if (!searchFlag.searchToggle) {
                                      searchFlag.toggleSearch();
                                      _markers = {};
                                    }

                                    List<AutoCompleteResult> searchResults =
                                        await MapServices().searchPlaces(value);

                                    allSearchResults.setResults(searchResults);
                                  } else {
                                    List<AutoCompleteResult> emptyList = [];
                                    allSearchResults.setResults(emptyList);
                                  }
                                });
                                loadMarkerEv();
                              },
                            ),
                          )
                        ]),
                      )
                    : Container(),
                searchFlag.searchToggle
                    ? allSearchResults.allReturnedResults.length != 0
                        ? Positioned(
                            top: 100.0,
                            left: 15.0,
                            child: Container(
                              height: 200.0,
                              width: screenWidth - 30.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white.withOpacity(0.7),
                              ),
                              child: ListView(
                                children: [
                                  ...allSearchResults.allReturnedResults
                                      .map((e) => buildListItem(e, searchFlag))
                                ],
                              ),
                            ))
                        : Positioned(
                            top: 100.0,
                            left: 15.0,
                            child: Container(
                              height: 200.0,
                              width: screenWidth - 30.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Colors.white.withOpacity(0.7),
                              ),
                              child: Center(
                                child: Column(children: [
                                  Text('No results to show',
                                      style: TextStyle(
                                          fontFamily: 'WorkSans',
                                          fontWeight: FontWeight.w400)),
                                  SizedBox(height: 5.0),
                                  Container(
                                    width: 125.0,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        searchFlag.toggleSearch();
                                      },
                                      child: Center(
                                        child: Text(
                                          'Close this',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'WorkSans',
                                              fontWeight: FontWeight.w300),
                                        ),
                                      ),
                                    ),
                                  )
                                ]),
                              ),
                            ))
                    : Container(),
                getDirections
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(15.0, 40.0, 15.0, 5),
                        child: Column(children: [
                          Container(
                            height: 50.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                            ),
                            child: TextFormField(
                              controller: _originController,
                              decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 15.0),
                                  border: InputBorder.none,
                                  hintText: 'Origin',
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.my_location_outlined),
                                    onPressed: () {
                                      getUserCurrentLocation()
                                          .then((value) async {
                                        print('my current location');
                                        print(value.latitude.toString() +
                                            " " +
                                            value.longitude.toString());

                                        _setMarker(LatLng(
                                            value.latitude, value.longitude));

                                        CameraPosition cameraPosition =
                                            CameraPosition(
                                                zoom: 14,
                                                target: LatLng(value.latitude,
                                                    value.longitude));

                                        final GoogleMapController controller =
                                            await _controller.future;

                                        controller.animateCamera(
                                            CameraUpdate.newCameraPosition(
                                                cameraPosition));
                                        setState(() {});
                                      });
                                    },
                                    iconSize: 30.0,
                                  )),
                            ),
                          ),
                          SizedBox(height: 3.0),
                          Container(
                            height: 50.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                            ),
                            child: TextFormField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 15.0),
                                  border: InputBorder.none,
                                  hintText: 'Destination',
                                  suffixIcon: Container(
                                      width: 96.0,
                                      child: Row(
                                        children: [
                                          IconButton(
                                              onPressed: () async {
                                                var directions =
                                                    await MapServices()
                                                        .getDirections(
                                                            _originController
                                                                .text,
                                                            _destinationController
                                                                .text);
                                                _markers = {};
                                                _polylines = {};
                                                gotoPlace(
                                                    directions['start_location']
                                                        ['lat'],
                                                    directions['start_location']
                                                        ['lng'],
                                                    directions['end_location']
                                                        ['lat'],
                                                    directions['end_location']
                                                        ['lng'],
                                                    directions['bounds_ne'],
                                                    directions['bounds_sw']);
                                                _setPolyline(directions[
                                                    'polyline_decoded']);
                                              },
                                              icon: Icon(Icons.search)),
                                          IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  getDirections = false;
                                                  _originController.text = '';
                                                  _destinationController.text =
                                                      '';
                                                  _markers = {};
                                                  _polylines = {};
                                                });
                                              },
                                              icon: Icon(Icons.close))
                                        ],
                                      ))),
                            ),
                          )
                        ]),
                      )
                    : Container(),
              ],
            )
          ],
        ),
      ),
      floatingActionButton: FabCircularMenu(
          alignment: Alignment.bottomLeft,
          fabColor: Colors.blue.shade50,
          fabOpenColor: Colors.red.shade100,
          ringDiameter: 250.0,
          ringWidth: 60.0,
          ringColor: Colors.blue.shade50,
          fabSize: 60.0,
          children: [
            IconButton(
                onPressed: () {
                  setState(() {
                    searchToggle = true;
                    // radiusSlider = false;
                    pressedNear = false;
                    cardTapped = false;
                    getDirections = false;
                  });
                },
                icon: Icon(Icons.search)),
            IconButton(
                onPressed: () {
                  setState(() {
                    searchToggle = false;
                    // radiusSlider = false;
                    pressedNear = false;
                    cardTapped = false;
                    getDirections = true;
                  });
                },
                icon: Icon(Icons.navigation)),
            IconButton(
              onPressed: () {
                getUserCurrentLocation().then((value) async {
                  print('my current location');
                  print(value.latitude.toString() +
                      " " +
                      value.longitude.toString());

                  _setMarker(LatLng(value.latitude, value.longitude));

                  CameraPosition cameraPosition = CameraPosition(
                      zoom: 14,
                      target: LatLng(value.latitude, value.longitude));

                  final GoogleMapController controller =
                      await _controller.future;

                  controller.animateCamera(
                      CameraUpdate.newCameraPosition(cameraPosition));
                  setState(() {});
                });
              },
              icon: Icon(Icons.my_location_outlined),
            ),
            IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                icon: Icon(Icons.refresh_outlined)),
            IconButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                icon: Icon(Icons.logout))
          ]),
    );
  }

  _buildReviewItem(review) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          child: Row(
            children: [
              Container(
                height: 35.0,
                width: 35.0,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                        image: NetworkImage(review['profile_photo_url']),
                        fit: BoxFit.cover)),
              ),
              SizedBox(width: 4.0),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 160.0,
                  child: Text(
                    review['author_name'],
                    style: TextStyle(
                        fontFamily: 'WorkSans',
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: 3.0),
                RatingStars(
                  value: review['rating'] * 1.0,
                  starCount: 5,
                  starSize: 7,
                  valueLabelColor: const Color(0xff9b9b9b),
                  valueLabelTextStyle: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                      fontSize: 9.0),
                  valueLabelRadius: 7,
                  maxValue: 5,
                  starSpacing: 2,
                  maxValueVisibility: false,
                  valueLabelVisibility: true,
                  animationDuration: Duration(milliseconds: 1000),
                  valueLabelPadding:
                      const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                  valueLabelMargin: const EdgeInsets.only(right: 4),
                  starOffColor: const Color(0xffe7e8ea),
                  starColor: Colors.yellow,
                )
              ])
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Container(
            child: Text(
              review['text'],
              style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 11.0,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
        Divider(color: Colors.grey.shade600, height: 1.0)
      ],
    );
  }

  gotoPlace(double lat, double lng, double endLat, double endLng,
      Map<String, dynamic> boundsNe, Map<String, dynamic> boundsSw) async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng'])),
        25));

    _setMarker(LatLng(lat, lng));
    _setMarker(LatLng(endLat, endLng));
  }

  Future<void> gotoSearchedPlace(double lat, double lng) async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 12)));

    _setMarker(LatLng(lat, lng));
  }

  Widget buildListItem(AutoCompleteResult placeItem, searchFlag) {
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: GestureDetector(
        onTapDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onTap: () async {
          var place = await MapServices().getPlace(placeItem.placeId);
          gotoSearchedPlace(place['geometry']['location']['lat'],
              place['geometry']['location']['lng']);
          searchFlag.toggleSearch();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: Colors.green, size: 25.0),
            SizedBox(width: 4.0),
            Container(
              height: 40.0,
              width: MediaQuery.of(context).size.width - 75.0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(placeItem.description ?? ''),
              ),
            )
          ],
        ),
      ),
    );
  }
}

showAlertDialog(BuildContext context, String name, double totalDistance) {
  Widget okButton = FlatButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  // Create AlertDialog
  Size size = MediaQuery.of(context).size;
  Container alert = Container(
    // title: Text("Simple Alert"),
    // content: Text("This is an alert message."),

    padding: EdgeInsets.all(10.0),
    margin: EdgeInsets.fromLTRB(20, size.height / 2, 20, 10),
    height: 100,
    alignment: Alignment.center,
    color: Colors.white,
    child: Column(
      children: [
        Icon(
          Icons.electric_car,
          size: 80,
          color: Colors.blueGrey,
        ),
        SizedBox(height: 20),
        Text(
          name,
          style: TextStyle(
              fontSize: 18,
              decoration: TextDecoration.none,
              color: Colors.black),
        ),
        SizedBox(
          height: 20,
        ),
        GestureDetector(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(children: [
                Icon(
                  Icons.charging_station,
                  color: Colors.greenAccent,
                ),
                SizedBox(
                  height: 10,
                ),
                Text('slots: 2',
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0))
              ]),
              SizedBox(
                width: 20,
              ),
              Column(children: [
                Icon(
                  Icons.currency_rupee,
                  color: Colors.greenAccent,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  '8/unit',
                  style: TextStyle(
                      decoration: TextDecoration.none,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0),
                )
              ]),
              SizedBox(
                width: 20,
              ),
              Column(children: [
                Icon(
                  Icons.location_pin,
                  color: Colors.greenAccent,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(totalDistance.toStringAsFixed(2) + " km",
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0))
              ]),
              SizedBox(
                width: 20,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 30,
        ),
        Material(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.circular(50),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Khalti()),
              );
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 290,
              height: 50,
              alignment: Alignment.center,
              child: const Text(
                'BOOK',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
        // actions: [
        //   okButton,
        // ],
      ],
    ),
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

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

  //Page controller for the nice pageview
  late PageController _pageController;
  int prevPage = 0;
  var tappedPlaceDetail;
  String placeImg = '';
  var photoGalleryIndex = 0;
  bool showBlankCard = false;
  bool isReviews = true;
  bool isPhotos = false;

  final key = 'AIzaSyDf5GmOWGjc3gBqOAqhVjH5VhU2CZPa-eI';

  var selectedPlaceDetails;

//Circle
//   Set<Circle> _circles = Set<Circle>();

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
        await getBytesFromAsset('assets/mapicons/automotive.png', 100);

    final Marker marker = Marker(
        markerId: MarkerId('markerev_$counter'),
        position: point,
        onTap: () => {showAlertDialog(context, text)},
        infoWindow: InfoWindow(title: text),
        icon: BitmapDescriptor.fromBytes(markerIcon));

    setState(() {
      _markers.add(marker);
    });
  }

  Widget _buildPopupDialog(BuildContext context) => Container(
        padding: EdgeInsets.all(0.0),
        margin: EdgeInsets.all(20.0),
        clipBehavior: Clip.hardEdge,
        height: 300,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50.0), color: Colors.white),
        child: Column(children: [
          Image.asset(
            'assets/images/electric-car.png',
            scale: 5,
            alignment: Alignment.topCenter,
          ),
          Text(
            'Kathmandu EV station',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(children: [
                Icon(
                  Icons.charging_station,
                  color: Colors.blueGrey,
                ),
                SizedBox(
                  height: 10,
                ),
                Text('2',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold))
              ]),
              SizedBox(
                width: 60,
              ),
              Column(children: [
                Icon(
                  Icons.currency_rupee,
                  color: Colors.blueGrey,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  '200',
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold),
                )
              ]),
              SizedBox(
                width: 60,
              ),
              Column(children: [
                Icon(
                  Icons.location_pin,
                  color: Colors.blueGrey,
                ),
                SizedBox(
                  height: 10,
                ),
                Text('200 km',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold))
              ]),
              SizedBox(
                width: 20,
              ),
            ],
          ),
          SizedBox(
            height: 30,
          ),
          Material(
            color: Colors.greenAccent,
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
              onTap: () {},
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
        ]),
      );

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

  // void _setCircle(LatLng point) async {
  //   final GoogleMapController controller = await _controller.future;
  //
  //   controller.animateCamera(CameraUpdate.newCameraPosition(
  //       CameraPosition(target: point, zoom: 12)));
  //   setState(() {
  //     _circles.add(Circle(
  //         circleId: CircleId('raj'),
  //         center: point,
  //         fillColor: Colors.blue.withOpacity(0.1),
  //         radius: radiusValue,
  //         strokeColor: Colors.blue,
  //         strokeWidth: 1));
  //     getDirections = false;
  //     searchToggle = false;
  //     radiusSlider = true;
  //   });
  // }

  // _setNearMarker(LatLng point, String label, List types, String status) async {
  //   var counter = markerIdCounter++;
  //
  //   final Uint8List markerIcon;
  //
  //   if (types.contains('automotive'))
  //     markerIcon = await getBytesFromAsset('assets/mapicons/automotive.png', 75);
  //
  //   final Marker marker = Marker(
  //       markerId: MarkerId('marker_$counter'),
  //       position: point,
  //       onTap: () {},
  //       icon: BitmapDescriptor.fromBytes(markerIcon));
  //
  //   setState(() {
  //     _markers.add(marker);
  //   });
  // }

  // Future<Uint8List> getBytesFromAsset(String path, int width) async {
  //   ByteData data = await rootBundle.load(path);
  //
  //   ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
  //       targetWidth: width);
  //   ui.FrameInfo fi = await codec.getNextFrame();
  //   return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
  //       .buffer
  //       .asUint8List();
  // }

  @override
  void initState() {
    // TODO: implement initState
    _pageController = PageController(initialPage: 1, viewportFraction: 0.85)
      ..addListener(_onScroll);
    super.initState();
    loadMarkerEv();
  }

  void _onScroll() {
    if (_pageController.page!.toInt() != prevPage) {
      prevPage = _pageController.page!.toInt();
      cardTapped = false;
      photoGalleryIndex = 1;
      showBlankCard = false;
      // goToTappedPlace();
      fetchImage();
    }
  }

  //Fetch image to place inside the tile in the pageView
  void fetchImage() async {
    if (_pageController.page !=
        null) if (allFavoritePlaces[_pageController.page!.toInt()]
            ['photos'] !=
        null) {
      setState(() {
        placeImg = allFavoritePlaces[_pageController.page!.toInt()]['photos'][0]
            ['photo_reference'];
      });
    } else {
      placeImg = '';
    }
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
                    // circles: _circles,
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
                                  hintText: 'Origin'),
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
                // radiusSlider
                //     ? Padding(
                //   padding: EdgeInsets.fromLTRB(15.0, 30.0, 15.0, 0.0),
                //   child: Container(
                //     height: 50.0,
                //     color: Colors.black.withOpacity(0.2),
                //     child: Row(
                //       children: [
                //         Expanded(
                //             child: Slider(
                //                 max: 7000.0,
                //                 min: 1000.0,
                //                 value: radiusValue,
                //                 onChanged: (newVal) {
                //                   radiusValue = newVal;
                //                   pressedNear = false;
                //                   _setCircle(tappedPoint);
                //                 })),
                //         !pressedNear
                //             ? IconButton(
                //             onPressed: () {
                //               if (_debounce?.isActive ?? false)
                //                 _debounce?.cancel();
                //               _debounce = Timer(Duration(seconds: 2),
                //                       () async {
                //                     var placesResult = await MapServices()
                //                         .getPlaceDetails(tappedPoint,
                //                         radiusValue.toInt());
                //
                //                     List<dynamic> placesWithin =
                //                     placesResult['results'] as List;
                //
                //                     allFavoritePlaces = placesWithin;
                //
                //                     tokenKey =
                //                         placesResult['next_page_token'] ??
                //                             'none';
                //                     _markers = {};
                //                     placesWithin.forEach((element) {
                //                       print('element ko output yaha xa hai: ');
                //                       print(element);
                //                       _setNearMarker(
                //                         LatLng(
                //                             element['geometry']
                //                             ['location']['lat'],
                //                             element['geometry']
                //                             ['location']['lng']),
                //                         element['name'],
                //                         element['types'],
                //                         element['business_status'] ??
                //                             'not available',
                //                       );
                //                     });
                //                     _markersDupe = _markers;
                //                     pressedNear = true;
                //                   });
                //             },
                //             icon: Icon(
                //               Icons.near_me,
                //               color: Colors.blue,
                //             ))
                //             : IconButton(
                //             onPressed: () {
                //               if (_debounce?.isActive ?? false)
                //                 _debounce?.cancel();
                //               _debounce = Timer(Duration(seconds: 2),
                //                       () async {
                //                     if (tokenKey != 'none') {
                //                       var placesResult =
                //                       await MapServices()
                //                           .getMorePlaceDetails(
                //                           tokenKey);

                //     List<dynamic> placesWithin =
                //     placesResult['results'] as List;
                //
                //     allFavoritePlaces
                //         .addAll(placesWithin);
                //
                //     tokenKey = placesResult[
                //     'next_page_token'] ??
                //         'none';
                //
                //     placesWithin.forEach((element) {
                //       _setNearMarker(
                //         LatLng(
                //             element['geometry']
                //             ['location']['lat'],
                //             element['geometry']
                //             ['location']['lng']),
                //         element['name'],
                //         element['types'],
                //         element['business_status'] ??
                //             'not available',
                //       );
                //     });
                //   } else {
                //     print('Thats all folks!!');
                //   }
                // });
                //             },
                //             icon: Icon(Icons.more_time,
                //                 color: Colors.blue)),
                //         IconButton(
                //             onPressed: () {
                //               setState(() {
                //                 radiusSlider = false;
                //                 pressedNear = false;
                //                 cardTapped = false;
                //                 radiusValue = 3000.0;
                //                 _circles = {};
                //                 _markers = {};
                //                 allFavoritePlaces = [];
                //               });
                //             },
                //             icon: Icon(Icons.close, color: Colors.red))
                //       ],
                //     ),
                //   ),
                // )
                //     : Container(),
                pressedNear
                    ? Positioned(
                        bottom: 20.0,
                        child: Container(
                          height: 200.0,
                          width: MediaQuery.of(context).size.width,
                          child: PageView.builder(
                              controller: _pageController,
                              itemCount: allFavoritePlaces.length,
                              itemBuilder: (BuildContext context, int index) {
                                return _nearbyPlacesList(index);
                              }),
                        ))
                    : Container(),
                cardTapped
                    ? Positioned(
                        top: 100.0,
                        left: 15.0,
                        child: FlipCard(
                          front: Container(
                            height: 250.0,
                            width: 175.0,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0))),
                            child: SingleChildScrollView(
                              child: Column(children: [
                                Container(
                                  height: 150.0,
                                  width: 175.0,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8.0),
                                        topRight: Radius.circular(8.0),
                                      ),
                                      image: DecorationImage(
                                          image: NetworkImage(placeImg != ''
                                              ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$placeImg&key=$key'
                                              : 'https://pic.onlinewebfonts.com/svg/img_546302.png'),
                                          fit: BoxFit.cover)),
                                ),
                                Container(
                                  padding: EdgeInsets.all(7.0),
                                  width: 175.0,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Address: ',
                                        style: TextStyle(
                                            fontFamily: 'WorkSans',
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Container(
                                          width: 105.0,
                                          child: Text(
                                            tappedPlaceDetail[
                                                    'formatted_address'] ??
                                                'none given',
                                            style: TextStyle(
                                                fontFamily: 'WorkSans',
                                                fontSize: 11.0,
                                                fontWeight: FontWeight.w400),
                                          ))
                                    ],
                                  ),
                                ),
                                Container(
                                  padding:
                                      EdgeInsets.fromLTRB(7.0, 0.0, 7.0, 0.0),
                                  width: 175.0,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Contact: ',
                                        style: TextStyle(
                                            fontFamily: 'WorkSans',
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Container(
                                          width: 105.0,
                                          child: Text(
                                            tappedPlaceDetail[
                                                    'formatted_phone_number'] ??
                                                'none given',
                                            style: TextStyle(
                                                fontFamily: 'WorkSans',
                                                fontSize: 11.0,
                                                fontWeight: FontWeight.w400),
                                          ))
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          back: Container(
                            height: 300.0,
                            width: 225.0,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(8.0)),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isReviews = true;
                                            isPhotos = false;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: Duration(milliseconds: 700),
                                          curve: Curves.easeIn,
                                          padding: EdgeInsets.fromLTRB(
                                              7.0, 4.0, 7.0, 4.0),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(11.0),
                                              color: isReviews
                                                  ? Colors.green.shade300
                                                  : Colors.white),
                                          child: Text(
                                            'Reviews',
                                            style: TextStyle(
                                                color: isReviews
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontFamily: 'WorkSans',
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isReviews = false;
                                            isPhotos = true;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: Duration(milliseconds: 700),
                                          curve: Curves.easeIn,
                                          padding: EdgeInsets.fromLTRB(
                                              7.0, 4.0, 7.0, 4.0),
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(11.0),
                                              color: isPhotos
                                                  ? Colors.green.shade300
                                                  : Colors.white),
                                          child: Text(
                                            'Photos',
                                            style: TextStyle(
                                                color: isPhotos
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontFamily: 'WorkSans',
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 250.0,
                                  child: isReviews
                                      ? ListView(
                                          children: [
                                            if (isReviews &&
                                                tappedPlaceDetail['reviews'] !=
                                                    null)
                                              ...tappedPlaceDetail['reviews']!
                                                  .map((e) {
                                                return _buildReviewItem(e);
                                              })
                                          ],
                                        )
                                      : _buildPhotoGallery(
                                          tappedPlaceDetail['photos'] ?? []),
                                )
                              ],
                            ),
                          ),
                        ))
                    : Container()
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
                  // showDialog(
                  //     context: context,
                  //     builder: (context) => Center(
                  //           child: CircularProgressIndicator(),
                  //         ));
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

  _buildPhotoGallery(photoElement) {
    if (photoElement == null || photoElement.length == 0) {
      showBlankCard = true;
      return Container(
        child: Center(
          child: Text(
            'No Photos',
            style: TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 12.0,
                fontWeight: FontWeight.w500),
          ),
        ),
      );
    } else {
      var placeImg = photoElement[photoGalleryIndex]['photo_reference'];
      var maxWidth = photoElement[photoGalleryIndex]['width'];
      var maxHeight = photoElement[photoGalleryIndex]['height'];
      var tempDisplayIndex = photoGalleryIndex + 1;

      return Column(
        children: [
          SizedBox(height: 10.0),
          Container(
              height: 200.0,
              width: 200.0,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                      image: NetworkImage(
                          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&maxheight=$maxHeight&photo_reference=$placeImg&key=$key'),
                      fit: BoxFit.cover))),
          SizedBox(height: 10.0),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  if (photoGalleryIndex != 0)
                    photoGalleryIndex = photoGalleryIndex - 1;
                  else
                    photoGalleryIndex = 0;
                });
              },
              child: Container(
                width: 40.0,
                height: 20.0,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9.0),
                    color: photoGalleryIndex != 0
                        ? Colors.green.shade500
                        : Colors.grey.shade500),
                child: Center(
                  child: Text(
                    'Prev',
                    style: TextStyle(
                        fontFamily: 'WorkSans',
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            Text(
              '$tempDisplayIndex/' + photoElement.length.toString(),
              style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (photoGalleryIndex != photoElement.length - 1)
                    photoGalleryIndex = photoGalleryIndex + 1;
                  else
                    photoGalleryIndex = photoElement.length - 1;
                });
              },
              child: Container(
                width: 40.0,
                height: 20.0,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9.0),
                    color: photoGalleryIndex != photoElement.length - 1
                        ? Colors.green.shade500
                        : Colors.grey.shade500),
                child: Center(
                  child: Text(
                    'Next',
                    style: TextStyle(
                        fontFamily: 'WorkSans',
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ])
        ],
      );
    }
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

  Future<void> moveCameraSlightly() async {
    final GoogleMapController controller = await _controller.future;

    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(
            allFavoritePlaces[_pageController.page!.toInt()]['geometry']
                    ['location']['lat'] +
                0.0125,
            allFavoritePlaces[_pageController.page!.toInt()]['geometry']
                    ['location']['lng'] +
                0.005),
        zoom: 14.0,
        bearing: 45.0,
        tilt: 45.0)));
  }

  _nearbyPlacesList(index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (BuildContext context, Widget? widget) {
        double value = 1;
        if (_pageController.position.haveDimensions) {
          value = (_pageController.page! - index);
          value = (1 - (value.abs() * 0.3) + 0.06).clamp(0.0, 1.0);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 125.0,
            width: Curves.easeInOut.transform(value) * 350.0,
            child: widget,
          ),
        );
      },
      child: InkWell(
        onTap: () async {
          cardTapped = !cardTapped;
          if (cardTapped) {
            tappedPlaceDetail = await MapServices()
                .getPlace(allFavoritePlaces[index]['place_id']);
            setState(() {});
          }
          moveCameraSlightly();
        },
        child: Stack(
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 20.0,
                ),
                height: 125.0,
                width: 275.0,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0.0, 4.0),
                          blurRadius: 10.0)
                    ]),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.white),
                  child: Row(
                    children: [
                      _pageController.position.haveDimensions
                          ? _pageController.page!.toInt() == index
                              ? Container(
                                  height: 90.0,
                                  width: 90.0,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10.0),
                                        topLeft: Radius.circular(10.0),
                                      ),
                                      image: DecorationImage(
                                          image: NetworkImage(placeImg != ''
                                              ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$placeImg&key=$key'
                                              : 'https://pic.onlinewebfonts.com/svg/img_546302.png'),
                                          fit: BoxFit.cover)),
                                )
                              : Container(
                                  height: 90.0,
                                  width: 20.0,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(10.0),
                                        topLeft: Radius.circular(10.0),
                                      ),
                                      color: Colors.blue),
                                )
                          : Container(),
                      SizedBox(width: 5.0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 170.0,
                            child: Text(allFavoritePlaces[index]['name'],
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontFamily: 'WorkSans',
                                    fontWeight: FontWeight.bold)),
                          ),
                          RatingStars(
                            value: allFavoritePlaces[index]['rating']
                                        .runtimeType ==
                                    int
                                ? allFavoritePlaces[index]['rating'] * 1.0
                                : allFavoritePlaces[index]['rating'] ?? 0.0,
                            starCount: 5,
                            starSize: 10,
                            valueLabelColor: const Color(0xff9b9b9b),
                            valueLabelTextStyle: TextStyle(
                                color: Colors.white,
                                fontFamily: 'WorkSans',
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                fontSize: 12.0),
                            valueLabelRadius: 10,
                            maxValue: 5,
                            starSpacing: 2,
                            maxValueVisibility: false,
                            valueLabelVisibility: true,
                            animationDuration: Duration(milliseconds: 1000),
                            valueLabelPadding: const EdgeInsets.symmetric(
                                vertical: 1, horizontal: 8),
                            valueLabelMargin: const EdgeInsets.only(right: 8),
                            starOffColor: const Color(0xffe7e8ea),
                            starColor: Colors.yellow,
                          ),
                          Container(
                            width: 170.0,
                            child: Text(
                              allFavoritePlaces[index]['business_status'] ??
                                  'none',
                              style: TextStyle(
                                  color: allFavoritePlaces[index]
                                              ['business_status'] ==
                                          'OPERATIONAL'
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Future<void> goToTappedPlace() async {
  //   final GoogleMapController controller = await _controller.future;
  //
  //   _markers = {};
  //
  //   var selectedPlace = allFavoritePlaces[_pageController.page!.toInt()];
  //
  //   _setNearMarker(
  //       LatLng(selectedPlace['geometry']['location']['lat'],
  //           selectedPlace['geometry']['location']['lng']),
  //       selectedPlace['name'] ?? 'no name',
  //       selectedPlace['types'],
  //       selectedPlace['business_status'] ?? 'none');
  //
  //   controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
  //       target: LatLng(selectedPlace['geometry']['location']['lat'],
  //           selectedPlace['geometry']['location']['lng']),
  //       zoom: 14.0,
  //       bearing: 45.0,
  //       tilt: 45.0)));
  // }

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

  showAlertDialog(BuildContext context, String name) {
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
                  Text('2',
                      style: TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0))
                ]),
                SizedBox(
                  width: 50,
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
                    '200',
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0),
                  )
                ]),
                SizedBox(
                  width: 40,
                ),
                Column(children: [
                  Icon(
                    Icons.location_pin,
                    color: Colors.greenAccent,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text('200 km',
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

    Widget _buildPopupDialog(BuildContext context) => Container(
          padding: EdgeInsets.all(0.0),
          margin: EdgeInsets.all(20.0),
          clipBehavior: Clip.hardEdge,
          height: 300,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0), color: Colors.white),
          child: Column(children: [
            Image.asset(
              'assets/images/electric-car.png',
              scale: 5,
              alignment: Alignment.topCenter,
            ),
            Text(
              'Kathmandu EV station',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [
                  Icon(
                    Icons.charging_station,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text('2',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold))
                ]),
                SizedBox(
                  width: 60,
                ),
                Column(children: [
                  Icon(
                    Icons.currency_rupee,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    '200',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  )
                ]),
                SizedBox(
                  width: 60,
                ),
                Column(children: [
                  Icon(
                    Icons.location_pin,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text('200 km',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold))
                ]),
                SizedBox(
                  width: 20,
                ),
              ],
            ),
            SizedBox(
              height: 30,
            ),
            Material(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                onTap: () {},
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
          ]),
        );

    // showDialog(context) {
    //   return showModalBottomSheet(
    //     backgroundColor: Colors.transparent,
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(30),
    //     ),
    //     context: context,
    //     builder: (BuildContext context) => _buildPopupDialog(context),
    //   );
    // }
  }
}

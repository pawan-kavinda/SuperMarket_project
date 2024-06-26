// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math';

import 'package:project/Controllers/user_data.dart';
import 'package:project/Screens/InnerScreens/cart_screen.dart';
import 'package:project/Screens/InnerScreens/payment.dart';
import 'package:project/Screens/home_screen.dart';

class SetLocation extends StatefulWidget {
  final int price;
  SetLocation({required this.price});

  @override
  State<SetLocation> createState() => _SetLocationState();
}

class _SetLocationState extends State<SetLocation> {
  Location locationController = Location();
  LatLng? _currentPosition;
  LatLng _medawachchiyaPosition = LatLng(8.5375, 80.4910);
  GoogleMapController? _googleMapController;
  bool _isLoading = true;
  final firestore = FirebaseFirestore.instance;
  UserData userData = new UserData();
  List<String> orderedProducts = [];
  TextEditingController? _mobileNoController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    getLocationData();
    getOrderProducts();
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  Future<void> getLocationData() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Checking whether location service is on
    _serviceEnabled = await locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Requesting location permission
    _permissionGranted = await locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData locationData = await locationController.getLocation();
    setState(() {
      _currentPosition =
          LatLng(locationData.latitude!, locationData.longitude!);
      _isLoading = false;
    });
  }

  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in km

    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLon = _degreesToRadians(end.longitude - start.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void addOrderDetails() async {
    if (_currentPosition != null && _mobileNoController!.text.isNotEmpty) {
      double distance =
          calculateDistance(_medawachchiyaPosition, _currentPosition!);
      if (distance <= 15) {
        setState(() {
          _isLoading = true;
        });

        User? user = FirebaseAuth.instance.currentUser;
        FirebaseFirestore.instance.collection('Pending Orders').add({
          'order_ID': user!.uid + Random().nextInt(100).toString(),
          'customer_name': user.displayName,
          'customer_mobileNo': _mobileNoController!.text,
          'total_price': widget.price,
          'location': GeoPoint(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          'product_list': orderedProducts
        });
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Order Placed"),
                content: Text("Your order has been placed successfully!"),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            });

        await Future.delayed(Duration(seconds: 3));
        setState(() {
          _isLoading = false;
        });

        Get.to(() => HomeScreen(), transition: Transition.cupertino);
      } else {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Delivery Unavailable"),
                content: Text("We are unable to deliver to your location."),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            });
      }
    } else {
      debugPrint("Error: _currentPosition is null or mobile number is empty");
    }
  }

  void getOrderProducts() async {
    orderedProducts = await userData.getCurrentUserCartDataOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Show us where to deliver",
          style: GoogleFonts.lato(
              fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 20),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 30),
                  child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: Color.fromARGB(255, 44, 208, 19),
                      width: 2,
                    )),
                    height: 400,
                    child: GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition!,
                        zoom: 15,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _googleMapController = controller;
                      },
                      markers: {
                        Marker(
                          markerId: MarkerId('currentLocation'),
                          position: _currentPosition!,
                          draggable: true,
                          onDragEnd: ((LatLng deliveryLocation) {
                            setState(() {
                              _currentPosition = deliveryLocation;
                            });
                            debugPrint(_currentPosition!.latitude.toString());
                            debugPrint(_currentPosition!.longitude.toString());
                          }),
                        ),
                        Marker(
                          markerId: MarkerId('Medawachchiya'),
                          position: _medawachchiyaPosition,
                        ),
                      },
                      circles: {
                        Circle(
                          circleId: CircleId('deliveryRadius'),
                          center: _medawachchiyaPosition,
                          radius: 15000, // 15 km radius
                          fillColor: Colors.blue.withOpacity(0.3),
                          strokeColor: Colors.blue,
                          strokeWidth: 2,
                        ),
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50.0, vertical: 20),
                  child: TextFormField(
                    textAlign: TextAlign.justify,
                    controller: _mobileNoController,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email_rounded),
                        hintText: "Contact Number",
                        hintStyle: GoogleFonts.rasa(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(35.0),
                  child: ElevatedButton(
                      onPressed: () {
                        addOrderDetails();
                      },
                      style: ElevatedButton.styleFrom(
                          elevation: 20,
                          shadowColor: Colors.grey,
                          minimumSize: Size(100, 35)),
                      child: Row(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Icon(IconlyBold.location),
                        ),
                        Text(
                          'Confirm Location',
                          style: GoogleFonts.lato(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontSize: 20),
                        ),
                      ])),
                ),
              ],
            ),
    );
  }
}

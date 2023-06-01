import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memorycare/services/email_service.dart';
import 'package:memorycare/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  StreamSubscription<Position>? _positionStreamSubscription;

  late MapController controller;

  late bool isPicker;
  late bool isTracking;
  GeoPoint? homePosition;
  Position? lastPosition;

  // Notifications
  Position? _currentPosition;
  double _radius = 3000.0;

  // Timeout
  bool canNotify = true;
  int _timeout = 10;

  void startTimer() {
    Timer(Duration(seconds: _timeout), () {
      setState(() {
        canNotify = true;
      });
    });
  }

  // Email
  String? guardianEmail;
  String backupEmail = "midou.xdd@gmail.com";

  @override
  void initState() {
    checkLocationPermission();
    super.initState();
    _startListening();
    _getGuardianEmail();
    getHomeLocation();
    drawHomeLocation();
    isPicker = false;
    isTracking = true;
    controller = MapController.withUserPosition();
    controller.enableTracking(enableStopFollow: true);
  }

  @override
  void dispose() {
    controller.dispose();
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          onPressed: () async {
            if (isTracking) {
              controller.disabledTracking();
            } else {
              controller.enableTracking(enableStopFollow: true);
              var currentLocation = await controller.myLocation();
              controller.goToLocation(currentLocation);
            }
            setState(() {
              isTracking = !isTracking;
            });
          },
          backgroundColor: isTracking ? Colors.blue : Colors.grey,
          child: const Icon(
            Icons.gps_fixed,
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton(
          onPressed: () async {
            if (!isPicker) {
              controller.advancedPositionPicker();
            } else {
              controller.clearAllRoads();
              controller.removeMarker(homePosition!);
              var geo = await controller.selectAdvancedPositionPicker();
              setState(() => homePosition = geo);
              var currentPosition = await controller.myLocation();
              controller.drawRoad(currentPosition, geo);
              controller.addMarker(geo);
              // save to shared_pref
              saveHomeLocation(geo.longitude, geo.latitude);
            }
            setState(() {
              isPicker = !isPicker;
            });
          },
          child: const Icon(
            Icons.track_changes_outlined,
          ),
        ),
      ]),
      body: OSMFlutter(
        controller: controller,
        trackMyPosition: false,
        initZoom: 10,
        minZoomLevel: 2,
        maxZoomLevel: 19,
        stepZoom: 1.0,
        userLocationMarker: UserLocationMaker(
          personMarker: const MarkerIcon(
            icon: Icon(
              Icons.location_history_rounded,
              color: Colors.red,
              size: 48,
            ),
          ),
          directionArrowMarker: const MarkerIcon(
            icon: Icon(
              Icons.location_history_rounded,
              color: Colors.red,
              size: 48,
            ),
          ),
        ),
        roadConfiguration: const RoadOption(
          roadColor: Colors.red,
        ),
        markerOption: MarkerOption(
          defaultMarker: const MarkerIcon(
            icon: Icon(
              Icons.home,
              color: Colors.blue,
              size: 56,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveHomeLocation(double longitude, double latitude) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('home_longitude', longitude);
    await prefs.setDouble('home_latitude', latitude);
  }

  Future<void> getHomeLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double longitude = prefs.getDouble('home_longitude') ?? 0.0;
    double latitude = prefs.getDouble('home_latitude') ?? 0.0;

    GeoPoint geo = GeoPoint(latitude: latitude, longitude: longitude);
    print("home location");
    print(geo);

    setState(() {
      homePosition = geo;
    });
  }

  void _startListening() {
    _positionStreamSubscription =
        Geolocator.getPositionStream().listen((Position position) {
      if (lastPosition == null) {
        lastPosition = position;
      }
      // Handle the new position here
      //print('New position: ${position.latitude}, ${position.longitude}');

      if (lastPosition?.latitude != position.latitude ||
          lastPosition?.longitude != position.longitude) {
        controller.clearAllRoads();
        GeoPoint currentLocation = GeoPoint(
            latitude: position.latitude, longitude: position.longitude);
        controller.drawRoad(currentLocation, homePosition!);
        controller.addMarker(homePosition!);
      }
      setState(() {
        lastPosition = position;
        _currentPosition = position;
      });
      checkGeofence();
    }, onError: (error) {
      print('Location error: $error');
    });
  }

  void _stopListening() {
    _positionStreamSubscription?.cancel();
  }

  void drawHomeLocation() async {
    await Future.delayed(const Duration(seconds: 10));
    var position = await controller.myLocation();
    //if (homePosition.latitude != 0)
    controller.addMarker(homePosition!);
    controller.clearAllRoads();
    GeoPoint currentLocation =
        GeoPoint(latitude: position.latitude, longitude: position.longitude);
    controller.drawRoad(currentLocation, homePosition!);
    controller.addMarker(homePosition!);

    if (homePosition!.longitude != 0 && homePosition!.latitude != 0) {
      CircleOSM circle = CircleOSM(
        key: "allowed_area",
        centerPoint: homePosition!,
        radius: _radius,
        color: Colors.green,
        strokeWidth: 2,
      );
      controller.drawCircle(circle);
    }
  }

  Future<void> checkLocationPermission() async {
    LocationPermission permission;
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showSnackBar('Location services are disabled');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      showSnackBar(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        showSnackBar(
            'Location permissions are denied (actual value: $permission).');
      }
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void checkGeofence() {
    if (_currentPosition == null) {
      return;
    }

    final double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      homePosition!.latitude,
      homePosition!.longitude,
    );

    if (distanceInMeters > _radius) {
      if (canNotify) {
        setState(() {
          canNotify = false;
        });
        NotificationService().showNotification(
            "Warning", "you have left the area! (3km radius)");
        EmailService.sendEmail(
            recepientEmail: guardianEmail ?? backupEmail,
            lon: _currentPosition!.longitude,
            lat: _currentPosition!.latitude,
            distanceFromHome: distanceInMeters.toInt());
        startTimer();
      }
    }
  }

  _getGuardianEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('guardian_email') ?? backupEmail;
    setState(() {
      guardianEmail = email;
    });
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';

class LocationService {
  static final Location _location = Location();

  static Future<bool> checkLocationPermission() async {
    PermissionStatus permissionStatus = await _location.hasPermission();
    return permissionStatus == PermissionStatus.granted;
  }

  static Future<void> askLocationPermission(BuildContext context) async {
    PermissionStatus permissionStatus = await _location.requestPermission();

    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await _location.requestPermission();
    }

    if (permissionStatus == PermissionStatus.granted) {
      print('Location permission granted');
    } else {
      // Handle permission denial gracefully, e.g., display a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required for this feature'),
        ),
      );
    }
  }
}

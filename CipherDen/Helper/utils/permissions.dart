import 'dart:io';
import 'package:iplus_flutter/utils/channels_registration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AppPermissions {

  /// Main method to check all permissions
  static Future<Map<String, dynamic>> checkAll() async {
    final location = await _checkLocation();
    final mic = await _checkMicrophone();
    final wifi = await _checkWifi();

    String bluetooth = "unknown";

    // Bluetooth handled via native (better control on iOS)
    if (Platform.isIOS) {
      bluetooth = await _getBluetoothStatusFromNative();
    }

    return {
      "location": location,
      "microphone": mic,
      "wifi": wifi,
      "bluetooth": bluetooth,
    };
  }

  // ---------------------------
  // LOCATION
  // ---------------------------
  static Future<String> _checkLocation() async {
    var status = await Permission.location.status;

    if (status.isGranted) return "granted";

    if (Platform.isIOS) {
      return await _requestFromNative("requestLocationPermission");
    } else {
      final result = await Permission.location.request();
      return result.isGranted ? "granted" : "denied";
    }
  }

  // ---------------------------
  // MICROPHONE
  // ---------------------------
  static Future<String> _checkMicrophone() async {
    var status = await Permission.microphone.status;

    if (status.isGranted) return "granted";

    if (Platform.isIOS) {
      return await _requestFromNative("requestMicrophonePermission");
    } else {
      final result = await Permission.microphone.request();
      return result.isGranted ? "granted" : "denied";
    }
  }

  // ---------------------------
  // WIFI (Connectivity only)
  // ---------------------------
  static Future<String> _checkWifi() async {
    final result = await Connectivity().checkConnectivity();

    if (result.contains(ConnectivityResult.wifi)) {
      return "connected";
    } else {
      return "not_connected";
    }
  }

  // ---------------------------
  // BLUETOOTH (Native iOS)
  // ---------------------------
  static Future<String> _getBluetoothStatusFromNative() async {
    try {
      final result = await ChannelsRegistration.nativeMethodChannel.invokeMethod('checkBluetoothStatus');
      return result ?? "unknown";
    } catch (e) {
      return "error";
    }
  }

  // ---------------------------
  // COMMON METHOD CHANNEL CALL
  // ---------------------------
  static Future<String> _requestFromNative(String method) async {
    try {
      final result = await ChannelsRegistration.nativeMethodChannel.invokeMethod(method);
      return result ?? "denied";
    } catch (e) {
      return "error";
    }
  }
}
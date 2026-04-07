import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iplus_flutter/home_screen.dart';
import 'package:iplus_flutter/models/camera_launch_args.dart';
import 'package:iplus_flutter/screens/camera_screen.dart';
import 'package:iplus_flutter/settings_screen.dart';
import 'channels_registration.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ── Native → Flutter ───────────────────────────
  static Future<dynamic> handleCall(MethodCall call) async {
    switch (call.method) {
      case 'navGoToFlutter':
        final args = call.arguments as Map?;
        final route = args?['route'] as String?;
        if (route != null) {
          _pushScreen(route, args);
        }
        break;

      //AppNavigator.push(const HomeScreen());

      case 'navPop':
        pop();
        break;
    }
  }

  // Native → Flutter
  static void _pushScreen(String route, Map<dynamic, dynamic>? args) {
    switch (route) {
      case '/home':
        _clearAndPush(const HomeScreen());
        break;

      case '/settings':
        _clearAndPush(const SettingsScreen());
        break;

      case '/camera':
        final params = args?['params'];
        if (params is! Map) {
          debugPrint('Missing camera params for /camera route.');
          return;
        }

        try {
          push(CameraScreen(args: CameraLaunchArgs.fromMap(params)));
        } on FormatException catch (error) {
          debugPrint('Invalid camera params: ${error.message}');
        }
        break;

      default:
        debugPrint('Unknown route: $route');
    }
  }

  // ── Flutter Navigation ─────────────────────────

  // Flutter → Flutter
  static void push(Widget screen) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => screen));
  }

  // Native → Flutter (clears stack, fresh start)
  static void _clearAndPush(Widget screen) {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false, // ← removes all previous routes
    );
  }

  static void pop() {
    if (navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.pop();
    } else {
      // stack empty → tell native to go back
      popToNative();
    }
  }

  // ── Flutter → Native ───────────────────────────
  static Future<void> popToNative() async {
    await ChannelsRegistration.nativeMethodChannel.invokeMethod(
      MethodChannelMethod.navPopFromFlutter.name,
    );
  }
}

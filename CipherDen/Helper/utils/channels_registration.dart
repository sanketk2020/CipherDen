import 'package:flutter/services.dart';
import 'package:iplus_flutter/utils/app_bridge.dart';
import 'app_navigator.dart';

enum MethodChannelMethod {
  /// For data
  dataCheckPermissions,

  navGoToHome,
  navGoToSettings,

  /// For Navigations
  navPopFromFlutter
}

class ChannelsRegistration {
  // ── Channel Names ──────────────────────────────
  static const String _methodChannel = 'com.iplusbyfermax/method';
  static const String _eventChannel = 'com.iplusbyfermax/events';

  // ── Channels ───────────────────────────────────
  static final MethodChannel nativeMethodChannel = const MethodChannel(
    _methodChannel,
  );

  static final EventChannel nativeEventChannel = const EventChannel(
    _eventChannel,
  );

  // ── Called once from main.dart ─────────────────
  static void registerHandlers() {
    nativeMethodChannel.setMethodCallHandler(_dispatch);
  }

  // ── Dispatches to correct class ────────────────
  static Future<dynamic> _dispatch(MethodCall call) async {
    switch (call.method) {

    // Navigation methods
      case 'navGoToFlutter':
      case 'navPop':
        return AppNavigator.handleCall(call);

    // Data/operation methods
      case 'dataCheckPermissions':
        return AppBridge.handleCall(call);

      default:
        throw PlatformException(
          code: 'NOT_IMPLEMENTED',
          message: '${call.method} is not implemented',
        );
    }
  }
}

import 'package:flutter/services.dart';
import 'package:iplus_flutter/utils/permissions.dart';

class AppBridge {
  AppBridge._();

  // ── Native → Flutter ───────────────────────────
  static Future<dynamic> handleCall(MethodCall call) async {
    switch (call.method) {
      case 'dataCheckPermissions':
        return await _checkPermissions();
    }
  }

  // ── Check Permission ───────────────────────
  static Future<Map<String, dynamic>> _checkPermissions() async {
    final result = await AppPermissions.checkAll();
    return result;
  }
}

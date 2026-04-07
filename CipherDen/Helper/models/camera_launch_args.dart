import 'package:vsdk/camera_device/commands/video_command.dart';

class CameraLaunchArgs {
  const CameraLaunchArgs({
    required this.deviceId,
    required this.password,
    this.deviceName = 'IP Camera',
    this.username = 'admin',
    this.model = 'QW6-T',
    this.clientId,
    this.connectType = 126,
    this.resolution = VideoResolution.general,
    this.autoPlayAudio = false,
  });

  final String deviceId;
  final String password;
  final String deviceName;
  final String username;
  final String model;
  final String? clientId;
  final int connectType;
  final VideoResolution resolution;
  final bool autoPlayAudio;

  factory CameraLaunchArgs.fromMap(Map<dynamic, dynamic> map) {
    final normalized = map.map((key, value) => MapEntry(key.toString(), value));

    final deviceId = _readString(
      normalized,
      keys: const ['deviceId', 'id', 'uid', 'did'],
    );
    final password = _readString(normalized, keys: const ['password', 'pwd']);

    if (deviceId == null || deviceId.isEmpty) {
      throw const FormatException(
        'Camera launch args must include a non-empty deviceId.',
      );
    }

    if (password == null || password.isEmpty) {
      throw const FormatException(
        'Camera launch args must include a non-empty password.',
      );
    }

    return CameraLaunchArgs(
      deviceId: deviceId,
      password: password,
      deviceName:
          _readString(normalized, keys: const ['deviceName', 'name']) ??
          'IP Camera',
      username:
          _readString(normalized, keys: const ['username', 'user']) ?? 'admin',
      model: _readString(normalized, keys: const ['model']) ?? 'QW6-T',
      clientId: _readString(normalized, keys: const ['clientId', 'uid']),
      connectType: _readInt(normalized, keys: const ['connectType']) ?? 126,
      resolution: _parseResolution(normalized['resolution']),
      autoPlayAudio:
          _readBool(normalized, keys: const ['autoPlayAudio', 'playAudio']) ??
          false,
    );
  }

  static String? _readString(
    Map<String, dynamic> map, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> map, {required List<String> keys}) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value);
      }
    }
    return null;
  }

  static bool? _readBool(
    Map<String, dynamic> map, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized == 'true' || normalized == '1') {
          return true;
        }
        if (normalized == 'false' || normalized == '0') {
          return false;
        }
      }
    }
    return null;
  }

  static VideoResolution _parseResolution(dynamic raw) {
    if (raw is int) {
      switch (raw) {
        case 1:
          return VideoResolution.high;
        case 2:
          return VideoResolution.general;
        case 4:
          return VideoResolution.low;
        case 100:
          return VideoResolution.superHD;
      }
    }

    if (raw is String) {
      switch (raw.toLowerCase().trim()) {
        case 'high':
          return VideoResolution.high;
        case 'low':
          return VideoResolution.low;
        case 'superhd':
        case 'super_hd':
        case 'super':
          return VideoResolution.superHD;
        case 'general':
        case 'normal':
        case 'medium':
          return VideoResolution.general;
      }
    }

    return VideoResolution.general;
  }
}

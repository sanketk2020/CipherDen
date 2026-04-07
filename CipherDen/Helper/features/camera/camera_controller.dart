import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:iplus_flutter/models/camera_launch_args.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk/camera_device/camera_device.dart';
import 'package:vsdk/camera_device/commands/camera_command.dart';
import 'package:vsdk/camera_device/commands/card_command.dart';

enum CameraViewMode { live, playback }

class CameraFeatureController extends ChangeNotifier {
  CameraFeatureController(this.args);

  final CameraLaunchArgs args;

  CameraDevice? _device;
  AppPlayerController? _playerController;

  CameraDevice? get device => _device;
  AppPlayerController? get playerController => _playerController;

  int? textureId;
  bool isBusy = true;
  bool isPlaying = false;
  bool isAudioEnabled = false;
  String statusText = 'Preparing camera...';
  String? errorText;

  int brightness = 128;
  int contrast = 128;

  List<RecordFile> recordings = <RecordFile>[];
  RecordFile? selectedRecording;
  CameraViewMode viewMode = CameraViewMode.live;

  Future<void> initialize() async {
    await _disposeResources();
    isBusy = true;
    isPlaying = false;
    isAudioEnabled = false;
    errorText = null;
    textureId = null;
    viewMode = CameraViewMode.live;
    statusText = 'Connecting to ${args.deviceName}...';
    notifyListeners();

    try {
      final camera = CameraDevice(
        args.deviceId,
        args.deviceName,
        args.username,
        args.password,
        args.model,
        clientId: args.clientId,
        connectType: args.connectType,
      );
      _device = camera;
      camera.addListener<CameraConnectChanged>(_onConnectChanged);

      final connectState = await camera.connect();
      if (connectState != CameraConnectState.connected) {
        throw Exception(_messageForConnectState(connectState));
      }

      final player = AppPlayerController(changeCallback: _onPlayerStateChanged);
      _playerController = player;

      final created = await player.create();
      if (!created) {
        throw Exception('Unable to create the VStarcam player.');
      }

      textureId = player.textureId;
      await _startLivePreview();
      await refreshImageParams();
      await loadRecordings();
    } catch (error) {
      errorText = error.toString().replaceFirst('Exception: ', '');
      statusText = 'Failed to load camera';
      isBusy = false;
      isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> _startLivePreview() async {
    final camera = _device;
    final player = _playerController;
    if (camera == null || player == null) {
      throw Exception('Camera is not ready.');
    }

    final clientPtr = camera.clientPtr;
    if (clientPtr == null || clientPtr == 0) {
      throw Exception('Camera connected but client pointer is invalid.');
    }

    final sourceReady = await player.setVideoSource(LiveVideoSource(clientPtr));
    if (!sourceReady) {
      throw Exception('Unable to bind the live stream source.');
    }

    final streamReady = await camera.startStream(resolution: args.resolution);
    if (!streamReady) {
      throw Exception('Camera stream could not be started.');
    }

    await player.stop();
    final playbackStarted = await player.start();
    if (!playbackStarted) {
      throw Exception('Live playback could not be started.');
    }

    if (args.autoPlayAudio) {
      await player.startVoice();
      isAudioEnabled = true;
    }

    camera.keepAlive(time: 10);
    viewMode = CameraViewMode.live;
    selectedRecording = null;
    isBusy = false;
    isPlaying = true;
    errorText = null;
    statusText = 'Live';
    notifyListeners();
  }

  Future<void> reconnect() async {
    await initialize();
  }

  Future<void> refreshImageParams() async {
    final camera = _device;
    if (camera == null) {
      return;
    }
    final loaded = await camera.getCameraParams();
    if (loaded) {
      brightness = camera.brightness;
      contrast = camera.contrast;
      notifyListeners();
    }
  }

  Future<void> setBrightness(double value) async {
    final camera = _device;
    if (camera == null) {
      return;
    }
    final normalized = value.round().clamp(0, 255);
    final changed = await camera.changeBrightness(normalized);
    if (changed) {
      brightness = normalized;
      notifyListeners();
    }
  }

  Future<void> setContrast(double value) async {
    final camera = _device;
    if (camera == null) {
      return;
    }
    final normalized = value.round().clamp(0, 255);
    final changed = await camera.changeContrast(normalized);
    if (changed) {
      contrast = normalized;
      notifyListeners();
    }
  }

  Future<void> moveUp() => _runMotor((motor) => motor.up());
  Future<void> moveDown() => _runMotor((motor) => motor.down());
  Future<void> moveLeft() => _runMotor((motor) => motor.left());
  Future<void> moveRight() => _runMotor((motor) => motor.right());
  Future<void> ptzCorrect() => _runMotor((motor) => motor.ptzCorrect());

  Future<void> _runMotor(
    Future<bool> Function(MotorCommand motor) action,
  ) async {
    final motor = _device?.motorCommand;
    if (motor == null) {
      errorText = 'This camera does not expose PTZ controls.';
      notifyListeners();
      return;
    }
    final ok = await action(motor);
    if (!ok) {
      errorText = 'PTZ command failed.';
      notifyListeners();
    }
  }

  Future<void> toggleAudio() async {
    final player = _playerController;
    if (player == null) {
      return;
    }
    bool result;
    if (isAudioEnabled) {
      result = await player.stopVoice();
      if (result) {
        isAudioEnabled = false;
      }
    } else {
      result = await player.startVoice();
      if (result) {
        isAudioEnabled = true;
      }
    }
    notifyListeners();
  }

  Future<File?> captureSnapshot() async {
    final player = _playerController;
    if (player == null) {
      return null;
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${args.deviceId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    file.parent.createSync(recursive: true);
    final ok = await player.screenshot(file.path);
    if (!ok) {
      errorText = 'Snapshot failed.';
      notifyListeners();
      return null;
    }
    statusText = 'Snapshot saved';
    notifyListeners();
    return file;
  }

  Future<void> loadRecordings() async {
    final camera = _device;
    if (camera == null) {
      return;
    }
    await camera.getRecordParam();
    recordings = await camera.getRecordFile(pageIndex: 0, pageSize: 20);
    recordings.sort((a, b) {
      final aTime = a.record_time ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.record_time ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    notifyListeners();
  }

  Future<void> playRecording(RecordFile recordFile) async {
    final camera = _device;
    final player = _playerController;
    if (camera == null || player == null) {
      return;
    }

    isBusy = true;
    errorText = null;
    statusText = 'Opening recording...';
    notifyListeners();

    try {
      await player.stopVoice();
      isAudioEnabled = false;
      await player.stop();

      final clientPtr = camera.clientPtr;
      if (clientPtr == null || clientPtr == 0) {
        throw Exception('Camera pointer is invalid.');
      }

      bool sourceReady;
      bool streamReady;

      if (recordFile.lineFile != null) {
        sourceReady = await player.setVideoSource(TimeLineSource(clientPtr));
        if (!sourceReady) {
          throw Exception('Unable to prepare timeline playback.');
        }
        streamReady = await camera.startRecordLineFile(
          recordFile.lineFile!.record_time,
          recordFile.lineFile!.record_alarm,
        );
      } else {
        sourceReady = await player.setVideoSource(
          CardVideoSource(
            clientPtr,
            recordFile.record_size,
            checkHead: recordFile.record_head == true ? 1 : 0,
          ),
        );
        if (!sourceReady) {
          throw Exception('Unable to prepare playback source.');
        }
        streamReady = await camera.startRecordFile(recordFile.record_name!, 0);
      }

      if (!streamReady) {
        throw Exception('Camera could not start playback for this recording.');
      }

      final started = await player.start();
      if (!started) {
        throw Exception('Recording playback could not be started.');
      }

      selectedRecording = recordFile;
      viewMode = CameraViewMode.playback;
      isBusy = false;
      isPlaying = true;
      statusText = 'Playback';
      notifyListeners();
    } catch (error) {
      errorText = error.toString().replaceFirst('Exception: ', '');
      isBusy = false;
      isPlaying = false;
      statusText = 'Playback failed';
      notifyListeners();
    }
  }

  Future<File?> exportSelectedRecording() async {
    final recordFile = selectedRecording;
    final player = _playerController;
    if (recordFile == null || player == null) {
      errorText = 'Open a recording first before exporting.';
      notifyListeners();
      return null;
    }

    final documents = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${documents.path}/camera_exports');
    exportsDir.createSync(recursive: true);
    final baseName =
        recordFile.record_name?.replaceAll('.mp4', '') ?? 'camera_recording';
    final exportPath = '${exportsDir.path}/$baseName';

    final duration = player.totalSec > 0
        ? player.totalSec
        : recordFile.lineFile?.record_duration ?? 0xFFFFFFFF;
    final result = await player.save(exportPath, start: 0, end: duration);
    if (result < 0) {
      errorText = 'Recording export failed.';
      notifyListeners();
      return null;
    }

    statusText = 'Recording exported';
    notifyListeners();
    return File('$exportPath.mp4');
  }

  Future<void> returnToLive() async {
    final camera = _device;
    if (camera == null) {
      return;
    }
    await camera.stopRecordFile();
    await _startLivePreview();
  }

  String _messageForConnectState(CameraConnectState state) {
    switch (state) {
      case CameraConnectState.connecting:
        return 'Connecting to camera...';
      case CameraConnectState.logging:
        return 'Logging in...';
      case CameraConnectState.connected:
        return 'Connected';
      case CameraConnectState.timeout:
        return 'Connection timed out.';
      case CameraConnectState.disconnect:
        return 'Camera disconnected.';
      case CameraConnectState.password:
        return 'Password is invalid.';
      case CameraConnectState.maxUser:
        return 'Camera reached the maximum viewer limit.';
      case CameraConnectState.offline:
        return 'Camera is offline.';
      case CameraConnectState.illegal:
        return 'Camera rejected the connection.';
      case CameraConnectState.none:
        return 'Preparing camera...';
    }
  }

  void _onConnectChanged(CameraDevice device, CameraConnectState connectState) {
    statusText = _messageForConnectState(connectState);
    notifyListeners();
  }

  void _onPlayerStateChanged(
    dynamic _,
    VideoStatus videoStatus,
    VoiceStatus voiceStatus,
    RecordStatus recordStatus,
    SoundTouchType touchType,
  ) {
    isPlaying = videoStatus == VideoStatus.PLAY;
    isAudioEnabled = voiceStatus == VoiceStatus.PLAY;
    if (errorText == null) {
      statusText = isPlaying
          ? (viewMode == CameraViewMode.live ? 'Live' : 'Playback')
          : videoStatus.name;
    }
    notifyListeners();
  }

  Future<void> _disposeResources() async {
    final camera = _device;
    final player = _playerController;
    _device = null;
    _playerController = null;

    if (camera != null) {
      camera.removeListener(_onConnectChanged);
    }

    if (player != null) {
      await player.stopVoice();
      await player.stop();
      player.dispose();
    }

    if (camera != null) {
      await camera.stopRecordFile();
      await camera.stopStream();
      await camera.disconnect();
      await camera.deviceDestroy();
    }
  }

  Future<void> disposeController() async {
    await _disposeResources();
    super.dispose();
  }
}

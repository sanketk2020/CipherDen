import 'package:flutter/material.dart';
import 'package:iplus_flutter/models/camera_launch_args.dart';
import 'package:iplus_flutter/utils/app_navigator.dart';
import 'package:vsdk/app_player.dart';
import 'package:vsdk/camera_device/camera_device.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.args});

  final CameraLaunchArgs args;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraDevice? _device;
  AppPlayerController? _playerController;
  int? _textureId;

  bool _isBusy = true;
  bool _isPlaying = false;
  String _statusText = 'Preparing camera...';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _disposeResources();

    setState(() {
      _isBusy = true;
      _isPlaying = false;
      _errorText = null;
      _statusText = 'Connecting to ${widget.args.deviceName}...';
    });

    try {
      final device = CameraDevice(
        widget.args.deviceId,
        widget.args.deviceName,
        widget.args.username,
        widget.args.password,
        widget.args.model,
        clientId: widget.args.clientId,
        connectType: widget.args.connectType,
      );

      _device = device;
      device.addListener<CameraConnectChanged>(_onConnectChanged);

      final connected = await device.connect();
      if (!mounted) {
        return;
      }

      if (connected != CameraConnectState.connected) {
        throw Exception(_messageForConnectState(connected));
      }

      final controller = AppPlayerController(
        changeCallback: _onPlayerStateChanged,
      );
      _playerController = controller;

      final created = await controller.create();
      if (!created) {
        throw Exception('Unable to create the vendor video player.');
      }

      _textureId = controller.textureId;

      final clientPtr = device.clientPtr;
      if (clientPtr == null || clientPtr == 0) {
        throw Exception('Device connected but client pointer is invalid.');
      }

      final sourceReady = await controller.setVideoSource(
        LiveVideoSource(clientPtr),
      );
      if (!sourceReady) {
        throw Exception('Unable to bind the live stream source.');
      }

      final streamReady = await device.startStream(
        resolution: widget.args.resolution,
      );
      if (!streamReady) {
        throw Exception('Camera stream could not be started.');
      }

      await controller.stop();
      final playbackStarted = await controller.start();
      if (!playbackStarted) {
        throw Exception('Live playback could not be started.');
      }

      if (widget.args.autoPlayAudio) {
        await controller.startVoice();
      }

      device.keepAlive(time: 10);

      if (!mounted) {
        return;
      }

      setState(() {
        _isBusy = false;
        _isPlaying = true;
        _errorText = null;
        _statusText = 'Live';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _isPlaying = false;
        _errorText = error.toString().replaceFirst('Exception: ', '');
        _statusText = 'Failed to load camera';
      });
    }
  }

  void _onConnectChanged(CameraDevice device, CameraConnectState connectState) {
    if (!mounted) {
      return;
    }

    setState(() {
      _statusText = _messageForConnectState(connectState);
    });
  }

  void _onPlayerStateChanged(
    dynamic _,
    VideoStatus videoStatus,
    VoiceStatus voiceStatus,
    RecordStatus recordStatus,
    SoundTouchType touchType,
  ) {
    if (!mounted) {
      return;
    }

    final playing = videoStatus == VideoStatus.PLAY;
    setState(() {
      _isPlaying = playing;
      if (_errorText == null) {
        _statusText = playing ? 'Live' : videoStatus.name;
      }
    });
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

  Future<void> _disposeResources() async {
    final device = _device;
    final controller = _playerController;

    _device = null;
    _playerController = null;
    _textureId = null;

    if (device != null) {
      device.removeListener(_onConnectChanged);
    }

    if (controller != null) {
      if (widget.args.autoPlayAudio) {
        await controller.stopVoice();
      }
      await controller.stop();
      controller.dispose();
    }

    if (device != null) {
      await device.stopStream();
      await device.disconnect();
      await device.deviceDestroy();
    }
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.args.deviceName),
        leading: IconButton(
          onPressed: AppNavigator.pop,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildPlayerBody(),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: _isPlaying ? Colors.greenAccent : Colors.white38,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusText,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isBusy ? null : _initializeCamera,
                    child: Text(
                      _errorText == null ? 'Reconnect Camera' : 'Retry',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerBody() {
    if (_textureId != null) {
      return Texture(textureId: _textureId!);
    }

    if (_isBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _errorText ?? 'No video available.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

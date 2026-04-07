import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iplus_flutter/features/camera/camera_controller.dart';
import 'package:iplus_flutter/features/camera/widgets/camera_live_controls.dart';
import 'package:iplus_flutter/features/camera/widgets/camera_preview.dart';
import 'package:iplus_flutter/features/camera/widgets/camera_recordings_panel.dart';
import 'package:iplus_flutter/models/camera_launch_args.dart';
import 'package:iplus_flutter/utils/app_navigator.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.args});

  final CameraLaunchArgs args;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late final CameraFeatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CameraFeatureController(widget.args)..initialize();
  }

  @override
  void dispose() {
    unawaited(_controller.disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.args.deviceName),
            leading: IconButton(
              onPressed: AppNavigator.pop,
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              TextButton(
                onPressed: _controller.isBusy ? null : _controller.reconnect,
                child: const Text('Reconnect'),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CameraPreview(
                    textureId: _controller.textureId,
                    isBusy: _controller.isBusy,
                    errorText: _controller.errorText,
                  ),
                  const SizedBox(height: 16),
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  CameraLiveControls(
                    onUp: _controller.moveUp,
                    onDown: _controller.moveDown,
                    onLeft: _controller.moveLeft,
                    onRight: _controller.moveRight,
                    onCenter: _controller.ptzCorrect,
                    onAudioToggle: _controller.toggleAudio,
                    onSnapshot: _controller.captureSnapshot,
                    onBackToLive: _controller.returnToLive,
                    isAudioEnabled: _controller.isAudioEnabled,
                    brightness: _controller.brightness.toDouble(),
                    contrast: _controller.contrast.toDouble(),
                    onBrightnessChanged: _controller.setBrightness,
                    onContrastChanged: _controller.setContrast,
                    showBackToLive:
                        _controller.viewMode == CameraViewMode.playback,
                  ),
                  const SizedBox(height: 24),
                  CameraRecordingsPanel(
                    recordings: _controller.recordings,
                    selectedRecording: _controller.selectedRecording,
                    onRefresh: _controller.loadRecordings,
                    onPlay: _controller.playRecording,
                    onExport: _controller.exportSelectedRecording,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: _controller.isPlaying
                      ? Colors.green
                      : Colors.orange.shade400,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_controller.statusText)),
              ],
            ),
            if (_controller.errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _controller.errorText!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Mode: ${_controller.viewMode == CameraViewMode.live ? 'Live preview' : 'TF playback'}',
            ),
            Text('Recordings found: ${_controller.recordings.length}'),
          ],
        ),
      ),
    );
  }
}

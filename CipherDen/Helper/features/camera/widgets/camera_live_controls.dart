import 'package:flutter/material.dart';

class CameraLiveControls extends StatelessWidget {
  const CameraLiveControls({
    super.key,
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onCenter,
    required this.onAudioToggle,
    required this.onSnapshot,
    required this.onBackToLive,
    required this.isAudioEnabled,
    required this.brightness,
    required this.contrast,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.showBackToLive,
  });

  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onCenter;
  final VoidCallback onAudioToggle;
  final VoidCallback onSnapshot;
  final VoidCallback onBackToLive;
  final bool isAudioEnabled;
  final double brightness;
  final double contrast;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final bool showBackToLive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.tonal(
              onPressed: onAudioToggle,
              child: Text(isAudioEnabled ? 'Mute Audio' : 'Play Audio'),
            ),
            FilledButton.tonal(
              onPressed: onSnapshot,
              child: const Text('Snapshot'),
            ),
            if (showBackToLive)
              FilledButton(
                onPressed: onBackToLive,
                child: const Text('Back To Live'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('PTZ', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 220,
            child: Column(
              children: [
                _PtzButton(icon: Icons.keyboard_arrow_up, onPressed: onUp),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PtzButton(
                      icon: Icons.keyboard_arrow_left,
                      onPressed: onLeft,
                    ),
                    _PtzButton(
                      icon: Icons.center_focus_strong,
                      onPressed: onCenter,
                    ),
                    _PtzButton(
                      icon: Icons.keyboard_arrow_right,
                      onPressed: onRight,
                    ),
                  ],
                ),
                _PtzButton(icon: Icons.keyboard_arrow_down, onPressed: onDown),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Image', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text('Brightness ${brightness.round()}'),
        Slider(
          min: 0,
          max: 255,
          divisions: 255,
          value: brightness.clamp(0, 255),
          onChanged: onBrightnessChanged,
        ),
        Text('Contrast ${contrast.round()}'),
        Slider(
          min: 0,
          max: 255,
          divisions: 255,
          value: contrast.clamp(0, 255),
          onChanged: onContrastChanged,
        ),
      ],
    );
  }
}

class _PtzButton extends StatelessWidget {
  const _PtzButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        minimumSize: const Size(56, 56),
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}

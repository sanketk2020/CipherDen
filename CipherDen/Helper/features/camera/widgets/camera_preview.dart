import 'package:flutter/material.dart';

class CameraPreview extends StatelessWidget {
  const CameraPreview({
    super.key,
    required this.textureId,
    required this.isBusy,
    required this.errorText,
  });

  final int? textureId;
  final bool isBusy;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (textureId != null) {
      return Texture(textureId: textureId!);
    }

    if (isBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          errorText ?? 'No video available.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

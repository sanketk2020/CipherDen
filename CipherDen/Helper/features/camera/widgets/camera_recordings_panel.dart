import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vsdk/camera_device/commands/card_command.dart';

class CameraRecordingsPanel extends StatelessWidget {
  CameraRecordingsPanel({
    super.key,
    required this.recordings,
    required this.selectedRecording,
    required this.onRefresh,
    required this.onPlay,
    required this.onExport,
  });

  final List<RecordFile> recordings;
  final RecordFile? selectedRecording;
  final VoidCallback onRefresh;
  final ValueChanged<RecordFile> onPlay;
  final VoidCallback onExport;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Memory Card Recordings',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(onPressed: onRefresh, child: const Text('Refresh')),
            FilledButton.tonal(
              onPressed: onExport,
              child: const Text('Export Current'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recordings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No TF/memory card recordings were found.'),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: recordings.length,
              separatorBuilder: (_, separatorIndex) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = recordings[index];
                final selected =
                    selectedRecording?.record_name == item.record_name;
                final recordTime = item.record_time;
                final subtitle = recordTime == null
                    ? item.record_name ?? 'Unknown recording'
                    : '${_dateFormat.format(recordTime)}  •  ${_formatBytes(item.record_size)}';
                return ListTile(
                  selected: selected,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.record_name ?? 'Recording'),
                  subtitle: Text(subtitle),
                  trailing: FilledButton.tonal(
                    onPressed: () => onPlay(item),
                    child: const Text('Play'),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '0 B';
    }
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int index = 0;
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[index]}';
  }
}

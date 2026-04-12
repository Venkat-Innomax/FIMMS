import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class RectificationUpload extends StatefulWidget {
  const RectificationUpload({super.key});

  @override
  State<RectificationUpload> createState() => _RectificationUploadState();
}

class _RectificationUploadState extends State<RectificationUpload> {
  int _uploadedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FimmsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FimmsColors.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 18, color: FimmsColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _uploadedCount > 0
                  ? '$_uploadedCount file(s) attached'
                  : 'Upload rectification evidence',
              style: const TextStyle(
                  fontSize: 12, color: FimmsColors.textMuted),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, size: 20),
            tooltip: 'Take photo',
            onPressed: () {
              setState(() => _uploadedCount++);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo captured (demo)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, size: 20),
            tooltip: 'Upload document',
            onPressed: () {
              setState(() => _uploadedCount++);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File selected (demo)')),
              );
            },
          ),
        ],
      ),
    );
  }
}

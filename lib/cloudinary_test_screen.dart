import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/cloudinary_media_service.dart';

class CloudinaryTestScreen extends StatefulWidget {
  const CloudinaryTestScreen({super.key});

  @override
  State<CloudinaryTestScreen> createState() =>
      _CloudinaryTestScreenState();
}

class _CloudinaryTestScreenState
    extends State<CloudinaryTestScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _uploading = false;
  String _message = 'Select an image to test Cloudinary upload.';

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _uploading = true;
        _message = 'Uploading image to Cloudinary...';
      });

      final File imageFile = File(pickedFile.path);

      final CloudinaryUploadResult result =
          await CloudinaryMediaService.uploadImage(
        imageFile,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _uploading = false;
        _message =
            'Upload successful!\n\n'
            'URL:\n${result.secureUrl}\n\n'
            'Public ID:\n${result.publicId}';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _uploading = false;
        _message = 'Upload failed:\n$e';
      });
    }
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _uploading = true;
        _message = 'Uploading video to Cloudinary...';
      });

      final CloudinaryUploadResult result =
          await CloudinaryMediaService.uploadVideo(
        pickedFile,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _uploading = false;
        _message =
            'Video upload successful!\n\n'
            'URL:\n${result.secureUrl}\n\n'
            'Public ID:\n${result.publicId}\n\n'
            'Duration:\n'
            '${result.duration?.toStringAsFixed(1) ?? 'Unknown'} seconds';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _uploading = false;
        _message = 'Video upload failed:\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloudinary Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed:
                  _uploading ? null : _pickAndUploadImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Test Image Upload'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed:
                  _uploading ? null : _pickAndUploadVideo,
              icon: const Icon(Icons.video_library_outlined),
              label: const Text('Test Video Upload'),
            ),
            const SizedBox(height: 24),
            if (_uploading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 16),
            SelectableText(
              _message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
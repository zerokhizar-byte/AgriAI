import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryMediaService {
  static const String _cloudName = 'llousa5i';

  static const String _imageUploadPreset =
      'agriai_images';

  static const String _videoUploadPreset =
      'agriai_videos';

  static const String _imageFolder =
      'agriai';

  static const String _videoFolder =
      'agriai/videos';

  /// Upload an image to Cloudinary.
  ///
  /// This keeps the image functionality available
  /// for the existing AgriAI image-upload features.
  static Future<CloudinaryUploadResult> uploadImage(
    File file,
  ) async {
    return _upload(
      file: file,
      resourceType: 'image',
      uploadPreset: _imageUploadPreset,
      folder: _imageFolder,
    );
  }

  /// Upload a video to Cloudinary.
  ///
  /// Uses the unsigned `agriai_videos` preset.
  static Future<CloudinaryUploadResult> uploadVideo(
    XFile file,
  ) async {
    final File videoFile = File(file.path);

    return _upload(
      file: videoFile,
      resourceType: 'video',
      uploadPreset: _videoUploadPreset,
      folder: _videoFolder,
    );
  }

  /// Internal Cloudinary multipart uploader.
  static Future<CloudinaryUploadResult> _upload({
    required File file,
    required String resourceType,
    required String uploadPreset,
    required String folder,
  }) async {
    if (!await file.exists()) {
      throw Exception(
        'Selected file does not exist.',
      );
    }

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
      '$_cloudName/$resourceType/upload',
    );

    final http.MultipartRequest request =
        http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['upload_preset'] =
        uploadPreset;

    request.fields['folder'] = folder;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    final http.StreamedResponse response =
        await request.send().timeout(
              const Duration(minutes: 5),
            );

    final String responseBody =
        await response.stream.bytesToString();

    Map<String, dynamic> data =
        <String, dynamic>{};

    try {
      final dynamic decoded =
          jsonDecode(responseBody);

      if (decoded
          is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {
      // Keep the original response body for
      // error reporting below.
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message = responseBody;

      final dynamic error =
          data['error'];

      if (error is Map<String, dynamic>) {
        final dynamic errorMessage =
            error['message'];

        if (errorMessage != null) {
          message = errorMessage.toString();
        }
      }

      throw Exception(
        'Cloudinary upload failed '
        '(${response.statusCode}): $message',
      );
    }

    final String secureUrl =
        '${data['secure_url'] ?? ''}'.trim();

    if (secureUrl.isEmpty) {
      throw Exception(
        'Cloudinary upload succeeded, '
        'but no secure URL was returned.',
      );
    }

    return CloudinaryUploadResult(
      secureUrl: secureUrl,
      publicId:
          '${data['public_id'] ?? ''}',
      resourceType:
          '${data['resource_type'] ?? resourceType}',
      format:
          '${data['format'] ?? ''}',
      originalFilename:
          '${data['original_filename'] ?? ''}',
      bytes: data['bytes'] is num
          ? (data['bytes'] as num).toInt()
          : null,
      width: data['width'] is num
          ? (data['width'] as num).toInt()
          : null,
      height: data['height'] is num
          ? (data['height'] as num).toInt()
          : null,
      duration: data['duration'] is num
          ? (data['duration'] as num)
              .toDouble()
          : null,
    );
  }
}

/// Result returned after a successful Cloudinary upload.
class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final String resourceType;
  final String format;
  final String originalFilename;

  final int? bytes;
  final int? width;
  final int? height;
  final double? duration;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    required this.format,
    required this.originalFilename,
    this.bytes,
    this.width,
    this.height,
    this.duration,
  });
}
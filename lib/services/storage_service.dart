import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

/// StorageService — powered by Cloudinary FREE tier
///
/// ─── ONE-TIME SETUP (5 minutes) ──────────────────────────────────────────
///
/// 1. Sign up FREE at https://cloudinary.com  (no credit card needed)
///    Free tier: 25 GB storage · 25 GB bandwidth/month
///
/// 2. From your Cloudinary Dashboard copy:
///      • Cloud Name  →  [cloudName] below
///
/// 3. Create an **Upload Preset** (so the app can upload without an API secret):
///      Cloudinary Dashboard → Settings → Upload → Upload Presets → Add preset
///      • Signing mode : Unsigned
///      • Folder       : sharebox         (optional but tidy)
///      • Save preset name → [uploadPreset] below
///
/// 
/// ─────────────────────────────────────────────────────────────────────────

class StorageService {
  // ⚠️  TODO: Replace with YOUR Cloudinary values
  static const String _cloudName = 'dnumhqx7d';       // e.g. 'dxyz1234'
  static const String _uploadPreset = 'sharebox_unsigned'; // e.g. 'sharebox_unsigned'

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // ─── IMAGE PICKERS ───────────────────────────────────────────────────────

  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return image != null ? File(image.path) : null;
  }

  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return image != null ? File(image.path) : null;
  }

  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return images.take(maxImages).map((x) => File(x.path)).toList();
  }

  // ─── UPLOAD: PROFILE IMAGE ───────────────────────────────────────────────

  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    return _uploadToCloudinary(
      imageFile: imageFile,
      folder: 'sharebox/profiles/$userId',
      publicId: 'profile_${_uuid.v4()}',
    );
  }

  // ─── UPLOAD: TOOL IMAGE ──────────────────────────────────────────────────

  Future<String> uploadToolImage({
    required String ownerId,
    required File imageFile,
    String? toolId,
  }) async {
    final folder = toolId != null
        ? 'sharebox/tools/$ownerId/$toolId'
        : 'sharebox/tools/$ownerId/temp';
    return _uploadToCloudinary(
      imageFile: imageFile,
      folder: folder,
      publicId: 'tool_${_uuid.v4()}',
    );
  }

  // ─── UPLOAD: MULTIPLE TOOL IMAGES ───────────────────────────────────────

  Future<List<String>> uploadToolImages({
    required String ownerId,
    required List<File> imageFiles,
    String? toolId,
  }) async {
    final urls = <String>[];
    for (final file in imageFiles) {
      final url = await uploadToolImage(
        ownerId: ownerId,
        imageFile: file,
        toolId: toolId,
      );
      urls.add(url);
    }
    return urls;
  }

  // ─── DELETE IMAGE ────────────────────────────────────────────────────────
  // Cloudinary unsigned presets don't allow deletion from the client.
  // Images are cleaned up from the Cloudinary dashboard, or via a
  // signed server-side call. This is intentionally a no-op on the client.
  Future<void> deleteImage(String downloadUrl) async {
    // No-op: use Cloudinary dashboard or a Cloud Function to delete.
    debugPrint('StorageService: deleteImage is a no-op on client side.');
  }

  Future<void> deleteImages(List<String> downloadUrls) async {
    for (final url in downloadUrls) {
      await deleteImage(url);
    }
  }

  // ─── CORE UPLOAD IMPLEMENTATION ─────────────────────────────────────────

  Future<String> _uploadToCloudinary({
    required File imageFile,
    required String folder,
    required String publicId,
  }) async {
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final dataUri = 'data:$mimeType;base64,$base64Image';

    final response = await http.post(
      Uri.parse(_uploadUrl),
      body: {
        'file': dataUri,
        'upload_preset': _uploadPreset,
        'folder': folder,
        'public_id': publicId,
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      if (secureUrl != null && secureUrl.isNotEmpty) return secureUrl;
      throw Exception('Cloudinary returned no URL');
    } else {
      final body = jsonDecode(response.body);
      throw Exception(
          'Cloudinary upload failed [${response.statusCode}]: ${body['error']?['message'] ?? response.body}');
    }
  }
}


// Dorm Life Cloudinary Service
// Handles image uploads (jpg/png) for dorm event creation
// Supports both mobile (File) and web (Uint8List bytes)

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class DormCloudinaryService {
  static const _cloudName    = 'dif9wnnci';
  static const _uploadPreset = 'beach_circle_screenshots';
  static final  _uri = Uri.parse(
    'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
  );

  // ── Mobile: upload from File ───────────────────────────────────────────────
  static Future<String?> uploadImage(File imageFile) async {
    final request = http.MultipartRequest('POST', _uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(body)['secure_url'];
    }
    return null;
  }

  // ── Web: upload from Uint8List bytes ──────────────────────────────────────
  static Future<String?> uploadImageBytes(Uint8List bytes, String filename) async {
    final request = http.MultipartRequest('POST', _uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(body)['secure_url'];
    }
    return null;
  }
}
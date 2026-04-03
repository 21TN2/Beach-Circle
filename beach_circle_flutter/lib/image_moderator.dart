import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ImageModerator {
  // These are the labels ML Kit uses that usually indicate NSFW or harmful content
  static const List<String> _bannedLabels = [
    'Nudity',
    'Underwear',
    'Swimwear',
    'Lingerie',
    'Weapon',
    'Gun',
    'Firearm',
    'Blood',
    'Violence',
  ];

  /// Downloads the URL and checks if it's safe. 
  /// Returns [true] if clean, [false] if it contains NSFW/Banned content.
  static Future<bool> isUrlSafe(String imageUrl) async {
    try {
      // 1. Download the image bytes from the URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return true; // If link is dead, we treat as safe or handle elsewhere

      // 2. Save to a temporary file on the device
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp_scan.jpg');
      await file.writeAsBytes(response.bodyBytes);

      // 3. Initialize ML Kit Image Labeler
      final inputImage = InputImage.fromFilePath(file.path);
      final ImageLabelerOptions options = ImageLabelerOptions(confidenceThreshold: 0.6);
      final imageLabeler = ImageLabeler(options: options);

      // 4. Process the image and get labels
      final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);

      // 5. Clean up: Close labeler and delete the temp file immediately
      imageLabeler.close();
      if (await file.exists()) await file.delete();

      // 6. Check if any detected labels match our banned list
      for (ImageLabel label in labels) {
        if (_bannedLabels.contains(label.label)) {
          print("MODERATION: Blocked ${label.label} (Confidence: ${label.confidence})");
          return false; // NSFW content detected
        }
      }

      return true; // Image passed the scan
    } catch (e) {
      print("Moderation Error: $e");
      return true; // If scan fails, we default to safe to avoid blocking valid posts
    }
  }
}
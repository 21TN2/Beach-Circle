import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ImageModerator {
  // These are the labels ML Kit uses that usually indicate NSFW or harmful content
  static const List<String> _bannedLabels = [
    // --- WEAPONS & VIOLENCE ---
    'Weaponry',           // This is the most common label for guns/knives
    'Handgun',            // Specific weapon label
    'Rifle',              // Specific weapon label
    'Firearm',            // Specific weapon label
    'Trigger',            // Often detected on weapon close-ups
    'Ammunition',         // Detected near weapons
    
    // --- ADULT / NSFW CONTENT ---
    'Underwear',          // Catch-all for lingerie/briefs
    'Lingerie',           // Specific adult clothing
    'Swimwear',           // Bikinis and trunks
    'Bikini',             // Specific swimwear
    'Maillot',            // One-piece swimsuits
    'Bra',                // Undergarments
    'Briefs',             // Undergarments
    'Abdomen',            // High confidence here often means a shirtless/NSFW photo
    
    // --- DRUGS & ALCOHOL ---
    'Cigarette',          // Smoking/Tobacco
    'Tobacco',            // Tobacco products
    'Beer',               // Alcohol
    'Wine',               // Alcohol
    'Alcoholic beverage', // General alcohol
    'Distilled beverage', // Hard liquor
    
    // --- RISKY (Use with Caution) ---
    'Blood',              // Violence/Injuries
    'Bruise',             // Violence/Injuries
    'Injury',             // Violence/Injuries
    'Scab',               // Violence/Injuries
    'gore',               // Violence/Injuries
    'Torture',            // Violence/Injuries
    'Death',              // Violence/Injuries
  ];

  /// Returns null if safe, or the [String] label name if it contains NSFW content.
  static Future<String?> isUrlSafe(String imageUrl) async {
    try {
      // 1. Download the image with headers to prevent being blocked by the host
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      // If the site blocks the download (403) or link is dead (404), we return null
      if (response.statusCode != 200) {
        print("MODERATION: Download failed with status: ${response.statusCode}");
        return null; 
      }

      // 2. Save to a temporary file on the device
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp_scan.jpg');
      await file.writeAsBytes(response.bodyBytes);

      // 3. Initialize ML Kit Image Labeler
      final inputImage = InputImage.fromFilePath(file.path);
      
      // Lowered threshold to 0.5 to be more sensitive to weapons/NSFW
      final ImageLabelerOptions options = ImageLabelerOptions(confidenceThreshold: 0.1);
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
          return label.label; // Return the specific reason for the block
        }
      }

      return null; // Image passed the scan
    } catch (e) {
      print("Moderation Error: $e");
      return null; 
    }
  }
}
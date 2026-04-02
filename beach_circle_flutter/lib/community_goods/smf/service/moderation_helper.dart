import 'package:flutter/services.dart' show rootBundle;

class ModerationHelper {
  static List<String> _bannedPhrases = [];
  static final Map<String, String> _charMap = {};
  static bool _isLoaded = false;

  /// Loads both the banned words and the character map into memory
  static Future<void> loadBadWords() async {
    if (_isLoaded) return; 
    
    try {
      // 1. Load the banned words (en.txt)
      final String wordsText = await rootBundle.loadString('assets/en.txt');
      _bannedPhrases = wordsText
          .split('\n')
          .map((word) => word.trim().toLowerCase())
          .where((word) => word.isNotEmpty)
          .toList();
          
      // 2. Load the character substitutions (char_map.txt)
      final String mapText = await rootBundle.loadString('assets/char_map.txt');
      final lines = mapText.split('\n');
      
      for (String line in lines) {
        if (line.trim().isEmpty || !line.contains('=')) continue;
        
        // Split "a=4,@,á" into normal letter ("a") and list of symbols (["4", "@", "á"])
        List<String> parts = line.split('=');
        String normalLetter = parts[0].trim().toLowerCase();
        List<String> weirdChars = parts[1].split(',');
        
        // Map every weird character back to the normal letter
        for (String wc in weirdChars) {
          _charMap[wc.trim().toLowerCase()] = normalLetter;
        }
      }
          
      _isLoaded = true;
    } catch (e) {
      print("Error loading moderation files: $e");
    }
  }

  /// Translates leet-speak back to normal text (e.g., "b1tch" -> "bitch")
  static String _normalizeText(String text) {
    String normalized = text.toLowerCase();
    
    // Sort the keys by length descending so multi-character replacements
    // (like "\/\/" for 'w') get replaced BEFORE single characters.
    var sortedWeirdChars = _charMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    // Swap out all the weird characters for normal letters
    for (String weirdChar in sortedWeirdChars) {
      if (normalized.contains(weirdChar)) {
        normalized = normalized.replaceAll(weirdChar, _charMap[weirdChar]!);
      }
    }
    
    return normalized;
  }

  /// Checks if the text contains any blocked words, even if they use leet-speak
  static bool containsProfanity(String text) {
    if (text.trim().isEmpty || !_isLoaded) return false;
    
    String lowerText = text.toLowerCase();
    String normalizedText = _normalizeText(lowerText);

    for (String phrase in _bannedPhrases) {
      // 1. Check the normalized text (Catches "b1tch" -> "bitch")
      if (normalizedText.contains(phrase) || 
          normalizedText.split(RegExp(r'\s+')).contains(phrase)) {
        return true; 
      }
      
      // 2. Fallback check on the raw text (Just to be extra safe)
      if (lowerText.contains(phrase) || 
          lowerText.split(RegExp(r'\s+')).contains(phrase)) {
        return true; 
      }
    }
    return false;
  }
}
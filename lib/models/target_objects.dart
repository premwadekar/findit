import 'package:flutter/material.dart';

/// The objects FindIt can detect locally on-device.
///
/// Fully aligned with PRD Sections 6, 7 & 10:
/// - Everyday: Bottle, Phone, Cup, Book, Bag, Backpack, Remote
/// - Desk: Keyboard, Mouse, Laptop
/// - Personal: Glasses, Wallet, Keys (explicitly listed in [unsupported])
///
/// Deliberately honest: FindIt never fakes detection.
class TargetObjects {
  static const Map<String, String> supported = {
    'bottle': 'bottle',
    'phone': 'cell phone',
    'cup': 'cup',
    'book': 'book',
    'bag': 'handbag',
    'backpack': 'backpack',
    'remote': 'remote',
    'keyboard': 'keyboard',
    'mouse': 'mouse',
    'laptop': 'laptop',
    'chair': 'chair',
    'bowl': 'bowl',
    'scissors': 'scissors',
    'toothbrush': 'toothbrush',
    'tv': 'tv',
    'spoon': 'spoon',
    'fork': 'fork',
    'knife': 'knife',
  };

  /// Common icons for visual accessibility and high-contrast UI.
  static const Map<String, IconData> icons = {
    'bottle': Icons.local_drink,
    'phone': Icons.smartphone,
    'cup': Icons.coffee,
    'book': Icons.menu_book,
    'bag': Icons.shopping_bag,
    'backpack': Icons.backpack,
    'remote': Icons.settings_remote,
    'keyboard': Icons.keyboard,
    'mouse': Icons.mouse,
    'laptop': Icons.laptop,
    'chair': Icons.chair,
    'bowl': Icons.rice_bowl,
    'scissors': Icons.content_cut,
    'toothbrush': Icons.brush,
    'tv': Icons.tv,
    'spoon': Icons.restaurant,
    'fork': Icons.restaurant,
    'knife': Icons.restaurant_menu,
  };

  /// Requested frequently by blind users, but not detectable by the mobile COCO model.
  /// The app explicitly says: "I can't reliably find that object yet."
  static const List<String> unsupported = [
    'key',
    'keys',
    'chaabi',
    'चाबी',
    'चाबियां',
    'ಕೀ',
    'ಕೀಲಿ',
    'తాళంచెవి',
    'కీలు',
    'சாவி',
    'wallet',
    'purse',
    'batua',
    'बटुआ',
    'पर्स',
    'ವ್ಯಾಲೆಟ್',
    'ಪರ್ಸ್',
    'వాలెట్',
    'పర్సు',
    'பணப்பை',
    'பர்ஸ்',
    'glasses',
    'spectacles',
    'chashma',
    'चश्मा',
    'ಕನ್ನಡಕ',
    'కళ్లద్దాలు',
    'மூக்குக்கண்ணாடி',
    'watch',
    'ring',
    'coin',
  ];

  static bool isSupported(String friendlyName) =>
      supported.containsKey(friendlyName.toLowerCase().trim());

  static String? modelLabelFor(String friendlyName) =>
      supported[friendlyName.toLowerCase().trim()];

  static IconData iconFor(String friendlyName) =>
      icons[friendlyName.toLowerCase().trim()] ?? Icons.search;

  /// Checks if the query matches an explicitly unsupported object across all supported languages.
  static bool isQueryUnsupported(String transcript) {
    final lower = transcript.toLowerCase();
    for (final item in unsupported) {
      if (lower.contains(item.toLowerCase())) return true;
    }
    return false;
  }

  /// Tries to map free-form voice input across languages to a supported friendly name.
  /// Returns null when nothing matches.
  static String? matchVoiceInput(String transcript) {
    final lower = transcript.toLowerCase();

    // Phonetic matches for common Indian accent transcriptions
    if (lower.contains('bottle') ||
        lower.contains('bottel') ||
        lower.contains('botal') ||
        lower.contains('botol') ||
        lower.contains('botle')) {
      return 'bottle';
    }
    if (lower.contains('phone') ||
        lower.contains('fone') ||
        lower.contains('mobile') ||
        lower.contains('mobail')) {
      return 'phone';
    }

    // Direct English matches
    for (final name in supported.keys) {
      if (lower.contains(name)) return name;
    }

    // Phone synonyms & multilingual keywords
    if (lower.contains('mobile') ||
        lower.contains('cell') ||
        lower.contains('telephone') ||
        lower.contains('smartphone') ||
        lower.contains('फ़ोन') ||
        lower.contains('फोन') ||
        lower.contains('मोबाइल') ||
        lower.contains('ಫೋನ್') ||
        lower.contains('ಮೊಬೈಲ್') ||
        lower.contains('ఫోన్') ||
        lower.contains('మొబైల్') ||
        lower.contains('போன்') ||
        lower.contains('கைப்பேசி')) {
      return 'phone';
    }

    // Bottle synonyms & multilingual keywords
    if (lower.contains('water bottle') ||
        lower.contains('flask') ||
        lower.contains('thermos') ||
        lower.contains('बोतल') ||
        lower.contains('पानी की बोतल') ||
        lower.contains('ಬಾಟಲ್') ||
        lower.contains('ನೀರಿನ ಬಾಟಲ್') ||
        lower.contains('బాటిల్') ||
        lower.contains('నీళ్ల బాటిల్') ||
        lower.contains('பாட்டில்') ||
        lower.contains('தண்ணீர் பாட்டில்')) {
      return 'bottle';
    }

    // Cup synonyms & multilingual keywords
    if (lower.contains('coffee') ||
        lower.contains('mug') ||
        lower.contains('tea cup') ||
        lower.contains('कप') ||
        lower.contains('मग') ||
        lower.contains('ಕಪ್') ||
        lower.contains('ಮಗ್') ||
        lower.contains('కప్పు') ||
        lower.contains('మగ్గు') ||
        lower.contains('கப்')) {
      return 'cup';
    }

    // Book synonyms & multilingual keywords
    if (lower.contains('notebook') ||
        lower.contains('किताब') ||
        lower.contains('पुस्तक') ||
        lower.contains('ಪುಸ್ತಕ') ||
        lower.contains('ಗ್ರಂಥ') ||
        lower.contains('పుస్తకం') ||
        lower.contains('புத்தகம்') ||
        lower.contains('நூல்')) {
      return 'book';
    }

    // Bag / Backpack synonyms & multilingual keywords
    if (lower.contains('backpack') ||
        lower.contains('rucksack') ||
        lower.contains('school bag') ||
        lower.contains('बैकपैक') ||
        lower.contains('ಬ್ಯಾಕ್‌ಪ್ಯಾಕ್') ||
        lower.contains('బ్యాక్‌ప్యాక్') ||
        lower.contains('முதுகுப்பை')) {
      return 'backpack';
    }
    if (lower.contains('handbag') ||
        lower.contains('tote') ||
        lower.contains('बैग') ||
        lower.contains('थैला') ||
        lower.contains('ब್ಯಾಗ್') ||
        lower.contains('ಚೀಲ') ||
        lower.contains('బ్యాగ్') ||
        lower.contains('సంచి') ||
        lower.contains('கைப்பை') ||
        lower.contains('பை')) {
      return 'bag';
    }

    // Remote synonyms & multilingual keywords
    if (lower.contains('controller') ||
        lower.contains('tv remote') ||
        lower.contains('रिमोट') ||
        lower.contains('ರಿಮೋಟ್') ||
        lower.contains('రిమోట్') ||
        lower.contains('ரிமோட்')) {
      return 'remote';
    }

    // Laptop synonyms & multilingual keywords
    if (lower.contains('computer') ||
        lower.contains('pc') ||
        lower.contains('लैपटॉप') ||
        lower.contains('कंप्यूटर') ||
        lower.contains('ಲ್ಯಾಪ್‌ಟಾಪ್') ||
        lower.contains('ಕಂಪ್ಯೂಟರ್') ||
        lower.contains('ల్యాప్‌టాప్') ||
        lower.contains('లాప్‌టాప్') ||
        lower.contains('மடிக்கணினி')) {
      return 'laptop';
    }

    // Kitchen / household targets (English + simple Hindi/regional words)
    if (lower.contains('scissor') ||
        lower.contains('kainchi') ||
        lower.contains('कैंची') ||
        lower.contains('ಕತ್ತರಿ') ||
        lower.contains('కత్తెర') ||
        lower.contains('கத்தரிக்கோல்')) {
      return 'scissors';
    }
    if (lower.contains('toothbrush') ||
        lower.contains('tooth brush') ||
        lower.contains('ब्रश') ||
        lower.contains('ಬ್ರಷ್') ||
        lower.contains('బ్రష్') ||
        lower.contains('பிரஷ்')) {
      return 'toothbrush';
    }
    if (lower.contains('knife') ||
        lower.contains('chaku') ||
        lower.contains('चाकू') ||
        lower.contains('ಚಾಕು') ||
        lower.contains('కత్తి') ||
        lower.contains('கத்தி')) {
      return 'knife';
    }
    if (lower.contains('spoon') ||
        lower.contains('chammach') ||
        lower.contains('चम्मच') ||
        lower.contains('ಚಮಚ') ||
        lower.contains('చెంచా') ||
        lower.contains('கரண்டி')) {
      return 'spoon';
    }
    if (lower.contains('fork') ||
        lower.contains('कांटा') ||
        lower.contains('काँटा') ||
        lower.contains('ಫೋರ್ಕ್') ||
        lower.contains('ఫోర్క్') ||
        lower.contains('ஃபோர்க்')) {
      return 'fork';
    }
    if (lower.contains('katori') ||
        lower.contains('कटोरी') ||
        lower.contains('कटोरा') ||
        lower.contains('ಬಟ್ಟಲು') ||
        lower.contains('గిన్నె') ||
        lower.contains('கிண்ணம்')) {
      return 'bowl';
    }
    if (lower.contains('kursi') ||
        lower.contains('कुर्सी') ||
        lower.contains('ಕುರ್ಚಿ') ||
        lower.contains('కుర్చీ') ||
        lower.contains('நாற்காலி')) {
      return 'chair';
    }
    if (lower.contains('television') ||
        lower.contains('टीवी') ||
        lower.contains('टेलीविजन') ||
        lower.contains('ಟಿವಿ') ||
        lower.contains('టీవీ') ||
        lower.contains('டிவி')) {
      return 'tv';
    }

    // Keyboard & Mouse
    if (lower.contains('कीबोर्ड') ||
        lower.contains('ಕೀಬೋರ್ಡ್') ||
        lower.contains('కీబోర్డ్') ||
        lower.contains('விசைப்பலகை')) {
      return 'keyboard';
    }
    if (lower.contains('माउस') ||
        lower.contains('ಮೌಸ್') ||
        lower.contains('మౌస్') ||
        lower.contains('மவுஸ்')) {
      return 'mouse';
    }

    return null;
  }
}

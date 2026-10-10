import '../models/app_language.dart';

/// Predefined translations for all guidance, assistant prompts, and UI labels.
///
/// Guidance phrases are strictly predefined per the PRD to ensure speed, predictability,
/// and reliability without runtime translation latency.
class LocalizationService {
  LocalizationService._();
  static final LocalizationService instance = LocalizationService._();

  static const Map<String, Map<AppLanguage, String>> _objectNames = {
    'bottle': {
      AppLanguage.english: 'bottle',
      AppLanguage.hindi: 'बोतल',
      AppLanguage.kannada: 'ಬಾಟಲ್',
      AppLanguage.telugu: 'బాటిల్',
      AppLanguage.tamil: 'பாட்டில்',
    },
    'phone': {
      AppLanguage.english: 'phone',
      AppLanguage.hindi: 'फ़ोन',
      AppLanguage.kannada: 'ಫೋನ್',
      AppLanguage.telugu: 'ఫోన్',
      AppLanguage.tamil: 'போன்',
    },
    'cup': {
      AppLanguage.english: 'cup',
      AppLanguage.hindi: 'कप',
      AppLanguage.kannada: 'ಕಪ್',
      AppLanguage.telugu: 'కప్పు',
      AppLanguage.tamil: 'கப்',
    },
    'book': {
      AppLanguage.english: 'book',
      AppLanguage.hindi: 'किताब',
      AppLanguage.kannada: 'ಪುಸ್ತಕ',
      AppLanguage.telugu: 'పుస్తకం',
      AppLanguage.tamil: 'புத்தகம்',
    },
    'bag': {
      AppLanguage.english: 'bag',
      AppLanguage.hindi: 'बैग',
      AppLanguage.kannada: 'ಬ್ಯಾಗ್',
      AppLanguage.telugu: 'బ్యాగ్',
      AppLanguage.tamil: 'பை',
    },
    'backpack': {
      AppLanguage.english: 'backpack',
      AppLanguage.hindi: 'बैकपैक',
      AppLanguage.kannada: 'ಬ್ಯಾಕ್‌ಪ್ಯಾಕ್',
      AppLanguage.telugu: 'బ్యాక్‌ప్యాక్',
      AppLanguage.tamil: 'முதுகுப்பை',
    },
    'remote': {
      AppLanguage.english: 'remote',
      AppLanguage.hindi: 'रिमोट',
      AppLanguage.kannada: 'ರಿಮೋಟ್',
      AppLanguage.telugu: 'రిమోట్',
      AppLanguage.tamil: 'ரிமோட்',
    },
    'keyboard': {
      AppLanguage.english: 'keyboard',
      AppLanguage.hindi: 'कीबोर्ड',
      AppLanguage.kannada: 'ಕೀಬೋರ್ಡ್',
      AppLanguage.telugu: 'కీబోర్డ్',
      AppLanguage.tamil: 'விசைப்பலகை',
    },
    'mouse': {
      AppLanguage.english: 'mouse',
      AppLanguage.hindi: 'माउस',
      AppLanguage.kannada: 'ಮೌಸ್',
      AppLanguage.telugu: 'మౌస్',
      AppLanguage.tamil: 'மவுஸ்',
    },
    'laptop': {
      AppLanguage.english: 'laptop',
      AppLanguage.hindi: 'लैपटॉप',
      AppLanguage.kannada: 'ಲ್ಯಾಪ್‌ಟಾಪ್',
      AppLanguage.telugu: 'ల్యాప్‌టాప్',
      AppLanguage.tamil: 'மடிக்கணினி',
    },
    'chair': {
      AppLanguage.english: 'chair',
      AppLanguage.hindi: 'कुर्सी',
      AppLanguage.kannada: 'ಕುರ್ಚಿ',
      AppLanguage.telugu: 'కుర్చీ',
      AppLanguage.tamil: 'நாற்காலி',
    },
    'bowl': {
      AppLanguage.english: 'bowl',
      AppLanguage.hindi: 'कटोरी',
      AppLanguage.kannada: 'ಬಟ್ಟಲು',
      AppLanguage.telugu: 'గిన్నె',
      AppLanguage.tamil: 'கிண்ணம்',
    },
    'scissors': {
      AppLanguage.english: 'scissors',
      AppLanguage.hindi: 'कैंची',
      AppLanguage.kannada: 'ಕತ್ತರಿ',
      AppLanguage.telugu: 'కత్తెర',
      AppLanguage.tamil: 'கத்தரிக்கோல்',
    },
    'toothbrush': {
      AppLanguage.english: 'toothbrush',
      AppLanguage.hindi: 'ब्रश',
      AppLanguage.kannada: 'ಬ್ರಷ್',
      AppLanguage.telugu: 'బ్రష్',
      AppLanguage.tamil: 'பிரஷ்',
    },
    'tv': {
      AppLanguage.english: 'TV',
      AppLanguage.hindi: 'टीवी',
      AppLanguage.kannada: 'ಟಿವಿ',
      AppLanguage.telugu: 'టీవీ',
      AppLanguage.tamil: 'டிவி',
    },
    'spoon': {
      AppLanguage.english: 'spoon',
      AppLanguage.hindi: 'चम्मच',
      AppLanguage.kannada: 'ಚಮಚ',
      AppLanguage.telugu: 'చెంచా',
      AppLanguage.tamil: 'கரண்டி',
    },
    'fork': {
      AppLanguage.english: 'fork',
      AppLanguage.hindi: 'कांटा',
      AppLanguage.kannada: 'ಫೋರ್ಕ್',
      AppLanguage.telugu: 'ఫోర్క్',
      AppLanguage.tamil: 'ஃபோர்க்',
    },
    'knife': {
      AppLanguage.english: 'knife',
      AppLanguage.hindi: 'चाकू',
      AppLanguage.kannada: 'ಚಾಕು',
      AppLanguage.telugu: 'కత్తి',
      AppLanguage.tamil: 'கத்தி',
    },
  };

  String objectName(String friendlyKey, AppLanguage lang) {
    final key = friendlyKey.toLowerCase().trim();
    return _objectNames[key]?[lang] ?? friendlyKey;
  }

  /// Names for objects that are not targets but can be reported as "nearby".
  static const Map<String, String> _nearbyOnlyEnglish = {
    'dining table': 'table',
    'cell phone': 'phone',
    'handbag': 'bag',
  };

  /// Localized name for a model label (e.g. 'cell phone' -> phone). Labels
  /// with no translation fall back to the English model label.
  String objectNameForModelLabel(String modelLabel, AppLanguage lang) {
    for (final e in _objectNames.entries) {
      final model = switch (e.key) {
        'phone' => 'cell phone',
        'bag' => 'handbag',
        _ => e.key,
      };
      if (model == modelLabel) return e.value[lang] ?? e.key;
    }
    return _nearbyOnlyEnglish[modelLabel] ?? modelLabel;
  }

  // Safe-reach (stage 2) guidance
  String safeReachInstruction(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
      'Found. Stop. Move your hand slowly forward, palm open.',
    AppLanguage.hindi =>
      'मिल गया। रुकिए। अपना हाथ धीरे-धीरे आगे बढ़ाइए, हथेली खुली रखें।',
    AppLanguage.kannada =>
      'ಸಿಕ್ಕಿದೆ. ನಿಲ್ಲಿಸಿ. ನಿಮ್ಮ ಕೈಯನ್ನು ನಿಧಾನವಾಗಿ ಮುಂದೆ ಚಾಚಿ, ಅಂಗೈ ತೆರೆದಿಡಿ.',
    AppLanguage.telugu =>
      'దొరికింది. ఆగండి. మీ చేతిని నెమ్మదిగా ముందుకు చాచండి, అరచేయి తెరిచి ఉంచండి.',
    AppLanguage.tamil =>
      'கிடைத்தது. நில்லுங்கள். உங்கள் கையை மெதுவாக முன்னே நீட்டுங்கள், உள்ளங்கையை திறந்து வைக்கவும்.',
  };

  String fragileWarning(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'This can fall. Bring your hand from below, slowly.',
    AppLanguage.hindi =>
      'यह गिर सकता है। अपना हाथ नीचे से, धीरे-धीरे लाइए।',
    AppLanguage.kannada =>
      'ಇದು ಬೀಳಬಹುದು. ನಿಮ್ಮ ಕೈಯನ್ನು ಕೆಳಗಿನಿಂದ ನಿಧಾನವಾಗಿ ತನ್ನಿ.',
    AppLanguage.telugu =>
      'ఇది పడిపోవచ్చు. మీ చేతిని కింద నుండి నెమ్మదిగా తీసుకురండి.',
    AppLanguage.tamil =>
      'இது கீழே விழலாம். உங்கள் கையை கீழிருந்து மெதுவாக கொண்டு வாருங்கள்.',
  };

  String nearbyObjectWarning(String modelLabel, AppLanguage lang) {
    final other = objectNameForModelLabel(modelLabel, lang);
    return switch (lang) {
      AppLanguage.english => 'There is also a $other nearby, go slowly.',
      AppLanguage.hindi => 'पास में $other भी है, धीरे जाइए।',
      AppLanguage.kannada => 'ಹತ್ತಿರದಲ್ಲಿ $other ಕೂಡ ಇದೆ, ನಿಧಾನವಾಗಿ ಸಾಗಿ.',
      AppLanguage.telugu => 'దగ్గరలో $other కూడా ఉంది, నెమ్మదిగా వెళ్లండి.',
      AppLanguage.tamil => 'அருகில் $other உம் உள்ளது, மெதுவாக செல்லுங்கள்.',
    };
  }

  // Directional guidance
  String moveLeft(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Move left.',
    AppLanguage.hindi => 'बाएं मुड़ें।',
    AppLanguage.kannada => 'ಎಡಕ್ಕೆ ಸಾಗಿ.',
    AppLanguage.telugu => 'ఎడమవైపు వెళ్లండి.',
    AppLanguage.tamil => 'இடதுபுறம் செல்லுங்கள்.',
  };

  String moveSlightlyLeft(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Move slightly left.',
    AppLanguage.hindi => 'थोड़ा बाएं जाएं।',
    AppLanguage.kannada => 'ಸ್ವಲ್ಪ ಎಡಕ್ಕೆ ಸಾಗಿ.',
    AppLanguage.telugu => 'కొద్దిగా ఎడమవైపు వెళ్లండి.',
    AppLanguage.tamil => 'சிறிது இடதுபுறம் செல்லுங்கள்.',
  };

  String moveForward(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Move forward.',
    AppLanguage.hindi => 'आगे बढ़ें।',
    AppLanguage.kannada => 'ಮುಂದೆ ಸಾಗಿ.',
    AppLanguage.telugu => 'ముందుకు వెళ్లండి.',
    AppLanguage.tamil => 'முன்னோக்கி செல்லுங்கள்.',
  };

  String moveSlightlyRight(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Move slightly right.',
    AppLanguage.hindi => 'थोड़ा दाएं जाएं।',
    AppLanguage.kannada => 'ಸ್ವಲ್ಪ ಬಲಕ್ಕೆ ಸಾಗಿ.',
    AppLanguage.telugu => 'కొద్దిగా కుడివైపు వెళ్లండి.',
    AppLanguage.tamil => 'சிறிது வலதுபுறம் செல்லுங்கள்.',
  };

  String moveRight(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Move right.',
    AppLanguage.hindi => 'दाएं मुड़ें।',
    AppLanguage.kannada => 'ಬಲಕ್ಕೆ ಸಾಗಿ.',
    AppLanguage.telugu => 'కుడివైపు వెళ్లండి.',
    AppLanguage.tamil => 'வலதுபுறம் செல்லுங்கள்.',
  };

  String youAreGettingCloser(AppLanguage lang) => switch (lang) {
    AppLanguage.english => "You're getting closer.",
    AppLanguage.hindi => 'आप करीब आ रहे हैं।',
    AppLanguage.kannada => 'ನೀವು ಹತ್ತಿರವಾಗುತ್ತಿದ್ದೀರಿ.',
    AppLanguage.telugu => 'మీరు దగ్గరకు వస్తున్నారు.',
    AppLanguage.tamil => 'நீங்கள் அருகில் வருகிறீர்கள்.',
  };

  String objectIsClose(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'The object is close.',
    AppLanguage.hindi => 'वस्तु पास है।',
    AppLanguage.kannada => 'ವಸ್ತು ಹತ್ತಿರದಲ್ಲಿದೆ.',
    AppLanguage.telugu => 'వస్తువు దగ్గరగా ఉంది.',
    AppLanguage.tamil => 'பொருள் அருகில் உள்ளது.',
  };

  String stopObjectFound(String friendlyTarget, AppLanguage lang) {
    final target = objectName(friendlyTarget, lang);
    return switch (lang) {
      AppLanguage.english => 'Stop. $target found.',
      AppLanguage.hindi => 'रुकिए। $target मिल गया।',
      AppLanguage.kannada => 'ನಿಲ್ಲಿಸಿ. $target ಸಿಕ್ಕಿದೆ.',
      AppLanguage.telugu => 'ఆగండి. $target దొరికింది.',
      AppLanguage.tamil => 'நில்லுங்கள். $target கிடைத்தது.',
    };
  }

  String objectDetected(String friendlyTarget, AppLanguage lang) {
    final target = objectName(friendlyTarget, lang);
    return switch (lang) {
      AppLanguage.english => '$target detected.',
      AppLanguage.hindi => '$target मिल गया है।',
      AppLanguage.kannada => '$target ಪತ್ತೆಯಾಗಿದೆ.',
      AppLanguage.telugu => '$target గుర్తించబడింది.',
      AppLanguage.tamil => '$target கண்டறியப்பட்டது.',
    };
  }

  String objectLost(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'I lost the object. Move the camera slowly.',
    AppLanguage.hindi => 'वस्तु खो गई है। कृपया कैमरा धीरे-धीरे घुमाएं।',
    AppLanguage.kannada =>
      'ವಸ್ತು ಕಾಣಿಸುತ್ತಿಲ್ಲ. ಕ್ಯಾಮೆರಾವನ್ನು ನಿಧಾನವಾಗಿ ಚಲಿಸಿ.',
    AppLanguage.telugu => 'వస్తువు కనిపించడం లేదు. కెమెరాను నెమ్మదిగా కదపండి.',
    AppLanguage.tamil => 'பொருள் தெரியவில்லை. கேமராவை மெதுவாக நகர்த்தவும்.',
  };

  String reacquiring(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Reacquiring object. Hold steady.',
    AppLanguage.hindi => 'वस्तु को पुनः खोजा जा रहा है। स्थिर रखें।',
    AppLanguage.kannada =>
      'ವಸ್ತುವನ್ನು ಮತ್ತೆ ಹುಡುಕಲಾಗುತ್ತಿದೆ. ಸ್ಥಿರವಾಗಿ ಹಿಡಿಯಿರಿ.',
    AppLanguage.telugu => 'వస్తువు కోసం మళ్లీ చూస్తున్నాము. స్థిరంగా ఉంచండి.',
    AppLanguage.tamil => 'பொருளை மீண்டும் தேடுகிறது. நிலையாக பிடிக்கவும்.',
  };

  String scanningUncertain(String friendlyTarget, AppLanguage lang) {
    final target = objectName(friendlyTarget, lang);
    return switch (lang) {
      AppLanguage.english =>
        "I'm not sure that's your $target. Please move the camera slowly.",
      AppLanguage.hindi =>
        'मुझे पक्का नहीं पता कि यह आपकी $target है। कृपया कैमरा धीरे-धीरे घुमाएं।',
      AppLanguage.kannada =>
        'ಇದು ನಿಮ್ಮ $target ಎಂದು ಖಚಿತವಿಲ್ಲ. ಕ್ಯಾಮೆರಾವನ್ನು ನಿಧಾನವಾಗಿ ಚಲಿಸಿ.',
      AppLanguage.telugu =>
        'ఇది మీ $target అని ఖచ్చితంగా లేదు. కెమెరాను నెమ్మదిగా కదపండి.',
      AppLanguage.tamil =>
        'இது உங்கள் $target என்று உறுதியாக தெரியவில்லை. கேமராவை மெதுவாக நகர்த்தவும்.',
    };
  }

  String scanRoom(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
      "I can't identify the object yet. Please slowly scan the room.",
    AppLanguage.hindi =>
      'अभी वस्तु नहीं पहचानी जा सकी। कृपया कमरे को धीरे-धीरे स्कैन करें।',
    AppLanguage.kannada =>
      'ವಸ್ತು ಇನ್ನೂ ಗುರುತಿಸಲಾಗಿಲ್ಲ. ದಯವಿಟ್ಟು ಕೋಣೆಯನ್ನು ನಿಧಾನವಾಗಿ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ.',
    AppLanguage.telugu =>
      'ఇంకా వస్తువు గుర్తించబడలేదు. దయచేసి గదిని నెమ్మదిగా స్కాన్ చేయండి.',
    AppLanguage.tamil =>
      'பொருளை இன்னும் அடையாளம் காண முடியவில்லை. அறையை மெதுவாக ஸ்கேன் செய்யவும்.',
  };

  String unsupportedObject(AppLanguage lang) => switch (lang) {
    AppLanguage.english => "I can't reliably find that object yet.",
    AppLanguage.hindi =>
      'मैं अभी उस वस्तु को भरोसेमंद तरीके से नहीं ढूंढ सकता।',
    AppLanguage.kannada =>
      'ನಾನು ಆ ವಸ್ತುವನ್ನು ಇನ್ನೂ ವಿಶ್ವಾಸಾರ್ಹವಾಗಿ ಹುಡುಕಲು ಸಾಧ್ಯವಿಲ್ಲ.',
    AppLanguage.telugu => 'నేను ఆ వస్తువును ఇంకా ఖచ్చితంగా కనుగొనలేను.',
    AppLanguage.tamil =>
      'என்னால் இன்னும் அந்தப் பொருளை நம்பத்தகுந்த முறையில் கண்டுபிடிக்க முடியாது.',
  };

  String searchingTarget(String friendlyTarget, AppLanguage lang) {
    final target = objectName(friendlyTarget, lang);
    return switch (lang) {
      AppLanguage.english => 'Okay. Looking for your $target.',
      AppLanguage.hindi => 'ठीक है। आपकी $target ढूंढ रहा हूँ।',
      AppLanguage.kannada => 'ಸರಿ. ನಿಮ್ಮ $target ಹುಡುಕುತ್ತಿದ್ದೇನೆ.',
      AppLanguage.telugu => 'సరే. మీ $target కోసం వెతుకుతున్నాను.',
      AppLanguage.tamil => 'சரி. உங்கள் $target தேடுகிறேன்.',
    };
  }

  // Onboarding & Friendly Assistant Strings
  String welcomeGreeting(AppLanguage lang) => switch (lang) {
    AppLanguage.english => "Hi, I'm FindIt.",
    AppLanguage.hindi => 'नमस्ते, मैं FindIt हूँ।',
    AppLanguage.kannada => 'ನಮಸ್ಕಾರ, ನಾನು FindIt.',
    AppLanguage.telugu => 'నమస్తే, నేను FindIt.',
    AppLanguage.tamil => 'வணக்கம், நான் FindIt.',
  };

  String askName(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Before we start, what should I call you?',
    AppLanguage.hindi => 'शुरू करने से पहले, मैं आपको किस नाम से बुलाऊं?',
    AppLanguage.kannada => 'ಪ್ರಾರಂಭಿಸುವ ಮೊದಲು, ನಾನು ನಿಮ್ಮನ್ನು ಏನಂತ ಕರೆಯಲಿ?',
    AppLanguage.telugu => 'మనం ప్రారంభించే ముందు, నేను మిమ్మల్ని ఏమని పిలవాలి?',
    AppLanguage.tamil =>
      'தொடங்குவதற்கு முன், நான் உங்களை என்னவென்று அழைக்க வேண்டும்?',
  };

  String niceToMeetYou(String name, AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Nice to meet you, $name.',
    AppLanguage.hindi => 'आपसे मिलकर अच्छा लगा, $name।',
    AppLanguage.kannada => 'ನಿಮ್ಮನ್ನು ಭೇಟಿಯಾಗಿದ್ದು ಸಂತೋಷವಾಯಿತು, $name.',
    AppLanguage.telugu => 'మిమ్మల్ని కలవడం ఆనందంగా ఉంది, $name.',
    AppLanguage.tamil => 'உங்களை சந்தித்ததில் மகிழ்ச்சி, $name.',
  };

  String askLanguage(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Which language would you like me to use?',
    AppLanguage.hindi => 'आप मुझसे किस भाषा में बात करना चाहेंगे?',
    AppLanguage.kannada => 'ನಾನು ಯಾವ ಭಾಷೆಯಲ್ಲಿ ಮಾತನಾಡಬೇಕೆಂದು ನೀವು ಬಯಸುತ್ತೀರಿ?',
    AppLanguage.telugu => 'నేను మీతో ఏ భాషలో మాట్లాడాలని మీరు కోరుకుంటున్నారు?',
    AppLanguage.tamil => 'நான் உங்களிடம் எந்த மொழியில் பேச வேண்டும்?',
  };

  String languageChangedAck(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Great. I will speak with you in English.',
    AppLanguage.hindi => 'ठीक है। अब मैं आपसे हिंदी में बात करूँगा।',
    AppLanguage.kannada =>
      'ಸರಿ. ಇನ್ನು ನಾನು ನಿಮ್ಮೊಂದಿಗೆ ಕನ್ನಡದಲ್ಲಿ ಮಾತನಾಡುತ್ತೇನೆ.',
    AppLanguage.telugu => 'సరే. ఇకపై నేను మీతో తెలుగులో మాట్లాడతాను.',
    AppLanguage.tamil => 'சரி. இனி நான் உங்களிடம் தமிழில் பேசுவேன்.',
  };

  String howAreYou(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'How are you today?',
    AppLanguage.hindi => 'आज आप कैसे हैं?',
    AppLanguage.kannada => 'ಇವತ್ತು ಹೇಗಿದ್ದೀರಿ?',
    AppLanguage.telugu => 'ఈ రోజు మీరు ఎలా ఉన్నారు?',
    AppLanguage.tamil => 'இன்று நீங்கள் எப்படி இருக்கிறீர்கள்?',
  };

  String howCanIHelp(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'What would you like me to help you with?',
    AppLanguage.hindi => 'मैं आपकी किस चीज़ में मदद कर सकता हूँ?',
    AppLanguage.kannada => 'ನಾನು ನಿಮಗೆ ಯಾವ ವಿಷಯದಲ್ಲಿ ಸಹಾಯ ಮಾಡಲಿ?',
    AppLanguage.telugu => 'నేను మీకు దేనిలో సహాయం చేయాలి?',
    AppLanguage.tamil => 'நான் உங்களுக்கு எதில் உதவ வேண்டும்?',
  };

  String findSomething(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Find something',
    AppLanguage.hindi => 'कुछ ढूंढें',
    AppLanguage.kannada => 'ಏನನ್ನಾದರೂ ಹುಡುಕಿ',
    AppLanguage.telugu => 'ఏదైనా వెతకండి',
    AppLanguage.tamil => 'ஏதாவது தேடுங்கள்',
  };

  String describeSurroundings(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Describe my surroundings',
    AppLanguage.hindi => 'आस-पास का वर्णन करें',
    AppLanguage.kannada => 'ನನ್ನ ಸುತ್ತಮುತ್ತಲಿನ ವಿವರಣೆ ನೀಡಿ',
    AppLanguage.telugu => 'నా పరిసరాలను వివరించండి',
    AppLanguage.tamil => 'என் சுற்றத்தை விவரிக்கவும்',
  };

  String helpMeUnderstand(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Help me understand something',
    AppLanguage.hindi => 'मुझे कुछ समझने में मदद करें',
    AppLanguage.kannada => 'ಏನನ್ನಾದರೂ ಅರ್ಥಮಾಡಿಕೊಳ್ಳಲು ಸಹಾಯ ಮಾಡಿ',
    AppLanguage.telugu => 'ఏదైనా అర్థం చేసుకోవడానికి సహాయం చేయండి',
    AppLanguage.tamil => 'ஏதாவது புரிந்து கொள்ள உதவுங்கள்',
  };

  String settings(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Settings',
    AppLanguage.hindi => 'सेटिंग्स',
    AppLanguage.kannada => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
    AppLanguage.telugu => 'సెట్టింగ్‌లు',
    AppLanguage.tamil => 'அமைப்புகள்',
  };

  String help(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Help',
    AppLanguage.hindi => 'मदद',
    AppLanguage.kannada => 'ಸಹಾಯ',
    AppLanguage.telugu => 'సహాయం',
    AppLanguage.tamil => 'உதவி',
  };

  String stop(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'STOP',
    AppLanguage.hindi => 'रुकें',
    AppLanguage.kannada => 'ನಿಲ್ಲಿಸಿ',
    AppLanguage.telugu => 'ఆగండి',
    AppLanguage.tamil => 'நில்லுங்கள்',
  };

  String resume(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'RESUME',
    AppLanguage.hindi => 'जारी रखें',
    AppLanguage.kannada => 'ಮುಂದುವರಿಸಿ',
    AppLanguage.telugu => 'కొనసాగించండి',
    AppLanguage.tamil => 'தொடரவும்',
  };

  String alarmSilenced(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Alarm silenced. Phone found.',
    AppLanguage.hindi => 'अलार्म बंद हो गया। फ़ोन मिल गया।',
    AppLanguage.kannada => 'ಅಲಾರಂ ನಿಲ್ಲಿಸಲಾಗಿದೆ. ಫೋನ್ ಸಿಕ್ಕಿತು.',
    AppLanguage.telugu => 'అలారం ఆపివేయబడింది. ఫోన్ దొరికింది.',
    AppLanguage.tamil => 'அலாரம் நிறுத்தப்பட்டது. போன் கிடைத்தது.',
  };

  String lostPhoneAlert(AppLanguage lang) => switch (lang) {
    AppLanguage.english => "I'm right here. Follow my voice or alarm.",
    AppLanguage.hindi => 'मैं यहीं हूँ। मेरी आवाज़ या अलार्म की दिशा में आइए।',
    AppLanguage.kannada => 'ನಾನು ಇಲ್ಲೇ ಇದ್ದೇನೆ. ನನ್ನ ಧ್ವನಿ ಅಥವಾ ಅಲಾರಂ ಅನುಸರಿಸಿ.',
    AppLanguage.telugu => 'నేను ఇక్కడే ఉన్నాను. నా స్వరాన్ని లేదా అలారంను అనుసరించండి.',
    AppLanguage.tamil => 'நான் இங்கே இருக்கிறேன். என் குரல் அல்லது அலாரத்தைப் பின்பற்றுங்கள்.',
  };

  // ---- Iris hands-free assistant ----

  String yesTellMe(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Yes, tell me.',
    AppLanguage.hindi => 'जी, बताइए।',
    AppLanguage.kannada => 'ಹೌದು, ಹೇಳಿ.',
    AppLanguage.telugu => 'అవును, చెప్పండి.',
    AppLanguage.tamil => 'ஆம், சொல்லுங்கள்.',
  };

  String didntHearAnything(AppLanguage lang) => switch (lang) {
    AppLanguage.english => "I didn't hear anything.",
    AppLanguage.hindi => 'मुझे कुछ सुनाई नहीं दिया।',
    AppLanguage.kannada => 'ನನಗೆ ಏನೂ ಕೇಳಿಸಲಿಲ್ಲ.',
    AppLanguage.telugu => 'నాకు ఏమీ వినిపించలేదు.',
    AppLanguage.tamil => 'எனக்கு எதுவும் கேட்கவில்லை.',
  };

  String irisCantDoThat(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
      "Sorry, I can't do that yet. I can find objects, ring your phone, tell the battery or time.",
    AppLanguage.hindi =>
      'माफ़ कीजिए, मैं अभी यह नहीं कर सकता। मैं चीज़ें ढूंढ सकता हूँ, आपका फ़ोन बजा सकता हूँ, बैटरी या समय बता सकता हूँ।',
    AppLanguage.kannada =>
      'ಕ್ಷಮಿಸಿ, ನಾನು ಇದನ್ನು ಇನ್ನೂ ಮಾಡಲಾರೆ. ನಾನು ವಸ್ತುಗಳನ್ನು ಹುಡುಕಬಲ್ಲೆ, ನಿಮ್ಮ ಫೋನ್ ರಿಂಗ್ ಮಾಡಬಲ್ಲೆ, ಬ್ಯಾಟರಿ ಅಥವಾ ಸಮಯ ಹೇಳಬಲ್ಲೆ.',
    AppLanguage.telugu =>
      'క్షమించండి, నేను ఇది ఇంకా చేయలేను. నేను వస్తువులను వెతకగలను, మీ ఫోన్ రింగ్ చేయగలను, బ్యాటరీ లేదా సమయం చెప్పగలను.',
    AppLanguage.tamil =>
      'மன்னிக்கவும், இதை என்னால் இன்னும் செய்ய முடியாது. பொருட்களைத் தேடலாம், உங்கள் போனை ஒலிக்கச் செய்யலாம், பேட்டரி அல்லது நேரத்தைச் சொல்லலாம்.',
  };

  String irisArmed(int minutes, AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
      'Iris is on. Say Hey Iris, or double-press Volume Up. It turns off in $minutes minutes.',
    AppLanguage.hindi =>
      'आइरिस चालू है। हे आइरिस कहें, या वॉल्यूम अप दो बार दबाएं। $minutes मिनट में बंद हो जाएगा।',
    AppLanguage.kannada =>
      'ಐರಿಸ್ ಆನ್ ಆಗಿದೆ. ಹೇ ಐರಿಸ್ ಎನ್ನಿ, ಅಥವಾ ವಾಲ್ಯೂಮ್ ಅಪ್ ಅನ್ನು ಎರಡು ಬಾರಿ ಒತ್ತಿ. $minutes ನಿಮಿಷಗಳಲ್ಲಿ ಆಫ್ ಆಗುತ್ತದೆ.',
    AppLanguage.telugu =>
      'ఐరిస్ ఆన్ అయింది. హే ఐరిస్ అనండి, లేదా వాల్యూమ్ అప్ రెండుసార్లు నొక్కండి. $minutes నిమిషాల్లో ఆఫ్ అవుతుంది.',
    AppLanguage.tamil =>
      'ஐரிஸ் இயக்கத்தில் உள்ளது. ஹே ஐரிஸ் என்று சொல்லுங்கள், அல்லது வால்யூம் அப்பை இரண்டு முறை அழுத்துங்கள். $minutes நிமிடங்களில் அணைந்துவிடும்.',
  };

  String irisDisarmed(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Iris is off. The microphone is off.',
    AppLanguage.hindi => 'आइरिस बंद है। माइक्रोफ़ोन बंद है।',
    AppLanguage.kannada => 'ಐರಿಸ್ ಆಫ್ ಆಗಿದೆ. ಮೈಕ್ರೋಫೋನ್ ಆಫ್ ಆಗಿದೆ.',
    AppLanguage.telugu => 'ఐరిస్ ఆఫ్ అయింది. మైక్రోఫోన్ ఆఫ్ అయింది.',
    AppLanguage.tamil => 'ஐரிஸ் அணைக்கப்பட்டது. மைக்ரோஃபோன் அணைக்கப்பட்டது.',
  };

  String irisNotificationText(int minutes, AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
      'Say "Hey Iris", double-press Volume Up, or tap Talk to Iris. Auto-off in $minutes min.',
    AppLanguage.hindi =>
      '"हे आइरिस" कहें, वॉल्यूम अप दो बार दबाएं, या आइरिस से बात करें दबाएं। $minutes मिनट में अपने-आप बंद।',
    AppLanguage.kannada =>
      '"ಹೇ ಐರಿಸ್" ಎನ್ನಿ, ವಾಲ್ಯೂಮ್ ಅಪ್ ಎರಡು ಬಾರಿ ಒತ್ತಿ, ಅಥವಾ ಐರಿಸ್ ಜೊತೆ ಮಾತನಾಡಿ ಒತ್ತಿ. $minutes ನಿಮಿಷದಲ್ಲಿ ತಾನಾಗಿ ಆಫ್.',
    AppLanguage.telugu =>
      '"హే ఐరిస్" అనండి, వాల్యూమ్ అప్ రెండుసార్లు నొక్కండి, లేదా ఐరిస్‌తో మాట్లాడండి నొక్కండి. $minutes నిమిషాల్లో ఆటో-ఆఫ్.',
    AppLanguage.tamil =>
      '"ஹே ஐரிஸ்" என்று சொல்லுங்கள், வால்யூம் அப்பை இரண்டு முறை அழுத்துங்கள், அல்லது ஐரிஸுடன் பேசுங்கள் அழுத்துங்கள். $minutes நிமிடத்தில் தானாக அணையும்.',
  };

  String talkToIris(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Talk to Iris',
    AppLanguage.hindi => 'आइरिस से बात करें',
    AppLanguage.kannada => 'ಐರಿಸ್ ಜೊತೆ ಮಾತನಾಡಿ',
    AppLanguage.telugu => 'ఐరిస్‌తో మాట్లాడండి',
    AppLanguage.tamil => 'ஐரிஸுடன் பேசுங்கள்',
  };

  String irisStatusOn(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'IRIS IS ON',
    AppLanguage.hindi => 'आइरिस चालू है',
    AppLanguage.kannada => 'ಐರಿಸ್ ಆನ್ ಆಗಿದೆ',
    AppLanguage.telugu => 'ఐరిస్ ఆన్‌లో ఉంది',
    AppLanguage.tamil => 'ஐரிஸ் இயக்கத்தில் உள்ளது',
  };

  String irisStatusOff(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'IRIS IS OFF',
    AppLanguage.hindi => 'आइरिस बंद है',
    AppLanguage.kannada => 'ಐರಿಸ್ ಆಫ್ ಆಗಿದೆ',
    AppLanguage.telugu => 'ఐరిస్ ఆఫ్‌లో ఉంది',
    AppLanguage.tamil => 'ஐரிஸ் அணைந்துள்ளது',
  };

  String batteryLevel(int percent, AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'Battery is at $percent percent.',
    AppLanguage.hindi => 'बैटरी $percent प्रतिशत है।',
    AppLanguage.kannada => 'ಬ್ಯಾಟರಿ ಶೇಕಡಾ $percent ಇದೆ.',
    AppLanguage.telugu => 'బ్యాటరీ $percent శాతం ఉంది.',
    AppLanguage.tamil => 'பேட்டரி $percent சதவீதம் உள்ளது.',
  };

  String batteryUnavailable(AppLanguage lang) => switch (lang) {
    AppLanguage.english => "I couldn't read the battery level.",
    AppLanguage.hindi => 'मैं बैटरी का स्तर नहीं पढ़ सका।',
    AppLanguage.kannada => 'ನನಗೆ ಬ್ಯಾಟರಿ ಮಟ್ಟ ಓದಲಾಗಲಿಲ್ಲ.',
    AppLanguage.telugu => 'నేను బ్యాటరీ స్థాయిని చదవలేకపోయాను.',
    AppLanguage.tamil => 'பேட்டரி அளவை என்னால் படிக்க முடியவில்லை.',
  };

  String timeIs(DateTime now, AppLanguage lang) {
    final t = spokenTime(now, lang);
    return switch (lang) {
      AppLanguage.english => 'The time is $t.',
      AppLanguage.hindi => 'समय $t है।',
      AppLanguage.kannada => 'ಸಮಯ $t.',
      AppLanguage.telugu => 'సమయం $t.',
      AppLanguage.tamil => 'நேரம் $t.',
    };
  }

  /// English uses 12-hour with AM/PM; other languages use 24-hour numerals,
  /// which every Indian-language TTS voice reads reliably.
  String spokenTime(DateTime now, AppLanguage lang) {
    final mm = now.minute.toString().padLeft(2, '0');
    if (lang == AppLanguage.english) {
      final h12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
      return '$h12:$mm ${now.hour < 12 ? 'AM' : 'PM'}';
    }
    return '${now.hour}:$mm';
  }

  String noAlarmRinging(AppLanguage lang) => switch (lang) {
    AppLanguage.english => 'No alarm is ringing right now.',
    AppLanguage.hindi => 'अभी कोई अलार्म नहीं बज रहा।',
    AppLanguage.kannada => 'ಈಗ ಯಾವುದೇ ಅಲಾರಂ ಮೊಳಗುತ್ತಿಲ್ಲ.',
    AppLanguage.telugu => 'ఇప్పుడు ఏ అలారం మోగడం లేదు.',
    AppLanguage.tamil => 'இப்போது எந்த அலாரமும் ஒலிக்கவில்லை.',
  };

  String surroundingsUnavailable(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
      'Describing your surroundings is not available yet. I can find a specific object for you.',
    AppLanguage.hindi =>
      'आस-पास का वर्णन अभी उपलब्ध नहीं है। मैं कोई खास वस्तु ढूंढ सकता हूँ।',
    AppLanguage.kannada =>
      'ಸುತ್ತಮುತ್ತಲಿನ ವಿವರಣೆ ಇನ್ನೂ ಲಭ್ಯವಿಲ್ಲ. ನಾನು ಒಂದು ನಿರ್ದಿಷ್ಟ ವಸ್ತುವನ್ನು ಹುಡುಕಬಲ್ಲೆ.',
    AppLanguage.telugu =>
      'పరిసరాల వివరణ ఇంకా అందుబాటులో లేదు. నేను ఒక నిర్దిష్ట వస్తువును వెతకగలను.',
    AppLanguage.tamil =>
      'சுற்றுப்புற விவரிப்பு இன்னும் கிடைக்கவில்லை. ஒரு குறிப்பிட்ட பொருளை நான் தேடித் தர முடியும்.',
  };

  // ---- Iris hands-free trigger (long press, screen wake) ----
  String handsFreeTitle(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Hands-free trigger',
    AppLanguage.hindi =>
        'हैंड्स-फ़्री ट्रिगर',
    AppLanguage.kannada =>
        'ಹ್ಯಾಂಡ್ಸ್-ಫ್ರೀ ಟ್ರಿಗರ್',
    AppLanguage.telugu =>
        'హ్యాండ్స్-ఫ్రీ ట్రిగ్గర్',
    AppLanguage.tamil =>
        'கைகள் இல்லா தூண்டுதல்',
  };

  String handsFreeExplain(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Hold Volume Up for about one second to wake Iris, even when the screen is off. This needs the FindIt Iris trigger turned on in Accessibility settings. It only detects a long press of Volume Up. It does not read your screen, and nothing is stored or sent.',
    AppLanguage.hindi =>
        'स्क्रीन बंद होने पर भी आइरिस को जगाने के लिए वॉल्यूम अप को लगभग एक सेकंड दबाए रखें। इसके लिए एक्सेसिबिलिटी सेटिंग्स में FindIt आइरिस ट्रिगर चालू होना चाहिए। यह केवल वॉल्यूम अप का लंबा दबाव पहचानता है। यह आपकी स्क्रीन नहीं पढ़ता, और कुछ भी सहेजा या भेजा नहीं जाता।',
    AppLanguage.kannada =>
        'ಪರದೆ ಆಫ್ ಆಗಿದ್ದರೂ ಐರಿಸ್ ಅನ್ನು ಎಬ್ಬಿಸಲು ವಾಲ್ಯೂಮ್ ಅಪ್ ಅನ್ನು ಸುಮಾರು ಒಂದು ಸೆಕೆಂಡ್ ಒತ್ತಿ ಹಿಡಿಯಿರಿ. ಇದಕ್ಕೆ ಪ್ರವೇಶಸಾಧ್ಯತೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ FindIt ಐರಿಸ್ ಟ್ರಿಗರ್ ಆನ್ ಆಗಿರಬೇಕು. ಇದು ವಾಲ್ಯೂಮ್ ಅಪ್‌ನ ದೀರ್ಘ ಒತ್ತುವಿಕೆಯನ್ನು ಮಾತ್ರ ಗುರುತಿಸುತ್ತದೆ. ಇದು ನಿಮ್ಮ ಪರದೆಯನ್ನು ಓದುವುದಿಲ್ಲ, ಮತ್ತು ಏನನ್ನೂ ಉಳಿಸಲಾಗುವುದಿಲ್ಲ ಅಥವಾ ಕಳುಹಿಸಲಾಗುವುದಿಲ್ಲ.',
    AppLanguage.telugu =>
        'స్క్రీన్ ఆఫ్‌లో ఉన్నా ఐరిస్‌ను మేల్కొలపడానికి వాల్యూమ్ అప్‌ను సుమారు ఒక సెకను నొక్కి ఉంచండి. దీనికి యాక్సెసిబిలిటీ సెట్టింగ్‌లలో FindIt ఐరిస్ ట్రిగ్గర్ ఆన్‌లో ఉండాలి. ఇది వాల్యూమ్ అప్ ఎక్కువసేపు నొక్కడాన్ని మాత్రమే గుర్తిస్తుంది. ఇది మీ స్క్రీన్‌ను చదవదు, ఏదీ నిల్వ చేయబడదు లేదా పంపబడదు.',
    AppLanguage.tamil =>
        'திரை அணைந்திருந்தாலும் ஐரிஸை எழுப்ப வால்யூம் அப்பை சுமார் ஒரு வினாடி அழுத்திப் பிடியுங்கள். இதற்கு அணுகல்தன்மை அமைப்புகளில் FindIt ஐரிஸ் தூண்டுதல் இயக்கப்பட்டிருக்க வேண்டும். இது வால்யூம் அப்பின் நீண்ட அழுத்தத்தை மட்டுமே கண்டறியும். இது உங்கள் திரையைப் படிக்காது, எதுவும் சேமிக்கப்படாது அல்லது அனுப்பப்படாது.',
  };

  String accessibilityStatusOn(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Accessibility trigger: ON',
    AppLanguage.hindi =>
        'एक्सेसिबिलिटी ट्रिगर: चालू',
    AppLanguage.kannada =>
        'ಪ್ರವೇಶಸಾಧ್ಯತೆ ಟ್ರಿಗರ್: ಆನ್',
    AppLanguage.telugu =>
        'యాక్సెసిబిలిటీ ట్రిగ్గర్: ఆన్',
    AppLanguage.tamil =>
        'அணுகல்தன்மை தூண்டுதல்: இயக்கத்தில்',
  };

  String accessibilityStatusOff(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Accessibility trigger: OFF',
    AppLanguage.hindi =>
        'एक्सेसिबिलिटी ट्रिगर: बंद',
    AppLanguage.kannada =>
        'ಪ್ರವೇಶಸಾಧ್ಯತೆ ಟ್ರಿಗರ್: ಆಫ್',
    AppLanguage.telugu =>
        'యాక్సెసిబిలిటీ ట్రిగ్గర్: ఆఫ్',
    AppLanguage.tamil =>
        'அணுகல்தன்மை தூண்டுதல்: அணைந்துள்ளது',
  };

  String screenWakeStatusOn(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Screen wake over lock screen: allowed',
    AppLanguage.hindi =>
        'लॉक स्क्रीन पर स्क्रीन जगाना: अनुमति है',
    AppLanguage.kannada =>
        'ಲಾಕ್ ಸ್ಕ್ರೀನ್ ಮೇಲೆ ಪರದೆ ಎಬ್ಬಿಸುವುದು: ಅನುಮತಿಸಲಾಗಿದೆ',
    AppLanguage.telugu =>
        'లాక్ స్క్రీన్‌పై స్క్రీన్ ఆన్ చేయడం: అనుమతించబడింది',
    AppLanguage.tamil =>
        'பூட்டுத் திரையில் திரையை எழுப்புதல்: அனுமதிக்கப்பட்டது',
  };

  String screenWakeStatusOff(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Screen wake over lock screen: not allowed',
    AppLanguage.hindi =>
        'लॉक स्क्रीन पर स्क्रीन जगाना: अनुमति नहीं है',
    AppLanguage.kannada =>
        'ಲಾಕ್ ಸ್ಕ್ರೀನ್ ಮೇಲೆ ಪರದೆ ಎಬ್ಬಿಸುವುದು: ಅನುಮತಿ ಇಲ್ಲ',
    AppLanguage.telugu =>
        'లాక్ స్క్రీన్‌పై స్క్రీన్ ఆన్ చేయడం: అనుమతి లేదు',
    AppLanguage.tamil =>
        'பூட்டுத் திரையில் திரையை எழுப்புதல்: அனுமதி இல்லை',
  };

  String openAccessibilitySettings(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Open Accessibility settings',
    AppLanguage.hindi =>
        'एक्सेसिबिलिटी सेटिंग्स खोलें',
    AppLanguage.kannada =>
        'ಪ್ರವೇಶಸಾಧ್ಯತೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ',
    AppLanguage.telugu =>
        'యాక్సెసిబిలిటీ సెట్టింగ్‌లను తెరవండి',
    AppLanguage.tamil =>
        'அணுகல்தன்மை அமைப்புகளைத் திறக்கவும்',
  };

  String allowScreenWake(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Allow screen wake',
    AppLanguage.hindi =>
        'स्क्रीन जगाने की अनुमति दें',
    AppLanguage.kannada =>
        'ಪರದೆ ಎಬ್ಬಿಸಲು ಅನುಮತಿಸಿ',
    AppLanguage.telugu =>
        'స్క్రీన్ ఆన్ చేయడానికి అనుమతించండి',
    AppLanguage.tamil =>
        'திரையை எழுப்ப அனுமதிக்கவும்',
  };

  String longPressNeedsAccessibility(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Long press needs Accessibility turned on.',
    AppLanguage.hindi =>
        'देर तक दबाने के लिए एक्सेसिबिलिटी चालू करना ज़रूरी है।',
    AppLanguage.kannada =>
        'ದೀರ್ಘ ಒತ್ತುವಿಕೆಗೆ ಪ್ರವೇಶಸಾಧ್ಯತೆ ಆನ್ ಆಗಿರಬೇಕು.',
    AppLanguage.telugu =>
        'ఎక్కువసేపు నొక్కడానికి యాక్సెసిబిలిటీ ఆన్‌లో ఉండాలి.',
    AppLanguage.tamil =>
        'நீண்ட அழுத்தத்திற்கு அணுகல்தன்மை இயக்கப்பட்டிருக்க வேண்டும்.',
  };

  String screenWakeNeedsPermission(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Iris cannot turn the screen on until you allow full-screen notifications.',
    AppLanguage.hindi =>
        'जब तक आप फ़ुल-स्क्रीन नोटिफ़िकेशन की अनुमति नहीं देते, आइरिस स्क्रीन चालू नहीं कर सकता।',
    AppLanguage.kannada =>
        'ಪೂರ್ಣ-ಪರದೆ ಅಧಿಸೂಚನೆಗಳನ್ನು ನೀವು ಅನುಮತಿಸುವವರೆಗೆ ಐರಿಸ್ ಪರದೆಯನ್ನು ಆನ್ ಮಾಡಲಾರದು.',
    AppLanguage.telugu =>
        'మీరు ఫుల్-స్క్రీన్ నోటిఫికేషన్‌లను అనుమతించే వరకు ఐరిస్ స్క్రీన్‌ను ఆన్ చేయలేదు.',
    AppLanguage.tamil =>
        'முழுத்திரை அறிவிப்புகளை நீங்கள் அனுமதிக்கும் வரை ஐரிஸ் திரையை இயக்க முடியாது.',
  };

  String handsFreeGuide(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'To use Iris with the screen off: first, turn on FindIt Iris trigger in Accessibility settings. Second, allow full-screen notifications. You can skip this and set it up later.',
    AppLanguage.hindi =>
        'स्क्रीन बंद होने पर आइरिस का उपयोग करने के लिए: पहले, एक्सेसिबिलिटी सेटिंग्स में FindIt आइरिस ट्रिगर चालू करें। दूसरा, फ़ुल-स्क्रीन नोटिफ़िकेशन की अनुमति दें। आप इसे छोड़कर बाद में भी कर सकते हैं।',
    AppLanguage.kannada =>
        'ಪರದೆ ಆಫ್ ಆಗಿರುವಾಗ ಐರಿಸ್ ಬಳಸಲು: ಮೊದಲು, ಪ್ರವೇಶಸಾಧ್ಯತೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ FindIt ಐರಿಸ್ ಟ್ರಿಗರ್ ಆನ್ ಮಾಡಿ. ಎರಡನೆಯದಾಗಿ, ಪೂರ್ಣ-ಪರದೆ ಅಧಿಸೂಚನೆಗಳನ್ನು ಅನುಮತಿಸಿ. ನೀವು ಇದನ್ನು ಬಿಟ್ಟು ನಂತರ ಹೊಂದಿಸಬಹುದು.',
    AppLanguage.telugu =>
        'స్క్రీన్ ఆఫ్‌లో ఐరిస్ వాడటానికి: మొదట, యాక్సెసిబిలిటీ సెట్టింగ్‌లలో FindIt ఐరిస్ ట్రిగ్గర్ ఆన్ చేయండి. రెండవది, ఫుల్-స్క్రీన్ నోటిఫికేషన్‌లను అనుమతించండి. మీరు దీన్ని వదిలేసి తర్వాత సెట్ చేసుకోవచ్చు.',
    AppLanguage.tamil =>
        'திரை அணைந்திருக்கும்போது ஐரிஸைப் பயன்படுத்த: முதலில், அணுகல்தன்மை அமைப்புகளில் FindIt ஐரிஸ் தூண்டுதலை இயக்குங்கள். இரண்டாவது, முழுத்திரை அறிவிப்புகளை அனுமதியுங்கள். இதைத் தவிர்த்து பின்னர் அமைக்கலாம்.',
  };

  String skipForNow(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Skip for now',
    AppLanguage.hindi =>
        'अभी छोड़ें',
    AppLanguage.kannada =>
        'ಈಗ ಬಿಡಿ',
    AppLanguage.telugu =>
        'ఇప్పుడు వదిలేయండి',
    AppLanguage.tamil =>
        'இப்போது தவிர்க்கவும்',
  };

  String hearExplanation(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Hear explanation',
    AppLanguage.hindi =>
        'समझाइश सुनें',
    AppLanguage.kannada =>
        'ವಿವರಣೆ ಕೇಳಿ',
    AppLanguage.telugu =>
        'వివరణ వినండి',
    AppLanguage.tamil =>
        'விளக்கத்தைக் கேளுங்கள்',
  };

  String irisListeningTitle(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Iris is listening',
    AppLanguage.hindi =>
        'आइरिस सुन रहा है',
    AppLanguage.kannada =>
        'ಐರಿಸ್ ಕೇಳುತ್ತಿದೆ',
    AppLanguage.telugu =>
        'ఐరిస్ వింటోంది',
    AppLanguage.tamil =>
        'ஐரிஸ் கேட்கிறது',
  };

  String fsiNotifTitle(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Iris needs permission to wake the screen',
    AppLanguage.hindi =>
        'स्क्रीन जगाने के लिए आइरिस को अनुमति चाहिए',
    AppLanguage.kannada =>
        'ಪರದೆ ಎಬ್ಬಿಸಲು ಐರಿಸ್‌ಗೆ ಅನುಮತಿ ಬೇಕು',
    AppLanguage.telugu =>
        'స్క్రీన్ ఆన్ చేయడానికి ఐరిస్‌కు అనుమతి కావాలి',
    AppLanguage.tamil =>
        'திரையை எழுப்ப ஐரிஸுக்கு அனுமதி தேவை',
  };

  String fsiNotifText(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Allow full-screen notifications for FindIt so Iris can turn the screen on.',
    AppLanguage.hindi =>
        'FindIt के लिए फ़ुल-स्क्रीन नोटिफ़िकेशन की अनुमति दें ताकि आइरिस स्क्रीन चालू कर सके।',
    AppLanguage.kannada =>
        'ಐರಿಸ್ ಪರದೆ ಆನ್ ಮಾಡಲು FindIt ಗಾಗಿ ಪೂರ್ಣ-ಪರದೆ ಅಧಿಸೂಚನೆಗಳನ್ನು ಅನುಮತಿಸಿ.',
    AppLanguage.telugu =>
        'ఐరిస్ స్క్రీన్ ఆన్ చేయడానికి FindIt కోసం ఫుల్-స్క్రీన్ నోటిఫికేషన్‌లను అనుమతించండి.',
    AppLanguage.tamil =>
        'ஐரிஸ் திரையை இயக்க FindIt க்கான முழுத்திரை அறிவிப்புகளை அனுமதியுங்கள்.',
  };

  // ---- Startup robustness (camera, model, permission) ----
  String cameraPermissionNeeded(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'FindIt needs camera permission to find objects. Allow it to continue.',
    AppLanguage.hindi =>
        'वस्तुएँ खोजने के लिए FindIt को कैमरे की अनुमति चाहिए। जारी रखने के लिए इसे अनुमति दें।',
    AppLanguage.kannada =>
        'ವಸ್ತುಗಳನ್ನು ಹುಡುಕಲು FindIt ಗೆ ಕ್ಯಾಮೆರಾ ಅನುಮತಿ ಬೇಕು. ಮುಂದುವರಿಯಲು ಅದನ್ನು ಅನುಮತಿಸಿ.',
    AppLanguage.telugu =>
        'వస్తువులను వెతకడానికి FindIt కు కెమెరా అనుమతి కావాలి. కొనసాగించడానికి అనుమతించండి.',
    AppLanguage.tamil =>
        'பொருட்களைத் தேட FindIt க்கு கேமரா அனுமதி தேவை. தொடர அனுமதியுங்கள்.',
  };

  String cameraPermissionBlocked(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Camera permission is turned off for FindIt. Open app settings and allow the camera.',
    AppLanguage.hindi =>
        'FindIt के लिए कैमरे की अनुमति बंद है। ऐप सेटिंग्स खोलकर कैमरा अनुमति दें।',
    AppLanguage.kannada =>
        'FindIt ಗಾಗಿ ಕ್ಯಾಮೆರಾ ಅನುಮತಿ ಆಫ್ ಆಗಿದೆ. ಅಪ್ಲಿಕೇಶನ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆದು ಕ್ಯಾಮೆರಾ ಅನುಮತಿಸಿ.',
    AppLanguage.telugu =>
        'FindIt க்கான கேமரா அனுமதி அணைக்கப்பட்டுள்ளது. ஆப் அமைப்புகளைத் திறந்து கேமராவை அனுமதியுங்கள்.',
    AppLanguage.tamil =>
        'FindIt కోసం కెమెరా అనుమతి ఆఫ్‌లో ఉంది. యాప్ సెట్టింగ్‌లు తెరిచి కెమెరాను అనుమతించండి.',
  };

  String noCameraFound(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'No camera was found on this phone, so FindIt cannot look for objects.',
    AppLanguage.hindi =>
        'इस फ़ोन में कोई कैमरा नहीं मिला, इसलिए FindIt वस्तुएँ नहीं खोज सकता।',
    AppLanguage.kannada =>
        'ಈ ಫೋನ್‌ನಲ್ಲಿ ಕ್ಯಾಮೆರಾ ಸಿಗಲಿಲ್ಲ, ಆದ್ದರಿಂದ FindIt ವಸ್ತುಗಳನ್ನು ಹುಡುಕಲಾರದು.',
    AppLanguage.telugu =>
        'ఈ ఫోన్‌లో కెమెరా కనిపించలేదు, కాబట్టి FindIt వస్తువులను వెతకలేదు.',
    AppLanguage.tamil =>
        'இந்த போனில் கேமரா இல்லை, எனவே FindIt பொருட்களைத் தேட முடியாது.',
  };

  String cameraStartFailed(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'The camera could not start. Close other camera apps and try again.',
    AppLanguage.hindi =>
        'कैमरा शुरू नहीं हो सका। दूसरे कैमरा ऐप बंद करके फिर से कोशिश करें।',
    AppLanguage.kannada =>
        'ಕ್ಯಾಮೆರಾ ಪ್ರಾರಂಭವಾಗಲಿಲ್ಲ. ಇತರ ಕ್ಯಾಮೆರಾ ಅಪ್ಲಿಕೇಶನ್‌ಗಳನ್ನು ಮುಚ್ಚಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
    AppLanguage.telugu =>
        'కెమెరా ప్రారంభం కాలేదు. ఇతర కెమెరా యాప్‌లను మూసివేసి మళ్లీ ప్రయత్నించండి.',
    AppLanguage.tamil =>
        'கேமரா தொடங்கவில்லை. மற்ற கேமரா ஆப்ஸை மூடிவிட்டு மீண்டும் முயலுங்கள்.',
  };

  String modelLoadFailed(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'The object detector could not load. Restart FindIt to try again.',
    AppLanguage.hindi =>
        'वस्तु पहचानने वाला मॉडल लोड नहीं हो सका। फिर से कोशिश करने के लिए FindIt दोबारा शुरू करें।',
    AppLanguage.kannada =>
        'ವಸ್ತು ಪತ್ತೆಕಾರಕ ಲೋಡ್ ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಲು FindIt ಅನ್ನು ಮರುಪ್ರಾರಂಭಿಸಿ.',
    AppLanguage.telugu =>
        'వస్తువు గుర్తింపు యంత్రం లోడ్ కాలేదు. మళ్లీ ప్రయత్నించడానికి FindIt ను పునఃప్రారంభించండి.',
    AppLanguage.tamil =>
        'பொருள் கண்டறியும் கருவி ஏற்றப்படவில்லை. மீண்டும் முயல FindIt ஐ மறுதொடக்கம் செய்யுங்கள்.',
  };

  String openAppSettings(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Open app settings',
    AppLanguage.hindi =>
        'ऐप सेटिंग्स खोलें',
    AppLanguage.kannada =>
        'ಅಪ್ಲಿಕೇಶನ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ',
    AppLanguage.telugu =>
        'యాప్ సెట్టింగ్‌లు తెరవండి',
    AppLanguage.tamil =>
        'ஆப் அமைப்புகளைத் திறக்கவும்',
  };

  String tryAgain(AppLanguage lang) => switch (lang) {
    AppLanguage.english =>
        'Try again',
    AppLanguage.hindi =>
        'फिर से कोशिश करें',
    AppLanguage.kannada =>
        'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
    AppLanguage.telugu =>
        'మళ్లీ ప్రయత్నించండి',
    AppLanguage.tamil =>
        'மீண்டும் முயலுங்கள்',
  };
}

// Display-time translation for Firestore content values.
// Does NOT modify Firestore documents — translates at render time only.
// DO NOT translate: farmer names, user names, phone numbers, emails, IDs.
class ContentTranslationService {
  ContentTranslationService._();

  // ── MACHINE TYPES ────────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _machineTypes = {
    'tractor': {
      'hi': 'ट्रैक्टर', 'kn': 'ಟ್ರ್ಯಾಕ್ಟರ್', 'ta': 'டிராக்டர்',
      'te': 'ట్రాక్టర్', 'mr': 'ट्रॅक्टर', 'ml': 'ട്രാക്ടർ',
    },
    'cultivator': {
      'hi': 'कल्टीवेटर', 'kn': 'ಕಲ್ಟಿವೇಟರ್', 'ta': 'கல்டிவேட்டர்',
      'te': 'కల్టివేటర్', 'mr': 'कल्टिव्हेटर', 'ml': 'കൾടിവേറ്റർ',
    },
    'harvester': {
      'hi': 'हार्वेस्टर', 'kn': 'ಹಾರ್ವೆಸ್ಟರ್', 'ta': 'அறுவடை இயந்திரம்',
      'te': 'హార్వెస్టర్', 'mr': 'हार्वेस्टर', 'ml': 'ഹാർവസ്റ്റർ',
    },
    'sprayer': {
      'hi': 'स्प्रेयर', 'kn': 'ಸ್ಪ್ರೇಯರ್', 'ta': 'தெளிப்பான்',
      'te': 'స్ప్రేయర్', 'mr': 'फवारणी यंत्र', 'ml': 'സ്പ്രേയർ',
    },
    'pump': {
      'hi': 'पंप', 'kn': 'ಪಂಪ್', 'ta': 'பம்ப்',
      'te': 'పంప్', 'mr': 'पंप', 'ml': 'പമ്പ്',
    },
    'thresher': {
      'hi': 'थ्रेशर', 'kn': 'ಥ್ರೆಷರ್', 'ta': 'நெற்கதிர் கதர்',
      'te': 'థ్రెషర్', 'mr': 'मळणी यंत्र', 'ml': 'തൽഷർ',
    },
    'seeder': {
      'hi': 'बीज बोने वाली मशीन', 'kn': 'ಬಿತ್ತನೆ ಯಂತ್ರ', 'ta': 'விதை விதைப்பான்',
      'te': 'సీడర్', 'mr': 'पेरणी यंत्र', 'ml': 'സീഡർ',
    },
    'plough': {
      'hi': 'हल', 'kn': 'ನೇಗಿಲು', 'ta': 'கலப்பை',
      'te': 'నాగలి', 'mr': 'नांगर', 'ml': 'കലപ്പ',
    },
    'tiller': {
      'hi': 'टिलर', 'kn': 'ಟಿಲ್ಲರ್', 'ta': 'டில்லர்',
      'te': 'టిల్లర్', 'mr': 'टिलर', 'ml': 'ടില്ലർ',
    },
    'sprinkler': {
      'hi': 'स्प्रिंकलर', 'kn': 'ಸ್ಪ್ರಿಂಕ್ಲರ್', 'ta': 'தெளிப்பி',
      'te': 'స్ప్రింక్లర్', 'mr': 'स्प्रिंकलर', 'ml': 'സ്പ്രിൻക്ലർ',
    },
    'rotavator': {
      'hi': 'रोटावेटर', 'kn': 'ರೋಟಾವೇಟರ್', 'ta': 'ரோட்டவேட்டர்',
      'te': 'రోటావేటర్', 'mr': 'रोटाव्हेटर', 'ml': 'റോട്ടവേറ്റർ',
    },
    'transplanter': {
      'hi': 'ट्रांसप्लांटर', 'kn': 'ಟ್ರಾನ್ಸ್‌ಪ್ಲಾಂಟರ್', 'ta': 'நடவு இயந்திரம்',
      'te': 'ట్రాన్స్‌ప్లాంటర్', 'mr': 'लावणी यंत्र', 'ml': 'ട്രാൻസ്‌പ്ലാന്റർ',
    },
    'power tiller': {
      'hi': 'पावर टिलर', 'kn': 'ಪವರ್ ಟಿಲ್ಲರ್', 'ta': 'பவர் டில்லர்',
      'te': 'పవర్ టిల్లర్', 'mr': 'पॉवर टिलर', 'ml': 'പവർ ടില്ലർ',
    },
    'mini tractor': {
      'hi': 'मिनी ट्रैक्टर', 'kn': 'ಮಿನಿ ಟ್ರ್ಯಾಕ್ಟರ್', 'ta': 'மினி டிராக்டர்',
      'te': 'మినీ ట్రాక్టర్', 'mr': 'मिनी ट्रॅक्टर', 'ml': 'മിനി ട്രാക്ടർ',
    },
    'other': {
      'hi': 'अन्य', 'kn': 'ಇತರ', 'ta': 'மற்றவை',
      'te': 'ఇతర', 'mr': 'इतर', 'ml': 'മറ്റുള്ളവ',
    },
  };

  // ── CROP / EXPORT PRODUCT NAMES ──────────────────────────────────────────
  static const Map<String, Map<String, String>> _cropNames = {
    'coconut': {
      'hi': 'नारियल', 'kn': 'ತೆಂಗಿನಕಾಯಿ', 'ta': 'தேங்காய்',
      'te': 'కొబ్బరికాయ', 'mr': 'नारळ', 'ml': 'തേങ്ങ',
    },
    'semi husked coconut': {
      'hi': 'अर्ध छिलके वाला नारियल', 'kn': 'ಅರ್ಧ ಸಿಪ್ಪೆ ತೆಂಗಿನಕಾಯಿ',
      'ta': 'அரை நீக்கப்பட்ட தேங்காய்', 'te': 'సగం పీచు కొబ్బరికాయ',
      'mr': 'अर्ध सोललेला नारळ', 'ml': 'അർദ്ധ ചകിരി തേങ്ങ',
    },
    'paddy': {
      'hi': 'धान', 'kn': 'ಭತ್ತ', 'ta': 'நெல்',
      'te': 'వరి', 'mr': 'भात', 'ml': 'നെൽ',
    },
    'rice': {
      'hi': 'चावल', 'kn': 'ಅಕ್ಕಿ', 'ta': 'அரிசி',
      'te': 'బియ్యం', 'mr': 'तांदूळ', 'ml': 'അരി',
    },
    'wheat': {
      'hi': 'गेहूं', 'kn': 'ಗೋಧಿ', 'ta': 'கோதுமை',
      'te': 'గోధుమ', 'mr': 'गहू', 'ml': 'ഗോതമ്പ്',
    },
    'sugarcane': {
      'hi': 'गन्ना', 'kn': 'ಕಬ್ಬು', 'ta': 'கரும்பு',
      'te': 'చెరకు', 'mr': 'ऊस', 'ml': 'കരിമ്പ്',
    },
    'cotton': {
      'hi': 'कपास', 'kn': 'ಹತ್ತಿ', 'ta': 'பருத்தி',
      'te': 'పత్తి', 'mr': 'कापूस', 'ml': 'പരുത്തി',
    },
    'groundnut': {
      'hi': 'मूंगफली', 'kn': 'ಕಡಲೆಕಾಯಿ', 'ta': 'கடலை',
      'te': 'వేరుసెనగ', 'mr': 'शेंगदाणे', 'ml': 'നിലക്കടല',
    },
    'soybean': {
      'hi': 'सोयाबीन', 'kn': 'ಸೋಯಾಬೀನ್', 'ta': 'சோயாபீன்',
      'te': 'సోయాబీన్', 'mr': 'सोयाबीन', 'ml': 'സോയാബീൻ',
    },
    'tomato': {
      'hi': 'टमाटर', 'kn': 'ಟೊಮೇಟೊ', 'ta': 'தக்காளி',
      'te': 'టమాటా', 'mr': 'टोमॅटो', 'ml': 'തക്കാളി',
    },
    'onion': {
      'hi': 'प्याज', 'kn': 'ಈರುಳ್ಳಿ', 'ta': 'வெங்காயம்',
      'te': 'ఉల్లిపాయ', 'mr': 'कांदा', 'ml': 'ഉള്ളി',
    },
    'potato': {
      'hi': 'आलू', 'kn': 'ಆಲೂಗಡ್ಡೆ', 'ta': 'உருளைக்கிழங்கு',
      'te': 'బంగాళదుంప', 'mr': 'बटाटा', 'ml': 'ഉരുളക്കിഴങ്ങ്',
    },
    'banana': {
      'hi': 'केला', 'kn': 'ಬಾಳೆಹಣ್ಣು', 'ta': 'வாழைப்பழம்',
      'te': 'అరటిపండు', 'mr': 'केळी', 'ml': 'വാഴപ്പഴം',
    },
    'mango': {
      'hi': 'आम', 'kn': 'ಮಾವಿನಹಣ್ಣು', 'ta': 'மாம்பழம்',
      'te': 'మామిడిపండు', 'mr': 'आंबा', 'ml': 'മാമ്പഴം',
    },
    'pepper': {
      'hi': 'काली मिर्च', 'kn': 'ಮೆಣಸು', 'ta': 'மிளகு',
      'te': 'మిరియాలు', 'mr': 'मिरी', 'ml': 'കുരുമുളക്',
    },
    'coffee': {
      'hi': 'कॉफी', 'kn': 'ಕಾಫಿ', 'ta': 'காபி',
      'te': 'కాఫీ', 'mr': 'कॉफी', 'ml': 'കാപ്പി',
    },
    'turmeric': {
      'hi': 'हल्दी', 'kn': 'ಅರಿಶಿನ', 'ta': 'மஞ்சள்',
      'te': 'పసుపు', 'mr': 'हळद', 'ml': 'മഞ്ഞൾ',
    },
    'ginger': {
      'hi': 'अदरक', 'kn': 'ಶುಂಠಿ', 'ta': 'இஞ்சி',
      'te': 'అల్లం', 'mr': 'आले', 'ml': 'ഇഞ്ചി',
    },
    'cardamom': {
      'hi': 'इलायची', 'kn': 'ಏಲಕ್ಕಿ', 'ta': 'ஏலக்காய்',
      'te': 'ఏలకులు', 'mr': 'वेलची', 'ml': 'ഏലം',
    },
    'arecanut': {
      'hi': 'सुपारी', 'kn': 'ಅಡಿಕೆ', 'ta': 'பாக்கு',
      'te': 'పోక', 'mr': 'सुपारी', 'ml': 'അടക്ക',
    },
    'maize': {
      'hi': 'मक्का', 'kn': 'ಮೆಕ್ಕೆಜೋಳ', 'ta': 'மக்காச்சோளம்',
      'te': 'మొక్కజొన్న', 'mr': 'मका', 'ml': 'ചോളം',
    },
    'jowar': {
      'hi': 'ज्वार', 'kn': 'ಜೋಳ', 'ta': 'சோளம்',
      'te': 'జొన్న', 'mr': 'ज्वारी', 'ml': 'ജോവർ',
    },
    'ragi': {
      'hi': 'रागी', 'kn': 'ರಾಗಿ', 'ta': 'கேழ்வரகு',
      'te': 'రాగి', 'mr': 'नाचणी', 'ml': 'റാഗി',
    },
  };

  // ── PLANT CATEGORIES ─────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _plantCategories = {
    'flowering': {
      'hi': 'फूलदार पौधे', 'kn': 'ಹೂವಿನ ಗಿಡ', 'ta': 'பூக்கும் தாவரம்',
      'te': 'పుష్ప మొక్కలు', 'mr': 'फुलझाडे', 'ml': 'പൂച്ചെടികൾ',
    },
    'fruit': {
      'hi': 'फलदार पौधे', 'kn': 'ಹಣ್ಣಿನ ಗಿಡ', 'ta': 'பழ மரம்',
      'te': 'పండ్ల మొక్కలు', 'mr': 'फळझाडे', 'ml': 'പഴ ചെടികൾ',
    },
    'medicinal': {
      'hi': 'औषधीय पौधे', 'kn': 'ಔಷಧೀಯ ಗಿಡ', 'ta': 'மருத்துவ தாவரம்',
      'te': 'ఔషధ మొక్కలు', 'mr': 'औषधी वनस्पती', 'ml': 'ഔഷധ സസ്യങ്ങൾ',
    },
    'vegetable': {
      'hi': 'सब्जी पौधे', 'kn': 'ತರಕಾರಿ ಗಿಡ', 'ta': 'காய்கறி செடி',
      'te': 'కూరగాయ మొక్కలు', 'mr': 'भाजीपाला', 'ml': 'പച്ചക്കറി ചെടികൾ',
    },
    'ornamental': {
      'hi': 'सजावटी पौधे', 'kn': 'ಅಲಂಕಾರಿಕ ಗಿಡ', 'ta': 'அலங்கார தாவரம்',
      'te': 'అలంకార మొక్కలు', 'mr': 'सजावटीची झाडे', 'ml': 'അലങ്കാര സസ്യങ്ങൾ',
    },
    'timber': {
      'hi': 'लकड़ी के पेड़', 'kn': 'ಮರದ ಗಿಡ', 'ta': 'மரம்',
      'te': 'కలప చెట్లు', 'mr': 'लाकडी झाडे', 'ml': 'തടി മരങ്ങൾ',
    },
    'aromatic': {
      'hi': 'सुगंधित पौधे', 'kn': 'ಸುಗಂಧ ಗಿಡ', 'ta': 'நறுமண தாவரம்',
      'te': 'సుగంధ మొక్కలు', 'mr': 'सुगंधी वनस्पती', 'ml': 'സുഗന്ധ സസ്യങ്ങൾ',
    },
  };

  // ── LABOUR CATEGORIES / SKILLS ───────────────────────────────────────────
  static const Map<String, Map<String, String>> _labourCategories = {
    'harvesting': {
      'hi': 'कटाई', 'kn': 'ಕೊಯ್ಲು', 'ta': 'அறுவடை',
      'te': 'కోత', 'mr': 'कापणी', 'ml': 'കൊയ്ത്ത്',
    },
    'planting': {
      'hi': 'रोपण', 'kn': 'ನಾಟಿ', 'ta': 'நடவு',
      'te': 'నాట్లు', 'mr': 'लागवड', 'ml': 'നടീൽ',
    },
    'irrigation': {
      'hi': 'सिंचाई', 'kn': 'ನೀರಾವರಿ', 'ta': 'நீர்பாசனம்',
      'te': 'నీటిపారుదల', 'mr': 'सिंचन', 'ml': 'ജലസേചനം',
    },
    'spraying': {
      'hi': 'छिड़काव', 'kn': 'ಸಿಂಪಡಿಸುವಿಕೆ', 'ta': 'தெளித்தல்',
      'te': 'పిచికారీ', 'mr': 'फवारणी', 'ml': 'തളിക്കൽ',
    },
    'weeding': {
      'hi': 'निराई', 'kn': 'ಕಳೆ ತೆಗೆಯುವಿಕೆ', 'ta': 'களை எடுத்தல்',
      'te': 'కలుపు తీయడం', 'mr': 'खुरपणी', 'ml': 'കളപ്പറിക്കൽ',
    },
    'pruning': {
      'hi': 'छंटाई', 'kn': 'ಕತ್ತರಿಸುವಿಕೆ', 'ta': 'கத்தரித்தல்',
      'te': 'కత్తిరింపు', 'mr': 'छाटणी', 'ml': 'കൊമ്പ് മുറിക്കൽ',
    },
    'loading': {
      'hi': 'लोडिंग', 'kn': 'ಲೋಡಿಂಗ್', 'ta': 'ஏற்றுதல்',
      'te': 'లోడింగ్', 'mr': 'लोडिंग', 'ml': 'ലോഡിംഗ്',
    },
    'transport': {
      'hi': 'परिवहन', 'kn': 'ಸಾರಿಗೆ', 'ta': 'போக்குவரத்து',
      'te': 'రవాణా', 'mr': 'वाहतूक', 'ml': 'ഗതാഗതം',
    },
    'farm labour': {
      'hi': 'खेत मजदूर', 'kn': 'ಕೃಷಿ ಕೂಲಿ', 'ta': 'விவசாய கூலி',
      'te': 'వ్యవసాయ కూలి', 'mr': 'शेत मजूर', 'ml': 'കർഷക തൊഴിലാളി',
    },
    'tractor driver': {
      'hi': 'ट्रैक्टर चालक', 'kn': 'ಟ್ರ್ಯಾಕ್ಟರ್ ಚಾಲಕ', 'ta': 'டிராக்டர் ஓட்டுனர்',
      'te': 'ట్రాక్టర్ డ్రైవర్', 'mr': 'ट्रॅक्टर चालक', 'ml': 'ട്രാക്ടർ ഡ്രൈവർ',
    },
    'general labour': {
      'hi': 'सामान्य मजदूर', 'kn': 'ಸಾಮಾನ್ಯ ಕೂಲಿ', 'ta': 'பொது கூலி',
      'te': 'సాధారణ కూలి', 'mr': 'सामान्य मजूर', 'ml': 'പൊതു തൊഴിലാളി',
    },
    'skilled labour': {
      'hi': 'कुशल मजदूर', 'kn': 'ಕುಶಲ ಕೂಲಿ', 'ta': 'திறமையான கூலி',
      'te': 'నిపుణ కూలి', 'mr': 'कुशल मजूर', 'ml': 'നൈപുണ്യ തൊഴിലാളി',
    },
  };

  // ── WAGE TYPE ────────────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _wageTypes = {
    'per day': {
      'hi': 'प्रति दिन', 'kn': 'ಪ್ರತಿ ದಿನ', 'ta': 'நாளுக்கு',
      'te': 'రోజుకు', 'mr': 'दररोज', 'ml': 'ദിവസം',
    },
    'per acre': {
      'hi': 'प्रति एकड़', 'kn': 'ಪ್ರತಿ ಎಕರೆ', 'ta': 'ஒரு ஏக்கருக்கு',
      'te': 'ఎకరాకు', 'mr': 'एकरी', 'ml': 'ഒരു ഏക്കറിന്',
    },
    'per hour': {
      'hi': 'प्रति घंटा', 'kn': 'ಪ್ರತಿ ಗಂಟೆ', 'ta': 'மணிக்கு',
      'te': 'గంటకు', 'mr': 'तासाला', 'ml': 'മണിക്കൂറിന്',
    },
  };

  // ── EXPORT CATEGORIES ────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _exportCategories = {
    'grains': {
      'hi': 'अनाज', 'kn': 'ಧಾನ್ಯ', 'ta': 'தானியங்கள்',
      'te': 'ధాన్యాలు', 'mr': 'धान्य', 'ml': 'ധാന്യങ്ങൾ',
    },
    'vegetables': {
      'hi': 'सब्जियां', 'kn': 'ತರಕಾರಿಗಳು', 'ta': 'காய்கறிகள்',
      'te': 'కూరగాయలు', 'mr': 'भाजीपाला', 'ml': 'പച്ചക്കറികൾ',
    },
    'fruits': {
      'hi': 'फल', 'kn': 'ಹಣ್ಣುಗಳು', 'ta': 'பழங்கள்',
      'te': 'పండ్లు', 'mr': 'फळे', 'ml': 'പഴങ്ങൾ',
    },
    'spices': {
      'hi': 'मसाले', 'kn': 'ಮಸಾಲೆ', 'ta': 'மசாலா',
      'te': 'మసాలాలు', 'mr': 'मसाले', 'ml': 'സുഗന്ധ വ്യഞ്ജനങ്ങൾ',
    },
    'pulses': {
      'hi': 'दालें', 'kn': 'ಬೇಳೆ', 'ta': 'பருப்பு வகைகள்',
      'te': 'పప్పులు', 'mr': 'डाळी', 'ml': 'പയർ വർഗ്ഗങ്ങൾ',
    },
    'oilseeds': {
      'hi': 'तिलहन', 'kn': 'ಎಣ್ಣೆ ಬೀಜ', 'ta': 'எண்ணெய் வித்துகள்',
      'te': 'నూనె విత్తనాలు', 'mr': 'तेलबिया', 'ml': 'എണ്ണക്കുരു',
    },
    'nuts': {
      'hi': 'मेवे', 'kn': 'ಬೀಜ', 'ta': 'கொட்டைகள்',
      'te': 'గింజలు', 'mr': 'सुकामेवा', 'ml': 'നട്ട്സ്',
    },
    'organic': {
      'hi': 'जैविक', 'kn': 'ಸಾವಯವ', 'ta': 'இயற்கை',
      'te': 'సేంద్రీయ', 'mr': 'सेंद्रिय', 'ml': 'ജൈവ',
    },
  };

  // ── STATUS VALUES ────────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _statusValues = {
    'available': {
      'hi': 'उपलब्ध', 'kn': 'ಲಭ್ಯ', 'ta': 'கிடைக்கும்',
      'te': 'అందుబాటులో', 'mr': 'उपलब्ध', 'ml': 'ലഭ്യം',
    },
    'unavailable': {
      'hi': 'अनुपलब्ध', 'kn': 'ಲಭ್ಯವಿಲ್ಲ', 'ta': 'கிடைக்காது',
      'te': 'అందుబాటులో లేదు', 'mr': 'अनुपलब्ध', 'ml': 'ലഭ്യമല്ല',
    },
    'sold': {
      'hi': 'बिक गया', 'kn': 'ಮಾರಾಟವಾಗಿದೆ', 'ta': 'விற்கப்பட்டது',
      'te': 'అమ్మబడింది', 'mr': 'विकले', 'ml': 'വിറ്റു',
    },
    'active': {
      'hi': 'सक्रिय', 'kn': 'ಸಕ್ರಿಯ', 'ta': 'செயலில்',
      'te': 'క్రియాశీల', 'mr': 'सक्रिय', 'ml': 'സജീവം',
    },
    'inactive': {
      'hi': 'निष्क्रिय', 'kn': 'ನಿಷ್ಕ್ರಿಯ', 'ta': 'செயலற்றது',
      'te': 'నిష్క్రియ', 'mr': 'निष्क्रिय', 'ml': 'നിഷ്‌ക്രിയം',
    },
  };

  // ── LOCATION TRANSLITERATIONS ────────────────────────────────────────────
  static const Map<String, Map<String, String>> _locationNames = {
    'kolaghatta': {
      'hi': 'कोलघट्ट', 'kn': 'ಕೊಳ್ಳೇಘಾಟ', 'ta': 'கொல்லகட்ட',
      'te': 'కొలఘట్ట', 'mr': 'कोलघट्ट', 'ml': 'കൊലഘട്ട',
    },
    'tumakuru': {
      'hi': 'तुमकुरु', 'kn': 'ತುಮಕೂರು', 'ta': 'துமக்கூரு',
      'te': 'తుమకూరు', 'mr': 'तुमकुरू', 'ml': 'തുമക്കൂർ',
    },
    'tumkur': {
      'hi': 'तुमकुर', 'kn': 'ತುಮಕೂರು', 'ta': 'துமக்கூர்',
      'te': 'తుమకూర్', 'mr': 'तुमकुर', 'ml': 'തുമ്‌കൂർ',
    },
    'turuvekere': {
      'hi': 'तुरुवेकेरे', 'kn': 'ತುರುವೇಕೆರೆ', 'ta': 'துருவேக்கேரே',
      'te': 'తురువేకెరె', 'mr': 'तुरुवेकेरे', 'ml': 'തുരുവേക്കേരെ',
    },
    'karnataka': {
      'hi': 'कर्नाटक', 'kn': 'ಕರ್ನಾಟಕ', 'ta': 'கர்நாடகா',
      'te': 'కర్ణాటక', 'mr': 'कर्नाटक', 'ml': 'കർണ്ണാടക',
    },
    'bengaluru': {
      'hi': 'बेंगलुरु', 'kn': 'ಬೆಂಗಳೂರು', 'ta': 'பெங்களூரு',
      'te': 'బెంగళూరు', 'mr': 'बेंगळुरू', 'ml': 'ബെംഗളൂരു',
    },
    'bangalore': {
      'hi': 'बेंगलोर', 'kn': 'ಬೆಂಗಳೂರು', 'ta': 'பெங்களூர்',
      'te': 'బెంగళూర్', 'mr': 'बंगळोर', 'ml': 'ബാംഗ്ലൂർ',
    },
    'hassan': {
      'hi': 'हासन', 'kn': 'ಹಾಸನ', 'ta': 'ஹாசன்',
      'te': 'హాసన్', 'mr': 'हासन', 'ml': 'ഹാസൻ',
    },
    'mysuru': {
      'hi': 'मैसूरु', 'kn': 'ಮೈಸೂರು', 'ta': 'மைசூரு',
      'te': 'మైసూరు', 'mr': 'म्हैसूर', 'ml': 'മൈസൂരു',
    },
    'mysore': {
      'hi': 'मैसूर', 'kn': 'ಮೈಸೂರು', 'ta': 'மைசூர்',
      'te': 'మైసూర్', 'mr': 'म्हैसूर', 'ml': 'മൈസൂർ',
    },
    'mandya': {
      'hi': 'मांड्या', 'kn': 'ಮಂಡ್ಯ', 'ta': 'மண்ட்யா',
      'te': 'మండ్య', 'mr': 'मांड्या', 'ml': 'മണ്ഡ്യ',
    },
    'shivamogga': {
      'hi': 'शिवमोग्गा', 'kn': 'ಶಿವಮೊಗ್ಗ', 'ta': 'சிவமொக்கா',
      'te': 'శివమొగ్గ', 'mr': 'शिवमोगा', 'ml': 'ശിവമൊഗ്ഗ',
    },
    'davangere': {
      'hi': 'दावणगेरे', 'kn': 'ದಾವಣಗೆರೆ', 'ta': 'தாவங்கெரே',
      'te': 'దావణగెరె', 'mr': 'दावणगेरे', 'ml': 'ദാവണഗെരെ',
    },
    'hubli': {
      'hi': 'हुबली', 'kn': 'ಹುಬ್ಬಳ್ಳಿ', 'ta': 'ஹுப்ளி',
      'te': 'హుబ్లి', 'mr': 'हुबळी', 'ml': 'ഹുബ്ലി',
    },
    'dharwad': {
      'hi': 'धारवाड़', 'kn': 'ಧಾರವಾಡ', 'ta': 'தார்வாட்',
      'te': 'ధార్వాడ్', 'mr': 'धारवाड', 'ml': 'ധാർവാഡ്',
    },
    'belagavi': {
      'hi': 'बेलगावी', 'kn': 'ಬೆಳಗಾವಿ', 'ta': 'பேலகவி',
      'te': 'బెళగావి', 'mr': 'बेळगाव', 'ml': 'ബെളഗാവി',
    },
    'udupi': {
      'hi': 'उडुपी', 'kn': 'ಉಡುಪಿ', 'ta': 'உடுப்பி',
      'te': 'ఉడుపి', 'mr': 'उडुपी', 'ml': 'ഉഡുപ്പി',
    },
    'mangaluru': {
      'hi': 'मंगलुरु', 'kn': 'ಮಂಗಳೂರು', 'ta': 'மங்களூரு',
      'te': 'మంగళూరు', 'mr': 'मंगळुरू', 'ml': 'മംഗളൂരു',
    },
  };

  // ── PUBLIC API ────────────────────────────────────────────────────────────

  /// Translate a machine type field value.
  static String translateMachineType(String value, String langCode) =>
      _lookup(_machineTypes, value, langCode);

  /// Translate a crop/export product name.
  static String translateCropName(String value, String langCode) =>
      _lookup(_cropNames, value, langCode);

  /// Translate a plant category/type.
  static String translatePlantCategory(String value, String langCode) =>
      _lookup(_plantCategories, value, langCode);

  /// Translate a labour skill or category.
  static String translateLabourSkill(String value, String langCode) =>
      _lookup(_labourCategories, value, langCode);

  /// Translate a wage type.
  static String translateWageType(String value, String langCode) =>
      _lookup(_wageTypes, value, langCode);

  /// Translate an export/product category.
  static String translateExportCategory(String value, String langCode) {
    // First try export categories, then crop names
    final fromCategory = _lookup(_exportCategories, value, langCode);
    if (fromCategory != value) return fromCategory;
    return _lookup(_cropNames, value, langCode);
  }

  /// Translate a status field.
  static String translateStatus(String value, String langCode) =>
      _lookup(_statusValues, value, langCode);

  /// Transliterate a location name into the target script.
  /// Falls back to original value if no entry exists.
  static String translateLocation(String value, String langCode) {
    if (langCode == 'en' || value.isEmpty) return value;
    // Try exact match first
    final exact = _lookup(_locationNames, value, langCode);
    if (exact != value) return exact;
    // Try word-by-word: translate each word found in the dict, keep unknowns
    final words = value.split(RegExp(r'\s+'));
    final translated = words.map((w) => _lookup(_locationNames, w, langCode)).join(' ');
    return translated;
  }

  /// Generic translate: tries all dictionaries in order.
  static String translate(String value, String langCode) {
    if (langCode == 'en' || value.isEmpty) return value;
    for (final dict in [
      _machineTypes, _cropNames, _plantCategories,
      _labourCategories, _wageTypes, _exportCategories, _statusValues,
    ]) {
      final r = _lookup(dict, value, langCode);
      if (r != value) return r;
    }
    return value;
  }

  // ── INTERNAL ──────────────────────────────────────────────────────────────

  static String _lookup(
    Map<String, Map<String, String>> dict,
    String value,
    String langCode,
  ) {
    if (langCode == 'en' || value.isEmpty) return value;
    final entry = dict[value.toLowerCase().trim()];
    if (entry == null) return value;
    return entry[langCode] ?? value;
  }
}

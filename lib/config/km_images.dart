// lib/config/km_images.dart
// Centralized image registry — ALL image paths/URLs defined here.
// Never scatter Unsplash or asset paths directly in widget code.

class KMImages {
  KMImages._();

  // ── Local assets ────────────────────────────────────────────────────────────
  static const String logo         = 'assets/leaves.png';
  static const String farmerLogo   = 'assets/farmer_logo.png';
  static const String loginBg      = 'assets/login_bg.png';

  // ── Feature icon assets ─────────────────────────────────────────────────────
  static const String iconCropDisease  = 'assets/icons/crop_disease.png';
  static const String iconWeather      = 'assets/icons/weather.png';
  static const String iconRent         = 'assets/icons/rent_machine.png';
  static const String iconPlantVendors = 'assets/icons/plant_vendors.png';
  static const String iconChatbot      = 'assets/icons/chatbot.png';

  // ── Hero / promotional photography ──────────────────────────────────────────
  // Used for banner slides and feature hero cards.
  // Format: 800×400, fit=crop, quality=75 for fast load.
  static const String heroExport  =
      'https://images.unsplash.com/photo-1625246333195-78d9c38ad449'
      '?w=800&q=75&fit=crop';
  static const String heroWeather =
      'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429'
      '?w=800&q=75&fit=crop';
  static const String heroRent    =
      'https://images.unsplash.com/photo-1592982537447-7440770cbfc9'
      '?w=800&q=75&fit=crop';
  static const String heroLabour  =
      'https://images.unsplash.com/photo-1500595046743-cd271d694d30'
      '?w=800&q=75&fit=crop';
  static const String heroLand    =
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef'
      '?w=800&q=75&fit=crop';
  static const String heroMarket  =
      'https://images.unsplash.com/photo-1542838132-92c53300491e'
      '?w=800&q=75&fit=crop';
  static const String heroPlantVendors =
      'https://images.unsplash.com/photo-1416879595882-3373a0480b5b'
      '?w=800&q=75&fit=crop';
}

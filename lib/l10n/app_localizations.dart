import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('ta'),
    Locale('te')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KrishiMithra'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Login with Email'**
  String get loginEmail;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get noAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @phoneLogin.
  ///
  /// In en, this message translates to:
  /// **'Login / Sign Up with Phone'**
  String get phoneLogin;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createAccount;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Your Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @kannada.
  ///
  /// In en, this message translates to:
  /// **'Kannada'**
  String get kannada;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get searchLocation;

  /// No description provided for @recentLocations.
  ///
  /// In en, this message translates to:
  /// **'Recent Locations'**
  String get recentLocations;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @f2bMart.
  ///
  /// In en, this message translates to:
  /// **'F2B Mart'**
  String get f2bMart;

  /// No description provided for @rentMachine.
  ///
  /// In en, this message translates to:
  /// **'Rent Machine'**
  String get rentMachine;

  /// No description provided for @plantVendors.
  ///
  /// In en, this message translates to:
  /// **'Plant Vendors'**
  String get plantVendors;

  /// No description provided for @labourHub.
  ///
  /// In en, this message translates to:
  /// **'Labour Hub'**
  String get labourHub;

  /// No description provided for @cropDisease.
  ///
  /// In en, this message translates to:
  /// **'Crop Disease'**
  String get cropDisease;

  /// No description provided for @exportHub.
  ///
  /// In en, this message translates to:
  /// **'Export Hub'**
  String get exportHub;

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get chatbot;

  /// No description provided for @mostlyClear.
  ///
  /// In en, this message translates to:
  /// **'Mostly Clear'**
  String get mostlyClear;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @farmAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Farm Advisory'**
  String get farmAdvisory;

  /// No description provided for @farmingNormal.
  ///
  /// In en, this message translates to:
  /// **'Weather conditions are normal for farming.'**
  String get farmingNormal;

  /// No description provided for @rainAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Rain Advisory'**
  String get rainAdvisory;

  /// No description provided for @noRain.
  ///
  /// In en, this message translates to:
  /// **'No rain expected in next 3 hours.'**
  String get noRain;

  /// No description provided for @safeSpray.
  ///
  /// In en, this message translates to:
  /// **'Safe time for pesticide spraying.'**
  String get safeSpray;

  /// No description provided for @hourlyForecast.
  ///
  /// In en, this message translates to:
  /// **'Hourly Forecast'**
  String get hourlyForecast;

  /// No description provided for @sevenDayForecast.
  ///
  /// In en, this message translates to:
  /// **'7-Day Forecast'**
  String get sevenDayForecast;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No weather data'**
  String get noData;

  /// No description provided for @nearbyMachines.
  ///
  /// In en, this message translates to:
  /// **'Nearby Machines'**
  String get nearbyMachines;

  /// No description provided for @listMachine.
  ///
  /// In en, this message translates to:
  /// **'List Machine'**
  String get listMachine;

  /// No description provided for @searchLabour.
  ///
  /// In en, this message translates to:
  /// **'Search labour...'**
  String get searchLabour;

  /// No description provided for @deleteLabour.
  ///
  /// In en, this message translates to:
  /// **'Delete Labour'**
  String get deleteLabour;

  /// No description provided for @deleteLabourConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this labour?'**
  String get deleteLabourConfirm;

  /// No description provided for @cannotOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Cannot open dialer'**
  String get cannotOpenDialer;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @busy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get busy;

  /// No description provided for @noLabourFound.
  ///
  /// In en, this message translates to:
  /// **'No labour entries found.'**
  String get noLabourFound;

  /// No description provided for @addLabour.
  ///
  /// In en, this message translates to:
  /// **'Add Labour'**
  String get addLabour;

  /// No description provided for @sortByDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by Distance'**
  String get sortByDistanceLabel;

  /// No description provided for @errorLoadingLabour.
  ///
  /// In en, this message translates to:
  /// **'Error loading labour data'**
  String get errorLoadingLabour;

  /// No description provided for @farmLabour.
  ///
  /// In en, this message translates to:
  /// **'Farm Labour'**
  String get farmLabour;

  /// No description provided for @tractorDriver.
  ///
  /// In en, this message translates to:
  /// **'Tractor Driver'**
  String get tractorDriver;

  /// No description provided for @plantationWorker.
  ///
  /// In en, this message translates to:
  /// **'Plantation Worker'**
  String get plantationWorker;

  /// No description provided for @sprayerOperator.
  ///
  /// In en, this message translates to:
  /// **'Sprayer Operator'**
  String get sprayerOperator;

  /// No description provided for @harvesterOperator.
  ///
  /// In en, this message translates to:
  /// **'Harvester Operator'**
  String get harvesterOperator;

  /// No description provided for @machineTechnician.
  ///
  /// In en, this message translates to:
  /// **'Machine Technician'**
  String get machineTechnician;

  /// No description provided for @dairyWorker.
  ///
  /// In en, this message translates to:
  /// **'Dairy Worker'**
  String get dairyWorker;

  /// No description provided for @seeds.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seeds;

  /// No description provided for @plant.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get plant;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @searchPlantVendor.
  ///
  /// In en, this message translates to:
  /// **'Search plant, type, vendor, location...'**
  String get searchPlantVendor;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @priceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: Low'**
  String get priceLow;

  /// No description provided for @priceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: High'**
  String get priceHigh;

  /// No description provided for @noListingsFound.
  ///
  /// In en, this message translates to:
  /// **'No listings found.'**
  String get noListingsFound;

  /// No description provided for @deleteListingQ.
  ///
  /// In en, this message translates to:
  /// **'Delete listing?'**
  String get deleteListingQ;

  /// No description provided for @permanentlyDeleteListing.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the listing.'**
  String get permanentlyDeleteListing;

  /// No description provided for @unknownPlant.
  ///
  /// In en, this message translates to:
  /// **'Unknown plant'**
  String get unknownPlant;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @vendorLabel.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendorLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @listedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Listed on'**
  String get listedOnLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @exporterHub.
  ///
  /// In en, this message translates to:
  /// **'Exporter Hub'**
  String get exporterHub;

  /// No description provided for @cropsTab.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get cropsTab;

  /// No description provided for @myListingsTab.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListingsTab;

  /// No description provided for @verifiedBuyersTab.
  ///
  /// In en, this message translates to:
  /// **'Verified Buyers'**
  String get verifiedBuyersTab;

  /// No description provided for @searchByCropFarmer.
  ///
  /// In en, this message translates to:
  /// **'Search by crop, farmer name or location'**
  String get searchByCropFarmer;

  /// No description provided for @pleaseSignInToViewListings.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your listings'**
  String get pleaseSignInToViewListings;

  /// No description provided for @pleaseSignInToViewOrders.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your orders'**
  String get pleaseSignInToViewOrders;

  /// No description provided for @pleaseSignInToAdd.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to add products.'**
  String get pleaseSignInToAdd;

  /// No description provided for @pleaseSignInToViewSeller.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view seller orders.'**
  String get pleaseSignInToViewSeller;

  /// No description provided for @noExportProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No export products match your search / filter.'**
  String get noExportProductsFound;

  /// No description provided for @noListingsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No listings match your search / filter.'**
  String get noListingsMatchFilter;

  /// No description provided for @noPurchaseOrders.
  ///
  /// In en, this message translates to:
  /// **'No purchase orders yet.'**
  String get noPurchaseOrders;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get buyNow;

  /// No description provided for @deleteListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Listing'**
  String get deleteListingTitle;

  /// No description provided for @areYouSureDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this product?'**
  String get areYouSureDeleteProduct;

  /// No description provided for @productDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully'**
  String get productDeletedSuccessfully;

  /// No description provided for @openMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get openMap;

  /// No description provided for @nearbyFarmersList.
  ///
  /// In en, this message translates to:
  /// **'Nearby farmers (list)'**
  String get nearbyFarmersList;

  /// No description provided for @sellingOrders.
  ///
  /// In en, this message translates to:
  /// **'Selling Orders'**
  String get sellingOrders;

  /// No description provided for @krishiMitraAIChatbot.
  ///
  /// In en, this message translates to:
  /// **'KrishiMithra Chatbot'**
  String get krishiMitraAIChatbot;

  /// No description provided for @askKrishiMitraHint.
  ///
  /// In en, this message translates to:
  /// **'Ask KrishiMithra...'**
  String get askKrishiMitraHint;

  /// No description provided for @krishiMitraTyping.
  ///
  /// In en, this message translates to:
  /// **'KrishiMithra is typing...'**
  String get krishiMitraTyping;

  /// No description provided for @chatbotSorryError.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I couldn\'t get a response. Please try again.'**
  String get chatbotSorryError;

  /// No description provided for @cropDiseaseDetector.
  ///
  /// In en, this message translates to:
  /// **'Crop Disease Detector'**
  String get cropDiseaseDetector;

  /// No description provided for @analyzeDisease.
  ///
  /// In en, this message translates to:
  /// **'Analyze Disease'**
  String get analyzeDisease;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @diseaseResult.
  ///
  /// In en, this message translates to:
  /// **'Disease'**
  String get diseaseResult;

  /// No description provided for @categoryResult.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryResult;

  /// No description provided for @symptomsResult.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptomsResult;

  /// No description provided for @treatmentResult.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatmentResult;

  /// No description provided for @preventionResult.
  ///
  /// In en, this message translates to:
  /// **'Prevention'**
  String get preventionResult;

  /// No description provided for @confidenceResult.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidenceResult;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @listingsCount.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get listingsCount;

  /// No description provided for @rentalsCount.
  ///
  /// In en, this message translates to:
  /// **'Rentals'**
  String get rentalsCount;

  /// No description provided for @activitySection.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activitySection;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'kn', 'ml', 'mr', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'kn': return AppLocalizationsKn();
    case 'ml': return AppLocalizationsMl();
    case 'mr': return AppLocalizationsMr();
    case 'ta': return AppLocalizationsTa();
    case 'te': return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

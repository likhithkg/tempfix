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

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @openMaps.
  ///
  /// In en, this message translates to:
  /// **'Open Maps'**
  String get openMaps;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get pickImage;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// No description provided for @pickImageFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick an image first'**
  String get pickImageFirst;

  /// No description provided for @imageUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully'**
  String get imageUploadedSuccessfully;

  /// No description provided for @imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get imageUploadFailed;

  /// No description provided for @imageUploaded.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded'**
  String get imageUploaded;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @setLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Location'**
  String get setLocation;

  /// No description provided for @searchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search place...'**
  String get searchPlace;

  /// No description provided for @fetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Fetching location...'**
  String get fetchingLocation;

  /// No description provided for @locationSet.
  ///
  /// In en, this message translates to:
  /// **'Location set'**
  String get locationSet;

  /// No description provided for @pricePerUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per unit (₹)'**
  String get pricePerUnitLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productNameLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get statusLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get totalLabel;

  /// No description provided for @farmerLabel.
  ///
  /// In en, this message translates to:
  /// **'Farmer:'**
  String get farmerLabel;

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile:'**
  String get mobileLabel;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty:'**
  String get qtyLabel;

  /// No description provided for @sellerLabel.
  ///
  /// In en, this message translates to:
  /// **'Seller:'**
  String get sellerLabel;

  /// No description provided for @buyerLabel.
  ///
  /// In en, this message translates to:
  /// **'Buyer:'**
  String get buyerLabel;

  /// No description provided for @ownerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner:'**
  String get ownerLabel;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @allListingsTab.
  ///
  /// In en, this message translates to:
  /// **'All Listings'**
  String get allListingsTab;

  /// No description provided for @pendingApprovalTab.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApprovalTab;

  /// No description provided for @postExportStock.
  ///
  /// In en, this message translates to:
  /// **'Post Export Stock'**
  String get postExportStock;

  /// No description provided for @noPendingListings.
  ///
  /// In en, this message translates to:
  /// **'No pending listings.'**
  String get noPendingListings;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @postStock.
  ///
  /// In en, this message translates to:
  /// **'Post Stock'**
  String get postStock;

  /// No description provided for @noListingsYet.
  ///
  /// In en, this message translates to:
  /// **'You have no listings yet.'**
  String get noListingsYet;

  /// No description provided for @deleteListingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this listing?'**
  String get deleteListingConfirm;

  /// No description provided for @listingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Listing deleted.'**
  String get listingDeleted;

  /// No description provided for @browseExportListings.
  ///
  /// In en, this message translates to:
  /// **'Browse Export Listings'**
  String get browseExportListings;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available.'**
  String get noProductsAvailable;

  /// No description provided for @createPurchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'Create Purchase Order'**
  String get createPurchaseOrder;

  /// No description provided for @listingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing Details'**
  String get listingDetailsTitle;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @approveListing.
  ///
  /// In en, this message translates to:
  /// **'Approve Listing'**
  String get approveListing;

  /// No description provided for @rejectListing.
  ///
  /// In en, this message translates to:
  /// **'Reject Listing'**
  String get rejectListing;

  /// No description provided for @listingApproved.
  ///
  /// In en, this message translates to:
  /// **'Listing approved.'**
  String get listingApproved;

  /// No description provided for @listingRejected.
  ///
  /// In en, this message translates to:
  /// **'Listing rejected.'**
  String get listingRejected;

  /// No description provided for @errorUpdatingListing.
  ///
  /// In en, this message translates to:
  /// **'Error updating listing.'**
  String get errorUpdatingListing;

  /// No description provided for @editExportStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Export Stock'**
  String get editExportStockTitle;

  /// No description provided for @pleaseEnterProductName.
  ///
  /// In en, this message translates to:
  /// **'Please enter product name'**
  String get pleaseEnterProductName;

  /// No description provided for @pleaseEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter quantity'**
  String get pleaseEnterQuantity;

  /// No description provided for @pleaseEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter price'**
  String get pleaseEnterPrice;

  /// No description provided for @pleaseEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter location'**
  String get pleaseEnterLocation;

  /// No description provided for @listingSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Listing submitted successfully.'**
  String get listingSubmittedSuccessfully;

  /// No description provided for @listingUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Listing updated successfully.'**
  String get listingUpdatedSuccessfully;

  /// No description provided for @failedToSubmitListing.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit listing.'**
  String get failedToSubmitListing;

  /// No description provided for @addExportProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Export Product'**
  String get addExportProductTitle;

  /// No description provided for @editExportProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Export Product'**
  String get editExportProductTitle;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @enterProductName.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get enterProductName;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter valid price'**
  String get enterValidPrice;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @productAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully.'**
  String get productAddedSuccessfully;

  /// No description provided for @productUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully.'**
  String get productUpdatedSuccessfully;

  /// No description provided for @failedToSubmitProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit product.'**
  String get failedToSubmitProduct;

  /// No description provided for @buyerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Buyer Name'**
  String get buyerNameLabel;

  /// No description provided for @deliveryAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddressLabel;

  /// No description provided for @notesOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptionalLabel;

  /// No description provided for @enterBuyerName.
  ///
  /// In en, this message translates to:
  /// **'Enter buyer name'**
  String get enterBuyerName;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter valid number'**
  String get enterValidNumber;

  /// No description provided for @enterDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter delivery address'**
  String get enterDeliveryAddress;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @orderPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get orderPlacedSuccessfully;

  /// No description provided for @failedToPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order.'**
  String get failedToPlaceOrder;

  /// No description provided for @myPurchaseOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Purchase Orders'**
  String get myPurchaseOrdersTitle;

  /// No description provided for @loadingProduct.
  ///
  /// In en, this message translates to:
  /// **'Loading product...'**
  String get loadingProduct;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @noPurchaseOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No purchase orders yet.'**
  String get noPurchaseOrdersYet;

  /// No description provided for @noOrdersReceivedYet.
  ///
  /// In en, this message translates to:
  /// **'No orders received yet.'**
  String get noOrdersReceivedYet;

  /// No description provided for @purchaseOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Order'**
  String get purchaseOrderTitle;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get notesLabel;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @completeOrder.
  ///
  /// In en, this message translates to:
  /// **'Complete Order'**
  String get completeOrder;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @confirmOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm this order?'**
  String get confirmOrderConfirm;

  /// No description provided for @completeOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to complete this order?'**
  String get completeOrderConfirm;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get cancelOrderConfirm;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order confirmed.'**
  String get orderConfirmed;

  /// No description provided for @orderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Order completed.'**
  String get orderCompleted;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled.'**
  String get orderCancelled;

  /// No description provided for @errorUpdatingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error updating order.'**
  String get errorUpdatingOrder;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get orderNotFound;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @nearbyFarmersTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Farmers'**
  String get nearbyFarmersTitle;

  /// No description provided for @nearbyFarmersMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Farmers (Map)'**
  String get nearbyFarmersMapTitle;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String kmAway(String distance);

  /// No description provided for @labourDetails.
  ///
  /// In en, this message translates to:
  /// **'Labour Details'**
  String get labourDetails;

  /// No description provided for @callLabour.
  ///
  /// In en, this message translates to:
  /// **'Call Labour'**
  String get callLabour;

  /// No description provided for @hireLabour.
  ///
  /// In en, this message translates to:
  /// **'Hire Labour'**
  String get hireLabour;

  /// No description provided for @deleteOptionAvailableInListingPage.
  ///
  /// In en, this message translates to:
  /// **'Delete option available in listing page.'**
  String get deleteOptionAvailableInListingPage;

  /// No description provided for @editLabour.
  ///
  /// In en, this message translates to:
  /// **'Edit Labour'**
  String get editLabour;

  /// No description provided for @addLabourTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Labour'**
  String get addLabourTitle;

  /// No description provided for @editLabourTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Labour'**
  String get editLabourTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @skillProfessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Skill / Profession'**
  String get skillProfessionLabel;

  /// No description provided for @contactNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Number'**
  String get contactNumberLabel;

  /// No description provided for @dailyWageLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Wage (₹)'**
  String get dailyWageLabel;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @enterSkill.
  ///
  /// In en, this message translates to:
  /// **'Enter skill'**
  String get enterSkill;

  /// No description provided for @enterContact.
  ///
  /// In en, this message translates to:
  /// **'Enter contact'**
  String get enterContact;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @saveLabour.
  ///
  /// In en, this message translates to:
  /// **'Save Labour'**
  String get saveLabour;

  /// No description provided for @updateLabour.
  ///
  /// In en, this message translates to:
  /// **'Update Labour'**
  String get updateLabour;

  /// No description provided for @labourSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Labour saved successfully.'**
  String get labourSavedSuccessfully;

  /// No description provided for @labourUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Labour updated successfully.'**
  String get labourUpdatedSuccessfully;

  /// No description provided for @failedToSaveLabour.
  ///
  /// In en, this message translates to:
  /// **'Failed to save labour.'**
  String get failedToSaveLabour;

  /// No description provided for @hireLabourTitle.
  ///
  /// In en, this message translates to:
  /// **'Hire {name}'**
  String hireLabourTitle(String name);

  /// No description provided for @yourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourNameLabel;

  /// No description provided for @yourContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Contact'**
  String get yourContactLabel;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateLabel;

  /// No description provided for @endDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDateLabel;

  /// No description provided for @numberOfDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Days'**
  String get numberOfDaysLabel;

  /// No description provided for @workTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Type'**
  String get workTypeLabel;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterStartDate.
  ///
  /// In en, this message translates to:
  /// **'Enter start date'**
  String get enterStartDate;

  /// No description provided for @enterEndDate.
  ///
  /// In en, this message translates to:
  /// **'Enter end date'**
  String get enterEndDate;

  /// No description provided for @enterNumberOfDays.
  ///
  /// In en, this message translates to:
  /// **'Enter number of days'**
  String get enterNumberOfDays;

  /// No description provided for @harvesting.
  ///
  /// In en, this message translates to:
  /// **'Harvesting'**
  String get harvesting;

  /// No description provided for @planting.
  ///
  /// In en, this message translates to:
  /// **'Planting'**
  String get planting;

  /// No description provided for @spraying.
  ///
  /// In en, this message translates to:
  /// **'Spraying'**
  String get spraying;

  /// No description provided for @ploughing.
  ///
  /// In en, this message translates to:
  /// **'Ploughing'**
  String get ploughing;

  /// No description provided for @sendHireRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Hire Request'**
  String get sendHireRequest;

  /// No description provided for @hireRequestSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Hire request sent successfully!'**
  String get hireRequestSentSuccessfully;

  /// No description provided for @failedToSendHireRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to send hire request.'**
  String get failedToSendHireRequest;

  /// No description provided for @mustBeSignedInToHire.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to send a hire request.'**
  String get mustBeSignedInToHire;

  /// No description provided for @nearbyLabourTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Labour'**
  String get nearbyLabourTitle;

  /// No description provided for @searchLabourHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, skill, or location'**
  String get searchLabourHint;

  /// No description provided for @selectRadius.
  ///
  /// In en, this message translates to:
  /// **'Select Radius'**
  String get selectRadius;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Please enable in settings.'**
  String get locationPermissionDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @noLabourFoundNearby.
  ///
  /// In en, this message translates to:
  /// **'No labour found nearby.'**
  String get noLabourFoundNearby;

  /// No description provided for @failedToLoadLabour.
  ///
  /// In en, this message translates to:
  /// **'Failed to load labour.'**
  String get failedToLoadLabour;

  /// No description provided for @couldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location.'**
  String get couldNotGetLocation;

  /// No description provided for @failedToLoadPlants.
  ///
  /// In en, this message translates to:
  /// **'Failed to load plants'**
  String get failedToLoadPlants;

  /// No description provided for @errorLoadingPlantDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading plant details'**
  String get errorLoadingPlantDetails;

  /// No description provided for @unknownVendor.
  ///
  /// In en, this message translates to:
  /// **'Unknown vendor'**
  String get unknownVendor;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @noDescriptionProvided.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get noDescriptionProvided;

  /// No description provided for @couldNotOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get couldNotOpenWhatsApp;

  /// No description provided for @descriptionHeader.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionHeader;

  /// No description provided for @addPlantTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Plant'**
  String get addPlantTitle;

  /// No description provided for @editPlantTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Plant'**
  String get editPlantTitle;

  /// No description provided for @plantNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Plant Name'**
  String get plantNameLabel;

  /// No description provided for @plantTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Plant Type'**
  String get plantTypeLabel;

  /// No description provided for @quantityAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity Available'**
  String get quantityAvailableLabel;

  /// No description provided for @vendorNurseryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Vendor / Nursery Name'**
  String get vendorNurseryNameLabel;

  /// No description provided for @floweringPlant.
  ///
  /// In en, this message translates to:
  /// **'Flowering Plant'**
  String get floweringPlant;

  /// No description provided for @fruitPlant.
  ///
  /// In en, this message translates to:
  /// **'Fruit Plant'**
  String get fruitPlant;

  /// No description provided for @vegetablePlant.
  ///
  /// In en, this message translates to:
  /// **'Vegetable Plant'**
  String get vegetablePlant;

  /// No description provided for @medicinalPlant.
  ///
  /// In en, this message translates to:
  /// **'Medicinal Plant'**
  String get medicinalPlant;

  /// No description provided for @ornamental.
  ///
  /// In en, this message translates to:
  /// **'Ornamental'**
  String get ornamental;

  /// No description provided for @enterPlantName.
  ///
  /// In en, this message translates to:
  /// **'Enter plant name'**
  String get enterPlantName;

  /// No description provided for @enterType.
  ///
  /// In en, this message translates to:
  /// **'Enter type'**
  String get enterType;

  /// No description provided for @enterVendorName.
  ///
  /// In en, this message translates to:
  /// **'Enter vendor name'**
  String get enterVendorName;

  /// No description provided for @savePlant.
  ///
  /// In en, this message translates to:
  /// **'Save Plant'**
  String get savePlant;

  /// No description provided for @updatePlant.
  ///
  /// In en, this message translates to:
  /// **'Update Plant'**
  String get updatePlant;

  /// No description provided for @plantSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Plant saved successfully.'**
  String get plantSavedSuccessfully;

  /// No description provided for @plantUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Plant updated successfully.'**
  String get plantUpdatedSuccessfully;

  /// No description provided for @failedToSavePlant.
  ///
  /// In en, this message translates to:
  /// **'Failed to save plant.'**
  String get failedToSavePlant;

  /// No description provided for @nearbyPlantVendorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Plant Vendors'**
  String get nearbyPlantVendorsTitle;

  /// No description provided for @locationNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Location not verified'**
  String get locationNotVerified;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get perDay;

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailable;

  /// No description provided for @listNewMachineTitle.
  ///
  /// In en, this message translates to:
  /// **'List New Machine'**
  String get listNewMachineTitle;

  /// No description provided for @editMachineTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Machine'**
  String get editMachineTitle;

  /// No description provided for @machineNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Machine Name'**
  String get machineNameLabel;

  /// No description provided for @machineTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Machine Type'**
  String get machineTypeLabel;

  /// No description provided for @pricePerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per day (₹)'**
  String get pricePerDayLabel;

  /// No description provided for @ownerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerNameLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @machineTractor.
  ///
  /// In en, this message translates to:
  /// **'Tractor'**
  String get machineTractor;

  /// No description provided for @machineHarvester.
  ///
  /// In en, this message translates to:
  /// **'Harvester'**
  String get machineHarvester;

  /// No description provided for @machinePlough.
  ///
  /// In en, this message translates to:
  /// **'Plough'**
  String get machinePlough;

  /// No description provided for @machineSeeder.
  ///
  /// In en, this message translates to:
  /// **'Seeder'**
  String get machineSeeder;

  /// No description provided for @machineSprayer.
  ///
  /// In en, this message translates to:
  /// **'Sprayer'**
  String get machineSprayer;

  /// No description provided for @machineTiller.
  ///
  /// In en, this message translates to:
  /// **'Tiller'**
  String get machineTiller;

  /// No description provided for @machineBaler.
  ///
  /// In en, this message translates to:
  /// **'Baler'**
  String get machineBaler;

  /// No description provided for @enterMachineName.
  ///
  /// In en, this message translates to:
  /// **'Enter machine name'**
  String get enterMachineName;

  /// No description provided for @selectAType.
  ///
  /// In en, this message translates to:
  /// **'Select a type'**
  String get selectAType;

  /// No description provided for @enterOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Enter owner name'**
  String get enterOwnerName;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone'**
  String get enterPhone;

  /// No description provided for @currentLocationSet.
  ///
  /// In en, this message translates to:
  /// **'Current location set'**
  String get currentLocationSet;

  /// No description provided for @locationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get locationNotSet;

  /// No description provided for @selectMachineType.
  ///
  /// In en, this message translates to:
  /// **'Select a machine type'**
  String get selectMachineType;

  /// No description provided for @setLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'Set location first'**
  String get setLocationFirst;

  /// No description provided for @enterValidNumericPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid numeric price'**
  String get enterValidNumericPrice;

  /// No description provided for @submitListing.
  ///
  /// In en, this message translates to:
  /// **'Submit Listing'**
  String get submitListing;

  /// No description provided for @updateListing.
  ///
  /// In en, this message translates to:
  /// **'Update Listing'**
  String get updateListing;

  /// No description provided for @nearestFirst.
  ///
  /// In en, this message translates to:
  /// **'Nearest first'**
  String get nearestFirst;

  /// No description provided for @lowestPriceFirst.
  ///
  /// In en, this message translates to:
  /// **'Lowest price first'**
  String get lowestPriceFirst;

  /// No description provided for @searchByNameOwnerLocation.
  ///
  /// In en, this message translates to:
  /// **'Search by name, owner, or location'**
  String get searchByNameOwnerLocation;

  /// No description provided for @referenceLocationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Reference location not available'**
  String get referenceLocationNotAvailable;

  /// No description provided for @noMachinesFoundNearby.
  ///
  /// In en, this message translates to:
  /// **'No machines found nearby'**
  String get noMachinesFoundNearby;

  /// No description provided for @nearbyMachinesMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Machines (Map)'**
  String get nearbyMachinesMapTitle;

  /// No description provided for @searchAndSetLocation.
  ///
  /// In en, this message translates to:
  /// **'Search & set location'**
  String get searchAndSetLocation;

  /// No description provided for @dayForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'{day} Forecast'**
  String dayForecastTitle(String day);

  /// No description provided for @minMaxTemperature.
  ///
  /// In en, this message translates to:
  /// **'Min / Max Temperature'**
  String get minMaxTemperature;

  /// No description provided for @enterLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter location...'**
  String get enterLocationHint;

  /// No description provided for @noLocationsFound.
  ///
  /// In en, this message translates to:
  /// **'No locations found'**
  String get noLocationsFound;

  /// No description provided for @diseaseDetected.
  ///
  /// In en, this message translates to:
  /// **'Disease detected'**
  String get diseaseDetected;

  /// No description provided for @errorContactingAI.
  ///
  /// In en, this message translates to:
  /// **'Error contacting AI'**
  String get errorContactingAI;

  /// No description provided for @chatbotWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! 👋 I am KrishiMithra AI. How can I help you with farming today?'**
  String get chatbotWelcomeMessage;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @updateProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Update profile photo'**
  String get updateProfilePhoto;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @themePreferenceSaved.
  ///
  /// In en, this message translates to:
  /// **'Theme preference saved. Restart app to apply immediately.'**
  String get themePreferenceSaved;

  /// No description provided for @passwordChangeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Password change not available'**
  String get passwordChangeNotAvailable;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get passwordResetEmailSent;

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email'**
  String get failedToSendResetEmail;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and associated user data. Are you sure?'**
  String get deleteAccountConfirm;

  /// No description provided for @exportStarted.
  ///
  /// In en, this message translates to:
  /// **'Export started (check your email or downloads)'**
  String get exportStarted;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @setDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Set default location'**
  String get setDefaultLocation;

  /// No description provided for @locationHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., Bengaluru, Karnataka'**
  String get locationHintText;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @defaultLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Default location'**
  String get defaultLocationLabel;

  /// No description provided for @pleaseProvideDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Please provide a default location'**
  String get pleaseProvideDefaultLocation;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @darkModeSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved locally. Restart to apply.'**
  String get darkModeSavedLocally;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @providerLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get providerLabel;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @errorDeletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Error deleting account'**
  String get errorDeletingAccount;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @pricePerKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Price/kg'**
  String get pricePerKgLabel;

  /// No description provided for @farmerDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer Details'**
  String get farmerDetailsTitle;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get by;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get at;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get statusIssued;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @pleaseSignInToPerformAction.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to perform this action'**
  String get pleaseSignInToPerformAction;

  /// No description provided for @onlySellerCanPerformAction.
  ///
  /// In en, this message translates to:
  /// **'Only the seller can perform this action'**
  String get onlySellerCanPerformAction;

  /// No description provided for @acceptResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept Response'**
  String get acceptResponseTitle;

  /// No description provided for @acceptBuyerResponseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept buyer response from \"{name}\"?'**
  String acceptBuyerResponseConfirm(String name);

  /// No description provided for @buyerResponseAccepted.
  ///
  /// In en, this message translates to:
  /// **'Buyer response accepted. PO status set to confirmed.'**
  String get buyerResponseAccepted;

  /// No description provided for @failedToAcceptResponse.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept response'**
  String get failedToAcceptResponse;

  /// No description provided for @rejectResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Response'**
  String get rejectResponseTitle;

  /// No description provided for @rejectBuyerResponseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject buyer response from \"{name}\"?'**
  String rejectBuyerResponseConfirm(String name);

  /// No description provided for @buyerResponseRejected.
  ///
  /// In en, this message translates to:
  /// **'Buyer response rejected.'**
  String get buyerResponseRejected;

  /// No description provided for @failedToRejectResponse.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject response'**
  String get failedToRejectResponse;

  /// No description provided for @acceptPurchaseOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept Purchase Order'**
  String get acceptPurchaseOrderTitle;

  /// No description provided for @acceptPurchaseOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept this purchase order? This will set PO status to accepted.'**
  String get acceptPurchaseOrderConfirm;

  /// No description provided for @purchaseOrderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Purchase order accepted.'**
  String get purchaseOrderAccepted;

  /// No description provided for @failedToAcceptPO.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept purchase order'**
  String get failedToAcceptPO;

  /// No description provided for @rejectPurchaseOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Purchase Order'**
  String get rejectPurchaseOrderTitle;

  /// No description provided for @rejectPurchaseOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject this purchase order? This will also reject pending buyer responses.'**
  String get rejectPurchaseOrderConfirm;

  /// No description provided for @purchaseOrderRejectedFull.
  ///
  /// In en, this message translates to:
  /// **'Purchase order rejected. Pending buyer responses were also rejected.'**
  String get purchaseOrderRejectedFull;

  /// No description provided for @failedToRejectPO.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject purchase order'**
  String get failedToRejectPO;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID: {id}'**
  String orderIdLabel(String id);

  /// No description provided for @createdAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdAtLabel(String date);

  /// No description provided for @acceptOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrderButton;

  /// No description provided for @rejectOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrderButton;

  /// No description provided for @poFinalizedMessage.
  ///
  /// In en, this message translates to:
  /// **'PO is finalized (status: {status}). No further accept/reject allowed.'**
  String poFinalizedMessage(String status);

  /// No description provided for @buyerContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Buyer • Contact: {contact}'**
  String buyerContactSubtitle(String contact);

  /// No description provided for @loadingSellerInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading seller info...'**
  String get loadingSellerInfo;

  /// No description provided for @sellerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Seller not found'**
  String get sellerNotFound;

  /// No description provided for @farmerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Farmer ID: {id}'**
  String farmerIdLabel(String id);

  /// No description provided for @contactColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact: {contact}'**
  String contactColonLabel(String contact);

  /// No description provided for @itemsSection.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsSection;

  /// No description provided for @addedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Added: {date}'**
  String addedAtLabel(String date);

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: ₹{amount}'**
  String totalAmountLabel(Object amount);

  /// No description provided for @buyerResponsesSection.
  ///
  /// In en, this message translates to:
  /// **'Buyer Responses'**
  String get buyerResponsesSection;

  /// No description provided for @errorLoadingResponses.
  ///
  /// In en, this message translates to:
  /// **'Error loading responses'**
  String get errorLoadingResponses;

  /// No description provided for @noBuyerResponsesYet.
  ///
  /// In en, this message translates to:
  /// **'No buyer responses yet.'**
  String get noBuyerResponsesYet;

  /// No description provided for @atDateLabel.
  ///
  /// In en, this message translates to:
  /// **'At: {date}'**
  String atDateLabel(String date);

  /// No description provided for @historySection.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historySection;

  /// No description provided for @noHistoryEntries.
  ///
  /// In en, this message translates to:
  /// **'No history entries.'**
  String get noHistoryEntries;

  /// No description provided for @contactSellerSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Contact Seller: {phone}'**
  String contactSellerSnackbar(String phone);

  /// No description provided for @contactSellerButton.
  ///
  /// In en, this message translates to:
  /// **'Contact Seller'**
  String get contactSellerButton;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @productNA.
  ///
  /// In en, this message translates to:
  /// **'Product: N/A'**
  String get productNA;

  /// No description provided for @productLoading.
  ///
  /// In en, this message translates to:
  /// **'Product: loading...'**
  String get productLoading;

  /// No description provided for @productNotFoundItem.
  ///
  /// In en, this message translates to:
  /// **'Product: not found'**
  String get productNotFoundItem;

  /// No description provided for @productNameItem.
  ///
  /// In en, this message translates to:
  /// **'Product: {name}'**
  String productNameItem(String name);

  /// No description provided for @errorLoadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error loading orders'**
  String get errorLoadingOrders;

  /// No description provided for @noOrdersPlacedYet.
  ///
  /// In en, this message translates to:
  /// **'No orders placed yet.'**
  String get noOrdersPlacedYet;

  /// No description provided for @totalAmountValue.
  ///
  /// In en, this message translates to:
  /// **'Total: ₹{amount}'**
  String totalAmountValue(Object amount);

  /// No description provided for @dateValue.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateValue(String date);

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @pleaseSignInViewPurchaseOrders.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your purchase orders.'**
  String get pleaseSignInViewPurchaseOrders;

  /// No description provided for @noOrdersForListingsYet.
  ///
  /// In en, this message translates to:
  /// **'No orders for your listings yet.'**
  String get noOrdersForListingsYet;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @noProfileDataFound.
  ///
  /// In en, this message translates to:
  /// **'No profile data found'**
  String get noProfileDataFound;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name} 👋'**
  String welcomeUser(String name);

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps'**
  String get couldNotOpenMaps;

  /// No description provided for @couldNotOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not open dialer'**
  String get couldNotOpenDialer;

  /// No description provided for @openFullMap.
  ///
  /// In en, this message translates to:
  /// **'Open full map'**
  String get openFullMap;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services disabled'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @f2bTagline.
  ///
  /// In en, this message translates to:
  /// **'Farm Fresh · Direct Trade'**
  String get f2bTagline;

  /// No description provided for @listProduce.
  ///
  /// In en, this message translates to:
  /// **'List Produce'**
  String get listProduce;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products, farmers...'**
  String get searchProducts;

  /// No description provided for @featuredProduce.
  ///
  /// In en, this message translates to:
  /// **'Featured Produce'**
  String get featuredProduce;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recentlyAdded;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @organic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get organic;

  /// No description provided for @farmerInfo.
  ///
  /// In en, this message translates to:
  /// **'Farmer Info'**
  String get farmerInfo;

  /// No description provided for @similarProducts.
  ///
  /// In en, this message translates to:
  /// **'Similar Products'**
  String get similarProducts;

  /// No description provided for @harvestDate.
  ///
  /// In en, this message translates to:
  /// **'Harvest Date'**
  String get harvestDate;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @minOrder.
  ///
  /// In en, this message translates to:
  /// **'Min. Order'**
  String get minOrder;

  /// No description provided for @contactFarmer.
  ///
  /// In en, this message translates to:
  /// **'Contact Farmer'**
  String get contactFarmer;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products, farmers, locations...'**
  String get searchHint;

  /// No description provided for @filterProducts.
  ///
  /// In en, this message translates to:
  /// **'Filter Products'**
  String get filterProducts;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @lowestPrice.
  ///
  /// In en, this message translates to:
  /// **'Lowest Price'**
  String get lowestPrice;

  /// No description provided for @highestPrice.
  ///
  /// In en, this message translates to:
  /// **'Highest Price'**
  String get highestPrice;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @resultsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsFound(int count);

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found. Try adjusting filters.'**
  String get noSearchResults;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @addedToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Added to wishlist'**
  String get addedToWishlist;

  /// No description provided for @removedFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get removedFromWishlist;

  /// No description provided for @yourWishlist.
  ///
  /// In en, this message translates to:
  /// **'Your Wishlist'**
  String get yourWishlist;

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistEmpty;

  /// No description provided for @browseProducts.
  ///
  /// In en, this message translates to:
  /// **'Browse Products'**
  String get browseProducts;

  /// No description provided for @loginToSave.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save items to wishlist'**
  String get loginToSave;

  /// No description provided for @shareProduct.
  ///
  /// In en, this message translates to:
  /// **'Share Product'**
  String get shareProduct;

  /// No description provided for @productInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'Product info copied to clipboard'**
  String get productInfoCopied;

  /// No description provided for @makeOffer.
  ///
  /// In en, this message translates to:
  /// **'Make Offer'**
  String get makeOffer;

  /// No description provided for @offerPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Offered Price'**
  String get offerPriceLabel;

  /// No description provided for @enterValidOfferPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get enterValidOfferPrice;

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current Price'**
  String get currentPrice;

  /// No description provided for @submitOffer.
  ///
  /// In en, this message translates to:
  /// **'Submit Offer'**
  String get submitOffer;

  /// No description provided for @offerSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Offer submitted! Track it in your orders.'**
  String get offerSubmitted;

  /// No description provided for @farmerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Farmer Dashboard'**
  String get farmerDashboard;

  /// No description provided for @incomingOrders.
  ///
  /// In en, this message translates to:
  /// **'Incoming Orders'**
  String get incomingOrders;

  /// No description provided for @activeListings.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListings;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// No description provided for @totalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get totalEarned;

  /// No description provided for @addListing.
  ///
  /// In en, this message translates to:
  /// **'Add Listing'**
  String get addListing;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit Listing'**
  String get editListing;

  /// No description provided for @deleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete Listing'**
  String get deleteListing;

  /// No description provided for @noIncomingOrders.
  ///
  /// In en, this message translates to:
  /// **'No incoming orders yet'**
  String get noIncomingOrders;

  /// No description provided for @negotiationOffer.
  ///
  /// In en, this message translates to:
  /// **'Negotiation'**
  String get negotiationOffer;

  /// No description provided for @buyerOfferedPrice.
  ///
  /// In en, this message translates to:
  /// **'Buyer Offered'**
  String get buyerOfferedPrice;

  /// No description provided for @makeCounterOffer.
  ///
  /// In en, this message translates to:
  /// **'Counter Offer'**
  String get makeCounterOffer;

  /// No description provided for @counterOfferPrice.
  ///
  /// In en, this message translates to:
  /// **'Your Counter Price'**
  String get counterOfferPrice;

  /// No description provided for @counterOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Counter offer sent to buyer'**
  String get counterOfferSent;

  /// No description provided for @orderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted'**
  String get orderAccepted;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected'**
  String get orderRejected;

  /// No description provided for @viewOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewOrderDetails;
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

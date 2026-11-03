const kRentHubPremium = 'renthub_premium';
const kPlantVendorPremium = 'plant_vendor_premium';
const kCropDiseasePremium = 'crop_disease_premium';

const kAllFeatureIds = [kRentHubPremium, kPlantVendorPremium, kCropDiseasePremium];

/// Prices by total-feature count. Do not change — backend validates these.
const kPremiumPrices = {0: 0, 1: 99, 2: 169, 3: 229};

const kFeatureNames = {
  kRentHubPremium: 'RentHub Premium',
  kPlantVendorPremium: 'Plant Vendor Premium',
  kCropDiseasePremium: 'Crop Disease AI',
};

/// Short one-line descriptions (used in the paywall gate page).
const kFeatureDescriptions = {
  kRentHubPremium: 'Rent or list farm equipment near you',
  kPlantVendorPremium: 'Buy & sell plants in the marketplace',
  kCropDiseasePremium: 'AI-powered crop disease detection',
};

/// Longer card descriptions shown on the premium screen feature cards.
const kFeatureLongDescriptions = {
  kRentHubPremium:
      'Publish your agricultural machinery listings and reach nearby farmers.',
  kPlantVendorPremium:
      'List your plants and agricultural products and connect with buyers.',
  kCropDiseasePremium:
      'Identify crop diseases and get AI-powered treatment recommendations.',
};

/// One-line benefit shown below the description on each feature card.
const kFeatureBenefits = {
  kRentHubPremium: 'Create and publish machine listings',
  kPlantVendorPremium: 'Create and publish plant and product listings',
  kCropDiseasePremium: 'Access crop disease AI detection',
};

/// Material icon codepoints — kept for compatibility with other widgets.
const kFeatureIcons = {
  kRentHubPremium: 0xe1b8,    // Icons.agriculture_rounded
  kPlantVendorPremium: 0xe40c, // Icons.local_florist_rounded
  kCropDiseasePremium: 0xe3f3, // Icons.biotech_rounded
};

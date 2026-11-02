const kRentHubPremium = 'renthub_premium';
const kPlantVendorPremium = 'plant_vendor_premium';
const kCropDiseasePremium = 'crop_disease_premium';

const kAllFeatureIds = [kRentHubPremium, kPlantVendorPremium, kCropDiseasePremium];

const kPremiumPrices = {0: 0, 1: 99, 2: 169, 3: 229};

const kFeatureNames = {
  kRentHubPremium: 'RentHub',
  kPlantVendorPremium: 'Plant Vendor',
  kCropDiseasePremium: 'Crop Disease AI',
};

const kFeatureDescriptions = {
  kRentHubPremium: 'Rent or list farm equipment near you',
  kPlantVendorPremium: 'Buy & sell plants in the marketplace',
  kCropDiseasePremium: 'AI-powered crop disease detection',
};

const kFeatureIcons = {
  kRentHubPremium: 0xe1b8,   // Icons.agriculture_rounded codepoint
  kPlantVendorPremium: 0xe40c, // Icons.local_florist_rounded codepoint
  kCropDiseasePremium: 0xe3f3, // Icons.biotech_rounded codepoint
};

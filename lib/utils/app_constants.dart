class AppConstants {
  // App Info
  static const String appName = 'ShareBox';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Borrow. Share. Build.';
  static const String appTaglineBn = 'বাংলাদেশের সেরা টুল শেয়ারিং প্ল্যাটফর্ম';

  // Currency
  static const String currency = '৳';
  static const String currencyCode = 'BDT';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String toolsCollection = 'tools';
  static const String rentalsCollection = 'rentals';
  static const String chatRoomsCollection = 'chatRooms';
  static const String messagesSubcollection = 'messages';

  // Storage Paths
  static const String profileImagesPath = 'profiles';
  static const String toolImagesPath = 'tools';

  // Pagination
  static const int toolsPageSize = 20;
  static const int messagesPageSize = 30;
  static const int chatRoomsPageSize = 20;

  // Image limits
  static const int maxToolImages = 5;
  static const int maxImageSizeMB = 5;
  static const int imageQuality = 85;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;

  // Validation
  static const int minPasswordLength = 6;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int minDescriptionLength = 20;
  static const int maxDescriptionLength = 1000;
  static const double minToolPrice = 10.0;
  static const double maxToolPrice = 100000.0;

  // Bangladesh Locations
  static const List<String> bangladeshLocations = [
    'Dhaka',
    'Gazipur',
    'Savar',
    'Narayanganj',
    'Tongi',
    'Narsingdi',
    'Manikganj',
    'Munshiganj',
    'Chittagong',
    'Sylhet',
    'Rajshahi',
    'Khulna',
    'Barisal',
    'Rangpur',
    'Mymensingh',
    'Comilla',
    'Bogra',
    'Jessore',
    'Dinajpur',
    'Tangail',
    'Faridpur',
    'Other',
  ];

  // Default user
  static const String defaultUserName = 'Alif';
  static const String defaultLocation = 'Gazipur, Dhaka';

  // Animation durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 600);

  // Error messages
  static const String networkError = 'Network error. Check your internet connection.';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String authError = 'Authentication failed. Please sign in again.';
  static const String permissionError = 'Permission denied. Please check your settings.';
}

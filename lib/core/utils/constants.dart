import 'package:flutter/material.dart';

/// ─────────────────────────────────────
/// COLORS
/// ─────────────────────────────────────
class AppColors {
  static const Color primary = Color(0xFF6F35A5);
  static const Color primaryLight = Color(0xFFF1E6FF);
  static const Color secondary = Color(0xFFBDBDBD);
  static const Color background = Color(0xFFF5F5F5);
  static const Color scaffoldBg = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
}

/// ─────────────────────────────────────
/// SPACING & DIMENSIONS
/// ─────────────────────────────────────
class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 32.0;

  static const double borderRadius = 12.0;
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}

/// ─────────────────────────────────────
/// TYPOGRAPHY
/// ─────────────────────────────────────
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}

/// ─────────────────────────────────────
/// ANIMATION DURATIONS
/// ─────────────────────────────────────
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
}

/// ─────────────────────────────────────
/// RESPONSIVE BREAKPOINTS
/// ─────────────────────────────────────
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;
}

/// ─────────────────────────────────────
/// ROUTE NAMES
/// ─────────────────────────────────────
class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String profile = '/profile';
}

/// ─────────────────────────────────────
/// ASSET PATHS
/// ─────────────────────────────────────
class AppAssets {
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/placeholder.png';
}

/// ─────────────────────────────────────
/// API ENDPOINTS
/// ─────────────────────────────────────
class ApiEndpoints {
  static const String baseUrl = 'https://api.example.com';
  static const String login = '$baseUrl/auth/login';
  static const String fetchProfile = '$baseUrl/user/profile';
}

/// ─────────────────────────────────────
/// VALIDATION PATTERNS
/// ─────────────────────────────────────
class ValidationPatterns {
  static final RegExp email = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp phone = RegExp(r'^\+?[0-9]{7,15}$');
}

/// ─────────────────────────────────────
/// SHARED PREFERENCE KEYS
/// ─────────────────────────────────────
class PrefKeys {
  static const String isLoggedIn = 'is_logged_in';
  static const String authToken = 'auth_token';
}

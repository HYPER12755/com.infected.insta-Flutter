import 'package:flutter/material.dart';

/// Instagram Exact Clone Theme & Constants
///
/// Instagram Brand Colors:
/// - Primary: #E1306C (Coral/Pink)
/// - Secondary: #405DE6 (Blue)
/// - Gradient: #833AB4, #FD1D1D, #F77737 (Purple, Red, Orange)
/// - Background: #000000 (Black) / #FFFFFF (White)
/// - Surface: #262626 (Dark Gray) / #FAFafa (Light Gray)
/// - Text: #262626 (Dark) / #FFFFFF (Light)
/// - Secondary Text: #8E8E8E

class InstagramColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFFE1306C);
  static const Color secondary = Color(0xFF405DE6);
  static const Color tertiary = Color(0xFF833AB4);
  static const Color orange = Color(0xFFF77737);
  static const Color red = Color(0xFFFD1D1D);

  // Gradient Colors
  static const List<Color> instagramGradient = [
    Color(0xFF833AB4),
    Color(0xFFFD1D1D),
    Color(0xFFF77737),
  ];

  // Dark Theme
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF262626);
  static const Color darkSecondary = Color(0xFF363636);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8E8E8E);

  // Light Theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightText = Color(0xFF262626);
  static const Color lightTextSecondary = Color(0xFF8E8E8E);
}

class InstagramTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: InstagramColors.primary,
      scaffoldBackgroundColor: InstagramColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: InstagramColors.primary,
        secondary: InstagramColors.secondary,
        surface: InstagramColors.darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: InstagramColors.darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: InstagramColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: InstagramColors.darkText),
        titleTextStyle: TextStyle(
          color: InstagramColors.darkText,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: InstagramColors.darkBackground,
        selectedItemColor: InstagramColors.darkText,
        unselectedItemColor: InstagramColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: InstagramColors.darkText,
        unselectedLabelColor: InstagramColors.darkTextSecondary,
        indicatorColor: InstagramColors.darkText,
      ),
      iconTheme: const IconThemeData(color: InstagramColors.darkText),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: InstagramColors.darkText,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: InstagramColors.darkText,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: InstagramColors.darkText,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(color: InstagramColors.darkText),
        bodyLarge: TextStyle(color: InstagramColors.darkText),
        bodyMedium: TextStyle(color: InstagramColors.darkText),
        bodySmall: TextStyle(color: InstagramColors.darkTextSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: InstagramColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: InstagramColors.darkSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: InstagramColors.darkText),
        ),
        hintStyle: const TextStyle(color: InstagramColors.darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: InstagramColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: InstagramColors.primary,
          side: const BorderSide(color: InstagramColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: InstagramColors.darkSecondary,
        thickness: 0.5,
      ),
    );
  }
}

/// Instagram-style Icons (using built-in icons as placeholders)
class InstagramIcons {
  static const IconData home = Icons.home_outlined;
  static const IconData homeFilled = Icons.home;
  static const IconData search = Icons.search;
  static const IconData add = Icons.add_box_outlined;
  static const IconData reels = Icons.play_arrow_outlined;
  static const IconData profile = Icons.person_outline;
  static const IconData heart = Icons.favorite_border;
  static const IconData heartFilled = Icons.favorite;
  static const IconData comment = Icons.chat_bubble_outline;
  static const IconData send = Icons.send_outlined;
  static const IconData bookmark = Icons.bookmark_outline;
  static const IconData bookmarkFilled = Icons.bookmark;
  static const IconData more = Icons.more_horiz;
  static const IconData settings = Icons.settings_outlined;
  static const IconData edit = Icons.edit;
  static const IconData camera = Icons.camera_alt_outlined;
  static const IconData gallery = Icons.photo_library_outlined;
  static const IconData video = Icons.videocam_outlined;
  static const IconData close = Icons.close;
  static const IconData back = Icons.arrow_back;
  static const IconData verify = Icons.verified_outlined;
  static const IconData message = Icons.message_outlined;
  static const IconData call = Icons.call_outlined;
  static const IconData videoCall = Icons.videocam_outlined;
  static const IconData info = Icons.info_outline;
  static const IconData share = Icons.share_outlined;
  static const IconData dots = Icons.more_vert;
  static const IconData location = Icons.location_on_outlined;
  static const IconData tag = Icons.tag;
}

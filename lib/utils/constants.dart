import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'AI Detection';
  static const String apiDetectAndOcrUrl =
      'https://ampolfood.ddns.net/detect_and_ocr';
  static const String apiLoginUrl = 'https://ampolfood.ddns.net/login';

  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentColor = Color(0xFF10B981);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color textColor = Color(0xFF1E293B);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);

  static const Color glassSurfaceColor = Color(0xFFFEFEFE);
  static const Color glassOverlayColor = Color(0x40FFFFFF);
  static const Color modernCardColor = Color(0xFFFBFBFB);
  static const Color dividerColor = Color(0xFFE2E8F0);

  static const double buttonHeight = 56.0;
  static const double buttonHeightLarge = 64.0;
  static const double buttonHeightSmall = 48.0;
  static const double borderRadius = 20.0;
  static const double borderRadiusSmall = 16.0;
  static const double borderRadiusLarge = 28.0;
  static const double borderRadiusXLarge = 32.0;
  static const double padding = 16.0;
  static const double paddingSmall = 12.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double elevation = 12.0;
  static const double elevationSmall = 6.0;
  static const double elevationLarge = 20.0;

  static const String loadingMessage = 'กำลังประมวลผล...';
  static const String cameraPermissionMessage = 'กรุณาอนุญาตให้เข้าถึงกล้อง';
  static const String storagePermissionMessage = 'กรุณาอนุญาตให้เข้าถึงไฟล์';
  static const String realtimeComingSoon =
      'ฟีเจอร์ Real-time Detection\nกำลังพัฒนา...';

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, secondaryColor],
        stops: [0.0, 1.0],
      );

  static LinearGradient get accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentColor, Color(0xFF059669)],
        stops: [0.0, 1.0],
      );

  static LinearGradient get secondaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [secondaryColor, primaryColor.withOpacity(0.8)],
        stops: const [0.0, 1.0],
      );

  static LinearGradient get glassMorphGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          glassOverlayColor,
          Colors.white.withOpacity(0.1),
        ],
      );

  static LinearGradient get modernCardGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          modernCardColor,
          Color(0xFFF8F9FA),
        ],
      );

  static BoxShadow get modernShadow => BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      );

  static BoxShadow get glassShadow => BoxShadow(
        color: primaryColor.withOpacity(0.1),
        blurRadius: 24,
        offset: const Offset(0, 12),
        spreadRadius: 0,
      );

  static BoxShadow get buttonShadow => BoxShadow(
        color: primaryColor.withOpacity(0.25),
        blurRadius: 16,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      );

  static BoxShadow get floatingShadow => BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 32,
        offset: const Offset(0, 16),
        spreadRadius: -4,
      );

  static BorderRadius get modernBorderRadius =>
      BorderRadius.circular(borderRadius);
  static BorderRadius get largeBorderRadius =>
      BorderRadius.circular(borderRadiusLarge);
  static BorderRadius get xlargeBorderRadius =>
      BorderRadius.circular(borderRadiusXLarge);
}

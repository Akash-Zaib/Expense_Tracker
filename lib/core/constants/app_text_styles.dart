import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Base text style using Inter font (or similar modern sans-serif)
  static final TextStyle _base = GoogleFonts.inter(
    color: AppColors.textPrimary,
  );

  static final TextStyle heading1 = _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle heading2 = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle heading3 = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle title = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle bodyMedium = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle bodyRegular = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle caption = _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static final TextStyle button = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );
}

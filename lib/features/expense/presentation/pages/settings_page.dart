import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings_rounded,
                size: 56,
                color: AppColors.purpleDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Settings',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              'App preferences, profile settings,\nand more will be available here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.purpleDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Coming Soon',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.purpleDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

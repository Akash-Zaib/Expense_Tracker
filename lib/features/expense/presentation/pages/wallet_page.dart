import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

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
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 56,
                color: AppColors.greenDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Wallet',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your linked bank accounts\nand payment methods here.',
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
                color: AppColors.greenDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Coming Soon',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.greenDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

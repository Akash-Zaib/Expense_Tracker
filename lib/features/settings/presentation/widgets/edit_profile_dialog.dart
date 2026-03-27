import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class EditProfileResult {
  final String name;
  final int signatureColorValue;

  const EditProfileResult({
    required this.name,
    required this.signatureColorValue,
  });
}

Future<EditProfileResult?> showEditProfileDialog({
  required BuildContext context,
  required String initialName,
  required int initialSignatureColorValue,
  Set<int> unavailableColorValues = const {},
}) {
  return showDialog<EditProfileResult>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _EditProfileDialog(
      initialName: initialName,
      initialSignatureColorValue: initialSignatureColorValue,
      unavailableColorValues: unavailableColorValues,
    ),
  );
}

class _EditProfileDialog extends StatefulWidget {
  final String initialName;
  final int initialSignatureColorValue;
  final Set<int> unavailableColorValues;

  const _EditProfileDialog({
    required this.initialName,
    required this.initialSignatureColorValue,
    required this.unavailableColorValues,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late int _selectedColorValue;

  static const List<int> _palette = [
    0xFFEC4899, // pink
    0xFFF97316, // orange
    0xFF8B5CF6, // purple
    0xFF22C55E, // green
    0xFF3B82F6, // blue
    0xFFEF4444, // red
    0xFFA855F7, // violet
    0xFF94A3B8, // slate
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedColorValue = widget.initialSignatureColorValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    Navigator.of(context).pop(
      EditProfileResult(
        name: _nameController.text,
        signatureColorValue: _selectedColorValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Profile', style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            Text(
              'Personalize your identity in the app.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'User Name',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Enter User Name',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Signature Color',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _palette.map((value) {
                final isSelected = value == _selectedColorValue;
                final isUnavailable = widget.unavailableColorValues.contains(
                  value,
                );
                return InkWell(
                  onTap: isUnavailable
                      ? null
                      : () => setState(() => _selectedColorValue = value),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnavailable
                            ? Colors.grey.withValues(alpha: 0.8)
                            : isSelected
                            ? Colors.black.withValues(alpha: 0.15)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : isUnavailable
                        ? const Icon(Icons.close, color: Colors.white, size: 14)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose a color that represents you in the app.',
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback? onConfirm;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.icon = Icons.help_outline_rounded,
    this.isDestructive = false,
    this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AppConfirmDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          icon: icon,
          isDestructive: isDestructive,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isDestructive
        ? const Color(0xFFD64545)
        : AppColors.primary;

    final accentBackground = isDestructive
        ? const Color(0xFFFFEEEE)
        : AppColors.cardGreen;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          AppDimensions.spacing22,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(
            AppDimensions.radius22,
          ),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(
                alpha: 0.20,
              ),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: accentBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: accentColor,
              ),
            ),
            const SizedBox(
              height: AppDimensions.spacing16,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(
              height: AppDimensions.spacing8,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(
              height: AppDimensions.spacing22,
            ),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppDimensions.smallButtonHeight,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            AppColors.textPrimary,
                        backgroundColor:
                            AppColors.surface,
                        side: const BorderSide(
                          color: AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            AppDimensions.radius14,
                          ),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: AppDimensions.smallButtonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        onConfirm?.call();
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            AppDimensions.radius14,
                          ),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
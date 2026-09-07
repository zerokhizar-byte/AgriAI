import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onActionTap;
  final IconData icon;

  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.actionText = 'Try Again',
    this.onActionTap,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final hasMessage =
        message != null && message!.trim().isNotEmpty;

    final hasAction =
        actionText != null &&
        actionText!.trim().isNotEmpty &&
        onActionTap != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          AppDimensions.spacing24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 34,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(
              height: AppDimensions.spacing16,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (hasMessage) ...[
              const SizedBox(
                height: AppDimensions.spacing8,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 330,
                ),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            if (hasAction) ...[
              const SizedBox(
                height: AppDimensions.spacing18,
              ),
              SizedBox(
                height: AppDimensions.smallButtonHeight,
                child: ElevatedButton.icon(
                  onPressed: onActionTap,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                  ),
                  label: Text(actionText!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radius16,
                      ),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
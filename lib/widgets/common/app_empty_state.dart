import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onActionTap;
  final double iconSize;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionText,
    this.onActionTap,
    this.iconSize = 30,
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
      child: Padding(
        padding: const EdgeInsets.all(
          AppDimensions.spacing24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.cardGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.primary,
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
                  maxWidth: 320,
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
                child: ElevatedButton(
                  onPressed: onActionTap,
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
                  ),
                  child: Text(
                    actionText!,
                    style: const TextStyle(
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
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final Widget? icon;
  final List<Widget>? actions;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.actions,
    this.showCloseButton = false,
    this.onClose,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    Widget? icon,
    List<Widget>? actions,
    bool showCloseButton = false,
    VoidCallback? onClose,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(
        alpha: 0.28,
      ),
      builder: (context) {
        return AppDialog(
          title: title,
          message: message,
          content: content,
          icon: icon,
          actions: actions,
          showCloseButton: showCloseButton,
          onClose: onClose,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMessage =
        message != null && message!.trim().isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxWidth: 420,
        ),
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
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(
                alpha: 0.18,
              ),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null || showCloseButton)
              Row(
                children: [
                  if (icon != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: icon!,
                      ),
                    )
                  else
                    const Spacer(),
                  if (showCloseButton)
                    IconButton(
                      onPressed: onClose ??
                          () {
                            Navigator.of(context).pop();
                          },
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 21,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            if (icon != null || showCloseButton)
              const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (hasMessage) ...[
              const SizedBox(
                height: AppDimensions.spacing8,
              ),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (content != null) ...[
              const SizedBox(
                height: AppDimensions.spacing16,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: content!,
              ),
            ],
            if (actions != null &&
                actions!.isNotEmpty) ...[
              const SizedBox(
                height: AppDimensions.spacing22,
              ),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: actions!
                    .map(
                      (action) => Padding(
                        padding:
                            const EdgeInsets.only(
                          left: 8,
                        ),
                        child: action,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppDialogButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool primary;
  final bool destructive;

  const AppDialogButton({
    super.key,
    required this.text,
    this.onPressed,
    this.primary = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFD64545)
        : AppColors.primary;

    if (primary) {
      return SizedBox(
        height: AppDimensions.smallButtonHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppDimensions.radius14,
              ),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: AppDimensions.smallButtonHeight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDimensions.radius14,
            ),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
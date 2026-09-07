import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry padding;
  final double? maxHeight;

  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.showCloseButton = true,
    this.onClose,
    this.padding = const EdgeInsets.fromLTRB(
      20,
      8,
      20,
      24,
    ),
    this.maxHeight,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    String? subtitle,
    Widget? leading,
    bool showCloseButton = true,
    VoidCallback? onClose,
    EdgeInsetsGeometry padding =
        const EdgeInsets.fromLTRB(
      20,
      8,
      20,
      24,
    ),
    double? maxHeight,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(
        alpha: 0.28,
      ),
      builder: (context) {
        return AppBottomSheet(
          title: title,
          subtitle: subtitle,
          leading: leading,
          showCloseButton: showCloseButton,
          onClose: onClose,
          padding: padding,
          maxHeight: maxHeight,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.sizeOf(context).height;

    final availableHeight =
        maxHeight ??
        screenHeight * 0.90;

    final hasTitle =
        title != null &&
        title!.trim().isNotEmpty;

    final hasSubtitle =
        subtitle != null &&
        subtitle!.trim().isNotEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: availableHeight,
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              AppDimensions.radius28,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(4),
                ),
              ),
              if (hasTitle || leading != null) ...[
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    16,
                    12,
                    8,
                  ),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 12),
                      ],
                      if (hasTitle)
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                title!,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w800,
                                  color:
                                      AppColors.textPrimary,
                                ),
                              ),
                              if (hasSubtitle) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w500,
                                    color: AppColors
                                        .textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (showCloseButton)
                        IconButton(
                          onPressed: onClose ??
                              () {
                                Navigator.of(context)
                                    .pop();
                              },
                          tooltip: 'Close',
                          icon: const Icon(
                            Icons.close_rounded,
                            color:
                                AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              Flexible(
                child: SingleChildScrollView(
                  padding: padding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomSheetAction extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool destructive;

  const AppBottomSheetAction({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFD64545)
        : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius16,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: destructive
                      ? const Color(0xFFFFEEEE)
                      : AppColors.cardGreen,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            destructive
                                ? const Color(
                                    0xFFD64545,
                                  )
                                : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null &&
                        subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
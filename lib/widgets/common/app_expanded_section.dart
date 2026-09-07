import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppExpandedSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;
  final IconData leadingIcon;
  final VoidCallback? onExpansionChanged;

  const AppExpandedSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
    this.leadingIcon = Icons.expand_more_rounded,
    this.onExpansionChanged,
  });

  @override
  State<AppExpandedSection> createState() =>
      _AppExpandedSectionState();
}

class _AppExpandedSectionState
    extends State<AppExpandedSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
    });

    widget.onExpansionChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppDimensions.radius18,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(
                AppDimensions.radius18,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cardGreen,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.leadingIcon,
                        size: 21,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color:
                                  AppColors.textPrimary,
                            ),
                          ),
                          if (widget.subtitle != null &&
                              widget.subtitle!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle!,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight:
                                    FontWeight.w500,
                                color:
                                    AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(
                        milliseconds: 220,
                      ),
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 24,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16,
              ),
              child: widget.child,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(
              milliseconds: 220,
            ),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}
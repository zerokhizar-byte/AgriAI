import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final TextInputAction textInputAction;

  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onTap,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.textInputAction = TextInputAction.search,
  });

  @override
  State<AppSearchField> createState() =>
      _AppSearchFieldState();
}

class _AppSearchFieldState
    extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();

    _ownsController = widget.controller == null;

    _controller = widget.controller ??
        TextEditingController();

    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);

    if (_ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 22,
          color: AppColors.textSecondary,
        ),
        suffixIcon: hasText
            ? IconButton(
                onPressed: _clear,
                tooltip: 'Clear',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radius16,
          ),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radius16,
          ),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radius16,
          ),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppDimensions.radius16,
          ),
          borderSide: const BorderSide(
            color: AppColors.divider,
          ),
        ),
      ),
    );
  }
}
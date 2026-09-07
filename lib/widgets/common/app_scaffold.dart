import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final EdgeInsetsGeometry? bodyPadding;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.backgroundColor = AppColors.background,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.bodyPadding,
  });

  @override
  Widget build(BuildContext context) {
    final content = bodyPadding == null
        ? body
        : Padding(
            padding: bodyPadding!,
            child: body,
          );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(
        top: appBar == null,
        bottom: bottomNavigationBar == null,
        child: content,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation:
          floatingActionButtonLocation,
      drawer: drawer,
      endDrawer: endDrawer,
      resizeToAvoidBottomInset:
          resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar:
          extendBodyBehindAppBar,
    );
  }
}
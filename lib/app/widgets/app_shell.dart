import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'app_colors.dart';

/// Unified page scaffold for student / teacher top-level screens.
///
/// - [withBackground] paints the shared login2 background image behind a
///   transparent scaffold (used for home / schedule / booking / score).
/// - Otherwise falls back to [AppColors.scaffoldBg] (used for list-style
///   screens such as feedback or notifications).
///
/// Pass [title] to render a centered [AppPageTitle] below the status bar.
/// Pass [appBar] for screens that genuinely need a Material AppBar (e.g.,
/// detail screens with a back button).
class AppPageScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final Widget? trailing;
  final PreferredSizeWidget? appBar;
  final bool withBackground;
  final EdgeInsetsGeometry? padding;

  const AppPageScaffold({
    super.key,
    required this.body,
    this.title,
    this.trailing,
    this.appBar,
    this.withBackground = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(child: AppPageTitle(text: title!)),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: trailing,
                  ),
                ],
              ),
            ),
          Expanded(
            child: padding != null
                ? Padding(padding: padding!, child: body)
                : body,
          ),
        ],
      ),
    );

    if (withBackground) {
      return Scaffold(
        appBar: appBar,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AssetImages.login2),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            content,
          ],
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      backgroundColor: AppColors.scaffoldBg,
      body: content,
    );
  }
}

/// Large centered page title used as a substitute for AppBar titles on
/// top-level role pages.
class AppPageTitle extends StatelessWidget {
  final String text;
  const AppPageTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Small all-caps section label above grouped content.
class AppSectionTitle extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const AppSectionTitle(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.only(left: 5, bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: padding,
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Standard white rounded shadowed surface — the base card used across the
/// app for grouped info and list tiles.
class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? borderLeftColor;
  final double borderLeftWidth;
  final VoidCallback? onTap;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.borderLeftColor,
    this.borderLeftWidth = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        border: borderLeftColor != null
            ? Border(
                left: BorderSide(
                  color: borderLeftColor!,
                  width: borderLeftWidth,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return container;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        onTap: onTap,
        child: container,
      ),
    );
  }
}

/// Circular icon button used inside headers (notifications, refresh).
class AppIconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const AppIconBubble({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        onTap: onTap,
        child: Container(
          width: AppColors.minTouchTarget,
          height: AppColors.minTouchTarget,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color ?? AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

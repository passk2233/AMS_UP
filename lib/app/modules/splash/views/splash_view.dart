import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../utilities/assets.dart';
import '../../../widgets/app_colors.dart';
import '../../../widgets/app_spacing.dart';
import '../../../widgets/app_typography.dart';
import '../controllers/splash_controller.dart';

/// Navy sampled directly from `images/loading.png` so the artwork's own
/// background dissolves into the screen — no visible square seam. The field
/// holds this exact navy through the artwork band and only deepens below it,
/// so the image edges never frame against a lighter tone. This is the one
/// sanctioned full-bleed Identity-Navy surface (a launch moment).
const Color _navy = Color(0xFF1B385F);

/// Connection / boot splash.
///
/// Holds the CEIT identity mark on a navy field while [SplashController]
/// reaches the backend: a perceived-progress bar + status line while
/// connecting, and a plain-language offline state with a retry CTA on
/// failure. The mark stays anchored; only the block beneath it swaps.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.identityNavy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _navy,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_navy, _navy, AppColors.identityNavy],
              stops: [0.0, 0.52, 1.0],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _HorizonGlow()),
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      const Spacer(flex: 5),
                      _IdentityMark(reduceMotion: reduceMotion),
                      const SizedBox(height: AppSpacing.xl),
                      // Fixed anchor: the swap block grows downward from a
                      // stable top edge so the mark above never shifts. Sized
                      // for the tallest error variant (icon + 2-line title +
                      // 2-line message + detail code + button).
                      SizedBox(
                        height: 272,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Obx(() {
                            final isError = controller.phase.value ==
                                SplashPhase.error;
                            return AnimatedSwitcher(
                              duration: Duration(
                                  milliseconds: reduceMotion ? 0 : 350),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeIn,
                              child: isError
                                  ? _ErrorBlock(
                                      key: const ValueKey('error'),
                                      fault: controller.fault,
                                      detail: controller.faultDetail,
                                      onRetry: controller.retry,
                                    )
                                  : _ConnectingBlock(
                                      key: const ValueKey('connecting'),
                                      progress: controller.progress,
                                      reduceMotion: reduceMotion,
                                    ),
                            );
                          }),
                        ),
                      ),
                      const Spacer(flex: 3),
                      const _FooterCaption(),
                      const SizedBox(height: AppSpacing.s),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft teal "horizon" glow low on the screen, behind the action area. Adds
/// life to the navy field without touching the mark's flat-navy band.
class _HorizonGlow extends StatelessWidget {
  const _HorizonGlow();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.78),
            radius: 0.85,
            colors: [Color(0x2940B4CD), Color(0x0040B4CD)],
            stops: [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

/// The CEIT artwork, decoded at display resolution (the source is 6400²) and
/// faded/scaled in once on first appearance.
class _IdentityMark extends StatelessWidget {
  final bool reduceMotion;

  const _IdentityMark({required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Floor against zero window metrics (Android can report a 0-size first
    // frame) so the size stays positive and cacheWidth never hits the
    // `cacheWidth > 0` assertion in Image.asset.
    final available = media.size.width > 0 ? media.size.width : 360.0;
    final dpr = media.devicePixelRatio > 0 ? media.devicePixelRatio : 1.0;
    final size = math.min(available * 0.72, 300.0);
    final image = Image.asset(
      AssetImages.splashArt,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: math.max(1, (size * dpr).round()),
      filterQuality: FilterQuality.medium,
      semanticLabel:
          'ໂລໂກ້ ພາກວິຊາວິສະວະກຳຄອມພິວເຕີ ແລະ ເຕັກໂນໂລຊີຂໍ້ມູນຂ່າວສານ',
    );
    if (reduceMotion) return image;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
      ),
      child: image,
    );
  }
}

/// Connecting state: progress bar + reassuring status line.
class _ConnectingBlock extends StatelessWidget {
  final AnimationController progress;
  final bool reduceMotion;

  const _ConnectingBlock({
    super.key,
    required this.progress,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProgressBar(progress: progress, reduceMotion: reduceMotion),
        const SizedBox(height: AppSpacing.m),
        Text(
          'ກຳລັງເຊື່ອມຕໍ່...',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Slim rounded determinate bar: translucent-white track, bright Faculty Teal
/// fill with a soft (optionally breathing) glow.
class _ProgressBar extends StatelessWidget {
  final AnimationController progress;
  final bool reduceMotion;

  const _ProgressBar({required this.progress, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    const trackH = 8.0;
    final screenW = MediaQuery.of(context).size.width;
    final width =
        screenW > 0 ? math.min(screenW * 0.60, 240.0) : 240.0;
    return SizedBox(
      width: width,
      height: trackH,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(trackH / 2),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                final v = progress.value.clamp(0.0, 1.0);
                // Grow the fill from the left edge. FractionallySizedBox
                // defaults to centering its child, which would make the fill
                // expand from the middle outward — wrong for a progress bar.
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v <= 0 ? 0.0001 : v,
                  child: _FillBar(reduceMotion: reduceMotion),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The teal fill of the progress bar. Its glow breathes gently unless reduced
/// motion is requested.
class _FillBar extends StatefulWidget {
  final bool reduceMotion;

  const _FillBar({required this.reduceMotion});

  @override
  State<_FillBar> createState() => _FillBarState();
}

class _FillBarState extends State<_FillBar>
    with SingleTickerProviderStateMixin {
  AnimationController? _glow;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _glow = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glow?.dispose();
    super.dispose();
  }

  Widget _bar(double glowAlpha) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primary, Color(0xFF74D6E8)],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: glowAlpha),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glow = _glow;
    if (glow == null) return _bar(0.6);
    return AnimatedBuilder(
      animation: glow,
      builder: (context, _) => _bar(0.45 + 0.35 * glow.value),
    );
  }
}

/// Offline state: badge + cause-specific message + faint code + retry CTA.
/// Composed like the connection-lost reference (mark → message → full-width
/// pill button), rendered in AMS navy rather than a carrier's red. The icon,
/// title, and guidance change with [fault] so the user knows *what* failed and
/// what to do about it.
class _ErrorBlock extends StatelessWidget {
  final SplashFault fault;
  final String? detail;
  final VoidCallback onRetry;

  const _ErrorBlock({
    super.key,
    required this.fault,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final content = _ErrorContent.of(fault);
    final code = detail;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(
              content.icon,
              size: 28,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            content.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.heading.copyWith(
              color: Colors.white,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            content.subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
              height: 1.5,
            ),
          ),
          if (code != null && code.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            // Caption floor is 12px and must still clear 4.5:1 on navy — a
            // fainter whisper would fail both the type scale and WCAG.
            Text(
              'ລະຫັດ: $code',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.66),
                letterSpacing: 0.2,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.l),
          _RetryButton(onRetry: onRetry),
        ],
      ),
    );
  }
}

/// Icon + Lao message pair for each [SplashFault].
class _ErrorContent {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ErrorContent({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  static _ErrorContent of(SplashFault fault) {
    switch (fault) {
      case SplashFault.offline:
        return const _ErrorContent(
          icon: Icons.wifi_off_rounded,
          title: 'ບໍ່ສາມາດເຊື່ອມຕໍ່ອິນເຕີເນັດ',
          subtitle: 'ກະລຸນາກວດສອບ Wi-Fi ຫຼື ອິນເຕີເນັດມືຖື ແລ້ວລອງໃໝ່ອີກຄັ້ງ',
        );
      case SplashFault.timeout:
        return const _ErrorContent(
          icon: Icons.cloud_off_rounded,
          title: 'ເຊີບເວີບໍ່ຕອບສະໜອງ',
          subtitle: 'ສັນຍານອາດອ່ອນ ຫຼື ເຊີບເວີຍຸ່ງ. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ',
        );
      case SplashFault.config:
        return const _ErrorContent(
          icon: Icons.report_gmailerrorred_outlined,
          title: 'ການຕັ້ງຄ່າແອັບບໍ່ຖືກຕ້ອງ',
          subtitle: 'ບໍ່ພົບທີ່ຢູ່ເຊີບເວີຂອງລະບົບ. ກະລຸນາຕິດຕໍ່ຜູ້ດູແລລະບົບ',
        );
      case SplashFault.unknown:
        return const _ErrorContent(
          icon: Icons.error_outline_rounded,
          title: 'ເກີດຂໍ້ຜິດພາດໃນການເຊື່ອມຕໍ່',
          subtitle: 'ມີບາງຢ່າງຜິດພາດ. ກະລຸນາລອງໃໝ່ອີກຄັ້ງ',
        );
    }
  }
}

/// Full-width teal pill, white label, lifted off the navy by a teal accent
/// glow (luminance alone can't separate an AA-safe teal fill from navy).
class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final width = screenW > 0 ? math.min(screenW * 0.72, 280.0) : 280.0;
    return SizedBox(
      width: width,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.34),
              blurRadius: 18,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('ລອງເຊື່ອມຕໍ່ໃໝ່'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryFill,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Brand line pinned near the bottom safe-area.
class _FooterCaption extends StatelessWidget {
  const _FooterCaption();

  @override
  Widget build(BuildContext context) {
    return Text(
      'CEIT · Academic Management System',
      textAlign: TextAlign.center,
      style: AppTypography.caption.copyWith(
        color: Colors.white.withValues(alpha: 0.66),
        letterSpacing: 0.3,
      ),
    );
  }
}

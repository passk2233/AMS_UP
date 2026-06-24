import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Animated shimmer wrapper. Any child rendered inside is painted with a
/// soft diagonal gradient that loops to suggest loading content.
///
/// Skeleton primitives below ([AppSkeletonBox], [AppSkeletonLine],
/// [AppSkeletonCircle]) are already wrapped, so usually you compose
/// those directly rather than wrapping content yourself.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.baseColor = const Color(0xFFE6EAF0),
    this.highlightColor = const Color(0xFFF5F7FA),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - 2 * t, -0.3),
              end: Alignment(1.0 - 2 * t, 0.3),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Solid rectangular shimmer block.
class AppSkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry margin;

  const AppSkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 6,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: const Color(0xFFE6EAF0),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Single-line text shimmer (height matches a typical body text).
class AppSkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final EdgeInsetsGeometry margin;

  const AppSkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeletonBox(
      width: width,
      height: height,
      radius: 4,
      margin: margin,
    );
  }
}

/// Circular shimmer placeholder (avatar / icon bubble).
class AppSkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry margin;

  const AppSkeletonCircle({
    super.key,
    this.size = 48,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: size,
        height: size,
        margin: margin,
        decoration: const BoxDecoration(
          color: Color(0xFFE6EAF0),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Surface used by every skeleton card so they share the same elevation /
/// radius / shadow as [AppSurfaceCard] (`alpha 0.06`, blur 8, offset 0,2).
Widget _skeletonSurface({
  required Widget child,
  EdgeInsetsGeometry margin = EdgeInsets.zero,
  EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  Color? borderLeftColor,
  double borderLeftWidth = 4,
  double radius = AppColors.cardRadius,
}) {
  return Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: borderLeftColor != null
          ? Border(
              left: BorderSide(
                  color: borderLeftColor, width: borderLeftWidth),
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
}

/// A single card-shaped skeleton placeholder used inside list / dashboard
/// skeletons. Mirrors the height + radius of [AppSurfaceCard].
class AppCardSkeleton extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry margin;

  const AppCardSkeleton({
    super.key,
    this.height = 88,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return _skeletonSurface(
      margin: margin,
      child: SizedBox(
        height: height - 28,
        child: Row(
          children: [
            const AppSkeletonCircle(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  AppSkeletonLine(width: 180, height: 12),
                  AppSkeletonLine(width: 120, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Default page-level skeleton: a vertical stack of [AppCardSkeleton]s.
class AppListSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const AppListSkeleton({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, _) => const AppCardSkeleton(),
    );
  }
}

/// Student home: greeting (no trailing bell — it lives in the top bar) +
/// 2-stat banner + 3 stat cards + class list. Mirrors `HomePage`.
class AppDashboardSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const AppDashboardSkeleton({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 100),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting header — name + date, no trailing action bubble.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AppSkeletonLine(width: 210, height: 17),
              AppSkeletonLine(width: 120, height: 13, margin: EdgeInsets.zero),
            ],
          ),
          const SizedBox(height: 25),
          // AppStatsBanner.
          const AppSkeletonBox(height: 76, radius: AppColors.cardRadius),
          const SizedBox(height: 25),
          // 3 AppStatCards.
          Row(
            children: const [
              Expanded(child: AppSkeletonBox(height: 110, radius: 14)),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 110, radius: 14)),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 110, radius: 14)),
            ],
          ),
          const SizedBox(height: 26),
          // "ຫ້ອງຮຽນມື້ນີ້" section heading (AppTypography.heading, 18).
          const AppSkeletonLine(width: 140, height: 16),
          const SizedBox(height: 14),
          const AppClassCardSkeleton(),
          const AppClassCardSkeleton(),
          const AppClassCardSkeleton(),
        ],
      ),
    );
  }
}

/// Teacher home dashboard: greeting + profile header card + 3-stat banner +
/// 4 quick-action tiles + class list. Mirrors `TeacherHomeView` (which adds a
/// profile card and quick actions the student home does not have, and uses a
/// 16-pt screen margin).
class AppTeacherDashboardSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const AppTeacherDashboardSkeleton({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 100),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting header.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AppSkeletonLine(width: 210, height: 17),
              AppSkeletonLine(width: 120, height: 13, margin: EdgeInsets.zero),
            ],
          ),
          const SizedBox(height: 16),
          // AppProfileHeader card (avatar + name + role + department).
          _skeletonSurface(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const AppSkeletonCircle(size: 70),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonLine(width: 160, height: 15),
                      AppSkeletonLine(width: 100, height: 12),
                      AppSkeletonLine(
                          width: 150, height: 12, margin: EdgeInsets.zero),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 3-stat banner.
          const AppSkeletonBox(height: 76, radius: AppColors.cardRadius),
          const SizedBox(height: 16),
          // Quick-action row — 4 equal tiles.
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Expanded(child: _quickActionSkeleton()),
                if (i < 3) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 24),
          const AppSkeletonLine(width: 140, height: 16),
          const SizedBox(height: 8),
          const AppClassCardSkeleton(),
          const AppClassCardSkeleton(),
          const AppClassCardSkeleton(),
        ],
      ),
    );
  }

  Widget _quickActionSkeleton() {
    return _skeletonSurface(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: const [
          AppSkeletonCircle(size: 38),
          SizedBox(height: 6),
          AppSkeletonBox(width: 40, height: 10, radius: 4),
        ],
      ),
    );
  }
}

/// Profile screens (student / teacher): avatar header card + three grouped
/// info-card blocks + a wide sign-out action. Mirrors `ProfileStudentView` /
/// `TeacherProfileView`, both of which render three info sections.
class AppProfileSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const AppProfileSkeleton({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 100),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // AppProfileHeader — AppAvatar(radius 35) = 70px circle.
          _skeletonSurface(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const AppSkeletonCircle(size: 70),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonLine(width: 160, height: 15),
                      AppSkeletonLine(width: 100, height: 12),
                      AppSkeletonLine(
                          width: 140, height: 12, margin: EdgeInsets.zero),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _sectionTitle(),
          _infoCardSkeleton(rows: 4),
          const SizedBox(height: 20),
          _sectionTitle(),
          _infoCardSkeleton(rows: 3),
          const SizedBox(height: 20),
          _sectionTitle(),
          _infoCardSkeleton(rows: 2),
          const SizedBox(height: 30),
          // AppSignOutButton (height = minTouchTarget 48, buttonRadius 12).
          const AppSkeletonBox(height: 48, radius: 12),
        ],
      ),
    );
  }

  /// AppSectionTitle — small left-aligned label with 5pt left / 8pt bottom
  /// padding.
  Widget _sectionTitle() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 5, bottom: 8),
        child: AppSkeletonLine(width: 110, height: 10, margin: EdgeInsets.zero),
      ),
    );
  }

  Widget _infoCardSkeleton({required int rows}) {
    return _skeletonSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(
          rows,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // AppInfoTile leading = round bubble (8pt pad + 20 icon = 36).
                const AppSkeletonCircle(size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonLine(width: 80, height: 10),
                      AppSkeletonLine(
                          width: 150, height: 12, margin: EdgeInsets.zero),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One [AppClassCard] placeholder — tinted square icon bubble + title/subtitle
/// + a meta row of two inline icon-text groups. The real card has **no** left
/// border (only the icon bubble + title are tinted), so neither does this.
class AppClassCardSkeleton extends StatelessWidget {
  const AppClassCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _skeletonSurface(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              // Tinted rounded-square bubble (8pt pad + 20 icon = 36, radius 10).
              AppSkeletonBox(width: 36, height: 36, radius: 10),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonLine(width: 150, height: 13),
                    AppSkeletonLine(
                        width: 90, height: 11, margin: EdgeInsets.zero),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Meta pills row (Wrap spacing 16) — time / instructor / location.
          Row(
            children: const [
              AppSkeletonBox(width: 70, height: 12, radius: 4),
              SizedBox(width: 16),
              AppSkeletonBox(width: 90, height: 12, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/// Schedule pages (student & teacher): vertical list of [AppClassCard]
/// placeholders. The surrounding date picker / day chips are rendered by the
/// page itself, so this only fills the list region.
class AppScheduleSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const AppScheduleSkeleton({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, _) => const AppClassCardSkeleton(),
    );
  }
}

/// One student/teacher booking row (ListTile shape): title + 2 subtitle lines
/// + trailing status pill. Mirrors `StudentBookingCard` / `TeacherBookingCard`.
class _BookingRowSkeleton extends StatelessWidget {
  const _BookingRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return _skeletonSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeletonLine(width: 170, height: 13),
                AppSkeletonLine(width: 130, height: 11),
                AppSkeletonLine(
                    width: 180, height: 11, margin: EdgeInsets.zero),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const AppSkeletonBox(width: 80, height: 26, radius: 20),
        ],
      ),
    );
  }
}

/// Booking screens (student & teacher): 4-tile stats row + section title +
/// filter chips + booking rows. Mirrors `BookingStudentView` / `BookingView`.
class AppBookingHistorySkeleton extends StatelessWidget {
  final int itemCount;
  const AppBookingHistorySkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Stats row — 4 colored tiles.
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              const Expanded(child: AppSkeletonBox(height: 80, radius: 12)),
              if (i < 3) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // Section title + count caption.
        Row(
          children: const [
            Expanded(child: AppSkeletonLine(width: 160, height: 14)),
            SizedBox(width: 8),
            AppSkeletonBox(width: 60, height: 11, radius: 4),
          ],
        ),
        const SizedBox(height: 8),
        // Filter chips.
        Row(
          children: const [
            AppSkeletonBox(width: 64, height: 32, radius: 20),
            SizedBox(width: 8),
            AppSkeletonBox(width: 80, height: 32, radius: 20),
            SizedBox(width: 8),
            AppSkeletonBox(width: 72, height: 32, radius: 20),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(itemCount, (_) => const _BookingRowSkeleton()),
      ],
    );
  }
}

/// One admin [BookingCard] placeholder — status circle + room/time header,
/// booker row, date/location meta row, and a two-button action row.
class _AdminBookingCardSkeleton extends StatelessWidget {
  const _AdminBookingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return _skeletonSurface(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: status circle + room title + time.
          Row(
            children: const [
              AppSkeletonCircle(size: 22),
              SizedBox(width: 8),
              Expanded(child: AppSkeletonBox(width: 120, height: 14, radius: 4)),
              SizedBox(width: 8),
              AppSkeletonBox(width: 64, height: 11, radius: 4),
            ],
          ),
          const SizedBox(height: 10),
          // Booker name + role pill.
          Row(
            children: const [
              AppSkeletonBox(width: 110, height: 12, radius: 4),
              SizedBox(width: 6),
              AppSkeletonBox(width: 50, height: 18, radius: 6),
            ],
          ),
          const SizedBox(height: 10),
          // Date + location meta row.
          Row(
            children: const [
              AppSkeletonBox(width: 14, height: 14, radius: 4),
              SizedBox(width: 4),
              AppSkeletonBox(width: 100, height: 11, radius: 4),
              Spacer(),
              AppSkeletonBox(width: 14, height: 14, radius: 4),
              SizedBox(width: 4),
              AppSkeletonBox(width: 60, height: 11, radius: 4),
            ],
          ),
          const SizedBox(height: 14),
          // Approve / reject action buttons.
          Row(
            children: const [
              Expanded(child: AppSkeletonBox(height: 40, radius: 8)),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 40, radius: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Student notifications: urgent label + tinted urgent card + recent
/// notification rows. Mirrors `UrgentNotificationCard` / `RecentNotificationCard`.
class AppNotificationsSkeleton extends StatelessWidget {
  const AppNotificationsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const AppSkeletonLine(width: 90, height: 11),
        const SizedBox(height: 10),
        // Urgent card — red-tinted surface.
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.rejectRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
            border:
                Border.all(color: AppColors.rejectRed.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon bubble (8pt pad + 24 icon = 40, radius 10).
              const AppSkeletonBox(width: 40, height: 40, radius: 10),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: AppSkeletonBox(
                              width: 160, height: 13, radius: 4),
                        ),
                        SizedBox(width: 8),
                        AppSkeletonBox(width: 36, height: 10, radius: 4),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const AppSkeletonLine(width: 200, height: 11),
                    const AppSkeletonLine(
                        width: 120, height: 11, margin: EdgeInsets.zero),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...List.generate(3, (_) => _recentCardSkeleton()),
      ],
    );
  }

  Widget _recentCardSkeleton() {
    return _skeletonSurface(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular icon bubble (10pt pad + 22 icon = 42).
          const AppSkeletonCircle(size: 42),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(
                      child:
                          AppSkeletonBox(width: 150, height: 13, radius: 4),
                    ),
                    SizedBox(width: 8),
                    AppSkeletonBox(width: 36, height: 10, radius: 4),
                  ],
                ),
                const SizedBox(height: 8),
                const AppSkeletonLine(
                    width: 220, height: 11, margin: EdgeInsets.zero),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Announcement history rows: icon bubble + title + relative time + message
/// + type tag + divider + a 3-button action row. Mirrors `HistoryTile`.
class AppHistoryListSkeleton extends StatelessWidget {
  final int itemCount;
  const AppHistoryListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, _) => _skeletonSurface(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row — icon bubble (7pt pad + 18 icon = 32, radius 8) +
            // title + relative time below.
            Row(
              children: const [
                AppSkeletonBox(width: 32, height: 32, radius: 8),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonLine(width: 140, height: 12),
                      AppSkeletonLine(
                          width: 80, height: 10, margin: EdgeInsets.zero),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const AppSkeletonLine(width: double.infinity, height: 10),
            const AppSkeletonLine(
                width: 200, height: 10, margin: EdgeInsets.zero),
            const SizedBox(height: 8),
            // Type tag.
            const AppSkeletonBox(width: 60, height: 18, radius: 6),
            const Divider(height: 18),
            // Edit / resend / delete action pills.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                AppSkeletonBox(width: 60, height: 28, radius: 8),
                SizedBox(width: 8),
                AppSkeletonBox(width: 70, height: 28, radius: 8),
                SizedBox(width: 8),
                AppSkeletonBox(width: 50, height: 28, radius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin approve: 3 stat chips, search bar + selection toggle, filter tabs,
/// admin booking cards. Mirrors `ApproveView`.
class AppAdminApproveSkeleton extends StatelessWidget {
  const AppAdminApproveSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3 stat chips.
          Row(
            children: const [
              Expanded(child: AppSkeletonBox(height: 60, radius: 12)),
              SizedBox(width: 8),
              Expanded(child: AppSkeletonBox(height: 60, radius: 12)),
              SizedBox(width: 8),
              Expanded(child: AppSkeletonBox(height: 60, radius: 12)),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar + 48x48 selection toggle.
          Row(
            children: const [
              Expanded(child: AppSkeletonBox(height: 48, radius: 12)),
              SizedBox(width: 8),
              AppSkeletonBox(width: 48, height: 48, radius: 10),
            ],
          ),
          const SizedBox(height: 12),
          // Filter tabs (with count badges → a touch wider).
          Row(
            children: const [
              AppSkeletonBox(width: 78, height: 34, radius: 20),
              SizedBox(width: 8),
              AppSkeletonBox(width: 78, height: 34, radius: 20),
              SizedBox(width: 8),
              AppSkeletonBox(width: 78, height: 34, radius: 20),
              SizedBox(width: 8),
              AppSkeletonBox(width: 78, height: 34, radius: 20),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(3, (_) => const _AdminBookingCardSkeleton()),
        ],
      ),
    );
  }
}

/// Admin home: gradient profile/stats card + section header + admin booking
/// cards. Mirrors `AdminHomeView` (`ProfileCard` + pending `BookingCard`s).
class AppAdminHomeSkeleton extends StatelessWidget {
  const AppAdminHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ProfileCard — gradient banner (radius cardRadius + 2 = 16).
          _skeletonSurface(
            padding: const EdgeInsets.all(16),
            radius: AppColors.cardRadius + 2,
            child: Column(
              children: [
                Row(
                  children: [
                    // White-ringed avatar (48px).
                    const AppSkeletonCircle(size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          AppSkeletonLine(width: 160, height: 14),
                          AppSkeletonLine(width: 100, height: 11),
                          AppSkeletonLine(
                              width: 150, height: 11, margin: EdgeInsets.zero),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 3 translucent stat tiles (radius 10).
                Row(
                  children: const [
                    Expanded(child: AppSkeletonBox(height: 64, radius: 10)),
                    SizedBox(width: 8),
                    Expanded(child: AppSkeletonBox(height: 64, radius: 10)),
                    SizedBox(width: 8),
                    Expanded(child: AppSkeletonBox(height: 64, radius: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // "ລາຍການອະນຸມັດການໃຊ້ຫ້ອງ" header + today's date.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppSkeletonLine(width: 200, height: 14),
              AppSkeletonLine(width: 80, height: 10),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(3, (_) => const _AdminBookingCardSkeleton()),
        ],
      ),
    );
  }
}

/// Faculty list cards: avatar + name/course + wide action button. Mirrors the
/// faculty card in `FacultyFeedbackView`.
class AppFacultyListSkeleton extends StatelessWidget {
  final int itemCount;
  const AppFacultyListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, _) => _skeletonSurface(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // AppAvatar(radius 30) = 60px circle.
                const AppSkeletonCircle(size: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonLine(width: 160, height: 15),
                      AppSkeletonLine(
                          width: 110, height: 13, margin: EdgeInsets.zero),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Action button (height = minTouchTarget 48).
            const AppSkeletonBox(height: 48, radius: 12),
          ],
        ),
      ),
    );
  }
}

/// Teacher feedback list: subject header + meta line + tinted question block +
/// quoted comment. Mirrors the feedback card (which has **no** left border).
class AppFeedbacksListSkeleton extends StatelessWidget {
  final int itemCount;
  const AppFeedbacksListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, _) => _skeletonSurface(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSkeletonLine(width: 180, height: 13),
            const AppSkeletonLine(
                width: 130, height: 11, margin: EdgeInsets.zero),
            const SizedBox(height: 8),
            // Tinted question block.
            const AppSkeletonBox(
                width: double.infinity, height: 34, radius: 8),
            const SizedBox(height: 10),
            // Quoted comment row — quote icon + text.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeletonBox(width: 16, height: 16, radius: 4),
                SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonLine(width: double.infinity, height: 11),
                      AppSkeletonLine(
                          width: 200, height: 11, margin: EdgeInsets.zero),
                    ],
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

/// Teacher evaluation: colored hero score card + 2 stat cards + section title +
/// expandable per-subject cards (no left border). Mirrors `TeacherEvaluationView`.
class AppEvaluationSkeleton extends StatelessWidget {
  const AppEvaluationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // OverallScoreCard.
          const AppSkeletonBox(height: 88, radius: AppColors.cardRadius),
          const SizedBox(height: 16),
          // 2 AppStatCards.
          Row(
            children: const [
              Expanded(child: AppSkeletonBox(height: 110, radius: 14)),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 110, radius: 14)),
            ],
          ),
          const SizedBox(height: 24),
          // "ການປະເມີນແຕ່ລະວິຊາ" heading.
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: AppSkeletonLine(width: 200, height: 16),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => _skeletonSurface(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppSkeletonLine(width: 200, height: 14),
                  AppSkeletonLine(width: 140, height: 11),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      // Score pill + respondent count.
                      AppSkeletonBox(width: 64, height: 24, radius: 10),
                      SizedBox(width: 10),
                      AppSkeletonBox(width: 90, height: 12, radius: 4),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin evaluation – questions page: header row with count + add button,
/// then question cards (left-border accent + action row). Mirrors
/// `EvalQuestionCard` (radius 12, left border width 4).
class AppQuestionListSkeleton extends StatelessWidget {
  const AppQuestionListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: const [
              AppSkeletonLine(
                  width: 160, height: 13, margin: EdgeInsets.zero),
              Spacer(),
              AppSkeletonBox(width: 80, height: 34, radius: 10),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (_, _) => _skeletonSurface(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              radius: 12,
              borderLeftColor: const Color(0xFFE6EAF0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      // Number bubble + category chip + active toggle.
                      AppSkeletonBox(width: 28, height: 28, radius: 8),
                      SizedBox(width: 8),
                      AppSkeletonBox(width: 70, height: 20, radius: 6),
                      Spacer(),
                      AppSkeletonBox(width: 44, height: 20, radius: 6),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const AppSkeletonLine(width: double.infinity, height: 12),
                  const AppSkeletonLine(
                      width: 220, height: 12, margin: EdgeInsets.zero),
                  const SizedBox(height: 10),
                  // Edit / delete action row.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      AppSkeletonBox(width: 60, height: 28, radius: 8),
                      SizedBox(width: 8),
                      AppSkeletonBox(width: 50, height: 28, radius: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Admin evaluation – results page: search bar + teacher rank cards. Mirrors
/// `EvalTeacherCard` (rounded-square rank bubble, stars row, trailing chevron).
class AppResultsListSkeleton extends StatelessWidget {
  const AppResultsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppSkeletonBox(height: 48, radius: 12),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (_, _) => _skeletonSurface(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Rounded-square rank bubble (48px, radius 12).
                  const AppSkeletonBox(width: 48, height: 48, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSkeletonLine(width: 160, height: 13),
                        const AppSkeletonLine(width: 110, height: 11),
                        const AppSkeletonLine(width: 140, height: 11),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            // Star row + numeric score.
                            AppSkeletonBox(width: 80, height: 14, radius: 4),
                            SizedBox(width: 6),
                            AppSkeletonBox(width: 30, height: 12, radius: 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Trailing chevron.
                  const AppSkeletonBox(width: 20, height: 20, radius: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Score page: profile header card + 4-cell transcript strip + section title +
/// semester chips + score cards with circular grade badge. Mirrors `ScoreView`.
class AppScoreSkeleton extends StatelessWidget {
  const AppScoreSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AppProfileHeader — AppAvatar(radius 35) = 70px circle.
          _skeletonSurface(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const AppSkeletonCircle(size: 70),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonLine(width: 160, height: 15),
                      AppSkeletonLine(width: 110, height: 12),
                      AppSkeletonLine(
                          width: 180, height: 11, margin: EdgeInsets.zero),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // TranscriptStatStrip — single 4-cell rounded strip.
          const AppSkeletonBox(height: 76, radius: AppColors.cardRadius),
          const SizedBox(height: 24),
          // "ຄະແນນແຕ່ລະພາກຮຽນ" subheading (16).
          const AppSkeletonLine(width: 200, height: 16),
          const SizedBox(height: 10),
          // Semester chips (height = minTouchTarget 48, chipRadius 20).
          Row(
            children: const [
              AppSkeletonBox(width: 86, height: 48, radius: 20),
              SizedBox(width: 10),
              AppSkeletonBox(width: 86, height: 48, radius: 20),
              SizedBox(width: 10),
              AppSkeletonBox(width: 86, height: 48, radius: 20),
            ],
          ),
          const Divider(height: 28),
          // Selected-semester label.
          const AppSkeletonLine(width: 120, height: 13),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => _skeletonSurface(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppSkeletonLine(width: 130, height: 11),
                        SizedBox(height: 4),
                        AppSkeletonLine(width: 180, height: 14),
                        AppSkeletonLine(
                            width: 120, height: 11, margin: EdgeInsets.zero),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Circular grade badge (52px) + caption.
                  Column(
                    children: const [
                      AppSkeletonCircle(size: 52),
                      SizedBox(height: 5),
                      AppSkeletonBox(width: 40, height: 9, radius: 4),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

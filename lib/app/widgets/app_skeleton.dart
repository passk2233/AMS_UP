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
/// radius as [AppSurfaceCard].
Widget _skeletonSurface({
  required Widget child,
  EdgeInsetsGeometry margin = EdgeInsets.zero,
  EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  Color? borderLeftColor,
  double borderLeftWidth = 4,
}) {
  return Container(
    margin: margin,
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(AppColors.cardRadius),
      border: borderLeftColor != null
          ? Border(
              left: BorderSide(
                  color: borderLeftColor, width: borderLeftWidth),
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
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

/// Student/teacher home: greeting + banner + 3 stat cards + class list.
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonLine(width: 200, height: 16),
                    AppSkeletonLine(width: 120, height: 12),
                  ],
                ),
              ),
              SizedBox(width: 12),
              AppSkeletonBox(width: 48, height: 48, radius: 14),
            ],
          ),
          const SizedBox(height: 20),
          const AppSkeletonBox(height: 92, radius: 14),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: AppSkeletonBox(height: 92, radius: 14)),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 92, radius: 14)),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 92, radius: 14)),
            ],
          ),
          const SizedBox(height: 24),
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

/// Profile screens: avatar header card + two grouped info-card blocks +
/// a wide action skeleton.
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
                      AppSkeletonLine(width: 160, height: 14),
                      AppSkeletonLine(width: 100, height: 12),
                      AppSkeletonLine(width: 140, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const AppSkeletonLine(width: 120, height: 10),
          const SizedBox(height: 8),
          _infoCardSkeleton(rows: 4),
          const SizedBox(height: 20),
          const AppSkeletonLine(width: 120, height: 10),
          const SizedBox(height: 8),
          _infoCardSkeleton(rows: 3),
          const SizedBox(height: 30),
          const AppSkeletonBox(height: 48, radius: 14),
        ],
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
                const AppSkeletonCircle(size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonLine(width: 80, height: 10),
                      AppSkeletonLine(width: 150, height: 12),
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

/// One AppClassCard placeholder — colored left border + title pills row.
class AppClassCardSkeleton extends StatelessWidget {
  const AppClassCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _skeletonSurface(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      borderLeftColor: const Color(0xFFE6EAF0),
      borderLeftWidth: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              AppSkeletonCircle(size: 36),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonLine(width: 180, height: 13),
                    AppSkeletonLine(width: 110, height: 11),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              AppSkeletonBox(width: 90, height: 22, radius: 11),
              SizedBox(width: 8),
              AppSkeletonBox(width: 110, height: 22, radius: 11),
            ],
          ),
        ],
      ),
    );
  }
}

/// Schedule pages (student & teacher): vertical list of class-card
/// placeholders. The surrounding date picker / day chips are rendered by
/// the page itself, so this only fills the list region.
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

/// One booking-history row: title + 2 subtitle lines + trailing status pill.
class _BookingRowSkeleton extends StatelessWidget {
  const _BookingRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return _skeletonSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeletonLine(width: 170, height: 13),
                AppSkeletonLine(width: 130, height: 11),
                AppSkeletonLine(width: 180, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const AppSkeletonBox(width: 70, height: 26, radius: 20),
        ],
      ),
    );
  }
}

/// Booking screens (student & teacher): section title + rows with trailing
/// status pill.
class AppBookingHistorySkeleton extends StatelessWidget {
  final int itemCount;
  const AppBookingHistorySkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const AppSkeletonLine(width: 180, height: 14),
        const SizedBox(height: 10),
        ...List.generate(itemCount, (_) => const _BookingRowSkeleton()),
      ],
    );
  }
}

/// Student notifications: urgent label + tinted urgent card + 3 recent
/// cards (icon bubble + title + description).
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
              const AppSkeletonBox(width: 38, height: 38, radius: 10),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AppSkeletonLine(width: 160, height: 13),
                    AppSkeletonLine(width: 200, height: 11),
                    AppSkeletonLine(width: 120, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...List.generate(
          3,
          (_) => _skeletonSurface(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeletonCircle(size: 42),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonLine(width: 150, height: 13),
                      AppSkeletonLine(width: 220, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Announcement history rows: small left icon, title line, time, body.
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSkeletonBox(width: 36, height: 36, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Expanded(child: AppSkeletonLine(width: 140, height: 12)),
                      SizedBox(width: 8),
                      AppSkeletonBox(width: 50, height: 10, radius: 4),
                    ],
                  ),
                  AppSkeletonLine(width: double.infinity, height: 10),
                  AppSkeletonLine(width: 200, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin approve: 3 status chips, search bar, filter tabs, booking cards.
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
          Row(
            children: const [
              Expanded(child: AppSkeletonBox(height: 56, radius: 12)),
              SizedBox(width: 8),
              Expanded(child: AppSkeletonBox(height: 56, radius: 12)),
              SizedBox(width: 8),
              Expanded(child: AppSkeletonBox(height: 56, radius: 12)),
            ],
          ),
          const SizedBox(height: 12),
          const AppSkeletonBox(height: 44, radius: 12),
          const SizedBox(height: 12),
          Row(
            children: const [
              AppSkeletonBox(width: 70, height: 32, radius: 20),
              SizedBox(width: 8),
              AppSkeletonBox(width: 70, height: 32, radius: 20),
              SizedBox(width: 8),
              AppSkeletonBox(width: 70, height: 32, radius: 20),
              SizedBox(width: 8),
              AppSkeletonBox(width: 70, height: 32, radius: 20),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => const _BookingRowSkeleton()),
        ],
      ),
    );
  }
}

/// Admin home: large profile/stats card + section header + booking cards.
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
          _skeletonSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const AppSkeletonCircle(size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          AppSkeletonLine(width: 160, height: 14),
                          AppSkeletonLine(width: 100, height: 11),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(child: AppSkeletonBox(height: 64, radius: 12)),
                    SizedBox(width: 10),
                    Expanded(child: AppSkeletonBox(height: 64, radius: 12)),
                    SizedBox(width: 10),
                    Expanded(child: AppSkeletonBox(height: 64, radius: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppSkeletonLine(width: 200, height: 14),
              AppSkeletonLine(width: 80, height: 10),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(3, (_) => const _BookingRowSkeleton()),
        ],
      ),
    );
  }
}

/// Faculty list cards: avatar + name/course + wide action button.
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
                const AppSkeletonCircle(size: 60),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonLine(width: 160, height: 14),
                      AppSkeletonLine(width: 110, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const AppSkeletonBox(height: 44, radius: 12),
          ],
        ),
      ),
    );
  }
}

/// Teacher feedback list: subject header + meta line + comment block.
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
        borderLeftColor: AppColors.statsBlue.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            AppSkeletonLine(width: 180, height: 13),
            AppSkeletonLine(width: 130, height: 11),
            SizedBox(height: 6),
            AppSkeletonLine(width: double.infinity, height: 11),
            AppSkeletonLine(width: 250, height: 11),
          ],
        ),
      ),
    );
  }
}

/// Teacher evaluation: colored hero banner + 2 stat cards + section title +
/// 3 colored expansion cards.
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
          const AppSkeletonBox(height: 100, radius: 14),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: AppSkeletonBox(height: 88, radius: 14)),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonBox(height: 88, radius: 14)),
            ],
          ),
          const SizedBox(height: 24),
          const AppSkeletonLine(width: 200, height: 16),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => _skeletonSurface(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              borderLeftColor: const Color(0xFFE6EAF0),
              borderLeftWidth: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppSkeletonLine(width: 200, height: 13),
                  AppSkeletonLine(width: 140, height: 11),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      AppSkeletonBox(width: 60, height: 24, radius: 10),
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
/// then numbered question cards.
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
              AppSkeletonLine(width: 160, height: 13),
              Spacer(),
              AppSkeletonBox(width: 80, height: 32, radius: 10),
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
              borderLeftColor: const Color(0xFFE6EAF0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      AppSkeletonBox(width: 28, height: 28, radius: 8),
                      SizedBox(width: 8),
                      AppSkeletonBox(width: 80, height: 20, radius: 6),
                      Spacer(),
                      AppSkeletonBox(width: 50, height: 20, radius: 6),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const AppSkeletonLine(width: double.infinity, height: 12),
                  const AppSkeletonLine(width: 220, height: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Admin evaluation – results page: search bar + teacher cards.
class AppResultsListSkeleton extends StatelessWidget {
  const AppResultsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppSkeletonBox(height: 44, radius: 12),
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
                  const AppSkeletonCircle(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppSkeletonLine(width: 160, height: 13),
                        AppSkeletonLine(width: 110, height: 11),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const AppSkeletonBox(width: 56, height: 28, radius: 14),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Score page: profile header card + 3-item banner + term chips row +
/// score cards with circular grade badge on the right.
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
          _skeletonSurface(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const AppSkeletonCircle(size: 64),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeletonLine(width: 160, height: 14),
                      AppSkeletonLine(width: 110, height: 12),
                      AppSkeletonLine(width: 180, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AppSkeletonBox(height: 92, radius: 14),
          const SizedBox(height: 24),
          const AppSkeletonLine(width: 200, height: 14),
          const SizedBox(height: 10),
          Row(
            children: const [
              AppSkeletonBox(width: 86, height: 38, radius: 18),
              SizedBox(width: 10),
              AppSkeletonBox(width: 86, height: 38, radius: 18),
              SizedBox(width: 10),
              AppSkeletonBox(width: 86, height: 38, radius: 18),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (_) => _skeletonSurface(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              borderLeftColor: const Color(0xFFE6EAF0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppSkeletonLine(width: 130, height: 11),
                        SizedBox(height: 4),
                        AppSkeletonLine(width: 180, height: 14),
                        AppSkeletonLine(width: 120, height: 11),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: const [
                      AppSkeletonCircle(size: 52),
                      SizedBox(height: 4),
                      AppSkeletonLine(width: 40, height: 9),
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

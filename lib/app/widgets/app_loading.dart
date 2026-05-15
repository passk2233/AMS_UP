import 'package:flutter/material.dart';

import 'app_skeleton.dart';

/// Shared page-level loading indicator.
///
/// Renders a skeleton placeholder shaped like the actual content that's
/// about to load. Use the page-matched named constructor whenever possible
/// (e.g. `AppLoading.schedule()` for class-list pages, `AppLoading.profile()`
/// for profile screens) so the placeholder closely mirrors the rendered
/// layout. The default `AppLoading()` falls back to a generic card stack.
class AppLoading extends StatelessWidget {
  final AppLoadingVariant variant;
  final int itemCount;

  const AppLoading({
    super.key,
    this.variant = AppLoadingVariant.list,
    this.itemCount = 5,
  });

  /// Student/teacher home dashboard: greeting + banner + 3 stat cards +
  /// class list.
  const AppLoading.dashboard({super.key})
      : variant = AppLoadingVariant.dashboard,
        itemCount = 0;

  /// Profile screens: avatar header + 2 grouped info-card blocks + action.
  const AppLoading.profile({super.key})
      : variant = AppLoadingVariant.profile,
        itemCount = 0;

  /// Schedule pages (student & teacher): class-card list only — the
  /// surrounding day chips / date picker is rendered by the page itself.
  const AppLoading.schedule({super.key, this.itemCount = 5})
      : variant = AppLoadingVariant.schedule;

  /// Booking history (student & teacher): section title + rows with
  /// trailing status pill.
  const AppLoading.booking({super.key, this.itemCount = 4})
      : variant = AppLoadingVariant.booking;

  /// Student notifications: urgent label + tinted urgent card + recent
  /// notification rows.
  const AppLoading.notifications({super.key})
      : variant = AppLoadingVariant.notifications,
        itemCount = 0;

  /// Announcement history list: small icon + title + meta + body rows.
  const AppLoading.historyList({super.key, this.itemCount = 6})
      : variant = AppLoadingVariant.historyList;

  /// Admin approve: 3 stat chips + search bar + filter tabs + booking
  /// cards.
  const AppLoading.adminApprove({super.key})
      : variant = AppLoadingVariant.adminApprove,
        itemCount = 0;

  /// Admin home: large profile/stats card + section header + booking
  /// cards.
  const AppLoading.adminHome({super.key})
      : variant = AppLoadingVariant.adminHome,
        itemCount = 0;

  /// Faculty list: avatar + name/course + wide action button cards.
  const AppLoading.facultyList({super.key, this.itemCount = 4})
      : variant = AppLoadingVariant.facultyList;

  /// Teacher feedback list: subject header + meta + comment block cards.
  const AppLoading.feedbacks({super.key, this.itemCount = 4})
      : variant = AppLoadingVariant.feedbacks;

  /// Teacher evaluation: hero banner + 2 stat cards + section + cards.
  const AppLoading.evaluation({super.key})
      : variant = AppLoadingVariant.evaluation,
        itemCount = 0;

  /// Admin evaluation – questions page.
  const AppLoading.questionList({super.key})
      : variant = AppLoadingVariant.questionList,
        itemCount = 0;

  /// Admin evaluation – results page.
  const AppLoading.resultsList({super.key})
      : variant = AppLoadingVariant.resultsList,
        itemCount = 0;

  /// Score page: profile header + banner + term chips + score cards with
  /// grade badge.
  const AppLoading.score({super.key})
      : variant = AppLoadingVariant.score,
        itemCount = 0;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AppLoadingVariant.dashboard:
        return const AppDashboardSkeleton();
      case AppLoadingVariant.profile:
        return const AppProfileSkeleton();
      case AppLoadingVariant.schedule:
        return AppScheduleSkeleton(itemCount: itemCount);
      case AppLoadingVariant.booking:
        return AppBookingHistorySkeleton(itemCount: itemCount);
      case AppLoadingVariant.notifications:
        return const AppNotificationsSkeleton();
      case AppLoadingVariant.historyList:
        return AppHistoryListSkeleton(itemCount: itemCount);
      case AppLoadingVariant.adminApprove:
        return const AppAdminApproveSkeleton();
      case AppLoadingVariant.adminHome:
        return const AppAdminHomeSkeleton();
      case AppLoadingVariant.facultyList:
        return AppFacultyListSkeleton(itemCount: itemCount);
      case AppLoadingVariant.feedbacks:
        return AppFeedbacksListSkeleton(itemCount: itemCount);
      case AppLoadingVariant.evaluation:
        return const AppEvaluationSkeleton();
      case AppLoadingVariant.questionList:
        return const AppQuestionListSkeleton();
      case AppLoadingVariant.resultsList:
        return const AppResultsListSkeleton();
      case AppLoadingVariant.score:
        return const AppScoreSkeleton();
      case AppLoadingVariant.list:
        return AppListSkeleton(itemCount: itemCount);
    }
  }
}

enum AppLoadingVariant {
  list,
  dashboard,
  profile,
  schedule,
  booking,
  notifications,
  historyList,
  adminApprove,
  adminHome,
  facultyList,
  feedbacks,
  evaluation,
  questionList,
  resultsList,
  score,
}

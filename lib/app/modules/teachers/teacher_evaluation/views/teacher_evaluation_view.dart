import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/teacher_evaluation_controller.dart';
import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';

class TeacherEvaluationView extends GetView<TeacherEvaluationController> {
  const TeacherEvaluationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AssetImages.dashboardBg),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Premium Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ຜົນປະເມີນຂອງຂ້ອຍ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: controller.refreshData,
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white),
                        tooltip: 'Refresh',
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final err = controller.errorMessage.value;
                  if (err.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_off_rounded,
                                      size: 56,
                                      color: Colors.white.withOpacity(0.8)),
                                  const SizedBox(height: 16),
                                  Text(
                                    err,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: controller.refreshData,
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 20),
                                    label: const Text('ລອງໃໝ່'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.refreshData,
                    color: AppColors.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        // ── Overall Score Hero Card ──
                        _buildOverallScoreCard(controller.overallAverage),
                        const SizedBox(height: 16),

                        // ── Stats Row ──
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'ຈຳນວນການປະເມີນ',
                                value: '${controller.totalEvaluations}',
                                icon: Icons.people_alt_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'ລາຍວິຊາ',
                                value: '${controller.totalSubjects}',
                                icon: Icons.menu_book_rounded,
                                color: AppColors.borderPending,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Section title ──
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'ລາຍວິຊາທີ່ໄດ້ຮັບການປະເມີນ',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 1),
                                        blurRadius: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Subject Evaluation Cards ──
                        ...controller.subjectGroups.map((g) {
                          return _SubjectEvalCard(group: g);
                        }),

                        if (controller.subjectGroups.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 32, horizontal: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.insert_chart_outlined,
                                          size: 56,
                                          color: Colors.white
                                              .withOpacity(0.7)),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'ຍັງບໍ່ມີຂໍ້ມູນການປະເມີນ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERALL SCORE HERO CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOverallScoreCard(double average) {
    Color scoreColor = AppColors.primary;
    String label = 'ດີ';
    IconData emoji = Icons.thumb_up_alt_rounded;

    if (average < 3.0) {
      scoreColor = AppColors.rejectRed;
      label = 'ຕ້ອງປັບປຸງ';
      emoji = Icons.trending_down_rounded;
    } else if (average < 4.0) {
      scoreColor = AppColors.borderPending;
      label = 'ປານກາງ';
      emoji = Icons.trending_flat_rounded;
    } else if (average >= 4.5) {
      scoreColor = AppColors.borderApproved;
      label = 'ດີເລີດ';
      emoji = Icons.emoji_events_rounded;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scoreColor.withOpacity(0.85),
                scoreColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: scoreColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left section — labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ຄະແນນສະເລ່ຍລວມ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(emoji, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right section — big score
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: scoreColor, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      average.toStringAsFixed(2),
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUBJECT EVALUATION CARD WITH PROGRESS BARS
// ═══════════════════════════════════════════════════════════════════════════════

class _SubjectEvalCard extends StatelessWidget {
  final SubjectEvalGroup group;
  const _SubjectEvalCard({required this.group});

  Color _scoreColor(double score) {
    if (score >= 4.5) return AppColors.borderApproved;
    if (score >= 3.5) return AppColors.borderPending;
    if (score >= 2.5) return AppColors.primary;
    return AppColors.rejectRed;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(group.averageScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            '${group.subjectName} ${group.subjectCode.isNotEmpty ? '(${group.subjectCode})' : ''}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (group.semesterLabel.isNotEmpty ||
                    group.studentGroupName.isNotEmpty)
                  Row(
                    children: [
                      if (group.semesterLabel.isNotEmpty) ...[
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(group.semesterLabel,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                      if (group.semesterLabel.isNotEmpty &&
                          group.studentGroupName.isNotEmpty)
                        const SizedBox(width: 10),
                      if (group.studentGroupName.isNotEmpty) ...[
                        Icon(Icons.group_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(group.studentGroupName,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 14, color: scoreColor),
                          const SizedBox(width: 4),
                          Text(
                            group.averageScore.toStringAsFixed(2),
                            style: TextStyle(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${group.totalResponses} ຄັ້ງ',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'ລາຍລະອຽດຄະແນນ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...group.questionScores.values.map((q) {
                    final pct = (q.average / 5.0).clamp(0.0, 1.0);
                    final barColor = _scoreColor(q.average);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  q.questionText,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                q.average.toStringAsFixed(2),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: barColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(barColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Comments section if any
                  if (group.comments.isNotEmpty) ...[
                    const Divider(),
                    Row(
                      children: [
                        Icon(Icons.format_quote_rounded,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          'ຄຳເຫັນຈາກນັກສຶກສາ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...group.comments.take(5).map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ',
                                  style: TextStyle(
                                      color: Colors.grey.shade500)),
                              Expanded(
                                child: Text(
                                  c,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

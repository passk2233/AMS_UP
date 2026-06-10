import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../../../data/models/evaluation_question_model.dart';
import '../../../data/models/open_evaluation_model.dart';
import '../controllers/evalutions_controller.dart';

/// Admin "Evaluations" tab.
///
/// Switches between question-bank management, the teacher-results list,
/// and a per-teacher detail page based on [EvalutionController.pageMode].
class EvalutionView extends GetView<EvalutionController> {
  const EvalutionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AssetImages.dashboardBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const AdminAppBar(),
            Expanded(child: _EvalutionBody(controller: controller)),
          ],
        ),
      ),
    );
  }
}

/// Picks the correct sub-page based on [EvalutionController.pageMode].
class _EvalutionBody extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _EvalutionBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.pageMode.value) {
        case EvalutionPageMode.questions:
          return _QuestionsPage(controller: controller);
        case EvalutionPageMode.teacherDetail:
          return _TeacherDetailPage(controller: controller);
        case EvalutionPageMode.window:
          return _WindowPage(controller: controller);
        case EvalutionPageMode.results:
        default:
          return _ResultsPage(controller: controller);
      }
    });
  }
}

// ─────────────────────────────────────────────────── mode toggle ──

/// Pill toggle that swaps between [EvalutionPageMode.questions] and
/// [EvalutionPageMode.results].
class _ModeToggle extends StatelessWidget {
  /// Source of reactive mode state.
  final EvalutionController controller;

  const _ModeToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _ToggleButton(
              icon: Icons.quiz_outlined,
              label: 'ຄຳຖາມ',
              selected:
                  controller.pageMode.value == EvalutionPageMode.questions,
              onTap: () =>
                  controller.pageMode.value = EvalutionPageMode.questions,
            ),
            _ToggleButton(
              icon: Icons.event_available_outlined,
              label: 'ໄລຍະເວລາ',
              selected: controller.pageMode.value == EvalutionPageMode.window,
              onTap: () => controller.pageMode.value = EvalutionPageMode.window,
            ),
            _ToggleButton(
              icon: Icons.bar_chart_rounded,
              label: 'ຜົນການປະເມີນ',
              selected: controller.pageMode.value == EvalutionPageMode.results,
              onTap: () =>
                  controller.pageMode.value = EvalutionPageMode.results,
            ),
          ],
        ),
      ),
    );
  }
}

/// One pill inside [_ModeToggle].
class _ToggleButton extends StatelessWidget {
  /// Glyph rendered next to the label.
  final IconData icon;

  /// Caption.
  final String label;

  /// Whether this pill is the active one.
  final bool selected;

  /// Tap handler.
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.laoBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
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

// ───────────────────────────────────────────────── questions page ──

/// Sub-page that lets the admin manage the evaluation question bank.
class _QuestionsPage extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _QuestionsPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModeToggle(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingQuestions.value) {
              return const AppLoading.questionList();
            }
            if (controller.questionsError.isNotEmpty &&
                controller.questions.isEmpty) {
              return AppErrorState(
                message: controller.questionsError.value,
                onRetry: controller.fetchQuestions,
              );
            }
            return _QuestionListSection(controller: controller);
          }),
        ),
      ],
    );
  }
}

/// Header (count + "Add" button) and the scrollable question list.
class _QuestionListSection extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _QuestionListSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                'ຄຳຖາມທັງໝົດ (${controller.questions.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: controller.addQuestion,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('ເພີ່ມ', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.laoBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: controller.questions.isEmpty
              ? const AppEmptyState(
                  icon: Icons.quiz_outlined,
                  title: 'ຍັງບໍ່ມີຄຳຖາມ',
                  subtitle: 'ກົດ "ເພີ່ມ" ເພື່ອສ້າງຄຳຖາມ',
                )
              : RefreshIndicator(
                  onRefresh: controller.fetchQuestions,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: controller.questions.length,
                    itemBuilder: (_, i) => _QuestionCard(
                      question: controller.questions[i],
                      index: i,
                      controller: controller,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// One question row card — number bubble + category + active toggle + edit
/// / delete actions.
class _QuestionCard extends StatelessWidget {
  /// The question rendered by this card.
  final EvaluationQuestionModel question;

  /// 1-based row number shown inside the leading bubble.
  final int index;

  /// Source of mutation callbacks.
  final EvalutionController controller;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final active = question.isActive == 1;
    final borderColor = active
        ? AppColors.borderApproved
        : Colors.grey.shade300;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _NumberBubble(number: index + 1),
                const SizedBox(width: 8),
                if (question.category != null && question.category!.isNotEmpty)
                  _CategoryChip(category: question.category!),
                const Spacer(),
                _ActiveToggle(
                  active: active,
                  onTap: () => controller.toggleQuestionActive(question),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _SmallActionButton(
                  icon: Icons.edit_outlined,
                  label: 'ແກ້ໄຂ',
                  color: AppColors.laoBlue,
                  onTap: () => controller.editQuestion(question),
                ),
                const SizedBox(width: 8),
                _SmallActionButton(
                  icon: Icons.delete_outline,
                  label: 'ລຶບ',
                  color: AppColors.rejectRed,
                  onTap: () =>
                      controller.deleteQuestion(question.evaQuestionId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small indigo square containing the 1-based row number.
class _NumberBubble extends StatelessWidget {
  /// Row number.
  final int number;

  const _NumberBubble({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.laoBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.laoBlue,
          ),
        ),
      ),
    );
  }
}

/// Gray pill showing the question's category.
class _CategoryChip extends StatelessWidget {
  /// Category label.
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Tappable status pill that flips the question's active flag.
class _ActiveToggle extends StatelessWidget {
  /// Current active state.
  final bool active;

  /// Tap handler.
  final VoidCallback onTap;

  const _ActiveToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? AppColors.borderApproved.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          active ? 'ເປີດ' : 'ປິດ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.borderApproved : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

/// Color-tinted inline action button shared by the question card.
class _SmallActionButton extends StatelessWidget {
  /// Glyph.
  final IconData icon;

  /// Caption.
  final String label;

  /// Tint applied to icon + text.
  final Color color;

  /// Tap handler.
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────── results page ──

/// Teacher list page (the second mode).
class _ResultsPage extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _ResultsPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModeToggle(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingResults.value) {
              return const AppLoading.resultsList();
            }
            if (controller.resultsError.isNotEmpty &&
                controller.results.isEmpty) {
              return AppErrorState(
                message: controller.resultsError.value,
                onRetry: controller.fetchResults,
              );
            }
            return _TeacherListSection(controller: controller);
          }),
        ),
      ],
    );
  }
}

/// Search bar + the filtered list of teachers.
class _TeacherListSection extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _TeacherListSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Obx(
            () => AppSearchBar(
              hint: 'ຄົ້ນຫາ ຊື່ອາຈານ, ລະຫັດ, ພາກ...',
              controller: controller.teacherSearchCtrl,
              onChanged: controller.onTeacherSearchChanged,
              currentQuery: controller.teacherSearch.value,
              onClear: controller.clearTeacherSearch,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final list = controller.filteredSummaries;
            if (list.isEmpty && controller.results.isEmpty) {
              return const AppEmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'ຍັງບໍ່ມີຜົນການປະເມີນ',
              );
            }
            if (list.isEmpty) {
              return const AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'ບໍ່ພົບຜົນການຄົ້ນຫາ',
              );
            }
            return RefreshIndicator(
              onRefresh: controller.fetchResults,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: list.length,
                itemBuilder: (_, i) => _TeacherCard(
                  summary: list[i],
                  rank: i + 1,
                  onTap: () => controller.openTeacherDetail(list[i]),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// One teacher row card on the results list. Tapping opens the detail page.
class _TeacherCard extends StatelessWidget {
  /// Source summary.
  final TeacherEvalSummary summary;

  /// 1-based rank in the sorted list.
  final int rank;

  /// Tap handler.
  final VoidCallback onTap;

  const _TeacherCard({
    required this.summary,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teacher = summary.teacher;
    final avg = summary.averageScore;
    final color = _EvalScoring.colorFor(avg);
    final label = _EvalScoring.labelFor(avg);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _RankBubble(rank: rank, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${teacher.nameLao} ${teacher.surnameLao}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teacher.department?.deptNameLao ?? teacher.teacherCode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.subjectNames.length} ວິຊາ • ${summary.totalResponses} ການປະເມີນ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StarRow(score: avg),
                        const SizedBox(width: 6),
                        Text(
                          avg.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _RatingTag(label: label, color: color),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient rank bubble shown on the left of [_TeacherCard].
class _RankBubble extends StatelessWidget {
  /// Rank number rendered inside.
  final int rank;

  /// Tint matching the teacher's average score.
  final Color color;

  const _RankBubble({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Small colored tag carrying the human rating label (e.g. "ດີຫຼາຍ").
class _RatingTag extends StatelessWidget {
  /// Rating label.
  final String label;

  /// Tint applied to background + foreground.
  final Color color;

  const _RatingTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          // Amber text on its own 10% tint fails AA; ink for that band.
          color: color == AppColors.warning ? AppColors.textPrimary : color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── teacher detail page ──

/// Detail page that drills into one teacher's per-subject results.
class _TeacherDetailPage extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _TeacherDetailPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.selectedTeacherSummary.value;
      if (summary == null) return const SizedBox.shrink();
      final teacher = summary.teacher;
      return Column(
        children: [
          _DetailTopBar(
            teacherName: '${teacher.nameLao} ${teacher.surnameLao}',
            onBack: controller.closeTeacherDetail,
          ),
          _TeacherSummaryCard(summary: summary),
          const SizedBox(height: 12),
          _SubjectsHeader(controller: controller),
          const SizedBox(height: 8),
          Expanded(child: _SubjectList(controller: controller)),
        ],
      );
    });
  }
}

/// Back + title row at the top of [_TeacherDetailPage].
class _DetailTopBar extends StatelessWidget {
  /// Title text (teacher full name).
  final String teacherName;

  /// Back button tap handler.
  final VoidCallback onBack;

  const _DetailTopBar({required this.teacherName, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              teacherName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// White card under the top bar showing the teacher's headline score, dept,
/// star rating, and the total evaluation count.
class _TeacherSummaryCard extends StatelessWidget {
  /// Source summary.
  final TeacherEvalSummary summary;

  const _TeacherSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final teacher = summary.teacher;
    final avg = summary.averageScore;
    final color = _EvalScoring.colorFor(avg);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                avg.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.department?.deptNameLao ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teacher.teacherCode,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _StarRow(score: avg),
                    const SizedBox(width: 8),
                    _RatingTag(label: _EvalScoring.labelFor(avg), color: color),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${summary.totalResponses}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'ການປະເມີນ',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "ວິຊາທີ່ສອນ (N)" heading above the subjects list.
class _SubjectsHeader extends StatelessWidget {
  /// Source of the reactive subjects count.
  final EvalutionController controller;

  const _SubjectsHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Obx(
          () => Text(
            'ວິຊາທີ່ສອນ (${controller.selectedTeacherSubjects.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical list of [_SubjectCard]s.
class _SubjectList extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _SubjectList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final subjects = controller.selectedTeacherSubjects;
      if (subjects.isEmpty) {
        return const AppEmptyState(
          icon: Icons.school_outlined,
          title: 'ບໍ່ມີຂໍ້ມູນວິຊາ',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        itemCount: subjects.length,
        itemBuilder: (_, i) => _SubjectCard(subject: subjects[i]),
      );
    });
  }
}

/// Expandable card for one subject — collapses to a summary row, expands
/// into per-question breakdown + anonymous comments.
class _SubjectCard extends StatelessWidget {
  /// Source summary.
  final SubjectEvalSummary subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final avg = subject.averageScore;
    final color = _EvalScoring.colorFor(avg);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: _SubjectScoreBadge(score: avg, color: color),
          title: Text(
            subject.subjectName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: _SubjectSubtitle(subject: subject),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            _QuestionBreakdown(scores: subject.questionScores),
            if (subject.evaluationDetails.any(
              (d) => d.comment != null && d.comment!.isNotEmpty,
            )) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _CommentsSection(
                comments: subject.evaluationDetails
                    .where((d) => d.comment != null && d.comment!.isNotEmpty)
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 40×40 square showing the subject's average score in [_SubjectCard].
class _SubjectScoreBadge extends StatelessWidget {
  /// Average score (0..5).
  final double score;

  /// Tint applied to text and tinted background.
  final Color color;

  const _SubjectScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          score.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Subtitle below the subject name — code, semester / group chips, response
/// count.
class _SubjectSubtitle extends StatelessWidget {
  /// Source summary.
  final SubjectEvalSummary subject;

  const _SubjectSubtitle({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subject.subjectCode.isNotEmpty)
          Text(
            subject.subjectCode,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            _MetaChip(
              icon: Icons.calendar_today_outlined,
              text: subject.semesterLabel,
              color: AppColors.info,
            ),
            const SizedBox(width: 6),
            if (subject.studentGroupName.isNotEmpty)
              _MetaChip(
                icon: Icons.group_outlined,
                text: subject.studentGroupName,
                color: AppColors.borderApproved,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${subject.totalResponses} ການປະເມີນ',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Small color-tinted meta chip used in [_SubjectSubtitle].
class _MetaChip extends StatelessWidget {
  /// Glyph.
  final IconData icon;

  /// Caption.
  final String text;

  /// Tint applied to background + glyph + text.
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-question breakdown rendered inside the expanded [_SubjectCard].
class _QuestionBreakdown extends StatelessWidget {
  /// Per-question score aggregates.
  final Map<int, QuestionScore> scores;

  const _QuestionBreakdown({required this.scores});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in scores.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.value.questionText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.value.average.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _EvalScoring.textColorFor(entry.value.average),
                  ),
                ),
                const Text(
                  '/5',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Anonymous comments section rendered inside the expanded [_SubjectCard].
class _CommentsSection extends StatelessWidget {
  /// Comments to render (already filtered to non-empty entries).
  final List<AnonymousEvalDetail> comments;

  const _CommentsSection({required this.comments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.comment_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 4),
            Text(
              'ຄຳເຫັນ (ບໍ່ລະບຸຕົວຕົນ)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final d in comments) _CommentTile(text: d.comment!),
      ],
    );
  }
}

/// One italic comment tile inside [_CommentsSection].
class _CommentTile extends StatelessWidget {
  /// Comment body.
  final String text;

  const _CommentTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── shared helpers ──

/// 0..5 star row shared by the list and detail pages.
class _StarRow extends StatelessWidget {
  /// Average score (0..5).
  final double score;

  const _StarRow({required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          if (i < score.floor())
            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning)
          else if (i < score)
            const Icon(
              Icons.star_half_rounded,
              size: 16,
              color: AppColors.warning,
            )
          else
            Icon(
              Icons.star_outline_rounded,
              size: 16,
              color: Colors.grey.shade300,
            ),
      ],
    );
  }
}

/// Tiny utility for the (score → color, score → label) mapping used in
/// multiple places.
abstract class _EvalScoring {
  /// Color for a 0..5 score:
  /// - 4.0+ → green
  /// - 3.0+ → blue
  /// - 2.0+ → amber
  /// - else → red
  static Color colorFor(double s) {
    if (s >= 4.0) return AppColors.success;
    if (s >= 3.0) return AppColors.info; // was off-palette #3B82F6
    if (s >= 2.0) return AppColors.warning; // was raw #F59E0B
    return AppColors.danger;
  }

  /// AA-safe foreground for a score used as TEXT on a white / tinted surface.
  /// Amber (#f59e0b) is ~2:1 on white and fails; the amber band falls back to
  /// ink. Use this anywhere [colorFor] would be a text color, not a fill/tint.
  static Color textColorFor(double s) {
    final c = colorFor(s);
    return c == AppColors.warning ? AppColors.textPrimary : c;
  }

  /// Lao rating label matching [colorFor].
  static String labelFor(double s) {
    if (s >= 4.0) return 'ດີຫຼາຍ';
    if (s >= 3.0) return 'ດີ';
    if (s >= 2.0) return 'ປານກາງ';
    return 'ຕ້ອງປັບປຸງ';
  }
}

// ───────────────────────────────────────────── evaluation window ──

/// Sub-page where the admin opens/closes the student evaluation window.
class _WindowPage extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _WindowPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModeToggle(controller: controller),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingWindow.value &&
                controller.openWindows.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.windowError.isNotEmpty &&
                controller.openWindows.isEmpty) {
              return AppErrorState(
                message: controller.windowError.value,
                onRetry: controller.fetchOpenWindow,
              );
            }
            return RefreshIndicator(
              onRefresh: controller.fetchOpenWindow,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  _WindowStatusCard(controller: controller),
                  const SizedBox(height: 16),
                  _WindowActions(controller: controller),
                  const SizedBox(height: 16),
                  _WindowHistorySection(controller: controller),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Headline card showing the current state of the evaluation window.
class _WindowStatusCard extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _WindowStatusCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.currentWindow;
      final isOpen = controller.isEvaluationOpen;
      final accent = isOpen
          ? AppColors.borderApproved
          : AppColors.textSecondary;
      final statusLabel = isOpen ? 'ເປີດໃຊ້ງານຢູ່' : 'ປິດ';
      final icon = isOpen
          ? Icons.lock_open_rounded
          : Icons.lock_outline_rounded;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
          border: Border(left: BorderSide(color: accent, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ສະຖານະການປະເມີນ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _WindowRow(
                label: 'ເປີດ',
                value: current.openTime != null
                    ? _fmt(current.openTime!)
                    : 'ບໍ່ໄດ້ກຳນົດ',
              ),
              const SizedBox(height: 6),
              _WindowRow(
                label: 'ປິດ',
                value: current.closeTime != null
                    ? _fmt(current.closeTime!)
                    : 'ບໍ່ໄດ້ກຳນົດ',
              ),
            ],
          ],
        ),
      );
    });
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }
}

/// One label/value row inside [_WindowStatusCard].
class _WindowRow extends StatelessWidget {
  /// Left-side label.
  final String label;

  /// Right-side value.
  final String value;

  const _WindowRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Open / close call-to-action row under the status card.
class _WindowActions extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _WindowActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isOpen = controller.isEvaluationOpen;
      final saving = controller.isSavingWindow.value;

      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      controller.prepareWindowForm();
                      final ok = await Get.dialog<bool>(
                        _WindowFormDialog(controller: controller),
                        barrierDismissible: false,
                      );
                      if (ok == true) await controller.openEvaluation();
                    },
              icon: Icon(
                isOpen ? Icons.edit_calendar_outlined : Icons.event_available,
                size: 18,
              ),
              label: Text(isOpen ? 'ແກ້ໄຂ / ຕໍ່ເວລາ' : 'ເປີດການປະເມີນ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.laoBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
          if (isOpen) ...[
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: saving ? null : controller.closeEvaluation,
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: const Text('ປິດການປະເມີນ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rejectRed,
                  side: const BorderSide(color: AppColors.rejectRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}

/// Past windows listed under the active one.
class _WindowHistorySection extends StatelessWidget {
  /// Source of reactive state.
  final EvalutionController controller;

  const _WindowHistorySection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final history = controller.openWindows.length > 1
          ? controller.openWindows.sublist(1)
          : const <OpenEvaluationModel>[];
      if (history.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ປະຫວັດໄລຍະການປະເມີນ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          for (final w in history) _WindowHistoryTile(window: w),
        ],
      );
    });
  }
}

/// One closed-window history card.
class _WindowHistoryTile extends StatelessWidget {
  /// Window row to render.
  final OpenEvaluationModel window;

  const _WindowHistoryTile({required this.window});

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime? dt) {
      if (dt == null) return '-';
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${fmt(window.openTime)} → ${fmt(window.closeTime)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            window.inactive == 0 ? 'ເປີດ' : 'ປິດ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: window.inactive == 0
                  ? AppColors.borderApproved
                  : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Date/time picker dialog for opening the window.
class _WindowFormDialog extends StatelessWidget {
  /// Source of the form fields.
  final EvalutionController controller;

  const _WindowFormDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius + 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ກຳນົດໄລຍະການປະເມີນ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ນັກສຶກສາຈະປະເມີນອາຈານໄດ້ພາຍໃນຊ່ວງເວລານີ້.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            _WindowTimePicker(
              label: 'ເວລາເປີດ',
              icon: Icons.event_available_outlined,
              value: controller.formOpenTime,
            ),
            const SizedBox(height: 10),
            _WindowTimePicker(
              label: 'ເວລາປິດ',
              icon: Icons.event_busy_outlined,
              value: controller.formCloseTime,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('ຍົກເລີກ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.laoBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('ເປີດການປະເມີນ'),
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

/// One labeled date/time picker row used inside [_WindowFormDialog].
class _WindowTimePicker extends StatelessWidget {
  /// Caption above the picker.
  final String label;

  /// Glyph rendered beside the value.
  final IconData icon;

  /// Reactive backing value updated when the user picks a moment.
  final Rx<DateTime?> value;

  const _WindowTimePicker({
    required this.label,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Obx(() {
          final v = value.value;
          final display = v == null ? 'ເລືອກວັນທີ ແລະ ເວລາ' : _fmt(v);
          return GestureDetector(
            onTap: () => _pick(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.laoBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: 13,
                        color: v == null
                            ? Colors.grey.shade500
                            : AppColors.textPrimary,
                        fontWeight: v == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}  '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _pick(BuildContext context) async {
    final initial = value.value ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    value.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}

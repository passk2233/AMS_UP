import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../../../data/data_exporter.dart';
import '../controllers/evalutions_controller.dart';

class EvalutionView extends GetView<EvalutionController> {
  const EvalutionView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EvalutionController>(
      builder: (c) => LayoutBuilder(
        builder: (context, constraints) {
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
              child: Column(
                children: [
                  const AdminAppBar(),
                  Expanded(
                    child: Obx(() {
                      switch (controller.pageMode.value) {
                        case 0:
                          return _questionsPage();
                        case 2:
                          return _teacherDetailPage();
                        default:
                          return _resultsPage();
                      }
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // MODE TOGGLE (Questions / Results)
  // ══════════════════════════════════════════════════════════════════════
  Widget _modeToggle() {
    return Obx(() => Container(
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
              _toggleBtn(Icons.quiz_outlined, 'ຄຳຖາມປະເມີນ',
                  controller.pageMode.value == 0, () => controller.pageMode.value = 0),
              _toggleBtn(Icons.bar_chart_rounded, 'ຜົນການປະເມີນ',
                  controller.pageMode.value == 1, () => controller.pageMode.value = 1),
            ],
          ),
        ));
  }

  Widget _toggleBtn(IconData icon, String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.laoBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // QUESTIONS PAGE
  // ══════════════════════════════════════════════════════════════════════
  Widget _questionsPage() {
    return Column(
      children: [
        _modeToggle(),
        Expanded(child: Obx(() {
          if (controller.isLoadingQuestions.value) {
            return const AppLoading.questionList();
          }
          if (controller.questionsError.isNotEmpty && controller.questions.isEmpty) {
            return _errorWidget(controller.questionsError.value, controller.fetchQuestions);
          }
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Text('ຄຳຖາມທັງໝົດ (${controller.questions.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: controller.addQuestion,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('ເພີ່ມ', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.laoBlue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ]),
            ),
            Expanded(
              child: controller.questions.isEmpty
                  ? _emptyState(Icons.quiz_outlined, 'ຍັງບໍ່ມີຄຳຖາມ', 'ກົດ "ເພີ່ມ" ເພື່ອສ້າງຄຳຖາມ')
                  : RefreshIndicator(
                      onRefresh: controller.fetchQuestions,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: controller.questions.length,
                        itemBuilder: (_, i) => _questionCard(controller.questions[i], i),
                      ),
                    ),
            ),
          ]);
        })),
      ],
    );
  }

  Widget _questionCard(EvaluationQuestionModel q, int i) {
    final active = q.isActive == 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: active ? const Color(0xFF10B981) : Colors.grey.shade300, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: AppColors.laoBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.laoBlue))),
            ),
            const SizedBox(width: 8),
            if (q.category != null && q.category!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
                child: Text(q.category!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ),
            const Spacer(),
            GestureDetector(
              onTap: () => controller.toggleQuestionActive(q),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(active ? 'ເປີດ' : 'ປິດ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? const Color(0xFF10B981) : Colors.grey.shade500)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(q.question, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _smallBtn(Icons.edit_outlined, 'ແກ້ໄຂ', AppColors.laoBlue, () => controller.editQuestion(q)),
            const SizedBox(width: 8),
            _smallBtn(Icons.delete_outline, 'ລຶບ', const Color(0xFFE53935), () => controller.deleteQuestion(q.evaQuestionId)),
          ]),
        ]),
      ),
    );
  }

  Widget _smallBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8), onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color), const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // RESULTS PAGE (Teacher List)
  // ══════════════════════════════════════════════════════════════════════
  Widget _resultsPage() {
    return Column(
      children: [
        _modeToggle(),
        Expanded(child: Obx(() {
          if (controller.isLoadingResults.value) {
            return const AppLoading.resultsList();
          }
          if (controller.resultsError.isNotEmpty && controller.results.isEmpty) {
            return _errorWidget(controller.resultsError.value, controller.fetchResults);
          }
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _searchBar(),
            ),
            Expanded(child: Obx(() {
              final list = controller.filteredSummaries;
              if (list.isEmpty && controller.results.isEmpty) {
                return _emptyState(Icons.bar_chart_rounded, 'ຍັງບໍ່ມີຜົນການປະເມີນ', '');
              }
              if (list.isEmpty) {
                return _emptyState(Icons.search_off_rounded, 'ບໍ່ພົບຜົນການຄົ້ນຫາ', '');
              }
              return RefreshIndicator(
                onRefresh: controller.fetchResults, color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _teacherCard(list[i], i),
                ),
              );
            })),
          ]);
        })),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller.teacherSearchCtrl,
        onChanged: controller.onTeacherSearchChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ຄົ້ນຫາ ຊື່ອາຈານ, ລະຫັດ, ພາກ...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
          suffixIcon: Obx(() => controller.teacherSearch.value.isEmpty
              ? const SizedBox.shrink()
              : IconButton(icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400), onPressed: controller.clearTeacherSearch)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _teacherCard(TeacherEvalSummary s, int i) {
    final avg = s.averageScore;
    final color = _scoreColor(avg);
    final label = _ratingLabel(avg);

    return GestureDetector(
      onTap: () => controller.openTeacherDetail(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.08)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s.teacher.nameLao} ${s.teacher.surnameLao}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(s.teacher.department?.deptNameLao ?? s.teacher.teacherCode,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('${s.subjectNames.length} ວິຊາ • ${s.totalResponses} ການປະເມີນ',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(height: 6),
                Row(children: [
                  _starRow(avg),
                  const SizedBox(width: 6),
                  Text(avg.toStringAsFixed(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ),
                ]),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 24),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TEACHER DETAIL PAGE
  // ══════════════════════════════════════════════════════════════════════
  Widget _teacherDetailPage() {
    return Obx(() {
      final summary = controller.selectedTeacherSummary.value;
      if (summary == null) return const SizedBox.shrink();
      final teacher = summary.teacher;
      final avg = summary.averageScore;
      final color = _scoreColor(avg);

      return Column(children: [
        // Top bar
        Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
          child: Row(children: [
            IconButton(
              onPressed: controller.closeTeacherDetail,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppColors.textPrimary),
            ),
            Expanded(
              child: Text('${teacher.nameLao} ${teacher.surnameLao}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),

        // Teacher summary header card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.1)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Text(avg.toStringAsFixed(1), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(teacher.department?.deptNameLao ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(teacher.teacherCode, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(height: 6),
                Row(children: [
                  _starRow(avg),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(_ratingLabel(avg), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                  ),
                ]),
              ]),
            ),
            Column(children: [
              Text('${summary.totalResponses}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('ການປະເມີນ', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ]),
          ]),
        ),

        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Obx(() => Text('ວິຊາທີ່ສອນ (${controller.selectedTeacherSubjects.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
          ),
        ),
        const SizedBox(height: 8),

        // Subject list
        Expanded(
          child: Obx(() {
            final subjects = controller.selectedTeacherSubjects;
            if (subjects.isEmpty) {
              return _emptyState(Icons.school_outlined, 'ບໍ່ມີຂໍ້ມູນວິຊາ', '');
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: subjects.length,
              itemBuilder: (_, i) => _subjectCard(subjects[i]),
            );
          }),
        ),
      ]);
    });
  }

  Widget _subjectCard(SubjectEvalSummary sub) {
    final avg = sub.averageScore;
    final color = _scoreColor(avg);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(avg.toStringAsFixed(1), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))),
          ),
          title: Text(sub.subjectName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (sub.subjectCode.isNotEmpty)
              Text(sub.subjectCode, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            const SizedBox(height: 4),
            Row(children: [
              _chip(Icons.calendar_today_outlined, sub.semesterLabel, const Color(0xFF6366F1)),
              const SizedBox(width: 6),
              if (sub.studentGroupName.isNotEmpty)
                _chip(Icons.group_outlined, sub.studentGroupName, const Color(0xFF10B981)),
            ]),
            const SizedBox(height: 4),
            Text('${sub.totalResponses} ການປະເມີນ', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ]),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Per-question scores
            ...sub.questionScores.entries.map((e) {
              final qs = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(qs.questionText, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3))),
                  const SizedBox(width: 8),
                  Text(qs.average.toStringAsFixed(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _scoreColor(qs.average))),
                  const Text('/5', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
              );
            }),
            // Comments section (anonymous)
            if (sub.evaluationDetails.any((d) => d.comment != null && d.comment!.isNotEmpty)) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Row(children: [
                Icon(Icons.comment_outlined, size: 14, color: AppColors.textSecondary),
                SizedBox(width: 4),
                Text('ຄຳເຫັນ (ບໍ່ລະບຸຕົວຕົນ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 6),
              ...sub.evaluationDetails
                  .where((d) => d.comment != null && d.comment!.isNotEmpty)
                  .map((d) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.format_quote_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(d.comment!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4, fontStyle: FontStyle.italic)),
                          ),
                        ]),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════
  Widget _starRow(double avg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < avg.floor()) return const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B));
        if (i < avg) return const Icon(Icons.star_half_rounded, size: 16, color: Color(0xFFF59E0B));
        return Icon(Icons.star_outline_rounded, size: 16, color: Colors.grey.shade300);
      }),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 4.0) return const Color(0xFF10B981);
    if (s >= 3.0) return const Color(0xFF3B82F6);
    if (s >= 2.0) return const Color(0xFFF59E0B);
    return const Color(0xFFE53935);
  }

  String _ratingLabel(double s) {
    if (s >= 4.0) return 'ດີຫຼາຍ';
    if (s >= 3.0) return 'ດີ';
    if (s >= 2.0) return 'ປານກາງ';
    return 'ຕ້ອງປັບປຸງ';
  }

  Widget _emptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
        if (sub.isNotEmpty) ...[const SizedBox(height: 4), Text(sub, style: TextStyle(fontSize: 13, color: Colors.grey.shade400))],
      ]),
    );
  }

  Widget _errorWidget(String msg, VoidCallback retry) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(msg, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: retry, icon: const Icon(Icons.refresh, size: 18), label: const Text('ລອງໃໝ່'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
    );
  }
}

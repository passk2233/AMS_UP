import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/widget.dart';

/// Read-only profile of the teacher who teaches a given subject, opened from
/// the subject-detail sheet on the student schedule.
///
/// The page is seeded with the [TeacherModel] already embedded in the study
/// plan, so it paints instantly with no spinner, then quietly enriches itself
/// from `GET /teachers/{id}` to fill in department / division. Only the data a
/// student actually needs to reach and place their teacher is shown — name,
/// code, contact, and affiliation — never the personal fields the record also
/// carries (date of birth, gender, religion, marital / health status, …).
class TeacherInfoView extends StatefulWidget {
  /// Teacher embedded in the study plan — used for the instant first paint.
  final TeacherModel? seedTeacher;

  /// Teacher id used to fetch the full record. `0` disables enrichment.
  final int teacherId;

  /// The subject this teacher teaches the student (for the "teaches you" card).
  final String? subjectName;

  /// The student group, for the "teaches you" card.
  final String? groupName;

  /// The class time label, for the "teaches you" card.
  final String? timeLabel;

  const TeacherInfoView({
    super.key,
    required this.seedTeacher,
    required this.teacherId,
    this.subjectName,
    this.groupName,
    this.timeLabel,
  });

  @override
  State<TeacherInfoView> createState() => _TeacherInfoViewState();
}

class _TeacherInfoViewState extends State<TeacherInfoView> {
  final PeopleProvider _people = PeopleProvider();
  TeacherModel? _teacher;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _teacher = widget.seedTeacher;
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.teacherId <= 0) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final teacher = await _people.fetchTeacherById(widget.teacherId);
      if (!mounted) return;
      if (teacher != null) setState(() => _teacher = teacher);
    } on DioException catch (e) {
      debugPrint(
          'TeacherInfo fetch Dio error:\n${AppDialogs.buildDioErrorDetail(e)}');
      if (mounted) setState(() => _failed = true);
    } catch (e) {
      debugPrint('TeacherInfo fetch error: $e');
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copy(String value, String labelLao) {
    Clipboard.setData(ClipboardData(text: value));
    AppSnackbar.success('ສຳເນົາ$labelLao ແລ້ວ');
  }

  @override
  Widget build(BuildContext context) {
    final t = _teacher;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Get.back(),
          tooltip: 'ກັບຄືນ',
        ),
        centerTitle: true,
        title: const Text(
          'ຂໍ້ມູນອາຈານ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // A slim progress line communicates background enrichment without a
        // blocking spinner, since the page already shows the seed data.
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
      body: t == null ? _buildFallback() : _buildContent(t),
    );
  }

  /// Only reached if there was no seed teacher (defensive) — show a real
  /// loading or error state rather than a blank screen.
  Widget _buildFallback() {
    if (_loading) return const AppLoading.profile();
    return AppErrorState(
      message: 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນອາຈານໄດ້',
      onRetry: _fetch,
    );
  }

  Widget _buildContent(TeacherModel t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TeacherHero(teacher: t),
          const SizedBox(height: 24),
          const AppSectionTitle('ຕິດຕໍ່'),
          AppSurfaceCard(
            child: Column(
              children: [
                _CopyTile(
                  icon: Icons.phone_outlined,
                  label: 'ເບີໂທລະສັບ',
                  value: t.telephone,
                  onCopy: () => _copy(t.telephone!, 'ເບີໂທ'),
                ),
                _CopyTile(
                  icon: Icons.email_outlined,
                  label: 'ອີເມວ',
                  value: t.email,
                  onCopy: () => _copy(t.email!, 'ອີເມວ'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AppSectionTitle('ສັງກັດ'),
          _AffiliationCard(
            teacher: t,
            loading: _loading,
            failed: _failed,
            onRetry: _fetch,
          ),
          if ((widget.subjectName ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            const AppSectionTitle('ວິຊາທີ່ສອນ'),
            AppSurfaceCard(
              child: Column(
                children: [
                  AppInfoTile(
                    icon: Icons.menu_book_rounded,
                    label: 'ວິຊາ',
                    value: widget.subjectName!,
                  ),
                  if ((widget.groupName ?? '').isNotEmpty)
                    AppInfoTile(
                      icon: Icons.groups_outlined,
                      label: 'ກຸ່ມຮຽນ',
                      value: widget.groupName!,
                    ),
                  if ((widget.timeLabel ?? '').isNotEmpty)
                    AppInfoTile(
                      icon: Icons.access_time_rounded,
                      label: 'ເວລາ',
                      value: widget.timeLabel!,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Centered identity header: avatar, Lao name, English name, code chip.
class _TeacherHero extends StatelessWidget {
  final TeacherModel teacher;

  const _TeacherHero({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final laoName =
        '${teacher.nameLao} ${teacher.surnameLao}'.trim().isEmpty
            ? teacher.nameEng
            : '${teacher.nameLao} ${teacher.surnameLao}'.trim();
    final engName = '${teacher.nameEng} ${teacher.surnameEng ?? ''}'.trim();
    final showEng = engName.isNotEmpty &&
        engName.toLowerCase() != laoName.toLowerCase();

    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          AppAvatar(
            photo: teacher.photo,
            radius: 42,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 14),
          Text(
            laoName.isEmpty ? '-' : laoName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (showEng) ...[
            const SizedBox(height: 4),
            Text(
              engName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
          if (teacher.teacherCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppColors.chipRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.badge_outlined,
                      size: 16, color: AppColors.primaryFill),
                  const SizedBox(width: 6),
                  Text(
                    teacher.teacherCode,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryFill,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Department / division card with loading, error-retry, and empty states for
/// the enrichment fetch.
class _AffiliationCard extends StatelessWidget {
  final TeacherModel teacher;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  const _AffiliationCard({
    required this.teacher,
    required this.loading,
    required this.failed,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final dept = teacher.department;
    final division = teacher.division;
    final hasAny = dept != null || division != null;

    if (hasAny) {
      return AppSurfaceCard(
        child: Column(
          children: [
            if (dept != null)
              AppInfoTile(
                icon: Icons.apartment_rounded,
                label: 'ພະແນກ',
                value: dept.deptNameLao.isEmpty
                    ? (dept.deptNameEng ?? dept.departmentCode)
                    : dept.deptNameLao,
              ),
            if (division != null)
              AppInfoTile(
                icon: Icons.account_tree_outlined,
                label: 'ສາຂາ',
                value: division.divisionNameLao.isEmpty
                    ? (division.divisionNameEng ?? division.divisionCode)
                    : division.divisionNameLao,
              ),
          ],
        ),
      );
    }

    // No affiliation data yet — pick the honest state.
    if (loading) {
      return const AppSurfaceCard(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Text(
              'ກຳລັງໂຫຼດຂໍ້ມູນສັງກັດ...',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (failed) {
      return AppSurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'ໂຫຼດຂໍ້ມູນສັງກັດບໍ່ສຳເລັດ',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryFill,
                minimumSize: const Size(0, 44),
              ),
              child: const Text('ລອງໃໝ່',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return const AppSurfaceCard(
      child: AppInfoTile(
        icon: Icons.apartment_rounded,
        label: 'ສັງກັດ',
        value: 'ບໍ່ມີຂໍ້ມູນ',
      ),
    );
  }
}

/// Contact row that copies its value to the clipboard on tap. Falls back to a
/// muted, non-interactive "no data" line when the field is empty.
class _CopyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onCopy;

  const _CopyTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: has ? onCopy : null,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        subtitle: Text(
          has ? value!.trim() : 'ບໍ່ມີຂໍ້ມູນ',
          style: TextStyle(
            color: has ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: has ? FontWeight.w600 : FontWeight.w400,
            fontSize: 15,
          ),
        ),
        trailing: has
            ? const Icon(Icons.copy_rounded,
                size: 18, color: AppColors.textSecondary)
            : null,
      ),
    );
  }
}

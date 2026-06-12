import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/widget.dart';

import '../../student_widgets/schedule/teacher_info_widgets.dart';

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
          TeacherHeroCard(teacher: t),
          const SizedBox(height: 24),
          const AppSectionTitle('ຕິດຕໍ່'),
          AppSurfaceCard(
            child: Column(
              children: [
                ContactCopyTile(
                  icon: Icons.phone_outlined,
                  label: 'ເບີໂທລະສັບ',
                  value: t.telephone,
                  onCopy: () => _copy(t.telephone!, 'ເບີໂທ'),
                ),
                ContactCopyTile(
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
          TeacherAffiliationCard(
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

import 'package:flutter/material.dart';

import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/widgets/widget.dart';

/// Centered identity header: avatar, Lao name, English name, code chip.
class TeacherHeroCard extends StatelessWidget {
  final TeacherModel teacher;

  const TeacherHeroCard({super.key, required this.teacher});

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
class TeacherAffiliationCard extends StatelessWidget {
  final TeacherModel teacher;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;

  const TeacherAffiliationCard({
    super.key,
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
class ContactCopyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onCopy;

  const ContactCopyTile({
    super.key,
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

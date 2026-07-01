import 'package:flutter/material.dart';

import '../../../../widgets/widget.dart';
import '../../../data/models/user_model.dart';

/// Indigo gradient hero with avatar initials, username, email, and role
/// pills.
class ProfileHeroCard extends StatelessWidget {
  /// Source user — `null` falls back to placeholders.
  final UserModel? user;

  const ProfileHeroCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final photo = user?.teacher?.photo ?? user?.student?.photo;
    final roles = user?.roles ?? const <String>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _AvatarCircle(photo: photo),
          const SizedBox(height: AppSpacing.s + 4),
          Text(
            user?.username ?? '-',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '-',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            _RolePillRow(roles: roles),
          ],
        ],
      ),
    );
  }
}

/// 80×80 white-bordered circle showing the user's profile photo, falling back
/// to the bundled placeholder when there is no photo.
class _AvatarCircle extends StatelessWidget {
  /// Stored teacher/student photo path or URL; null shows the placeholder.
  final String? photo;

  const _AvatarCircle({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 3,
        ),
      ),
      child: AppAvatar(
        photo: photo,
        radius: 37,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}

/// Horizontal row of translucent role pills shown in the hero card.
class _RolePillRow extends StatelessWidget {
  /// Role names — each rendered as one pill.
  final List<String> roles;

  const _RolePillRow({required this.roles});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (final r in roles)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppColors.chipRadius),
            ),
            child: Text(
              r,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

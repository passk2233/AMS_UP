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
    final initials = _initials(user?.username ?? '?');
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
          _AvatarCircle(initials: initials),
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

  /// Up to 2 uppercase letters extracted from the user's name.
  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

/// 80×80 white-bordered circle showing the user's initials.
class _AvatarCircle extends StatelessWidget {
  /// 1–2 character initial string.
  final String initials;

  const _AvatarCircle({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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

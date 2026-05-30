import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shell.dart';

/// Greeting / dashboard header — bold name on the left, optional trailing
/// action bubble on the right.
class AppGreetingHeader extends StatelessWidget {
  final String greeting;
  final String? subtitle;
  final Widget? trailing;

  const AppGreetingHeader({
    super.key,
    required this.greeting,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Profile header — circular avatar (image or initials) plus name + two
/// metadata lines, wrapped in a white surface card.
class AppProfileHeader extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? caption;
  final ImageProvider? avatarImage;
  final String? avatarFallback;
  final Color? captionColor;

  const AppProfileHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.caption,
    this.avatarImage,
    this.avatarFallback,
    this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (avatarFallback != null && avatarFallback!.isNotEmpty)
        ? avatarFallback!.substring(0, 1).toUpperCase()
        : (name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?');

    return AppSurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                if (caption != null && caption!.isNotEmpty)
                  Text(
                    caption!,
                    style: TextStyle(
                      color: captionColor ?? AppColors.borderApproved,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Non-tappable info row inside an [AppSurfaceCard]: round icon + label + value.
class AppInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const AppInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
        value,
        style: TextStyle(
          color: valueColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Tappable settings row inside an [AppSurfaceCard].
class AppActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.scaffoldBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
        onTap: onTap,
      ),
    );
  }
}

/// Vertical white stat card — icon + value + label. Used in dashboards.
class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient banner with a row of small stat items (icon + label + value).
class AppStatItem {
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  const AppStatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.suffix = '',
  });
}

class AppStatsBanner extends StatelessWidget {
  final List<AppStatItem> items;
  final Color color;

  const AppStatsBanner({
    super.key,
    required this.items,
    this.color = AppColors.statsBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map(_buildItem).toList(),
      ),
    );
  }

  Widget _buildItem(AppStatItem item) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(item.icon, color: Colors.white70, size: 14),
          ],
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: item.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.suffix.isNotEmpty)
                TextSpan(
                  text: item.suffix,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Generic class / schedule list card with a colored left border, title row
/// (with optional trailing time), subtitle, and a meta row (time / instructor
/// / location).
class AppClassCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? time;
  final String? instructor;
  final String? location;
  final Color color;
  final VoidCallback? onTap;
  final IconData leadingIcon;

  const AppClassCard({
    super.key,
    required this.title,
    required this.color,
    this.subtitle,
    this.time,
    this.instructor,
    this.location,
    this.onTap,
    this.leadingIcon = Icons.class_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      borderLeftColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(leadingIcon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if ((time != null && time!.isNotEmpty) ||
              (instructor != null && instructor!.isNotEmpty) ||
              (location != null && location!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (time != null && time!.isNotEmpty)
                  _metaPill(Icons.access_time_rounded, time!),
                if (instructor != null && instructor!.isNotEmpty)
                  _metaPill(Icons.person_outline_rounded, instructor!),
                if (location != null && location!.isNotEmpty)
                  _metaPill(Icons.location_on_outlined, location!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

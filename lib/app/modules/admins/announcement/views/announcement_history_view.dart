import 'package:flutter/material.dart';
import 'package:frontend/app/utilities/assets.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../controllers/announcement_controller.dart';

/// Full-screen history page for notifications with search, sort, filter,
/// edit, resend, and delete capabilities.
class AnnouncementHistoryView extends StatelessWidget {
  const AnnouncementHistoryView({super.key});

  AnnouncementController get c => Get.find<AnnouncementController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AnnouncementController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Container(
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
                _buildTopBar(),
                _buildSearchBar(),
                _buildSortFilterRow(),
                Expanded(child: _buildList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 48, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: c.closeHistory,
            icon: const Icon(Icons.arrow_back_ios_rounded,
                size: 20, color: AppColors.textPrimary),
          ),
          const Text(
            'ປະຫວັດການແຈ້ງເຕືອນ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Obx(() => Text(
                '${c.filteredNotifications.length} ລາຍການ',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              )),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: c.searchHistoryCtrl,
        onChanged: c.onHistorySearchChanged,
        decoration: InputDecoration(
          hintText: 'ຄົ້ນຫາ...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          suffixIcon: Obx(() => c.historySearch.value.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                  onPressed: () {
                    c.searchHistoryCtrl.clear();
                    c.onHistorySearchChanged('');
                  },
                )
              : const SizedBox.shrink()),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.laoBlue, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildSortFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() => Row(
                  children: [
                    _sortChip('ໃໝ່ສຸດ', 0),
                    const SizedBox(width: 6),
                    _sortChip('ເກົ່າສຸດ', 1),
                    const SizedBox(width: 6),
                    _sortChip('ຫົວຂໍ້ A-Z', 2),
                    const SizedBox(width: 12),
                    // Divider
                    Container(width: 1, height: 24, color: Colors.grey.shade300),
                    const SizedBox(width: 12),
                    // Filter: All
                    _filterChip('ທັງໝົດ', ''),
                    const SizedBox(width: 6),
                    // Dynamic type filters
                    ...c.uniqueTypes.take(4).map((t) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _filterChip(
                            t.length > 15 ? '${t.substring(0, 15)}…' : t,
                            t,
                          ),
                        )),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, int mode) {
    return Obx(() {
      final selected = c.historySortMode.value == mode;
      return GestureDetector(
        onTap: () => c.setHistorySortMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.laoBlue : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? AppColors.laoBlue : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort_rounded,
                  size: 14,
                  color: selected ? Colors.white : Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      );
    });
  }

  Widget _filterChip(String label, String typeValue) {
    return Obx(() {
      final selected = c.historyFilterType.value == typeValue;
      return GestureDetector(
        onTap: () => c.setHistoryFilterType(typeValue),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade300),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF10B981)
                    : AppColors.textSecondary,
              )),
        ),
      );
    });
  }

  Widget _buildList() {
    return Obx(() {
      if (c.isLoading.value) {
        return const AppLoading.historyList();
      }

      if (c.filteredNotifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text('ບໍ່ພົບຜົນລັບ',
                  style:
                      TextStyle(fontSize: 15, color: Colors.grey.shade500)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: c.filteredNotifications.length,
        itemBuilder: (_, i) =>
            _buildHistoryTile(c.filteredNotifications[i]),
      );
    });
  }

  Widget _buildHistoryTile(dynamic noti) {
    final createdAt = noti.createdAt;
    String timeStr = '';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes} ນາທີກ່ອນ';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours} ຊົ່ວໂມງກ່ອນ';
      } else {
        timeStr = '${diff.inDays} ວັນກ່ອນ';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.laoBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: AppColors.laoBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(noti.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (timeStr.isNotEmpty)
                      Text(timeStr,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Message
          Text(noti.message,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          // Type tag
          if (noti.type != null && noti.type!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.laoBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(noti.type!,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.laoBlue,
                      fontWeight: FontWeight.w500)),
            ),
          ],
          const Divider(height: 18),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionBtn(Icons.edit_rounded, 'ແກ້ໄຂ',
                  const Color(0xFF4C4DDC), () => c.editNotification(noti)),
              const SizedBox(width: 8),
              _actionBtn(Icons.replay_rounded, 'ສົ່ງຊ້ຳ',
                  const Color(0xFF10B981), () => c.resendNotification(noti)),
              const SizedBox(width: 8),
              _actionBtn(Icons.delete_outline_rounded, 'ລຶບ',
                  const Color(0xFFE53935),
                  () => c.deleteNotification(noti.notiId)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

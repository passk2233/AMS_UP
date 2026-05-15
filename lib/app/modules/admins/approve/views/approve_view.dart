import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utilities/assets.dart';
import '../../../../widgets/widget.dart';
import '../controllers/approve_controller.dart';

class ApproveView extends GetView<ApproveController> {
  const ApproveView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ApproveController>(
      builder: (controller) => LayoutBuilder(
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
                      if (controller.isLoading.value) {
                        return const AppLoading.adminApprove();
                      }

                      if (controller.errorMessage.isNotEmpty &&
                          controller.bookings.isEmpty) {
                        return _buildErrorState();
                      }

                      return RefreshIndicator(
                        onRefresh: controller.refreshData,
                        color: AppColors.primary,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            // ── Stats summary ────────────────────────
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 16, 16, 0),
                                child: _buildStatsRow(),
                              ),
                            ),

                            // ── Search bar ───────────────────────────
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 12, 16, 0),
                                child: _buildSearchBar(),
                              ),
                            ),

                            // ── Tab filters ──────────────────────────
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 12, 16, 8),
                                child: _buildFilterTabs(),
                              ),
                            ),

                            // ── Booking list ─────────────────────────
                            _buildBookingList(),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 20),
                            ),
                          ],
                        ),
                      );
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

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsRow() {
    return Obx(() => Row(
          children: [
            _buildStatChip(
              icon: Icons.hourglass_top_rounded,
              label: 'ລໍຖ້າ',
              count: controller.pendingCount.value,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              icon: Icons.check_circle_outline_rounded,
              label: 'ອະນຸມັດ',
              count: controller.approvedCount.value,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(width: 8),
            _buildStatChip(
              icon: Icons.cancel_outlined,
              label: 'ປະຕິເສດ',
              count: controller.rejectedCount.value,
              color: const Color(0xFFE53935),
            ),
          ],
        ));
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchCtrl,
        onChanged: controller.onSearchChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ຄົ້ນຫາ ຫ້ອງ, ຜູ້ຈອງ, ຈຸດປະສົງ...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
              onPressed: controller.clearSearch,
            );
          }),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER TABS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFilterTabs() {
    const tabs = [
      _TabInfo('ທັງໝົດ', null),
      _TabInfo('ລໍຖ້າ', Color(0xFFF59E0B)),
      _TabInfo('ອະນຸມັດ', Color(0xFF10B981)),
      _TabInfo('ປະຕິເສດ', Color(0xFFE53935)),
    ];

    return Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isSelected = controller.selectedTab.value == i;

              // Count for badge
              int count;
              switch (i) {
                case 1:
                  count = controller.pendingCount.value;
                  break;
                case 2:
                  count = controller.approvedCount.value;
                  break;
                case 3:
                  count = controller.rejectedCount.value;
                  break;
                default:
                  count = controller.totalCount.value;
              }

              return Padding(
                padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => controller.setTab(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (tab.color ?? AppColors.primary)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (tab.color ?? AppColors.primary)
                              : Colors.grey.shade300,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (tab.color ?? AppColors.primary)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOKING LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBookingList() {
    return Obx(() {
      final list = controller.filteredBookings;

      if (list.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  controller.searchQuery.value.isNotEmpty
                      ? 'ບໍ່ພົບຜົນການຄົ້ນຫາ'
                      : 'ບໍ່ມີລາຍການຈອງ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.searchQuery.value.isNotEmpty
                      ? 'ລອງຄົ້ນຫາດ້ວຍຄຳອື່ນ'
                      : 'ລາຍການຈອງຈະສະແດງຢູ່ບ່ອນນີ້',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final booking = list[index];
              return BookingCard(
                booking: booking,
                onApprove: () =>
                    controller.approveBooking(booking.bookingId),
                onReject: () =>
                    controller.rejectBooking(booking.bookingId),
              );
            },
            childCount: list.length,
          ),
        ),
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Obx(() => Text(
                controller.errorMessage.value,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              )),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('ລອງໃໝ່'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper class for tab info ───────────────────────────────────────────────
class _TabInfo {
  final String label;
  final Color? color;
  const _TabInfo(this.label, this.color);
}

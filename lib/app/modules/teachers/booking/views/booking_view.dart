import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/booking_controller.dart';
import '../controllers/fixed_booking.dart';
import '../../../data/data_exporter.dart';
import '../../../../widgets/widget.dart';

class BookingView extends GetView<BookingController> {
  const BookingView({super.key});
  @override
  Widget build(BuildContext context) {
    return GetBuilder<BookingController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('ຈອງຫ້ອງ'),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => Get.toNamed('/teacher-noti'),
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: 'ການແຈ້ງເຕືອນ',
                )
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context),
              backgroundColor: AppColors.primaryFill,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('ຈອງໃໝ່'),
            ),
            body: Obx(() {
              if (controller.isLoading.value) {
                return AppRefreshableLoader(
                  onRefresh: controller.refreshData,
                  child: const AppLoading.booking(),
                );
              }
              final err = controller.errorMessage.value;
              if (err.isNotEmpty) {
                return AppErrorState(
                  message: err,
                  onRetry: controller.refreshData,
                );
              }

              final fixedList = controller.filteredFixedBookings;
              final filtered = controller.filteredMyBookings;
              final hasAnyFixed = controller.fixedBookings.isNotEmpty;
              final isTeacher =
                  controller.currentUser.value?.teacherId != null;

              return RefreshIndicator(
                onRefresh: controller.refreshData,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _statsRow(controller),
                    const SizedBox(height: AppSpacing.m),
                    if (hasAnyFixed) ...[
                      _fixedSectionHeader(controller),
                      const SizedBox(height: AppSpacing.s),
                      _fixedFilterChips(controller),
                      const SizedBox(height: AppSpacing.s + 2),
                      if (fixedList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: AppEmptyState(
                            icon: Icons.event_busy_outlined,
                            title: 'ບໍ່ມີຄາບໃນຕົວກອງນີ້',
                            subtitle: 'ລອງເລືອກຕົວກອງອື່ນ',
                          ),
                        )
                      else
                        ..._buildFixedList(context, fixedList),
                      const SizedBox(height: AppSpacing.l),
                    ] else if (isTeacher) ...[
                      _fixedDiagnosticBanner(controller),
                      const SizedBox(height: AppSpacing.l),
                    ],
                    Row(
                      children: [
                        const Expanded(
                          child: Text('ປະຫວັດການຈອງຂອງຂ້ອຍ',
                              style: AppTypography.subheading),
                        ),
                        Text('${filtered.length} ລາຍການ',
                            style: AppTypography.caption),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _filterChips(controller),
                    const SizedBox(height: 10),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl),
                        child: AppEmptyState(
                          icon: Icons.inbox_outlined,
                          title: controller.myBookings.isEmpty
                              ? 'ຍັງບໍ່ມີການຈອງ'
                              : 'ບໍ່ມີຂໍ້ມູນທີ່ກົງກັບຕົວກອງ',
                          subtitle: controller.myBookings.isEmpty
                              ? 'ກົດປຸ່ມ "ຈອງໃໝ່" ເພື່ອເລີ່ມຕົ້ນ'
                              : 'ລອງເລືອກຕົວກອງອື່ນ',
                          actionLabel: controller.myBookings.isEmpty
                              ? 'ຈອງໃໝ່'
                              : 'ລ້າງຕົວກອງ',
                          actionIcon: controller.myBookings.isEmpty
                              ? Icons.add_rounded
                              : Icons.filter_alt_off_rounded,
                          onAction: controller.myBookings.isEmpty
                              ? () => _showCreateDialog(context)
                              : () => controller.bookingFilter.value = 'all',
                        ),
                      )
                    else
                      ...filtered.map((b) => _bookingCard(b)),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _statsRow(BookingController c) {
    Widget tile(String label, int value, Color color, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('ກຳລັງມາ', c.countUpcoming, AppColors.primary,
            Icons.event_available),
        const SizedBox(width: 8),
        tile('ລໍຖ້າ', c.countPending, AppColors.borderPending,
            Icons.hourglass_top),
        const SizedBox(width: 8),
        tile('ອະນຸມັດ', c.countApproved, AppColors.borderApproved,
            Icons.check_circle),
        const SizedBox(width: 8),
        tile('ຜ່ານໄປແລ້ວ', c.countPast, Colors.grey, Icons.history),
      ],
    );
  }

  Widget _filterChips(BookingController c) {
    const filters = <(String, String)>[
      ('all', 'ທັງໝົດ'),
      ('upcoming', 'ກຳລັງມາ'),
      ('pending', 'ລໍຖ້າ'),
      ('approved', 'ອະນຸມັດ'),
      ('cancelled', 'ຍົກເລີກ'),
      ('past', 'ຜ່ານໄປແລ້ວ'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final (key, label) = filters[i];
          final selected = c.bookingFilter.value == key;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => c.bookingFilter.value = key,
            labelStyle: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.grey.shade100,
            side: BorderSide(color: Colors.grey.shade300),
            visualDensity: VisualDensity.compact,
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemCount: filters.length,
      ),
    );
  }

  Widget _bookingCard(RoomBookingModel b) {
    final room = b.room?.roomCode ?? 'Room ${b.roomId}';
    final date =
        '${b.bookingDate.day}/${b.bookingDate.month}/${b.bookingDate.year}';
    final status = b.status;
    final s = status.toLowerCase();
    final past = controller.isBookingPast(b);
    final color = s == 'approved'
        ? Colors.green
        : s == 'rejected' || s == 'cancelled'
            ? Colors.red
            : Colors.orange;
    final canCancel = (s == 'pending' || s == 'approved') && !past;
    final dayBadge = _dayBadge(b.bookingDate);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Opacity(
        opacity: past ? 0.65 : 1.0,
        child: ListTile(
          title: Row(
            children: [
              Flexible(
                child: Text(
                  '$room • ${b.startTime} - ${b.endTime}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (dayBadge != null) ...[
                const SizedBox(width: 6),
                dayBadge,
              ],
            ],
          ),
          subtitle: Text(
            [
              'ວັນທີ $date',
              if (b.purpose != null && b.purpose!.isNotEmpty)
                'ເປົ້າໝາຍ: ${b.purpose}',
            ].join('\n'),
          ),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (canCancel) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => controller.cancelAdHocBooking(b),
                  child: const Text(
                    'ຍົກເລີກ',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _fixedSectionHeader(BookingController c) {
    return Row(
      children: [
        const Expanded(
          child: Text('ການຈອງປະຈຳ (ຈາກຕາຕະລາງຮຽນ)',
              style: AppTypography.subheading),
        ),
        if (c.countFixedCancelled > 0)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.rejectRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ຍົກເລີກ ${c.countFixedCancelled}',
                style: const TextStyle(
                  color: AppColors.rejectRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Text('${c.countFixedUpcoming} ຄາບ', style: AppTypography.caption),
      ],
    );
  }

  Widget _fixedFilterChips(BookingController c) {
    const filters = <(String, String)>[
      ('upcoming', 'ກຳລັງມາ'),
      ('today', 'ມື້ນີ້'),
      ('week', '7 ວັນ'),
      ('cancelled', 'ຍົກເລີກ'),
      ('all', 'ທັງໝົດ'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final (key, label) = filters[i];
          final selected = c.fixedFilter.value == key;
          int? badge;
          if (key == 'today') badge = c.countFixedToday;
          if (key == 'cancelled') badge = c.countFixedCancelled;
          return ChoiceChip(
            label: Text(
              badge != null && badge > 0 ? '$label ($badge)' : label,
            ),
            selected: selected,
            onSelected: (_) => c.fixedFilter.value = key,
            labelStyle: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: AppColors.bookingBlue,
            backgroundColor: Colors.grey.shade100,
            side: BorderSide(color: Colors.grey.shade300),
            visualDensity: VisualDensity.compact,
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemCount: filters.length,
      ),
    );
  }

  /// Diagnostic banner shown when a teacher has no fixed bookings. Surfaces
  /// the controller's persist-pipeline state so it's obvious whether the gap
  /// is "no study plans assigned", "semester missing dates", or "backend
  /// rejected the POST" — instead of an empty silent list.
  Widget _fixedDiagnosticBanner(BookingController c) {
    final sem = c.activeSemester.value;
    final user = c.currentUser.value;
    final bail = c.persistBailReason.value;
    final lastErr = c.persistLastError.value;

    String semLine;
    if (sem == null) {
      semLine = 'ບໍ່ມີ (none)';
    } else if (sem.startDate == null || sem.endDate == null) {
      semLine = '${sem.semasterCode} — ບໍ່ມີວັນທີ';
    } else {
      final s = sem.startDate!;
      final e = sem.endDate!;
      semLine = '${sem.semasterCode} '
          '(${s.day}/${s.month}/${s.year} → ${e.day}/${e.month}/${e.year})';
    }

    Widget kv(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  k,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  v,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.borderPending.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.borderPending.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.borderPending, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ບໍ່ມີຄາບການຮຽນປະຈຳ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ຍັງບໍ່ມີ room_booking ທີ່ຕິດກັບ study_plan. ກວດສະຖານະຂ້າງລຸ່ມ ແລ້ວກົດ ດຶງຂໍ້ມູນຄືນ.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
          const SizedBox(height: AppSpacing.s),
          kv('ພາກຮຽນ:', semLine),
          kv('Teacher ID:',
              user?.teacherId?.toString() ?? 'ບໍ່ມີ (not a teacher account)'),
          kv('Study plans ໂຫລດ:', '${c.persistPlansConsidered.value}'),
          kv('ຕົງກັບອາຈານ:', '${c.persistPlansForMe.value}'),
          kv('ມີຫ້ອງ+ເວລາ:', '${c.persistPlansComplete.value}'),
          kv('Marker rows ໃນ DB:', '${c.persistMarkerRowsInDb.value}'),
          kv('ສ້າງລ່າສຸດ:',
              '${c.persistRowsCreated.value} (ຂ້າມ existing ${c.persistSlotsSkippedExisting.value}, ຂ້າມ taken ${c.persistSlotsSkippedTaken.value})'),
          if (bail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.rejectRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.rejectRed, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ສາເຫດ: $bail',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.rejectRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (lastErr.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.rejectRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API error:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.rejectRed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastErr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.rejectRed,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: c.resyncFixedBookings,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('ດຶງຂໍ້ມູນຄືນ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryFill,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m, vertical: AppSpacing.s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders [list] grouped under date headers so a week's classes scan top to
  /// bottom without the eye having to re-derive the date for each card.
  List<Widget> _buildFixedList(BuildContext context, List<FixedBooking> list) {
    final widgets = <Widget>[];
    String? currentDateKey;
    for (final fb in list) {
      final key =
          '${fb.date.year}-${fb.date.month.toString().padLeft(2, '0')}-${fb.date.day.toString().padLeft(2, '0')}';
      if (key != currentDateKey) {
        widgets.add(_fixedDateHeader(fb.date));
        currentDateKey = key;
      }
      widgets.add(_fixedCard(context, fb));
    }
    return widgets;
  }

  Widget _fixedDateHeader(DateTime d) {
    final weekday = _weekdayLao(d.weekday);
    final dateStr = '${d.day}/${d.month}/${d.year}';
    final today = dateOnly(DateTime.now());
    final target = dateOnly(d);
    String? hint;
    if (sameDate(target, today)) {
      hint = 'ມື້ນີ້';
    } else if (sameDate(target, today.add(const Duration(days: 1)))) {
      hint = 'ມື້ອື່ນ';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            '$weekday $dateStr',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              letterSpacing: 0.3,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                hint,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _weekdayLao(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'ວັນຈັນ';
      case DateTime.tuesday:
        return 'ວັນອັງຄານ';
      case DateTime.wednesday:
        return 'ວັນພຸດ';
      case DateTime.thursday:
        return 'ວັນພະຫັດ';
      case DateTime.friday:
        return 'ວັນສຸກ';
      case DateTime.saturday:
        return 'ວັນເສົາ';
      case DateTime.sunday:
        return 'ວັນອາທິດ';
      default:
        return '';
    }
  }

  Widget _fixedCard(BuildContext context, FixedBooking fb) {
    final room = fb.plan.room?.roomCode ?? 'Room ${fb.roomId}';
    final subject =
        fb.plan.subject?.nameLao ?? fb.plan.subject?.nameEng ?? 'ວິຊາ';
    final group = fb.plan.studentGroup?.stdGroupName ?? '-';
    final color = fb.cancelled ? Colors.grey : AppColors.bookingBlue;
    final past = isPastSlot(fb.date, fb.startTime);
    final canRestore = fb.cancelled && !past;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Opacity(
        opacity: past ? 0.7 : 1.0,
        child: ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              fb.cancelled ? Icons.event_busy : Icons.event_repeat,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            '$subject • $room',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              decoration: fb.cancelled
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              'ກຸ່ມ $group • ${fb.startTime}-${fb.endTime}',
              if (fb.cancelled && (fb.cancelReason ?? '').isNotEmpty)
                'ເຫດຜົນ: ${fb.cancelReason}',
            ].join('\n'),
          ),
          isThreeLine: fb.cancelled && (fb.cancelReason ?? '').isNotEmpty,
          trailing: fb.cancelled
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.rejectRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ຍົກເລີກ',
                        style: TextStyle(
                          color: AppColors.rejectRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (canRestore) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => controller.restoreFixedBooking(fb),
                        child: const Text(
                          'ກູ້ຄືນ',
                          style: TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : past
                  ? Text(
                      'ສຳເລັດ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () => _promptCancelReason(context, fb),
                      icon: const Icon(Icons.cancel,
                          color: AppColors.rejectRed, size: 18),
                      label: const Text('ຍົກເລີກ',
                          style: TextStyle(
                              color: AppColors.rejectRed, fontSize: 12)),
                    ),
        ),
      ),
    );
  }

  Future<void> _promptCancelReason(
      BuildContext context, FixedBooking fb) async {
    final reasonCtrl = TextEditingController();
    final dateStr = '${fb.date.day}/${fb.date.month}/${fb.date.year}';
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ຍົກເລີກການຮຽນ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ວັນທີ $dateStr ${fb.startTime}-${fb.endTime}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ເຫດຜົນ (ບໍ່ບັງຄັບ)',
                hintText: 'ເຊັ່ນ: ອາຈານປ່ວຍ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ນັກສຶກສາໃນກຸ່ມຈະຮັບການແຈ້ງເຕືອນ (ມີເຫດຜົນຖ້າລະບຸ)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ກັບຄືນ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ຍົກເລີກການຮຽນ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.cancelFixedBooking(fb, reason: reasonCtrl.text);
  }

  /// "ມື້ນີ້" / "ມື້ອື່ນ" pill for today/tomorrow; null otherwise.
  Widget? _dayBadge(DateTime d) {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(d);
    String? label;
    Color? color;
    if (sameDate(target, today)) {
      label = 'ມື້ນີ້';
      color = AppColors.primary;
    } else if (sameDate(target, today.add(const Duration(days: 1)))) {
      label = 'ມື້ອື່ນ';
      color = AppColors.bookingBlue;
    }
    if (label == null || color == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    TextEditingController target,
  ) async {
    final raw = target.text.trim();
    final parts = raw.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    target.text = '$hh:$mm';
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final selectedRoomId = RxnInt();
    final date = Rx<DateTime>(DateTime.now());
    final startCtrl = TextEditingController(text: '08:30');
    final endCtrl = TextEditingController(text: '10:00');
    final purposeCtrl = TextEditingController();
    final conflictNote = ''.obs;
    final pastNote = ''.obs;

    void recomputeConflict() {
      pastNote.value =
          controller.pastSlotReason(date.value, startCtrl.text.trim()) ?? '';
      final id = selectedRoomId.value;
      if (id == null) {
        conflictNote.value = '';
        return;
      }
      final reason = controller.conflictReason(
        roomId: id,
        bookingDate: date.value,
        startTime: startCtrl.text.trim(),
        endTime: endCtrl.text.trim(),
      );
      conflictNote.value = reason ?? '';
    }

    startCtrl.addListener(recomputeConflict);
    endCtrl.addListener(recomputeConflict);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Obx(() {
            final isPast = pastNote.value.isNotEmpty;
            final available = isPast
                ? const <RoomModel>[]
                : controller.availableRoomsFor(
                    bookingDate: date.value,
                    startTime: startCtrl.text.trim(),
                    endTime: endCtrl.text.trim(),
                  );
            if (selectedRoomId.value != null &&
                !available.any((r) => r.id == selectedRoomId.value)) {
              selectedRoomId.value = null;
            }
            final canSubmit = !isPast &&
                selectedRoomId.value != null &&
                conflictNote.value.isEmpty;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: SizedBox(
                    width: 40,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.all(Radius.circular(99)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ຈອງຫ້ອງໃໝ່',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedRoomId.value,
                  items: available
                      .map(
                        (r) => DropdownMenuItem<int>(
                          value: r.id,
                          child: Text('${r.roomCode} (${r.capacity})'),
                        ),
                      )
                      .toList(),
                  onChanged: isPast
                      ? null
                      : (v) {
                          selectedRoomId.value = v;
                          recomputeConflict();
                        },
                  decoration: InputDecoration(
                    labelText: isPast
                        ? 'ບໍ່ມີຫ້ອງ (ເວລາຜ່ານໄປແລ້ວ)'
                        : 'ຫ້ອງ (ມີ ${available.length} ຫ້ອງວ່າງ)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final today = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(
                                today.year, today.month, today.day),
                            lastDate: today.add(const Duration(days: 365)),
                            initialDate: date.value.isBefore(today)
                                ? today
                                : date.value,
                          );
                          if (picked != null) {
                            date.value = picked;
                            recomputeConflict();
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          '${date.value.day}/${date.value.month}/${date.value.year}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        readOnly: true,
                        onTap: () => _pickTime(context, startCtrl),
                        decoration: const InputDecoration(
                          labelText: 'ເລີ່ມ (HH:mm)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        readOnly: true,
                        onTap: () => _pickTime(context, endCtrl),
                        decoration: const InputDecoration(
                          labelText: 'ສິ້ນສຸດ (HH:mm)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PurposeChips(
                  presets: const [
                    'ສອນຊົດເຊີຍ',
                    'ສອບເສັງ',
                    'ປະຊຸມ',
                    'ກິດຈະກຳ',
                  ],
                  controller: purposeCtrl,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: purposeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ເປົ້າໝາຍ (ບໍ່ບັງຄັບ)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (pastNote.value.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _inlineWarning(pastNote.value, Colors.red),
                ] else if (conflictNote.value.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _inlineWarning(conflictNote.value, Colors.red),
                ],
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: 'ສົ່ງຄຳຂໍ',
                  icon: Icons.send_rounded,
                  onPressed: !canSubmit
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          await controller.createBooking(
                            roomId: selectedRoomId.value!,
                            bookingDate: date.value,
                            startTime: startCtrl.text.trim(),
                            endTime: endCtrl.text.trim(),
                            purpose: purposeCtrl.text.trim().isEmpty
                                ? null
                                : purposeCtrl.text.trim(),
                          );
                        },
                ),
              ],
            );
          }),
        );
      },
    );

    startCtrl.removeListener(recomputeConflict);
    endCtrl.removeListener(recomputeConflict);
  }

  Widget _inlineWarning(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurposeChips extends StatelessWidget {
  final List<String> presets;
  final TextEditingController controller;
  const _PurposeChips({required this.presets, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final label = presets[i];
          return ActionChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            onPressed: () => controller.text = label,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

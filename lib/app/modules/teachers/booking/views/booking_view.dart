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
                  onPressed: controller.refreshData,
                  icon: const Icon(Icons.refresh),
                )
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('ຈອງໃໝ່'),
            ),
            body: Obx(() {
              if (controller.isLoading.value) {
                return const AppLoading.booking();
              }
              final err = controller.errorMessage.value;
              if (err.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          err,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: controller.refreshData,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }

              final fixedList = controller.upcomingFixedBookings;
              final filtered = controller.filteredMyBookings;

              return RefreshIndicator(
                onRefresh: controller.refreshData,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _statsRow(controller),
                    const SizedBox(height: 16),
                    if (fixedList.isNotEmpty) ...[
                      const Text(
                        'ການຈອງປະຈຳ (ຈາກຕາຕະລາງຮຽນ)',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      ...fixedList.map((fb) => _fixedCard(context, fb)),
                      const SizedBox(height: 20),
                    ],
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ປະຫວັດການຈອງຂອງຂ້ອຍ',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${filtered.length} ລາຍການ',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _filterChips(controller),
                    const SizedBox(height: 10),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                controller.myBookings.isEmpty
                                    ? 'ຍັງບໍ່ມີການຈອງ'
                                    : 'ບໍ່ມີຂໍ້ມູນທີ່ກົງກັບຕົວກອງ',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
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

  Widget _fixedCard(BuildContext context, FixedBooking fb) {
    final room = fb.plan.room?.roomCode ?? 'Room ${fb.roomId}';
    final subject =
        fb.plan.subject?.nameLao ?? fb.plan.subject?.nameEng ?? 'ວິຊາ';
    final group = fb.plan.studentGroup?.stdGroupName ?? '-';
    final dateStr = '${fb.date.day}/${fb.date.month}/${fb.date.year}';
    final color = fb.cancelled ? Colors.grey : Colors.blueAccent;
    final dayBadge = _dayBadge(fb.date);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        leading: Icon(
          fb.cancelled ? Icons.event_busy : Icons.event_repeat,
          color: color,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                '$subject • $room',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  decoration: fb.cancelled
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
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
            'ກຸ່ມ $group',
            'ວັນທີ $dateStr • ${fb.startTime}-${fb.endTime}',
            if (fb.cancelled && (fb.cancelReason ?? '').isNotEmpty)
              'ເຫດຜົນ: ${fb.cancelReason}',
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: fb.cancelled
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('ຍົກເລີກແລ້ວ',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              )
            : TextButton.icon(
                onPressed: () => _promptCancelReason(context, fb),
                icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                label: const Text('ຍົກເລີກ',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('ສົ່ງຄຳຂໍ'),
                  ),
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

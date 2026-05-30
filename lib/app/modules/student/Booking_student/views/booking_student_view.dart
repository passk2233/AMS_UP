import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/booking_student_controller.dart';
import '../../../data/data_exporter.dart';
import '../../../../widgets/widget.dart';
import '../../../teachers/booking/controllers/fixed_booking.dart';

class BookingStudentView extends GetView<BookingStudentController> {
  const BookingStudentView({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BookingStudentController>()) {
      Get.put(BookingStudentController());
    }
    return GetBuilder<BookingStudentController>(
      builder: (controller) => LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('ຈອງຫ້ອງ'),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => Get.toNamed('/student-noti'),
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: 'ການແຈ້ງເຕືອນ',
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

              final filtered = controller.filteredMyBookings;

              return RefreshIndicator(
                onRefresh: controller.refreshData,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _statsRow(controller),
                    const SizedBox(height: AppSpacing.m),
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
                    const SizedBox(height: AppSpacing.s),
                    _filterChips(controller),
                    const SizedBox(height: AppSpacing.s + 2),
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

  Widget _statsRow(BookingStudentController c) {
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

  Widget _filterChips(BookingStudentController c) {
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
                  onTap: () => controller.cancelBooking(b),
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
                    'ອ່ານປຶ້ມ',
                    'ໂປຣເຈັກກຸ່ມ',
                    'ປະຊຸມຊົມຮົມ',
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

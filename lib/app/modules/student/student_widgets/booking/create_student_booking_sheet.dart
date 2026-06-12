import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/widget.dart';
import '../../../data/data_exporter.dart';
import '../../Booking_student/controllers/booking_student_controller.dart';

/// Bottom sheet that creates a new student room booking.
Future<void> showCreateStudentBookingSheet(
  BuildContext context,
  BookingStudentController controller,
) async {
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
                          firstDate:
                              DateTime(today.year, today.month, today.day),
                          lastDate: today.add(const Duration(days: 365)),
                          initialDate:
                              date.value.isBefore(today) ? today : date.value,
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
                      onTap: () => pickTime24h(context, startCtrl),
                      decoration: const InputDecoration(
                        labelText: 'ເລີ່ມ (HH:mm)',
                        suffixIcon: Icon(Icons.access_time, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      readOnly: true,
                      onTap: () => pickTime24h(context, endCtrl),
                      decoration: const InputDecoration(
                        labelText: 'ສິ້ນສຸດ (HH:mm)',
                        suffixIcon: Icon(Icons.access_time, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BookingPurposeChips(
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
                ),
              ),
              if (pastNote.value.isNotEmpty) ...[
                const SizedBox(height: 8),
                BookingInlineWarning(message: pastNote.value),
              ] else if (conflictNote.value.isNotEmpty) ...[
                const SizedBox(height: 8),
                BookingInlineWarning(message: conflictNote.value),
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

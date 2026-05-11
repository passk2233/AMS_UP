import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/booking_controller.dart';
import '../../../widgets/widget.dart';

class BookingView extends GetView<BookingController> {
  const BookingView({super.key});
  @override
  Widget build(BuildContext context) {
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
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
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

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'ປະຫວັດການຈອງຂອງຂ້ອຍ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (controller.myBookings.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('ຍັງບໍ່ມີການຈອງ')),
                )
              else
                ...controller.myBookings.map((b) {
                  final room = b.room?.roomCode ?? 'Room ${b.roomId}';
                  final date = '${b.bookingDate.day}/${b.bookingDate.month}/${b.bookingDate.year}';
                  final status = b.status;
                  final color = status.toLowerCase() == 'approved'
                      ? Colors.green
                      : status.toLowerCase() == 'rejected'
                          ? Colors.red
                          : Colors.orange;
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      title: Text(
                        '$room • ${b.startTime} - ${b.endTime}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          'ວັນທີ $date',
                          if (b.purpose != null && b.purpose!.isNotEmpty)
                            'ເປົ້າໝາຍ: ${b.purpose}',
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final selectedRoomId = RxnInt();
    final date = Rx<DateTime>(DateTime.now());
    final startCtrl = TextEditingController(text: '08:30');
    final endCtrl = TextEditingController(text: '10:00');
    final purposeCtrl = TextEditingController();

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
                  items: controller.rooms
                      .map(
                        (r) => DropdownMenuItem<int>(
                          value: r.id,
                          child: Text('${r.roomCode} (${r.capacity})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => selectedRoomId.value = v,
                  decoration: const InputDecoration(
                    labelText: 'ຫ້ອງ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            initialDate: date.value,
                          );
                          if (picked != null) date.value = picked;
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
                        decoration: const InputDecoration(
                          labelText: 'ເລີ່ມ (HH:mm)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ສິ້ນສຸດ (HH:mm)',
                          border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedRoomId.value == null
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
  }
}

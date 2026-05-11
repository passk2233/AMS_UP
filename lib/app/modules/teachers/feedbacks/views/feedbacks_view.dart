import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/feedbacks_controller.dart';
import '../../../../widgets/widget.dart';

class FeedbacksView extends GetView<FeedbacksController> {
  const FeedbacksView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ຄຳເຫັນ / Feedback'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
              if (controller.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('ຍັງບໍ່ມີຄຳເຫັນ')),
                )
              else
                ...controller.items.map((it) {
                  final header = [
                    it.subjectName,
                    if (it.subjectCode.isNotEmpty) '(${it.subjectCode})',
                  ].join(' ');
                  final meta = [
                    if (it.semesterLabel.isNotEmpty) it.semesterLabel,
                    if (it.studentGroupName.isNotEmpty) it.studentGroupName,
                  ].join(' • ');
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            header,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          if (meta.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              meta,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            it.comment,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}

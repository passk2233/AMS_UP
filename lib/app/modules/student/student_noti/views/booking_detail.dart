import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/widgets/app_colors.dart';

class BookingDetailView extends StatelessWidget {
  const BookingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Get.back(),
            ),
            title: const Text(
              "Booking Detail",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Column(
            children: [
              const SizedBox(height: 30),
              // Success Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "CONFIRMED",
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 25),
              const Text(
                "Booking Confirmed",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your study group session has been confirmed.",
                style: TextStyle(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 30),

              // Details Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.apartment,
                        "ROOM LOCATION",
                        "Room A301",
                        "Academic Wing, 3rd Floor",
                        AppColors.info.withValues(alpha: 0.1),
                        AppColors.info,
                      ),
                      const Divider(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailRow(
                              Icons.calendar_today,
                              "DATE",
                              "Jan 26, 2024",
                              "",
                              AppColors.info.withValues(alpha: 0.1),
                              AppColors.info,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailRow(
                              Icons.access_time,
                              "TIME",
                              "09:00 - 11:00",
                              "",
                              AppColors.info.withValues(alpha: 0.1),
                              AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 40),
                      _buildDetailRow(
                        Icons.person_outline,
                        "BOOKED BY",
                        "Souksakhone SAYYAVONG",
                        "",
                        AppColors.info.withValues(alpha: 0.1),
                        AppColors.info,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String title,
    String sub,
    Color bgColor,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            if (sub.isNotEmpty)
              Text(
                sub,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

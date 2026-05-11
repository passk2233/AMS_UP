import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookingDetailView extends StatelessWidget {
  const BookingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Booking Detail",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF22C55E),
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "CONFIRMED",
              style: TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 25),
          const Text(
            "Booking Confirmed",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your study group session has been confirmed.",
            style: TextStyle(color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 30),

          // Details Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                    const Color(0xFFEEF2FF),
                    const Color(0xFF6366F1),
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
                          const Color(0xFFFFF7ED),
                          const Color(0xFFF97316),
                        ),
                      ),
                      Expanded(
                        child: _buildDetailRow(
                          Icons.access_time,
                          "TIME",
                          "09:00 - 11:00",
                          "",
                          const Color(0xFFEFF6FF),
                          const Color(0xFF3B82F6),
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
                    const Color(0xFFF5F3FF),
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (sub.isNotEmpty)
              Text(
                sub,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      ],
    );
  }
}

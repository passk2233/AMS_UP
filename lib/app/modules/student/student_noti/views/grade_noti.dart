import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GradeNotiView extends StatelessWidget {
  const GradeNotiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text("Grade Notification", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Status Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_outline, color: Color(0xFF6366F1), size: 18),
                  SizedBox(width: 8),
                  Text("Database Update: New Results Available", 
                    style: TextStyle(color: Color(0xFF6366F1), fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text("ACADEMIC RECORD", style: TextStyle(color: Colors.grey, letterSpacing: 1.2, fontSize: 12)),
          const SizedBox(height: 10),
          const Text("Database System 2", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 50),
          
          // Grade Circle
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF818CF8), width: 12),
            ),
            alignment: Alignment.center,
            child: const Text("A", style: TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
          ),
          
          const SizedBox(height: 20),
          const Text("EXCELLENT", style: TextStyle(color: Color(0xFF818CF8), fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 2)),
          
          const SizedBox(height: 50),
          
          // Info Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_work_outlined, color: Color(0xFF4338CA), size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Grade Published by Academic Office", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 5),
                        Text("Database transcript data synchronized", style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
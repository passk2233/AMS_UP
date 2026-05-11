import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/faculty_feedback_controller.dart';
import 'faculty_model.dart';
import 'package:frontend/app/routes/app_pages.dart';

class FacultyFeedbackView extends GetView<FacultyFeedbackController> {
  const FacultyFeedbackView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Faculty Feedback',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search professor or course...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.facultyList.length,
                itemBuilder: (context, index) {
                  return _buildFacultyCard(controller.facultyList[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyCard(Faculty faculty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue[50],
                child: Text(
                  faculty.initials,
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(faculty.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(faculty.course, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: faculty.isSubmitted 
                ? _buildSubmittedButton() 
                : _buildEvaluateButton(faculty),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluateButton(Faculty faculty) {
    return ElevatedButton(
      onPressed: () => Get.toNamed(Routes.EVALUATION_FORM, arguments: faculty),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text('Evaluate', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildSubmittedButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text('Feedback Submitted', style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}
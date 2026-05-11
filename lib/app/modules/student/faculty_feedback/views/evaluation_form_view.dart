import "package:flutter/material.dart";
import "package:get/get.dart";
import "../controllers/faculty_feedback_controller.dart";
import "faculty_model.dart";

class EvaluationFormView extends GetView<FacultyFeedbackController> {
  const EvaluationFormView({super.key});

  @override
  Widget build(BuildContext context) {
    // รับข้อมูล Faculty จาก arguments (ห้ามใส่ ?? 0 เพราะเราส่งเป็น Object)
    final Faculty faculty = Get.arguments;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Faculty Feedback', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFacultyHeader(faculty),
            const SizedBox(height: 20),

            for (int i = 0; i < 7; i++) _buildStarRatingQuestion(i),

            const SizedBox(height: 20),
            const Text("Comment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            TextField(
              onChanged: (val) => controller.comment.value = val,
              decoration: InputDecoration(
                hintText: 'ใส่ความเห็นเพิ่มเติม',
                fillColor: Colors.grey[200],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.submitFeedback(faculty),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D69F1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Submit Feedback', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyHeader(Faculty faculty) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue[50],
          child: Text(faculty.initials, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(faculty.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(faculty.course, style: const TextStyle(color: Colors.grey)),
          ],
        )
      ],
    );
  }

  Widget _buildStarRatingQuestion(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("หัวข้อการประเมินที่ ${index + 1}", style: const TextStyle(fontSize: 16)),
          Obx(() => Row(
            children: List.generate(5, (starIndex) {
              return IconButton(
                icon: Icon(
                  Icons.star,
                  size: 35,
                  color: starIndex < controller.ratings[index] 
                      ? Colors.orangeAccent 
                      : Colors.grey[300],
                ),
                onPressed: () => controller.setRating(index, starIndex + 1),
              );
            }),
          )),
        ],
      ),
    );
  }
}
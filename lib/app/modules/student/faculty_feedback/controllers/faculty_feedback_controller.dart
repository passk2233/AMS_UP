import 'package:frontend/app/modules/student/faculty_feedback/views/faculty_model.dart';
import 'package:get/get.dart';

class FacultyFeedbackController extends GetxController {
  // รายชื่ออาจารย์
  var facultyList = <Faculty>[
    Faculty(initials: 'TB', name: 'ຮສ ທາ ບຸນທັນ', course: 'Database System 2'),
    Faculty(initials: 'KP', name: 'ອຈ ຄຳເພົ້າ', course: 'ຄວາມປວດໄພຂອງຂໍ້ມູນ'),
    Faculty(
      initials: 'SCH',
      name: 'ຮສ ແສງລັດສະໝີ ຈັນທະມີນາວົງ',
      course: 'Web Programming',
      isSubmitted: true,
    ),
  ].obs;

  // คะแนนดาว 7 ข้อ
  var ratings = <int>[0, 0, 0, 0, 0, 0, 0].obs;
  
  // ข้อความ Comment
  var comment = "".obs;

  void setRating(int questionIndex, int rating) {
    ratings[questionIndex] = rating;
  }

  void submitFeedback(Faculty faculty) {
    // หาตำแหน่งของคนนี้ใน List
    int index = facultyList.indexWhere((f) => f.name == faculty.name);

    if (index != -1) {
      // 1. อัปเดตสถานะ (สร้าง Object ใหม่เพื่อให้ Obx รับรู้การเปลี่ยนแปลง)
      facultyList[index] = Faculty(
        initials: faculty.initials,
        name: faculty.name,
        course: faculty.course,
        isSubmitted: true,
      );

      // 2. ล้างค่าในฟอร์มเพื่อรอประเมินคนต่อไป
      ratings.assignAll(List.filled(7, 0));
      comment.value = "";

      // 3. กลับหน้าหลัก
      Get.back();
      Get.snackbar(
        "Success", 
        "Submitted feedback for ${faculty.name}",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
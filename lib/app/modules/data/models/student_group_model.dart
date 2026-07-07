import 'curriculum_model.dart';

class StudentGroupModel {
  int id;
  String stdGroupCode;
  String stdGroupName;
  int curriculumId;
  int startYear;
  CurriculumModel? curriculum;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  StudentGroupModel({
    required this.id,
    required this.stdGroupCode,
    required this.stdGroupName,
    required this.curriculumId,
    this.startYear = 0,
    this.curriculum,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory StudentGroupModel.fromJson(Map<String, dynamic> json) {
    return StudentGroupModel(
      id: json['id'] as int? ?? 0,
      stdGroupCode: json['std_group_code'] as String? ?? '',
      stdGroupName: json['std_group_name'] as String? ?? '',
      curriculumId: json['curriculum_id'] as int? ?? json['curri_id'] as int? ?? 0,
      startYear: json['start_year'] as int? ?? 0,
      curriculum: json['curriculum'] != null ? CurriculumModel.fromJson(json['curriculum']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  /// Display label with the enrollment year replaced by the students' study
  /// year as of [academicYear] — "ນັກສຶກສາໄອທີຕໍ່ເນື່ອງ ປີ 2020 ຫ້ອງ 1" →
  /// "ໄອທີຕໍ່ເນື່ອງ ປີ 2 ຫ້ອງ 1". ຕໍ່ເນື່ອງ (continuing) groups run 2 years,
  /// everyone else 4, so the year is clamped to that final year.
  String yearRoomLabel(int academicYear) {
    var name = stdGroupName.replaceFirst(RegExp(r'^ນັກສຶກສາ\s*'), '').trim();
    if (name.isEmpty) return stdGroupCode;
    if (startYear > 0 && academicYear > 0) {
      final cap = name.contains('ຕໍ່ເນື່ອງ') ? 2 : 4;
      final year = (academicYear - startYear + 1).clamp(1, cap);
      name = name.replaceFirst(RegExp(r'ປີ\s*\d{4}'), 'ປີ $year');
    }
    return name;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'std_group_code': stdGroupCode,
      'std_group_name': stdGroupName,
      'curriculum_id': curriculumId,
      'start_year': startYear,
      'curriculum': curriculum?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

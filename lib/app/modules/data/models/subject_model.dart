import 'curriculum_model.dart';
import 'subject_group_model.dart';

class SubjectModel {
  int id;
  int curriId;
  int groupId;
  String subjectCode;
  String nameLao;
  String? nameEng;
  int credit;
  int labHours;
  int lectureHours;
  int practicHours;
  int levelingroup;
  int levelinterm;
  int term;
  int year;
  int status;
  CurriculumModel? curriculum;
  SubjectGroupModel? subjectGroup;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  SubjectModel({
    required this.id,
    required this.curriId,
    required this.groupId,
    required this.subjectCode,
    required this.nameLao,
    this.nameEng,
    required this.credit,
    required this.labHours,
    required this.lectureHours,
    required this.practicHours,
    required this.levelingroup,
    required this.levelinterm,
    required this.term,
    required this.year,
    required this.status,
    this.curriculum,
    this.subjectGroup,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as int? ?? 0,
      curriId: json['curri_id'] as int? ?? 0,
      groupId: json['group_id'] as int? ?? 0,
      subjectCode: json['subject_code'] as String? ?? '',
      nameLao: json['name_lao'] as String? ?? '',
      nameEng: json['name_eng'] as String?,
      credit: json['credit'] as int? ?? 0,
      labHours: json['lab_hours'] as int? ?? 0,
      lectureHours: json['lecture_hours'] as int? ?? 0,
      practicHours: json['practic_hours'] as int? ?? 0,
      levelingroup: json['levelingroup'] as int? ?? 0,
      levelinterm: json['levelinterm'] as int? ?? 0,
      term: json['term'] as int? ?? 0,
      year: json['year'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
      curriculum: json['curriculum'] != null ? CurriculumModel.fromJson(json['curriculum']) : null,
      subjectGroup: json['subject_group'] != null ? SubjectGroupModel.fromJson(json['subject_group']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'curri_id': curriId,
      'group_id': groupId,
      'subject_code': subjectCode,
      'name_lao': nameLao,
      'name_eng': nameEng,
      'credit': credit,
      'lab_hours': labHours,
      'lecture_hours': lectureHours,
      'practic_hours': practicHours,
      'levelingroup': levelingroup,
      'levelinterm': levelinterm,
      'term': term,
      'year': year,
      'status': status,
      'curriculum': curriculum?.toJson(),
      'subject_group': subjectGroup?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

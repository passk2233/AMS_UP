import 'student_model.dart';
import 'village_model.dart';

class StdFamilyModel {
  int id;
  int stdId;
  String name;
  int? arg;
  int? villageId;
  String? jobTitle;
  String? office;
  String? telephone;
  String? relation;
  int? emergencyLevel;
  StudentModel? student;
  VillageModel? village;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  StdFamilyModel({
    required this.id,
    required this.stdId,
    required this.name,
    this.arg,
    this.villageId,
    this.jobTitle,
    this.office,
    this.telephone,
    this.relation,
    this.emergencyLevel,
    this.student,
    this.village,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory StdFamilyModel.fromJson(Map<String, dynamic> json) {
    return StdFamilyModel(
      id: json['id'] as int? ?? 0,
      stdId: json['std_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      arg: json['arg'] as int?,
      villageId: json['village_id'] as int?,
      jobTitle: json['job_title'] as String?,
      office: json['office'] as String?,
      telephone: json['telephone'] as String?,
      relation: json['relation'] as String?,
      emergencyLevel: json['emergency_level'] as int?,
      student: json['student'] != null ? StudentModel.fromJson(json['student']) : null,
      village: json['village'] != null ? VillageModel.fromJson(json['village']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'std_id': stdId,
      'name': name,
      'arg': arg,
      'village_id': villageId,
      'job_title': jobTitle,
      'office': office,
      'telephone': telephone,
      'relation': relation,
      'emergency_level': emergencyLevel,
      'student': student?.toJson(),
      'village': village?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

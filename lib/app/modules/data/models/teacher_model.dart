import 'department_model.dart';
import 'division_model.dart';

class TeacherModel {
  int id;
  int deptId;
  String teacherCode;
  String nameLao;
  String surnameLao;
  String nameEng;
  String? surnameEng;
  String gender;
  DateTime dateofbirth;
  String? photo;
  int curVillage;
  int bornVillage;
  String? telephone;
  String? email;
  String? nationality;
  String? ethnic;
  String? race;
  String? tribe;
  String? religion;
  String? maritalStatus;
  String? healthStatus;
  int? divisionId;
  DepartmentModel? department;
  DivisionModel? division;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  TeacherModel({
    required this.id,
    required this.deptId,
    required this.teacherCode,
    required this.nameLao,
    required this.surnameLao,
    required this.nameEng,
    this.surnameEng,
    required this.gender,
    required this.dateofbirth,
    this.photo,
    required this.curVillage,
    required this.bornVillage,
    this.telephone,
    this.email,
    this.nationality,
    this.ethnic,
    this.race,
    this.tribe,
    this.religion,
    this.maritalStatus,
    this.healthStatus,
    this.divisionId,
    this.department,
    this.division,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] as int? ?? 0,
      deptId: json['dept_id'] as int? ?? 0,
      teacherCode: json['teacher_code'] as String? ?? '',
      nameLao: json['name_lao'] as String? ?? '',
      surnameLao: json['surname_lao'] as String? ?? '',
      nameEng: json['name_eng'] as String? ?? '',
      surnameEng: json['surname_eng'] as String?,
      gender: json['gender'] as String? ?? '',
      dateofbirth: json['dateofbirth'] != null ? (DateTime.tryParse(json['dateofbirth'].toString()) ?? DateTime.now()) : DateTime.now(),
      photo: json['photo'] as String?,
      curVillage: json['cur_village'] as int? ?? 0,
      bornVillage: json['born_village'] as int? ?? 0,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      nationality: json['nationality'] as String?,
      ethnic: json['ethnic'] as String?,
      race: json['race'] as String?,
      tribe: json['tribe'] as String?,
      religion: json['religion'] as String?,
      maritalStatus: json['marital_status'] as String?,
      healthStatus: json['health_status'] as String?,
      divisionId: json['division_id'] as int?,
      department: json['department'] != null ? DepartmentModel.fromJson(json['department']) : null,
      division: json['division'] != null ? DivisionModel.fromJson(json['division']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dept_id': deptId,
      'teacher_code': teacherCode,
      'name_lao': nameLao,
      'surname_lao': surnameLao,
      'name_eng': nameEng,
      'surname_eng': surnameEng,
      'gender': gender,
      'dateofbirth': dateofbirth.toIso8601String(),
      'photo': photo,
      'cur_village': curVillage,
      'born_village': bornVillage,
      'telephone': telephone,
      'email': email,
      'nationality': nationality,
      'ethnic': ethnic,
      'race': race,
      'tribe': tribe,
      'religion': religion,
      'marital_status': maritalStatus,
      'health_status': healthStatus,
      'division_id': divisionId,
      'department': department?.toJson(),
      'division': division?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

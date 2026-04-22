import 'curriculum_model.dart';
import 'student_group_model.dart';
import 'student_type_model.dart';

class StudentModel {
  int id;
  String stdCode;
  int stdTypeId;
  int? stdGroupId;
  int curriId;
  String nameLao;
  String? surnameLao;
  String nameEng;
  String? surnameEng;
  String nameTitle;
  String gender;
  DateTime dateofbirth;
  String? photo;
  int? curVillage;
  int? bornVillage;
  String? telephone;
  String? email;
  String? nationality;
  String? ethnic;
  String? race;
  String? tribe;
  String? jobTitle;
  String? school;
  String? religion;
  String? maritalStatus;
  String? healthStatus;
  StudentTypeModel? studentType;
  StudentGroupModel? studentGroup;
  CurriculumModel? curriculum;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  StudentModel({
    required this.id,
    required this.stdCode,
    required this.stdTypeId,
    this.stdGroupId,
    required this.curriId,
    required this.nameLao,
    this.surnameLao,
    required this.nameEng,
    this.surnameEng,
    required this.nameTitle,
    required this.gender,
    required this.dateofbirth,
    this.photo,
    this.curVillage,
    this.bornVillage,
    this.telephone,
    this.email,
    this.nationality,
    this.ethnic,
    this.race,
    this.tribe,
    this.jobTitle,
    this.school,
    this.religion,
    this.maritalStatus,
    this.healthStatus,
    this.studentType,
    this.studentGroup,
    this.curriculum,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as int? ?? 0,
      stdCode: json['std_code'] as String? ?? '',
      stdTypeId: json['std_type_id'] as int? ?? 0,
      stdGroupId: json['std_group_id'] as int?,
      curriId: json['curri_id'] as int? ?? 0,
      nameLao: json['name_lao'] as String? ?? '',
      surnameLao: json['surname_lao'] as String?,
      nameEng: json['name_eng'] as String? ?? '',
      surnameEng: json['surname_eng'] as String?,
      nameTitle: json['name_title'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      dateofbirth: json['dateofbirth'] != null ? (DateTime.tryParse(json['dateofbirth'].toString()) ?? DateTime.now()) : DateTime.now(),
      photo: json['photo'] as String?,
      curVillage: json['cur_village'] as int?,
      bornVillage: json['born_village'] as int?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      nationality: json['nationality'] as String?,
      ethnic: json['ethnic'] as String?,
      race: json['race'] as String?,
      tribe: json['tribe'] as String?,
      jobTitle: json['job_title'] as String?,
      school: json['school'] as String?,
      religion: json['religion'] as String?,
      maritalStatus: json['marital_status'] as String?,
      healthStatus: json['health_status'] as String?,
      studentType: json['student_type'] != null ? StudentTypeModel.fromJson(json['student_type']) : null,
      studentGroup: json['student_group'] != null ? StudentGroupModel.fromJson(json['student_group']) : null,
      curriculum: json['curriculum'] != null ? CurriculumModel.fromJson(json['curriculum']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'std_code': stdCode,
      'std_type_id': stdTypeId,
      'std_group_id': stdGroupId,
      'curri_id': curriId,
      'name_lao': nameLao,
      'surname_lao': surnameLao,
      'name_eng': nameEng,
      'surname_eng': surnameEng,
      'name_title': nameTitle,
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
      'job_title': jobTitle,
      'school': school,
      'religion': religion,
      'marital_status': maritalStatus,
      'health_status': healthStatus,
      'student_type': studentType?.toJson(),
      'student_group': studentGroup?.toJson(),
      'curriculum': curriculum?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

import 'student_model.dart';
import 'teacher_model.dart';

class UserModel {
  int id;
  String username;
  String? email;
  int? stdId;
  int? teacherId;
  int? active;
  StudentModel? student;
  TeacherModel? teacher;
  List<String>? roles;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.stdId,
    this.teacherId,
    this.active,
    this.student,
    this.teacher,
    this.roles,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      stdId: json['std_id'] as int?,
      teacherId: json['teacher_id'] as int?,
      active: json['active'] as int?,
      student: json['student'] != null ? StudentModel.fromJson(json['student']) : null,
      teacher: json['teacher'] != null ? TeacherModel.fromJson(json['teacher']) : null,
      roles: json['roles'] != null ? List<String>.from(json['roles'].map((x) => x.toString())) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'std_id': stdId,
      'teacher_id': teacherId,
      'active': active,
      'student': student?.toJson(),
      'teacher': teacher?.toJson(),
      'roles': roles,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

import 'room_model.dart';
import 'semaster_model.dart';
import 'student_group_model.dart';
import 'subject_model.dart';
import 'teacher_model.dart';

class StudyPlanModel {
  int id;
  int semasterId;
  int subjectId;
  int stdGroupId;
  int teacherId;
  int? roomId;
  String? dayOfWeek;
  String? startTime;
  String? endTime;
  String? attechLink;
  String? scoreFile;
  SemasterModel? semaster;
  SubjectModel? subject;
  StudentGroupModel? studentGroup;
  TeacherModel? teacher;
  RoomModel? room;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  StudyPlanModel({
    required this.id,
    required this.semasterId,
    required this.subjectId,
    required this.stdGroupId,
    required this.teacherId,
    this.roomId,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.attechLink,
    this.scoreFile,
    this.semaster,
    this.subject,
    this.studentGroup,
    this.teacher,
    this.room,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory StudyPlanModel.fromJson(Map<String, dynamic> json) {
    return StudyPlanModel(
      id: json['id'] as int? ?? 0,
      semasterId: json['semaster_id'] as int? ?? 0,
      subjectId: json['subject_id'] as int? ?? 0,
      stdGroupId: json['std_group_id'] as int? ?? 0,
      teacherId: json['teacher_id'] as int? ?? 0,
      roomId: json['room_id'] as int?,
      dayOfWeek: json['day_of_week'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      attechLink: json['attech_link'] as String?,
      scoreFile: json['score_file'] as String?,
      semaster: json['semaster'] != null ? SemasterModel.fromJson(json['semaster']) : null,
      subject: json['subject'] != null ? SubjectModel.fromJson(json['subject']) : null,
      studentGroup: json['student_group'] != null ? StudentGroupModel.fromJson(json['student_group']) : null,
      teacher: json['teacher'] != null ? TeacherModel.fromJson(json['teacher']) : null,
      room: json['room'] != null ? RoomModel.fromJson(json['room']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semaster_id': semasterId,
      'subject_id': subjectId,
      'std_group_id': stdGroupId,
      'teacher_id': teacherId,
      'room_id': roomId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'attech_link': attechLink,
      'score_file': scoreFile,
      'semaster': semaster?.toJson(),
      'subject': subject?.toJson(),
      'student_group': studentGroup?.toJson(),
      'teacher': teacher?.toJson(),
      'room': room?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

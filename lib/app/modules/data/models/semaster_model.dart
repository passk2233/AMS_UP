class SemasterModel {
  int id;
  String semasterCode;
  int year;
  int term;
  DateTime? startDate;
  DateTime? endDate;
  int status;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  SemasterModel({
    required this.id,
    required this.semasterCode,
    required this.year,
    required this.term,
    this.startDate,
    this.endDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory SemasterModel.fromJson(Map<String, dynamic> json) {
    return SemasterModel(
      id: json['id'] as int? ?? 0,
      semasterCode: json['semaster_code'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      term: json['term'] as int? ?? 0,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'].toString()) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'].toString()) : null,
      status: json['status'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semaster_code': semasterCode,
      'year': year,
      'term': term,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

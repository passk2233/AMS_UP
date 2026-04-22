class RoomModel {
  int id;
  String roomCode;
  int capacity;
  String? description;
  int status;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  RoomModel({
    required this.id,
    required this.roomCode,
    required this.capacity,
    this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as int? ?? 0,
      roomCode: json['room_code'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      description: json['description'] as String?,
      status: json['status'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_code': roomCode,
      'capacity': capacity,
      'description': description,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}

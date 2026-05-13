class Faculty {
  final int studyPlanId;
  final int teacherId;
  final String initials;
  final String name;
  final String course;
  bool isSubmitted;

  Faculty({
    required this.studyPlanId,
    required this.teacherId,
    required this.initials,
    required this.name,
    required this.course,
    this.isSubmitted = false,
  });
}
class Faculty {
  final String initials;
  final String name;
  final String course;
  bool isSubmitted;

  Faculty({
    required this.initials,
    required this.name,
    required this.course,
    this.isSubmitted = false,
  });
}
/// View-model for one row of the student's faculty-evaluation list — a
/// teacher the student can evaluate for a specific study plan, with a
/// per-row submitted flag the controller flips after a successful submission.
///
/// Built client-side by joining `/study-plans` with their teacher relation;
/// it is not a direct table mirror, which is why it lives apart from the
/// JSON `*_model` types but still belongs in the data layer rather than a
/// view folder.
class Faculty {
  final int studyPlanId;
  final int teacherId;
  final String initials;
  final String name;
  final String course;

  /// Teacher's stored photo path/URL; null/broken shows the placeholder.
  final String? photo;
  bool isSubmitted;

  Faculty({
    required this.studyPlanId,
    required this.teacherId,
    required this.initials,
    required this.name,
    required this.course,
    this.photo,
    this.isSubmitted = false,
  });
}

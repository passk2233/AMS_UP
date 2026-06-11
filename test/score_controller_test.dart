import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:frontend/app/modules/data/data_exporter.dart';
import 'package:frontend/app/modules/student/score/controllers/score_controller.dart';

/// Builds a graded enrollment with the nested study-plan → semester / subject
/// that [ScoreController] reads. `semaster` carries term/year so the controller
/// can resolve the transcript label without hitting `/semasters`.
EnrollmentModel _enroll({
  required int semId,
  required int term,
  required int year,
  required String grade,
  required int credit,
  int subjectYear = 1,
}) {
  return EnrollmentModel(
    id: 0,
    studyPlanId: 0,
    stdId: 1,
    status: 'enrolled',
    grade: grade,
    studyPlan: StudyPlanModel(
      id: 0,
      semasterId: semId,
      subjectId: 0,
      stdGroupId: 0,
      teacherId: 0,
      semaster: SemasterModel(
        id: semId,
        semasterCode: 'S$semId',
        year: year,
        term: term,
        status: 1,
      ),
      subject: SubjectModel(
        id: 0,
        curriId: 0,
        groupId: 0,
        subjectCode: 'SUB',
        nameLao: 'ວິຊາ',
        credit: credit,
        labHours: 0,
        lectureHours: 0,
        practicHours: 0,
        levelingroup: 0,
        levelinterm: 0,
        term: term,
        year: subjectYear,
        status: 1,
      ),
    ),
  );
}

void main() {
  // ScoreController's constructor builds providers on ApiClient.dio, which
  // reads API_URL from dotenv — seed it so construction works off-device.
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_URL=http://localhost');
  });

  // Data taken verbatim from the official transcript of 225Q007022
  // (ທ້າວ ເພັດສະໝອນ ສີສົມຫວັງ):
  //   ເທີມ 1 ສົກສຶກສາ 2022 - 2023 → 18 ໜ່ວຍກິດ, GPA 3.00
  //   ເທີມ 2 ສົກສຶກສາ 2022 - 2023 → 16 ໜ່ວຍກິດ, GPA 3.09, ສະສົມ CGPA 3.04
  group('ScoreController — semesters from transcript data', () {
    late ScoreController c;

    setUp(() {
      c = ScoreController();
      c.enrollments.assignAll([
        // ── ເທີມ 1 ສົກສຶກສາ 2022 - 2023 ──
        _enroll(semId: 1, term: 1, year: 2022, grade: 'C+', credit: 2),
        _enroll(semId: 1, term: 1, year: 2022, grade: 'C+', credit: 2),
        _enroll(semId: 1, term: 1, year: 2022, grade: 'B', credit: 2),
        _enroll(semId: 1, term: 1, year: 2022, grade: 'B+', credit: 3),
        _enroll(semId: 1, term: 1, year: 2022, grade: 'B+', credit: 3),
        _enroll(semId: 1, term: 1, year: 2022, grade: 'B', credit: 2),
        _enroll(semId: 1, term: 1, year: 2022, grade: 'B', credit: 2),
        _enroll(semId: 1, term: 1, year: 2022, grade: 'C+', credit: 2),
        // ── ເທີມ 2 ສົກສຶກສາ 2022 - 2023 ──
        _enroll(semId: 2, term: 2, year: 2022, grade: 'B+', credit: 2),
        _enroll(semId: 2, term: 2, year: 2022, grade: 'B+', credit: 2),
        _enroll(semId: 2, term: 2, year: 2022, grade: 'B', credit: 3),
        _enroll(semId: 2, term: 2, year: 2022, grade: 'B+', credit: 2),
        _enroll(semId: 2, term: 2, year: 2022, grade: 'B+', credit: 3),
        _enroll(semId: 2, term: 2, year: 2022, grade: 'C', credit: 3),
        _enroll(semId: 2, term: 2, year: 2022, grade: 'B', credit: 1),
      ]);
      c.selectedSemesterId.value = 1;
    });

    test('groups into two chronological semesters (oldest first)', () {
      final s = c.semesters;
      expect(s.length, 2);
      expect(s.first.semasterId, 1);
      expect(s.last.semasterId, 2);
    });

    test('chip order is newest-first', () {
      expect(c.semestersNewestFirst.first.semasterId, 2);
    });

    test('labels use the transcript format, not "ພາກ1"', () {
      final first = c.semesters.first;
      expect(c.labelFor(first), 'ເທີມ 1 ສົກສຶກສາ 2022 - 2023');

      final chip = c.chipLabelFor(first);
      expect(chip.line1, 'ເທີມ 1');
      expect(chip.line2, 'ສົກສຶກສາ 2022 - 2023');
    });

    test('per-semester GPA + credits match the transcript', () {
      c.selectedSemesterId.value = 1;
      expect(c.selectedSemesterGpa, closeTo(3.00, 0.005));
      expect(c.selectedSemesterCredits, 18);
      expect(c.selectedSemesterSubjects, 8);

      c.selectedSemesterId.value = 2;
      expect(c.selectedSemesterGpa, closeTo(3.09, 0.005));
      expect(c.selectedSemesterCredits, 16);
      expect(c.selectedSemesterSubjects, 7);
    });

    test('cumulative CGPA + header totals match the transcript', () {
      expect(c.gpa, closeTo(3.04, 0.005)); // overall CGPA
      expect(c.totalCredits, 34);
      expect(c.totalSubjects, 15);
      expect(c.currentTermNumber, 2);

      c.selectedSemesterId.value = 2;
      expect(c.selectedCumulativeGpa, closeTo(3.04, 0.005));
      expect(c.selectedCumulativeCredits, 34);
    });
  });

  test('term progress is studied / (max curriculum year × 2)', () {
    final c = ScoreController();
    c.enrollments.assignAll([
      _enroll(
          semId: 7, term: 1, year: 2025, grade: 'A', credit: 3, subjectYear: 4),
    ]);
    expect(c.currentTermNumber, 1);
    expect(c.totalProgramTerms, 8); // year-4 program → 8 terms → "1/8"
  });

  test('falls back to the semester code when term/year are unknown', () {
    final c = ScoreController();
    c.enrollments.assignAll([
      EnrollmentModel(
        id: 0,
        studyPlanId: 0,
        stdId: 1,
        status: 'enrolled',
        grade: 'A',
        studyPlan: StudyPlanModel(
          id: 0,
          semasterId: 9,
          subjectId: 0,
          stdGroupId: 0,
          teacherId: 0,
          semaster: SemasterModel(
            id: 9,
            semasterCode: '2099-T1',
            year: 0,
            term: 0,
            status: 1,
          ),
          subject: SubjectModel(
            id: 0,
            curriId: 0,
            groupId: 0,
            subjectCode: 'X',
            nameLao: 'ວ',
            credit: 3,
            labHours: 0,
            lectureHours: 0,
            practicHours: 0,
            levelingroup: 0,
            levelinterm: 0,
            term: 0,
            year: 0,
            status: 1,
          ),
        ),
      ),
    ]);
    expect(c.labelFor(c.semesters.first), '2099-T1');
  });
}

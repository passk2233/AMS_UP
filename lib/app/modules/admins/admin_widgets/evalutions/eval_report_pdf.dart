import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/evaluation_question_model.dart';
import '../../evalutions/controllers/evalutions_controller.dart';
import 'eval_scoring.dart';

/// Builds the printable teacher-evaluation report as a PDF and opens the
/// system print / share sheet (Save as PDF). This is the native equivalent of
/// the webapp's `report.php` — "browser print → Save as PDF" — so the on-paper
/// layout (header, category-grouped question scores, total/average/verdict,
/// legend, comments) matches what admins already get from the web app.
abstract class EvalReportPdf {
  /// Render [subjects] (one study plan each) into a single PDF — one page per
  /// subject — and hand it to the OS print/share dialog. One subject ⇒ the
  /// per-class report; many ⇒ the teacher's bulk report.
  static Future<void> share({
    required String teacherName,
    required List<SubjectEvalSummary> subjects,
    required List<EvaluationQuestionModel> questions,
  }) async {
    // ponytail: Lao glyphs need an embedded font — the pdf package's default
    // Helvetica renders them as empty boxes. PdfGoogleFonts downloads + caches
    // Noto Sans Lao on first use (this app is online-first and already needs
    // the network). Bundle the TTF as an asset only if offline PDF is required.
    final base = await PdfGoogleFonts.notoSansLaoRegular();
    final bold = await PdfGoogleFonts.notoSansLaoBold();
    final theme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: base, bold: bold),
    );

    final doc = pw.Document();
    for (final s in subjects) {
      doc.addPage(
        pw.MultiPage(
          pageTheme: theme,
          build: (_) => _report(teacherName, s, questions),
        ),
      );
    }

    final date = _stamp('-');
    final name = subjects.length == 1
        ? _fileName([
            teacherName,
            subjects.first.subjectName,
            subjects.first.studentGroupName,
            date,
          ])
        : _fileName([teacherName, date]);
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: name);
  }

  // ── one report (one study plan) ──────────────────────────────────────────

  static List<pw.Widget> _report(
    String teacher,
    SubjectEvalSummary s,
    List<EvaluationQuestionModel> questions,
  ) {
    // Group the answered questions by category, in the canonical question-bank
    // order — the same ordering the evaluate form and webapp report use.
    final order = <String>[];
    final byCat = <String, List<_Line>>{};
    for (final q in questions) {
      final qs = s.questionScores[q.evaQuestionId];
      if (qs == null) continue;
      final cat = (q.category?.trim().isNotEmpty ?? false)
          ? q.category!.trim()
          : 'ອື່ນໆ';
      byCat.putIfAbsent(cat, () {
        order.add(cat);
        return <_Line>[];
      });
      final text = qs.questionText.trim().isNotEmpty
          ? qs.questionText.trim()
          : q.question.trim();
      byCat[cat]!.add(_Line(text, qs.average));
    }

    var total = 0.0;
    var count = 0;
    for (final lines in byCat.values) {
      for (final l in lines) {
        total += l.score;
        count++;
      }
    }
    final avg = count > 0 ? total / count : 0.0;

    final comments = <String>{
      for (final d in s.evaluationDetails)
        if (d.comment != null && d.comment!.trim().isNotEmpty)
          d.comment!.trim(),
    }.toList();

    final rows = <pw.TableRow>[_headerRow()];
    for (final cat in order) {
      rows.add(_bandRow(cat));
      for (final l in byCat[cat]!) {
        rows.add(_lineRow(l.text, l.score));
      }
    }
    rows.add(_totalRow('ຄະແນນລວມ', total));
    rows.add(_totalRow('ຄະແນນສະເລ່ຍ', avg));
    rows.add(_verdictRow(EvalScoring.verdictFor(avg)));

    return [
      pw.Text(
        'ບົດລາຍງານການປະເມີນອາຈານ',
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      _headBlock(teacher, s),
      pw.SizedBox(height: 12),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: .5),
        columnWidths: const {
          0: pw.FlexColumnWidth(3),
          1: pw.FixedColumnWidth(120),
        },
        children: rows,
      ),
      pw.SizedBox(height: 14),
      _legend(),
      pw.SizedBox(height: 12),
      _comments(s.studentGroupName, comments),
    ];
  }

  static pw.Widget _headBlock(String teacher, SubjectEvalSummary s) {
    pw.Widget kv(String k, String v) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(
                text: '$k ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: v.isNotEmpty ? v : '-'),
            ]),
          ),
        );
    return pw.Column(
      children: [
        pw.Row(children: [
          pw.Expanded(child: kv('ອາຈານ:', teacher)),
          pw.Expanded(child: kv('ວັນທີ:', _stamp('/'))),
        ]),
        pw.Row(children: [
          pw.Expanded(child: kv('ຫ້ອງ:', s.studentGroupName)),
          pw.Expanded(child: kv('ວິຊາ:', s.subjectName)),
        ]),
      ],
    );
  }

  // ── table rows ─────────────────────────────────────────────────────────

  static pw.TableRow _headerRow() => pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell('ລາຍການມາດຕະຖານຕ່າງໆ', bold: true),
          _cell('ຄະແນນແຕ່ລະດ້ານ ຄະແນນເຕັມ (10)', bold: true, center: true),
        ],
      );

  static pw.TableRow _bandRow(String title) => pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          _cell(title, bold: true),
          _cell(''),
        ],
      );

  static pw.TableRow _lineRow(String text, double score) => pw.TableRow(
        children: [
          _cell(text),
          _cell(
            score.toStringAsFixed(2),
            center: true,
            bold: true,
            color: _scoreColor(score),
          ),
        ],
      );

  static pw.TableRow _totalRow(String label, double value) => pw.TableRow(
        children: [
          _cell(label, bold: true),
          _cell(value.toStringAsFixed(2), center: true, bold: true),
        ],
      );

  static pw.TableRow _verdictRow(String verdict) => pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell(verdict, bold: true),
          _cell(''),
        ],
      );

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    bool center = false,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(
          text,
          textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );

  // ── legend + comments ────────────────────────────────────────────────────

  static pw.Widget _legend() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ໝາຍເຫດ:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          for (final line in EvalScoring.legend)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text('• $line', style: const pw.TextStyle(fontSize: 9)),
            ),
        ],
      );

  static pw.Widget _comments(String className, List<String> comments) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ຄຳຄິດເຫັນຂອງນັກສຶກສາ ${className.isNotEmpty ? className : ''}'.trim(),
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          if (comments.isEmpty)
            pw.Text('ບໍ່ມີຄຳຄິດເຫັນ',
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
          else
            for (final c in comments)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text('• $c', style: const pw.TextStyle(fontSize: 9)),
              ),
        ],
      );

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Score-band color matching the webapp's `score_class()` legend.
  static PdfColor _scoreColor(double s) {
    if (s >= 9) return const PdfColor.fromInt(0xff0c7a3c); // green
    if (s >= 7) return const PdfColor.fromInt(0xff3a57e8); // blue
    if (s >= 5) return const PdfColor.fromInt(0xffb4540e); // orange
    return const PdfColor.fromInt(0xffc03221); // red
  }

  static String _stamp(String sep) {
    final n = DateTime.now();
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(n.day)}$sep${two(n.month)}$sep${n.year}';
  }

  static String _fileName(List<String> parts) {
    final joined = parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .join(' ')
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${joined.isEmpty ? 'report' : joined}.pdf';
  }
}

/// One scored question line in a report category.
class _Line {
  final String text;
  final double score;
  const _Line(this.text, this.score);
}

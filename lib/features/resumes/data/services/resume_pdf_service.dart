import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../shared/models/resume_models.dart';

/// Renders a [Resume] to PDF and hands it to the platform print/share sheet.
///
/// Kept out of the widget layer so it can be unit-tested and reused (e.g. to
/// attach a generated resume to an application) without a BuildContext.
abstract final class ResumePdfService {
  /// Builds the document bytes. Separated from [share] so tests can assert on
  /// the output without opening a print dialog.
  static Future<Uint8List> build(Resume resume) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            resume.fullName.isNotEmpty ? resume.fullName : resume.title,
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          if (resume.targetField.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(resume.targetField, style: const pw.TextStyle(fontSize: 14)),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            [resume.email, resume.phone, resume.location]
                .where((item) => item.isNotEmpty)
                .join('  •  '),
          ),
          if (resume.linkedin.isNotEmpty || resume.portfolio.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              [resume.linkedin, resume.portfolio]
                  .where((item) => item.isNotEmpty)
                  .join('  •  '),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
          if (resume.summary.isNotEmpty)
            _section('PROFESSIONAL SUMMARY', [pw.Text(resume.summary)]),
          _bulletSection('SKILLS', resume.skills),
          _bulletSection('EXPERIENCE', resume.experience),
          _bulletSection('EDUCATION', resume.education),
          _bulletSection('PROJECTS', resume.projects),
          _bulletSection('CERTIFICATIONS', resume.certifications),
        ],
      ),
    );

    return document.save();
  }

  /// Opens the platform print / save-as-PDF sheet.
  static Future<void> share(Resume resume) async {
    final bytes = await build(resume);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '${resume.title.isEmpty ? 'resume' : resume.title}.pdf',
    );
  }

  static pw.Widget _section(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 15),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.Divider(thickness: 0.6),
        pw.SizedBox(height: 4),
        ...children,
      ],
    );
  }

  /// Skips the heading entirely when a section has nothing in it, so an
  /// unfinished resume does not print a page of empty titles.
  static pw.Widget _bulletSection(String title, List<String> items) {
    if (items.isEmpty) return pw.SizedBox();
    return _section(
      title,
      items.map((item) => pw.Bullet(text: item)).toList(),
    );
  }
}

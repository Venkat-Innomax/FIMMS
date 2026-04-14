import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/facility.dart';
import '../models/inspection.dart';
import '../models/user.dart';
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data row model (both mandal + collector tables share this shape)
// ─────────────────────────────────────────────────────────────────────────────

class InspectionReportRow {
  final String facilityName;
  final String facilityType;
  final String subType;
  final String mandal;
  final String officer;
  final DateTime date;
  final double score;
  final String grade;
  final bool urgent;
  final String status;

  const InspectionReportRow({
    required this.facilityName,
    required this.facilityType,
    required this.subType,
    required this.mandal,
    required this.officer,
    required this.date,
    required this.score,
    required this.grade,
    required this.urgent,
    required this.status,
  });

  factory InspectionReportRow.fromInspection(
    Inspection i,
    Map<String, Facility> facilityMap,
    Map<String, User> userMap,
  ) {
    final f = facilityMap[i.facilityId];
    final u = userMap[i.officerId];
    return InspectionReportRow(
      facilityName: f?.name ?? i.facilityId,
      facilityType: f?.type.label ?? '',
      subType: f?.subTypeLabel ?? '',
      mandal: _cap(f?.mandalId ?? ''),
      officer: u?.name ?? i.officerId,
      date: i.datetime,
      score: i.totalScore,
      grade: i.grade.label,
      urgent: i.urgentFlag,
      status: i.status.label,
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ─────────────────────────────────────────────────────────────────────────────
// CSV builder
// ─────────────────────────────────────────────────────────────────────────────

String buildInspectionCsv(List<InspectionReportRow> rows, String title) {
  final df = DateFormat('dd/MM/yyyy HH:mm');
  final buf = StringBuffer()
    ..writeln('# $title')
    ..writeln(
        '# Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}')
    ..writeln()
    ..writeln([
      'Facility',
      'Type',
      'Sub Type',
      'Mandal',
      'Officer',
      'Inspection Date',
      'Score',
      'Grade',
      'Urgent',
      'Status',
    ].map(_field).join(','));

  for (final r in rows) {
    buf.writeln([
      r.facilityName,
      r.facilityType,
      r.subType,
      r.mandal,
      r.officer,
      df.format(r.date),
      r.score.toStringAsFixed(1),
      r.grade,
      r.urgent ? 'Yes' : 'No',
      r.status,
    ].map(_field).join(','));
  }
  return buf.toString();
}

String _field(String v) {
  if (v.contains(',') || v.contains('"') || v.contains('\n')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF builder
// ─────────────────────────────────────────────────────────────────────────────

Future<Uint8List> buildInspectionPdf(
  List<InspectionReportRow> rows,
  String title,
  String subtitle,
) async {
  final doc = pw.Document();
  final df = DateFormat('dd MMM yyyy');

  final avgScore = rows.isEmpty
      ? 0.0
      : rows.map((r) => r.score).reduce((a, b) => a + b) / rows.length;
  final urgent = rows.where((r) => r.urgent).length;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(subtitle,
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey700)),
          pw.Text(
              'Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.blueGrey200),
          pw.SizedBox(height: 4),
        ],
      ),
      build: (_) => [
        // Summary stats row
        pw.Row(children: [
          _statBox('Total', '${rows.length}', PdfColors.blue800),
          pw.SizedBox(width: 8),
          _statBox('Avg Score',
              '${avgScore.toStringAsFixed(1)}/100', PdfColors.green700),
          pw.SizedBox(width: 8),
          _statBox('Urgent Flags', '$urgent', PdfColors.red700),
        ]),
        pw.SizedBox(height: 14),

        // Table
        pw.Table(
          border:
              pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3.0),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.8),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.0),
            5: const pw.FlexColumnWidth(0.9),
            6: const pw.FlexColumnWidth(0.8),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration:
                  const pw.BoxDecoration(color: PdfColors.blue900),
              children: [
                'Facility',
                'Mandal',
                'Officer',
                'Date',
                'Score',
                'Grade',
                'Urgent',
              ]
                  .map((h) => _cell(h,
                      bold: true, textColor: PdfColors.white))
                  .toList(),
            ),
            // Data rows
            ...rows.asMap().entries.map((e) {
              final even = e.key.isEven;
              final r = e.value;
              final bg = even ? PdfColors.white : PdfColors.blueGrey50;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: bg),
                children: [
                  r.facilityName,
                  r.mandal,
                  r.officer,
                  df.format(r.date),
                  r.score.toStringAsFixed(0),
                  r.grade,
                  r.urgent ? '⚠' : '—',
                ].map((v) => _cell(v)).toList(),
              );
            }),
          ],
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _statBox(String label, String value, PdfColor color) =>
    pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius:
              const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 7, color: PdfColors.white)),
          ],
        ),
      ),
    );

pw.Widget _cell(String text,
    {bool bold = false, PdfColor? textColor}) =>
    pw.Padding(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Download triggers (CSV + PDF)
// ─────────────────────────────────────────────────────────────────────────────

/// Downloads / shares a CSV file.
Future<void> downloadCsv(String csvContent, String filename) async {
  final bytes = Uint8List.fromList(csvContent.codeUnits);
  if (kIsWeb) {
    webDownloadBytes(bytes, filename, 'text/csv');
  } else {
    // On mobile use the print/share sheet — attach as raw bytes.
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}

/// Downloads / shares a PDF file.
Future<void> downloadPdf(Uint8List bytes, String filename) async {
  if (kIsWeb) {
    webDownloadBytes(bytes, filename, 'application/pdf');
  } else {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}

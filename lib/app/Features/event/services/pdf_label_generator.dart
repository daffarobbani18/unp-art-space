import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:barcode_widget/barcode_widget.dart' as barcode;
import 'package:qr_flutter/qr_flutter.dart';

/// Model untuk artwork yang akan di-print
class ArtworkModel {
  final String submissionId; // UUID dari event_submissions
  final String id; // ID artwork (kept for compatibility)
  final String title;
  final String artistName;
  final String category;
  final String year;

  ArtworkModel({
    required this.submissionId,
    required this.id,
    required this.title,
    required this.artistName,
    required this.category,
    required this.year,
  });
}

/// Service untuk generate PDF label QR Code
/// Format: A4 dengan 6 label per halaman (2 kolom x 3 baris)
class PdfLabelGenerator {
  // Konstanta ukuran
  static const double qrSize = 5.0 * PdfPageFormat.cm; // 5cm x 5cm (EXACT)
  static const double labelWidth = 9.5 * PdfPageFormat.cm; // ~9.5 cm
  static const double labelHeight = 8.0 * PdfPageFormat.cm; // ~8 cm
  static const double padding = 0.3 * PdfPageFormat.cm;
  static const double margin = 0.5 * PdfPageFormat.cm;
  static const int labelsPerRow = 2;
  static const int rowsPerPage = 3;
  static const int labelsPerPage = labelsPerRow * rowsPerPage; // 6

  /// Generate dan preview PDF label QR Code
  static Future<void> generateAndPreview({
    required List<ArtworkModel> artworks,
    required String eventTitle,
  }) async {
    final pdf = await _generatePdf(
      artworks: artworks,
      eventTitle: eventTitle,
    );

    // Show preview dengan opsi print/share
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'QR_Labels_${eventTitle.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Generate PDF document
  static Future<pw.Document> _generatePdf({
    required List<ArtworkModel> artworks,
    required String eventTitle,
  }) async {
    final pdf = pw.Document(
      title: 'QR Code Labels - $eventTitle',
      author: 'UNP Art Space',
      creator: 'Campus Art Space App',
    );

    // Load font untuk support Unicode
    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontMedium = await PdfGoogleFonts.poppinsMedium();

    // Split artworks into pages (6 per page)
    final pages = <List<ArtworkModel>>[];
    for (var i = 0; i < artworks.length; i += labelsPerPage) {
      final end = (i + labelsPerPage < artworks.length)
          ? i + labelsPerPage
          : artworks.length;
      pages.add(artworks.sublist(i, end));
    }

    // Generate each page
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageArtworks = pages[pageIndex];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header halaman
                _buildPageHeader(
                  eventTitle: eventTitle,
                  pageNumber: pageIndex + 1,
                  totalPages: pages.length,
                  fontBold: fontBold,
                  fontRegular: fontRegular,
                ),
                pw.SizedBox(height: 0.5 * PdfPageFormat.cm),

                // Grid labels
                pw.Expanded(
                  child: _buildLabelsGrid(
                    artworks: pageArtworks,
                    fontBold: fontBold,
                    fontRegular: fontRegular,
                    fontMedium: fontMedium,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  /// Build page header
  static pw.Widget _buildPageHeader({
    required String eventTitle,
    required int pageNumber,
    required int totalPages,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding * 0.5,
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey400,
            width: 1,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'QR CODE LABELS',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: PdfColors.grey800,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                eventTitle,
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Text(
            'Page $pageNumber of $totalPages',
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 7,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build grid of labels
  static pw.Widget _buildLabelsGrid({
    required List<ArtworkModel> artworks,
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required pw.Font fontMedium,
  }) {
    final rows = <pw.Widget>[];

    for (var i = 0; i < artworks.length; i += labelsPerRow) {
      final rowArtworks = <ArtworkModel>[];
      for (var j = 0; j < labelsPerRow && (i + j) < artworks.length; j++) {
        rowArtworks.add(artworks[i + j]);
      }

      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: rowArtworks.map((artwork) {
            return pw.Expanded(
              child: pw.Padding(
                padding: pw.EdgeInsets.all(padding * 0.5),
                child: _buildLabel(
                  artwork: artwork,
                  fontBold: fontBold,
                  fontRegular: fontRegular,
                  fontMedium: fontMedium,
                ),
              ),
            );
          }).toList(),
        ),
      );

      // Add spacing between rows (except last row)
      if (i + labelsPerRow < artworks.length) {
        rows.add(pw.SizedBox(height: padding));
      }
    }

    return pw.Column(
      children: rows,
    );
  }

  /// Build single label
  static pw.Widget _buildLabel({
    required ArtworkModel artwork,
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required pw.Font fontMedium,
  }) {
    final qrUrl = 'https://campus-art-space.vercel.app/submission/${artwork.submissionId}';

    return pw.Container(
      width: labelWidth,
      height: labelHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
          width: 1,
          style: pw.BorderStyle.dashed,
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: pw.EdgeInsets.all(padding),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left side: Text information
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Title (bold, larger)
                pw.Text(
                  artwork.title,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11,
                    color: PdfColors.grey900,
                    height: 1.2,
                  ),
                  maxLines: 3,
                  overflow: pw.TextOverflow.clip,
                ),
                pw.SizedBox(height: padding * 0.5),

                // Artist name
                pw.Row(
                  children: [
                    pw.Container(
                      width: 3,
                      height: 3,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.deepPurple,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                      child: pw.Text(
                        artwork.artistName,
                        style: pw.TextStyle(
                          font: fontMedium,
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),

                // Category
                pw.Row(
                  children: [
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        artwork.category,
                        style: pw.TextStyle(
                          font: fontMedium,
                          fontSize: 7,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      artwork.year,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Tech indicator
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [
                        PdfColors.deepPurple,
                        PdfColors.blue,
                      ],
                    ),
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                  child: pw.Text(
                    'DIGITAL ART',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 5,
                      color: PdfColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(width: padding * 0.8),

          // Right side: QR Code (EXACT 5cm x 5cm)
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // QR Code container with tech border
              pw.Container(
                width: qrSize,
                height: qrSize,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.deepPurple,
                    width: 2,
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                  boxShadow: [
                    pw.BoxShadow(
                      color: PdfColors.grey300,
                      offset: const PdfPoint(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: pw.EdgeInsets.all(6),
                child: pw.BarcodeWidget(
                  data: qrUrl,
                  barcode: pw.Barcode.qrCode(),
                  width: qrSize - 12, // Minus padding
                  height: qrSize - 12,
                  drawText: false,
                ),
              ),
              pw.SizedBox(height: 4),

              // "SCAN ME" caption
              pw.Container(
                padding: pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey900,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 6,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.deepPurple300,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      'SCAN ME',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 7,
                        color: PdfColors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Generate PDF as bytes (untuk save/share manual)
  static Future<Uint8List> generatePdfBytes({
    required List<ArtworkModel> artworks,
    required String eventTitle,
  }) async {
    final pdf = await _generatePdf(
      artworks: artworks,
      eventTitle: eventTitle,
    );
    return pdf.save();
  }

  /// Print directly (tanpa preview)
  static Future<bool> printDirectly({
    required List<ArtworkModel> artworks,
    required String eventTitle,
  }) async {
    final pdfBytes = await generatePdfBytes(
      artworks: artworks,
      eventTitle: eventTitle,
    );

    return await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'QR_Labels_${eventTitle.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Share PDF (WhatsApp, Email, etc)
  static Future<void> sharePdf({
    required List<ArtworkModel> artworks,
    required String eventTitle,
  }) async {
    final pdfBytes = await generatePdfBytes(
      artworks: artworks,
      eventTitle: eventTitle,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'QR_Labels_${eventTitle.replaceAll(' ', '_')}.pdf',
    );
  }
}

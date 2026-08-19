import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:villaguest/features/bookings/data/models/booking_model.dart';

class InvoiceService {
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _timestampFmt = DateFormat('dd/MM/yyyy HH:mm');

  // ─── Puntos de entrada para la previsualización (PdfPreview.build) ────────
  // Reciben PdfPageFormat porque PdfPreview lo pasa dinámicamente.

  static Future<Uint8List> buildConfirmationBytes(
    PdfPageFormat format,
    BookingModel booking,
  ) async {
    final theme = await _theme();
    final doc = pw.Document(theme: theme);
    doc.addPage(_confirmationPage(booking, format));
    return doc.save();
  }

  static Future<Uint8List> buildFinalInvoiceBytes(
    PdfPageFormat format,
    BookingModel booking,
  ) async {
    final theme = await _theme();
    final doc = pw.Document(theme: theme);
    doc.addPage(_finalInvoicePage(booking, format));
    return doc.save();
  }

  // ─── Descarga directa (sin previsualización) ──────────────────────────────

  static Future<void> downloadConfirmation(BookingModel booking) async {
    final bytes = await buildConfirmationBytes(PdfPageFormat.a4, booking);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'confirmacion_${_shortId(booking.id)}.pdf',
    );
  }

  static Future<void> downloadFinalInvoice(BookingModel booking) async {
    final bytes = await buildFinalInvoiceBytes(PdfPageFormat.a4, booking);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'factura_${_shortId(booking.id)}.pdf',
    );
  }

  // ─── Tema: fuentes con soporte Unicode completo ───────────────────────────
  // PdfGoogleFonts descarga Noto Sans en tiempo de ejecución.
  // Si no hay conexión, cae al tema por defecto (Latin-1 únicamente).

  static Future<pw.ThemeData?> _theme() async {
    try {
      final base = await PdfGoogleFonts.notoSansRegular();
      final bold = await PdfGoogleFonts.notoSansBold();
      return pw.ThemeData.withFont(base: base, bold: bold);
    } catch (_) {
      return null;
    }
  }

  // ─── Páginas ──────────────────────────────────────────────────────────────

  static pw.Page _confirmationPage(BookingModel booking, PdfPageFormat format) {
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    final balance = booking.totalPrice - booking.depositPaid;

    return pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(48),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('CONFIRMACION DE RESERVA'),
          pw.SizedBox(height: 28),
          _metaRow('No. de Reserva', _shortId(booking.id).toUpperCase()),
          _metaRow('Fecha de Reserva', _dateFmt.format(booking.createdAt)),
          pw.SizedBox(height: 20),
          _section('Datos del Huesped'),
          _row('Nombre', booking.guestName),
          _row('Email', booking.guestEmail),
          _row('Telefono', booking.guestPhone),
          pw.SizedBox(height: 20),
          _section('Detalles de la Estancia'),
          _row('Check-in', _dateFmt.format(booking.checkIn)),
          _row('Check-out', _dateFmt.format(booking.checkOut)),
          _row('Noches', '$nights'),
          pw.SizedBox(height: 20),
          _section('Desglose de Pago'),
          _paymentRow('Precio Total', booking.totalPrice),
          _paymentRow('Senal Abonada', booking.depositPaid),
          pw.Divider(color: PdfColors.grey300),
          _paymentRow('Saldo Pendiente', balance, bold: true),
          pw.SizedBox(height: 20),
          _statusBadge(booking.status),
          pw.Spacer(),
          _footer(
            'Esta es una confirmacion oficial de su reserva.\n'
            'El saldo restante debera ser abonado al momento del check-in.',
          ),
        ],
      ),
    );
  }

  static pw.Page _finalInvoicePage(BookingModel booking, PdfPageFormat format) {
    final nights = booking.checkOut.difference(booking.checkIn).inDays;

    return pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(48),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('FACTURA FINAL'),
          pw.SizedBox(height: 28),
          _metaRow('No. de Factura', _shortId(booking.id).toUpperCase()),
          _metaRow('Fecha de Emision', _dateFmt.format(DateTime.now())),
          _metaRow(
            'Periodo',
            '${_dateFmt.format(booking.checkIn)} - ${_dateFmt.format(booking.checkOut)}',
          ),
          pw.SizedBox(height: 20),
          _section('Datos del Huesped'),
          _row('Nombre', booking.guestName),
          _row('Email', booking.guestEmail),
          _row('Telefono', booking.guestPhone),
          pw.SizedBox(height: 20),
          _section('Detalles de la Estancia'),
          _row('Check-in', _dateFmt.format(booking.checkIn)),
          _row('Check-out', _dateFmt.format(booking.checkOut)),
          _row('Noches', '$nights'),
          pw.SizedBox(height: 20),
          _section('Resumen de Pago'),
          _paymentRow('Precio por estancia', booking.totalPrice),
          _paymentRow('Senal abonada', booking.depositPaid),
          _paymentRow(
            'Saldo restante abonado',
            booking.totalPrice - booking.depositPaid,
          ),
          pw.Divider(color: PdfColors.grey300),
          _paymentRow('TOTAL COBRADO', booking.totalPrice, bold: true, large: true),
          pw.SizedBox(height: 20),
          _paidStamp(),
          pw.Spacer(),
          _footer(
            'Gracias por hospedarse con nosotros. Esperamos verle de nuevo pronto.',
          ),
        ],
      ),
    );
  }

  // ─── Componentes de diseño ────────────────────────────────────────────────

  static pw.Widget _header(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'VillaGuestRD',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo800,
                  ),
                ),
                pw.Text(
                  'Gestion de Hospedaje',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 2, color: PdfColors.indigo800),
      ],
    );
  }

  static pw.Widget _section(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.indigo800,
        ),
      ),
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: const pw.TextStyle(color: PdfColors.grey600),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _paymentRow(
    String label,
    double amount, {
    bool bold = false,
    bool large = false,
  }) {
    final fontSize = large ? 14.0 : 12.0;
    final style = bold
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize)
        : pw.TextStyle(fontSize: fontSize);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('RD\$ ${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  static pw.Widget _statusBadge(String status) {
    final labels = {
      'pending': 'Pendiente',
      'confirmed': 'Confirmada',
      'completed': 'Completada',
      'cancelled': 'Cancelada',
    };
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: PdfColors.indigo300),
      ),
      child: pw.Text(
        'Estado: ${labels[status] ?? status}',
        style: pw.TextStyle(
          color: PdfColors.indigo800,
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  static pw.Widget _paidStamp() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 14),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green700, width: 1.5),
      ),
      child: pw.Center(
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // Cuadrado relleno como indicador visual de "completado"
            pw.Container(
              width: 14,
              height: 14,
              margin: const pw.EdgeInsets.only(right: 8),
              decoration: const pw.BoxDecoration(
                color: PdfColors.green700,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Text(
              'PAGO COMPLETADO',
              style: pw.TextStyle(
                color: PdfColors.green800,
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _footer(String message) {
    final now = _timestampFmt.format(DateTime.now());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 6),
        pw.Text(
          message,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'VillaGuestRD - Generado el $now',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 9),
        ),
      ],
    );
  }

  // ─── Utilidades ───────────────────────────────────────────────────────────

  static String _shortId(String id) =>
      id.length > 12 ? id.substring(0, 12) : id;
}

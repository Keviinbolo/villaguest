import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:villaguest/core/theme/gradient_app_bar.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Muestra una previsualización interactiva del PDF (zoom, scroll de páginas)
/// y ofrece un botón para compartir/descargar el archivo.
///
/// [buildBytes] recibe el PdfPageFormat que PdfPreview calcula según el
/// dispositivo y devuelve los bytes del documento. Se llama cada vez que
/// el formato cambia (aunque aquí lo fijamos en A4).
class InvoicePreviewScreen extends StatelessWidget {
  const InvoicePreviewScreen({
    super.key,
    required this.title,
    required this.buildBytes,
    required this.filename,
  });

  final String title;
  final Future<Uint8List> Function(PdfPageFormat format) buildBytes;
  final String filename;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: title),
      body: PdfPreview(
        build: buildBytes,
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        canDebug: false,
        allowSharing: true,
        allowPrinting: false,
        pdfFileName: filename,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (ctx, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo generar la factura.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/gestion_reportes/reportes.dart';

class ReportePdfService {
  final PdfColor primaryColor = PdfColor.fromInt(0xFF0D47A1);
  final PdfColor accentColor = PdfColor.fromInt(0xFFE65100);

  /// Genera el documento PDF con los cambios solicitados en las tablas
  Future<void> exportarPdf(ReporteObraModel data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (context) => [
          _buildHeader(data),
          _buildInfoObra(data),
          pw.SizedBox(height: 20),
          _buildResumenCuadros(data),
          pw.SizedBox(height: 25),
          _buildSeccionActividades(data),
          pw.SizedBox(height: 25),
          _buildSeccionAvances(data),
          pw.SizedBox(height: 25),
          _buildSeccionSeguridad(data),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _buildHeader(ReporteObraModel data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text("REGCONS - SISTEMA DE CONTROL",
            style: pw.TextStyle(color: accentColor, fontSize: 12)),
        pw.Text(
            "Generado: ${data.fechaGeneracion.day}/${data.fechaGeneracion.month}/${data.fechaGeneracion.year}",
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildInfoObra(ReporteObraModel data) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(data.obra.nombre, style: const pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 4),
          pw.Text("Cliente: ${data.obra.cliente ?? 'No especificado'}"),
          pw.Text("Estado General: ${data.obra.estado}"),
          pw.Text("Presupuesto: \$${data.obra.presupuesto?.toStringAsFixed(2) ?? '0.00'}"),
        ],
      ),
    );
  }

  pw.Widget _buildResumenCuadros(ReporteObraModel data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _datoCuadro("AVANCE FÍSICO", "${data.porcentajeAvance.toStringAsFixed(1)}%", accentColor),
        _datoCuadro("HORAS TOTALES", "${data.totalHorasTrabajadas}h", PdfColors.blue600),
        _datoCuadro("INCIDENTES", "${data.totalIncidentes}", PdfColors.red600),
      ],
    );
  }

  /// Tabla de actividades simplificada (sin columna de progreso)
  pw.Widget _buildSeccionActividades(ReporteObraModel data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("ESTADO DE ACTIVIDADES", style: pw.TextStyle(color: primaryColor)),
        pw.Divider(color: primaryColor),
        pw.Table.fromTextArray(
          headers: ['Actividad', 'Estado'],
          headerDecoration: const pw.BoxDecoration(color: PdfColors.orange100),
          headerStyle: const pw.TextStyle(fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          data: data.actividades.map((a) => [
            a.nombre,
            a.estado,
          ]).toList(),
        ),
      ],
    );
  }

  /// Tabla de avances con la columna de Actividad Asociada integrada
  pw.Widget _buildSeccionAvances(ReporteObraModel data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("ÚLTIMOS AVANCES DE CAMPO", style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 5),
        pw.Table.fromTextArray(
          headers: ['Fecha', 'Actividad', 'Horas', 'Descripción'],
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          headerStyle: const pw.TextStyle(fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          data: data.ultimosAvances.map((av) => [
            av.fechaFormateada,
            av.descripcion ?? 'N/A',
            "${av.horasTrabajadas}h",
            av.descripcion ?? 'Sin descripción',
          ]).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildSeccionSeguridad(ReporteObraModel data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("REGISTRO DE SEGURIDAD Y SALUD",
            style: pw.TextStyle(color: PdfColors.red800)),
        pw.Divider(color: PdfColors.red800),
        pw.SizedBox(height: 5),
        data.incidentes.isEmpty
            ? pw.Text("No se reportan incidentes críticos.",
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10))
            : pw.Table.fromTextArray(
          headers: ['Tipo', 'Severidad', 'Descripción'],
          headerStyle: const pw.TextStyle(color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.red900),
          cellStyle: const pw.TextStyle(fontSize: 9),
          data: data.incidentes.map((i) => [
            i.tipo,
            i.severidad,
            i.descripcion,
          ]).toList(),
        ),
      ],
    );
  }

  pw.Widget _datoCuadro(String label, String value, PdfColor color) {
    return pw.Container(
      width: 130,
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }
}
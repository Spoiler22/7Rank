import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:remessa/models/widgets/consts.dart';

class Distrito implements Comparable<Distrito> {
  Distrito({
    this.id,
    this.pastor,
    this.faltam,
    this.data,
  });

  final String? id;
  final int? faltam;
  final String? pastor;
  String? data;

  String? getIndex(int index) {
    switch (index) {
      case 0:
        return id;
      case 1:
        return faltam.toString();
      case 2:
        return data;
      case 3:
        return pastor;
    }
    return '';
  }

  @override
  int compareTo(Distrito other) {
    DateTime? adate = currentDate(date: other.data);
    DateTime? bdate = currentDate(date: other.data);
    return this.faltam == 0
        ? adate!.compareTo(bdate!)
        : this.faltam!.compareTo(other.faltam!);
  }
}

class IgrejaModel {
  const IgrejaModel(
    this.nome,
    this.distrito,
  );

  final String? nome;
  final String? distrito;

  String? getIndex(int index) {
    switch (index) {
      case 0:
        return nome;
      case 1:
        return distrito;
    }
    return '';
  }
}

Future<Uint8List> buildPdf2(List<IgrejaModel> igrejas, String data) async {
  final pw.Document doc = pw.Document();
  final baseColor = PdfColors.blue;
  const _darkColor = PdfColors.blueGrey800;

  PdfColor _baseTextColor = PdfColors.white;
  final List<String> headers = ['Igreja', 'Distrito'];

  PdfPageFormat? format;
  doc.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Container(
          child: pw.Column(
            children: [
              pw.Container(
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Rank Atualizado $data',
                      style: pw.TextStyle(color: PdfColors.black, fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Table.fromTextArray(
                  border: null,
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration: pw.BoxDecoration(
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(2)),
                    color: baseColor,
                  ),
                  headerHeight: 20,
                  cellHeight: 11,
                  cellPadding: pw.EdgeInsets.all(2),
                  oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey400),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                  },
                  headerStyle: pw.TextStyle(
                    color: _baseTextColor,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(
                    color: _darkColor,
                    fontSize: 14,
                  ),
                  rowDecoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.blueGrey900,
                        width: .5,
                      ),
                    ),
                  ),
                  headers: headers,
                  data: List<List<String?>>.generate(
                    igrejas.length,
                    (row) => List<String?>.generate(
                      headers.length,
                      (col) => igrejas[row].getIndex(col),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      pageFormat: format,
    ),
  );
  return await doc.save();
}

Future<Uint8List> buildPdf(
    List<Distrito> distritos, int total, String date, bool simples) async {
  final pw.Document doc = pw.Document();
  final baseColor = PdfColors.blue;
  const _darkColor = PdfColors.blueGrey800;

  PdfColor _baseTextColor = PdfColors.white;
  final List<String> headers = simples
      ? ['Distrito', 'Faltam', 'Data']
      : ['Distrito', 'Faltam', 'Data', 'Pastor'];
  for (var distrito in distritos) {
    if (distrito.faltam != 0) {
      distrito.data = "Falta";
    }
  }

  PdfPageFormat? format;
  doc.addPage(
    pw.Page(
      pageFormat: format,
      build: (pw.Context context) {
        return pw.Container(
          child: pw.Column(
            children: [
              pw.Container(
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Rank Atualizado $date',
                      style: pw.TextStyle(color: PdfColors.black, fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Table.fromTextArray(
                  border: null,
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration: pw.BoxDecoration(
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(2)),
                    color: baseColor,
                  ),
                  headerHeight: 20,
                  cellHeight: 11,
                  cellPadding: pw.EdgeInsets.all(2),
                  oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey400),
                  cellAlignments: simples
                      ? {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.center,
                          2: pw.Alignment.centerRight,
                        }
                      : {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.center,
                          2: pw.Alignment.centerRight,
                          3: pw.Alignment.centerRight,
                        },
                  headerStyle: pw.TextStyle(
                    color: _baseTextColor,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(
                    color: _darkColor,
                    fontSize: 10,
                  ),
                  rowDecoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.blueGrey900,
                        width: .5,
                      ),
                    ),
                  ),
                  headers: headers,
                  data: List<List<String?>>.generate(
                    distritos.length,
                    (row) => List<String?>.generate(
                      headers.length,
                      (col) => distritos[row].getIndex(col),
                    ),
                  ),
                ),
              ),
              pw.Container(
                height: 20,
                child: pw.Center(
                  child: pw.Text(
                    "Total:   $total",
                    style: pw.TextStyle(fontSize: 20, color: PdfColors.white),
                  ),
                ),
                color: PdfColors.blue,
              )
            ],
          ),
        );
      },
    ),
  );
  return await doc.save();
}

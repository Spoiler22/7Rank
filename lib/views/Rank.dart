import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:remessa/models/widgets/consts.dart';
import 'package:remessa/models/RankPdf.dart';
import 'package:share/share.dart';

class Rank extends StatefulWidget {
  const Rank(this.date);
  final String date;

  @override
  _RankState createState() => _RankState();
}

class _RankState extends State<Rank> {
  final _controller = StreamController.broadcast();
  PdfPageFormat format;
  bool _buildFeita = false;
  List<Distrito> distritos = [];
  bool _print = false;
  int _total = 0;

  pdf() {
    return buildPdf(format, distritos, _total, widget.date);
  }

  Stream<QuerySnapshot> _rank() {
    Stream<QuerySnapshot> distritos = db
        .collection("distritos")
        .orderBy("faltam")
        .orderBy("data")
        .snapshots();

    distritos.listen((event) {
      _controller.add(event);
    });
    return null;
  }

  @override
  void initState() {
    super.initState();
    _rank();
  }

  Future _shareFile() async {
    final dir = (await getApplicationDocumentsDirectory()).path;
    final file = File('$dir/Rank Atualizado.pdf');
    await file.writeAsBytesSync(await pdf());
    Share.shareFile(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.fitWidth,
          child: Text(
            "Data: ${widget.date}",
          ),
        ),
        actions: [
          Row(
            children: [
              IconButton(
                  icon: Icon(!kIsWeb ? Icons.share : Icons.save),
                  onPressed: () {
                    kIsWeb
                        ? Printing.sharePdf(
                            bytes: pdf(),
                            filename: 'Rank Atualizado.pdf',
                          )
                        : _shareFile();
                  }),
              IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () {
                    setState(() {
                      _print = !_print;
                    });
                  }),
              IconButton(
                  icon: Icon(Icons.print),
                  onPressed: () {
                    Printing.layoutPdf(
                      name: 'Rank Atualizado ${widget.date} ',
                      onLayout: (PdfPageFormat format) {
                        return pdf();
                      },
                    );
                  }),
            ],
          )
        ],
      ),
      body: Container(
        child: StreamBuilder(
          stream: _controller.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              QuerySnapshot querySnapshot = snapshot.data;
              if (_buildFeita == false) {
                for (var i = 0; i < querySnapshot.docs.length; i++) {
                  _total += querySnapshot.docs[i]["faltam"];
                  distritos.add(
                    Distrito(
                      querySnapshot.docs[i].id,
                      querySnapshot.docs[i]["faltam"].toString(),
                      querySnapshot.docs[i]["faltam"] == 0
                          ? querySnapshot.docs[i]["data"]
                          : 'Falta',
                    ),
                  );
                  if (i == querySnapshot.docs.length - 1) {
                    _buildFeita = true;
                  }
                }
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: querySnapshot.docs.length,
                      itemBuilder: (context, index) {
                        List<DocumentSnapshot> distritos =
                            querySnapshot.docs.toList();
                        DocumentSnapshot documentSnapshot = distritos[index];
                        String data = documentSnapshot['data'];
                        return Container(
                          padding:
                              _print ? EdgeInsets.all(0) : EdgeInsets.all(10),
                          color: index.isOdd
                              ? Colors.grey[400]
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  documentSnapshot.id,
                                  style: TextStyle(fontSize: _print ? 10 : 16),
                                ),
                              ),
                              Align(
                                alignment: FractionalOffset.centerRight,
                                child: Text(
                                  documentSnapshot["faltam"].toString(),
                                  style: TextStyle(fontSize: _print ? 10 : 16),
                                ),
                              ),
                              documentSnapshot["faltam"].toString() == "0"
                                  ? Align(
                                      alignment: FractionalOffset.centerRight,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 20),
                                        child: Text(
                                          data,
                                          style: TextStyle(
                                              fontSize: _print ? 11 : 16),
                                        ),
                                      ))
                                  : Container()
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 30,
                    child: Center(
                      child: Text(
                        "Total:   $_total",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                    color: Colors.blue,
                  )
                ],
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}

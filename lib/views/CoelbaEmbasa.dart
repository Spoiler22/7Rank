import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:remessa/models/theme/TextStyles.dart';
import 'package:remessa/models/widgets/Button.dart';
import 'package:remessa/models/widgets/consts.dart';
import 'package:url_launcher/url_launcher.dart';

class CoelbaEmbasa extends StatefulWidget {
  final String gerenciador;
  const CoelbaEmbasa(this.gerenciador);
  @override
  _CoelbaEmbasaState createState() => _CoelbaEmbasaState();
}

class _CoelbaEmbasaState extends State<CoelbaEmbasa> {
  TextEditingController _controllerPesquisa = TextEditingController();
  StreamController<QuerySnapshot> _controllerIgreja =
      StreamController.broadcast();
  StreamController<QuerySnapshot> _controllerRank =
      StreamController.broadcast();
  TextEditingController _controller = TextEditingController();
  FirebaseStorage storage = FirebaseStorage.instance;
  List<String> igrejas = [];
  bool mostrar2 = false;
  bool mostrar = false;
  bool _coelba = true;
  String nome = '';
  late String valor;

  void getIgrejas() {
    db.collection("igrejas").orderBy("cod").get().then((value) {
      Iterable<String> values = value.docs
          .map((e) => "${e["cod"].toString()} - ${e["nome"].toString()}");
      igrejas.addAll(values);
    });
  }

  Stream<QuerySnapshot>? _pegarDados() {
    int i = int.parse(_controller.text);
    Stream<QuerySnapshot> rank = db
        .collection("igrejas")
        .where(_coelba ? "contrato" : "matricula",
            isEqualTo: _controller.text.contains(RegExp(r'A-Z'))
                ? _controller.text
                : i)
        .snapshots();

    rank.listen((event) {
      _controllerRank.add(event);
    });

    return null;
  }

  void _getIgreja(String cod) {
    db
        .collection("igrejas")
        .where("cod", isEqualTo: int.parse(cod))
        .get()
        .then((value) {
      QueryDocumentSnapshot values = value.docs.first;
      setState(() {
        valor = values["cod"].toString();
        nome = values["nome"].toString().replaceAll('- ', "");
      });
    });
  }

  // Future<String> _pegarImagem() async {
  //   print(
  //       "${nome.toLowerCase().replaceAll(" ", '-')}_${_coelba ? "contrato" : "matricula"}.png");
  //   return storage
  //       .ref(
  //           "${nome.toLowerCase().replaceAll(" ", '-')}_${_coelba ? "contrato" : "matricula"}.png")
  //       .getDownloadURL()
  //       .then((value) {
  //     print(value);
  //     return value;
  //     // ignore: argument_type_not_assignable_to_error_handler
  //   }).catchError(() {
  //     print('olá');
  //     return 'https://firebasestorage.googleapis.com/v0/b/igreja-4019a.appspot.com/o/imagem-error.png?alt=media&token=98e9452b-dc41-4ef8-83db-4c6d2738aad7';
  //   });
  // }

  Stream<QuerySnapshot>? _pegarIgreja() {
    Stream<QuerySnapshot> igreja = db
        .collection("igrejas")
        .where('cod', isEqualTo: int.parse(valor))
        .snapshots();

    igreja.listen((event) {
      _controllerIgreja.add(event);
    });

    return null;
  }

  @override
  void initState() {
    getIgrejas();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_coelba ? "Coelba" : "Embasa"),
        centerTitle: true,
        actions: actions(widget.gerenciador, context, 'coelba'),
      ),
      drawer: kIsWeb ? null : drawer(widget.gerenciador, context, 'coelba'),
      body: SingleChildScrollView(
          child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Button(
                  onPressed: () {
                    setState(() {
                      _coelba = true;
                      mostrar = false;
                      mostrar2 = false;
                      _controller.text = "";
                      _controllerPesquisa.text = "";
                    });
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.wb_incandescent,
                        color: _coelba ? Colors.blue : Colors.black,
                      ),
                      Text("Coelba"),
                    ],
                  ),
                ),
                Button(
                  onPressed: () {
                    setState(() {
                      _coelba = false;
                      mostrar = false;
                      mostrar2 = false;
                      _controller.text = "";
                      _controllerPesquisa.text = "";
                    });
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        color: !_coelba ? Colors.blue : Colors.black,
                      ),
                      Text("Embasa"),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Button(
                  onPressed: () {
                    _pegarDados();
                    setState(() {
                      mostrar = true;
                      mostrar2 = false;
                    });
                  },
                  label: "Pesquisar",
                  style: TextStyles.bigWhite,
                  color: Colors.blue,
                ),
                SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _controller.text = value;
                      });
                    },
                    textAlign: TextAlign.end,
                    decoration: inputDecoration.copyWith(
                        labelText: _coelba ? "Contrato" : "Matricula"),
                  ),
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Button(
                  onPressed: () {
                    _pegarIgreja();
                    setState(() {
                      mostrar2 = true;
                      mostrar = false;
                    });
                  },
                  label: "Pesquisar",
                  style: TextStyles.bigWhite,
                  color: Colors.blue,
                ),
                SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: TypeAheadField<String>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _controllerPesquisa,
                      textAlign: TextAlign.end,
                      decoration: inputDecoration.copyWith(labelText: "Igreja"),
                    ),
                    debounceDuration: Duration(milliseconds: 600),
                    suggestionsCallback: (pattern) {
                      return igrejas.where((element) => element
                          .toLowerCase()
                          .contains(pattern.toLowerCase()));
                    },
                    onSuggestionSelected: (suggestion) {
                      _controllerPesquisa.text = suggestion;
                      _getIgreja(suggestion.split(" ")[0]);
                    },
                    noItemsFoundBuilder: (context) => ListTile(
                      title: Text('Nenhuma igreja encontrada'),
                    ),
                    itemBuilder: (context, itemData) => ListTile(
                      title: Text("$itemData"),
                    ),
                  ),
                )
              ],
            ),
            SizedBox(
              height: 20,
            ),
            mostrar
                ? StreamBuilder<QuerySnapshot>(
                    stream: _controllerRank.stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container();
                      } else if (snapshot.hasData) {
                        QuerySnapshot querySnapshot = snapshot.data!;
                        setState(() {
                          nome = querySnapshot.docs
                              .toList()[0]["nome"]
                              .toString()
                              .replaceAll('- ', "");
                        });
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: querySnapshot.docs.length,
                            itemBuilder: (context, index) {
                              List<DocumentSnapshot> igrejas =
                                  querySnapshot.docs.toList();
                              DocumentSnapshot documentSnapshot =
                                  igrejas[index];
                              return ListView(
                                shrinkWrap: true,
                                children: [
                                  ListTile(
                                    title: Text(
                                        "Distrito: ${documentSnapshot["distrito"]}"),
                                  ),
                                  ListTile(
                                    title: Text(
                                        "Igreja: ${documentSnapshot["nome"]}"),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      } else {
                        var snackbar =
                            SnackBar(content: Text("Igreja não encontrada"));
                        ScaffoldMessenger.of(context).showSnackBar(snackbar);
                      }
                      return Container();
                    },
                  )
                : Container(),
            mostrar
                ? SizedBox(
                    height: 20,
                  )
                : Container(),
            mostrar2
                ? StreamBuilder<QuerySnapshot>(
                    stream: _controllerIgreja.stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container();
                      } else if (snapshot.hasData) {
                        QuerySnapshot querySnapshot = snapshot.data!;
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: querySnapshot.docs.length,
                            itemBuilder: (context, index) {
                              List<DocumentSnapshot> igrejas =
                                  querySnapshot.docs.toList();
                              DocumentSnapshot documentSnapshot =
                                  igrejas[index];
                              return ListView(
                                shrinkWrap: true,
                                children: [
                                  ListTile(
                                    title: Text(
                                        "Distrito: ${documentSnapshot["distrito"]}"),
                                  ),
                                  _coelba
                                      ? ListTile(
                                          title: Text(
                                              "Contrato: ${documentSnapshot["contrato"].toString()}"),
                                        )
                                      : ListTile(
                                          title: Text(
                                              "Matricula: ${documentSnapshot["matricula"].toString()}"),
                                        ),
                                ],
                              );
                            },
                          ),
                        );
                      } else {
                        var snackbar =
                            SnackBar(content: Text("Igreja não encontrada"));

                        ScaffoldMessenger.of(context).showSnackBar(snackbar);
                      }
                      return Container();
                    },
                  )
                : Container(),
            mostrar2
                ? SizedBox(
                    height: 20,
                  )
                : Container(),
            Button(
              onPressed: () async {
                await launch(_coelba
                    ? "http://servicos.coelba.com.br/servicos-ao-cliente/Pages/login-av.aspx"
                    : "http://www.embasa2.ba.gov.br/novo/central-servicos/?mod=sua-conta&a=2via");
              },
              color: Colors.blue,
              label: "Ir para o Site",
            ),
            // mostrar || mostrar2
            //     ? Flexible(
            //         child: ConstrainedBox(
            //         constraints: BoxConstraints(
            //             maxHeight:
            //                 ((MediaQuery.of(context).size.height / 5) * 3) -
            //                     100),
            //         child: FutureBuilder<String>(
            //           future: _pegarImagem(),
            //           builder: (context, snapshot) {
            //             if (snapshot.hasData) {
            //               return Image.network(
            //                 snapshot.data!,
            //                 fit: BoxFit.contain,
            //               );
            //             } else {
            //               return Container();
            //             }
            //           },
            //         ),
            //       ))
            //     : Container()
          ],
        ),
      )),
    );
  }
}

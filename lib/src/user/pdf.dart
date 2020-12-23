import 'package:flutter/material.dart';
import 'package:flutter_plugin_pdf_viewer/flutter_plugin_pdf_viewer.dart';

class Pdf extends StatefulWidget {
  final user;
  final week;
  final list;

  Pdf(this.user, this.list, this.week);

  @override
  _PdfState createState() => _PdfState(user, list, week);
}

class _PdfState extends State<Pdf> {
  bool _isLoading = true;
  PDFDocument document;
  final user;
  final week;
  final list;

  _PdfState(this.user, this.list, this.week);

  @override
  void initState() {
    super.initState();
    loadDocument();
  }

  loadDocument() async {
    var url = list['url'];
    print(url);
    try {
      document = await PDFDocument.fromURL(url);

      setState(() => _isLoading = false);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("Week $week : " + user),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          backgroundColor: const Color(0xFFB3590A),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 20,
                  ),
                  Text('Inafungua file tafadhari subiri'),
                ],
              ))
            : PDFViewer(document: document),
      ),
    );
  }
}

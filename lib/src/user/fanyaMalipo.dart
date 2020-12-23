import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class FanyaMalipo extends StatefulWidget {
  final user;
  FanyaMalipo(this.user);

  @override
  _FanyaMalipoState createState() => new _FanyaMalipoState(user);
}

class _FanyaMalipoState extends State<FanyaMalipo> {
  final TextEditingController _fullnameController = new TextEditingController();
  final TextEditingController _amountController = new TextEditingController();
  final user;
  _FanyaMalipoState(this.user);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB3590A),
        title: Text('Fanya Malipo'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(3),
          children: <Widget>[
            Container(
              child: new Column(
                children: <Widget>[
                  new Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.more_vert),
                          title: Text('M-Pesa'),
                          subtitle: Text(
                              'Tuma pesa kwenda 0754236418 JINA: ELISHA THOMSON '),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.more_vert),
                          title: Text('Tigo-Pesa'),
                          subtitle: Text(
                              'Tuma pesa kwenda 0717163462 JINA: ELISHA MWANKENJA '),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.more_vert),
                          title: Text('Mitandao mingine'),
                          subtitle: Text(
                              'Tuma pesa kwenda mitandao mingine, chagua tigopesa kisha weka namba hii 0717163462'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  _submitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return Container(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Baada ya kupokea meseji ya malipo ijaze kwenye fomu hapo chini au jaza jina la wakala kama umetumia wakala kisha bonyeza "Tuma malipo" ili kukamilisha ulipaji.',
            ),
          ),
          Card(
            color: Colors.white,
            child: TextField(
              controller: _fullnameController,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.greenAccent, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: const Color(0xFFB3590A), width: 2.0),
                  ),
                  hintText: "Jaza SMS ya muamala au jina la wakala"),
            ),
          ),
          Card(
            color: Colors.white,
            child: TextField(
              controller: _amountController,
              decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.greenAccent, width: 2.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: const Color(0xFFB3590A), width: 2.0),
                  ),
                  border: InputBorder.none,
                  hintText: "Kiasi ulicholipia"),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            width: 200,
            child: FlatButton(
              child: Text(
                'Tuma malipo',
                style: TextStyle(fontSize: 20),
              ),
              shape: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.all(15),
              textColor: Colors.white,
              color: const Color(0xFFB3590A),
              onPressed: () async {
                if (_fullnameController.text.isNotEmpty) {
                  showDialog(
                    barrierDismissible: true,
                    useRootNavigator: true,
                    context: context,
                    builder: (_) => Material(
                      type: MaterialType.transparency,
                      child: Center(
                        // Aligns the container to center
                        child: Container(
                          // A simplified version of dialog.
                          width: 100.0,
                          height: 100.0,
                          color: Colors.transparent,
                          child: Container(
                              padding: const EdgeInsets.all(15),
                              child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                  );
                  var response = await submitProcess(
                    _fullnameController.text,
                    _amountController.text,
                  );
                  _fullnameController.clear();
                  _amountController.clear();

                  Navigator.of(context, rootNavigator: true).pop();
                  if (response.statusCode != 200) {
                    return showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(
                            'Mtandao umekosekana, angalia mtandao kisha jaribu tena',
                          ),
                          actions: <Widget>[
                            FlatButton(
                              child: Text('Sawa'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    return showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(
                              'Asante kwa kufanya malipo, team yetu itafanyia uhakiki yakikamilika yataonekana kwenye profile yako. Endelea kufurahia huduma'),
                          actions: <Widget>[
                            FlatButton(
                              child: Text('Sawa'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                } else {
                  return showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text('Weka SMS ya muamala au jina la wakala'),
                        actions: <Widget>[
                          FlatButton(
                            child: Text('Sawa'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<http.Response> submitProcess(
    sms,
    amount,
  ) {
    try {
      return http.post(
        'https://masomo.co.tz/Api/malipo',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'id': user['id'],
          'phone': '',
          'sms': sms,
          'amount': amount,
        }),
      );
    } catch (e) {
      return null;
    }
  }
}

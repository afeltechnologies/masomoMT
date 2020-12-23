import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyProfile extends StatefulWidget {
  final user;
  MyProfile(this.user);

  @override
  _MyProfileState createState() => _MyProfileState(user);
}

class _MyProfileState extends State<MyProfile> {
  final user;
  _MyProfileState(this.user);
  var pays;
  totalPayments() {
    var total = 0.0;
    pays = user['payments'];
    for (int i = 0; i < pays.length; i++) {
      var amount = double.parse(pays[i]['amount']);
      total = total + amount;
    }
    return total.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final _width = MediaQuery.of(context).size.width;
    final _height = MediaQuery.of(context).size.height;
    pays = user['payments'];
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFB3590A),
          title: Text('Taarifa zangu'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Container(
          height: _height,
          width: _width,
          child: Column(
            children: [
              ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(2),
                children: <Widget>[
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.verified_user,
                        color: Colors.green,
                      ),
                      title: Row(
                        children: [
                          Text('JINA :'),
                          Spacer(),
                          Text(widget.user['name'].toUpperCase())
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.phone,
                        color: Colors.green,
                      ),
                      title: Row(
                        children: [
                          Text('NAMBA YA SIMU :'),
                          Spacer(),
                          Text(widget.user['phone'].toUpperCase())
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.category,
                        color: Colors.green,
                      ),
                      title: Row(
                        children: [
                          Text('DARASA :'),
                          Spacer(),
                          Text(widget.user['class'].toUpperCase())
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.access_alarm,
                        color: Colors.green,
                      ),
                      title: Row(
                        children: [
                          Text('WIKI YA SASA :'),
                          Spacer(),
                          Text('Week #' + widget.user['week'].toUpperCase())
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.date_range,
                        color: Colors.green,
                      ),
                      title: Row(
                        children: [
                          Text('TAREHE:'),
                          Spacer(),
                          Text(widget.user['date'].toUpperCase())
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.date_range,
                        color: Colors.green,
                      ),
                      title: Row(
                        children: [
                          Text('JUMLA YA MALIPO:'),
                          Spacer(),
                          Text('TSH ' + totalPayments()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Divider(),
              Text(
                'Malipo yangu',
                style: TextStyle(color: Colors.black),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pays.length,
                  itemBuilder: (BuildContext context, int index) {
                    var amount = pays[index]['amount'];
                    var datePaid = pays[index]['date_confirmed'];
                    var method = pays[index]['method'];
                    var mobileUsed = pays[index]['mobile_used'];
                    var transactionID = pays[index]['transactionID'];
                    var sms = pays[index]['sms'];
                    return new Card(
                      margin: const EdgeInsets.all(10),
                      child: InkWell(
                        splashColor: Colors.blue.withAlpha(30),
                        onTap: () {
                          if (sms.length > 0) {
                            return showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  content: Text(sms),
                                  actions: <Widget>[
                                    FlatButton(
                                      child: Text('Ok'),
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
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(6),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    Icons.bookmark_border,
                                    size: 40,
                                    color: Colors.green,
                                  )
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'AMOUNT: $amount  DATE: $datePaid',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    ' $method Mobile: $mobileUsed TxID: $transactionID',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 12,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            nisogezeConfirm(context);
          },
          child: Icon(Icons.add),
          backgroundColor: const Color(0xFFB3590A),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  nisogeze() async {
    try {
      var week = int.parse(user['week']) + 1;
      var response = await http.post(
        'https://masomo.co.tz/api/nisogeze',
        body: jsonEncode({'id': user['id'], 'week': week}),
      );
      return response;
    } catch (e) {
      return null;
    }
  }

  nisogezeConfirm(context) async {
    return await showDialog(
      context: context,
      builder: (dialogContex4) {
        return AlertDialog(
          content: Text(
              'Kama umemaliza wiki ya sasa bonyeza Nipeleke kwenda wiki inayofuata'),
          actions: <Widget>[
            FlatButton(
              child: Text(
                'Hapana',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text(
                'Nipeleke',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () async {
                Navigator.of(context).pop(true);

                showDialog(
                  barrierDismissible: true,
                  useRootNavigator: true,
                  context: context,
                  builder: (_) => Material(
                    type: MaterialType.transparency,
                    child: Center(
                      // Aligns the container to center
                      child: Container(
                        width: 100.0,
                        height: 100.0,
                        color: Colors.transparent,
                        child: Container(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                              ],
                            )),
                      ),
                    ),
                  ),
                );
                var data = await nisogeze();
                Navigator.of(context, rootNavigator: true).pop();
                if (data.body != null) {
                  showDialog(
                    context: context,
                    builder: (dialogContex) {
                      return AlertDialog(
                        content: Text(
                          'Ombi lako limefanyiwa kazi, rudi kwenye wiki uka refresh!',
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text('Ok'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (dialogContex2) {
                      return AlertDialog(
                        content: Text(
                          'Mtandao umekosekana!',
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text('Ok'),
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
          ],
        );
      },
    );
  }
}

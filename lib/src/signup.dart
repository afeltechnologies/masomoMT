import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../src/user/homepage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  final phone;
  SignUpPage(this.phone);

  @override
  _SignUpPageState createState() => _SignUpPageState(phone);
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _fullnameController = new TextEditingController();
  final phone;
  _SignUpPageState(this.phone);

  Widget _backButton() {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 0, top: 10, bottom: 10),
              child: Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            Text('Back',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white))
          ],
        ),
      ),
    );
  }

  bool validate(String _fullname) {
    if (_fullname.length > 2) {
      return true;
    } else {
      return false;
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/user.json');
  }

  Future<File> write(user) async {
    final file = await _localFile;
    return file.writeAsString(json.encode(user));
  }

  // ignore: non_constant_identifier_names
  Future<http.Response> SignUp_process(String _fullname) {
    try {
      return http.post(
        'https://masomo.co.tz/Api/register',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'phone': phone, 'name': _fullname}),
      );
    } catch (e) {
      inspect(e);
      return null;
    }
  }

  Widget _entryField() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Jina kamili',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          SizedBox(
            height: 4,
          ),
          TextFormField(
            controller: _fullnameController,
            obscureText: false,
            decoration: InputDecoration(
                border: InputBorder.none,
                fillColor: Color(0xFFE2DFDD),
                hintText: 'Jina kamili',
                filled: true),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return Container(
        width: double.infinity,
        child: FlatButton(
          child: Text(
            'Jisajili',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          shape: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.all(15),
          textColor: Colors.white,
          color: const Color(0xFFB3590A),
          onPressed: () async {
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
            if (validate(_fullnameController.text) == true) {
              var response = await SignUp_process(_fullnameController.text);

              inspect(response);
              print(response);
              Navigator.of(context, rootNavigator: true).pop();
              if (response.statusCode != 200) {
                return showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Text('Mtandao umekosekana!'),
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
                Map<String, dynamic> user = jsonDecode(response.body);
                return _loginSuccess(user);
              }
            } else {
              return showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Text('Jaza sehemu zote/Fill the form first'),
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
        ));
  }

  Widget _title() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 230,
          height: 52,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              image: DecorationImage(
                  image: AssetImage('assets/images/masomo.png'),
                  fit: BoxFit.contain)),
        ),
        SizedBox(
          height: 10,
        ),
        SizedBox(
          height: 10,
        ),
      ],
    );
  }

  Widget _emailPasswordWidget() {
    return Column(
      children: <Widget>[
        _entryField(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        body: Container(
      color: const Color(0xFFB3590A),
      height: height,
      child: Stack(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: height * .2),
                  _title(),
                  SizedBox(height: 50),
                  _emailPasswordWidget(),
                  SizedBox(height: 20),
                  _submitButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Positioned(top: 40, left: 0, child: _backButton()),
        ],
      ),
    ));
  }

  _loginSuccess(user) {
    write(user);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          user,
        ),
      ),
    );
  }
}

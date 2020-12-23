import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../src/signup.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

// ignore: camel_case_types
class Login_response {
  final int id;
  final String title;

  Login_response({this.id, this.title});

  factory Login_response.fromJson(Map<String, dynamic> json) {
    return Login_response(
      id: json['phone'],
      title: json['weeks'],
    );
  }
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = new TextEditingController();
  final TextEditingController _passwordController = new TextEditingController();

  bool validate(String _phone, String _password) {
    if (_phone.length > 2 && _password.length > 2) {
      return true;
    } else {
      return false;
    }
  }

  // ignore: non_constant_identifier_names
  Future<http.Response> LoginProcess(String _phone, String _password) {
    try {
      var response = http.post(
        'https://masomo.co.tz/Api',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'phone': _phone, 'password': _password}),
      );
      return response;
    } catch (e) {
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
            'Namba ya simu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _phoneController,
            obscureText: false,
            decoration: InputDecoration(
                border: InputBorder.none,
                fillColor: Color(0xFFE2DFDD),
                hintText: 'Namba ya simu',
                filled: true),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            'Password',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
                border: InputBorder.none,
                fillColor: Color(0xFFE2DFDD),
                hintText: 'Password',
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
            'Login',
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
            if (validate(_phoneController.text, _passwordController.text) ==
                true) {
              var response = await LoginProcess(
                  _phoneController.text, _passwordController.text);

              Navigator.of(context, rootNavigator: true).pop();
              if (response == null) {
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
                if (response.body.length != 1) {
                  // var user = jsonDecode(response.body);
                  // return _loginSuccess(user, response.body);
                } else {
                  return showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content:
                            Text('Umekosea namba ya simu au nenosiri/password'),
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

  Widget _createAccountLabel() {
    return InkWell(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => SignUpPage('phone')));
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 20),
        padding: EdgeInsets.all(15),
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Bado hujajisajili?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Jisajili sasa',
              style: TextStyle(
                  color: Color(0xFFB3590A),
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
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
                  image: AssetImage('assets/images/masomo2.png'),
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
      color: Colors.white54,
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
                  _createAccountLabel(),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:splashscreen/splashscreen.dart';
import 'src/signup.dart';
import 'src/user/homepage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);

  runApp(
    new MaterialApp(
      home: MyApp(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

String phoneNumber;

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // return new SplashScreen(
    //     seconds: 3,
    //     navigateAfterSeconds: new LoginPage(),
    //     image: new Image.asset('assets/images/masomo.png'),
    //     backgroundColor: const Color(0xFFB3590A),
    //     styleTextUnderTheLoader: new TextStyle(),
    //     loadingText: Text('Masomo Mtandaoni'),
    //     photoSize: 100.0,
    //     loaderColor: Colors.white);
    // );
    return LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogedIn = false;
  bool isLoading = true;
  var userData;
  var data;

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

  Future<void> read() async {
    try {
      final file = await _localFile;
      await file.readAsString().then((String result) {
        setState(() {
          isLogedIn = true;
          isLoading = false;
          data = result;
        });
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  final TextEditingController _phoneController = new TextEditingController();

  bool validate(String _phone) {
    if (_phone.length > 8) {
      return true;
    } else {
      return false;
    }
  }

  // ignore: non_constant_identifier_names
  Future<http.Response> LoginProcess(String _phone) {
    try {
      var response = http.post(
        'https://masomo.co.tz/Api',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body:
            jsonEncode(<String, String>{'phone': _phone, 'password': 'masomo'}),
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
          TextFormField(
            controller: _phoneController,
            obscureText: false,
            decoration: InputDecoration(
              border: InputBorder.none,
              fillColor: Color(0xFFE2DFDD),
              hintText: 'Namba ya simu',
              filled: true,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            maxLength: 12,
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlatButton(
              child: Container(
                width: double.infinity,
                child: Text(
                  'Endelea',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
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
                FocusScope.of(context).requestFocus(FocusNode());
                showDialog(
                  barrierDismissible: false,
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
                if (validate(_phoneController.text) == true) {
                  var response = await LoginProcess(_phoneController.text);

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
                      Map<String, dynamic> user = jsonDecode(response.body);
                      return _loginSuccess(user);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SignUpPage(_phoneController.text),
                        ),
                      );
                    }
                  }
                } else {
                  return showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text('Hakikisha namba uliyojaza ni sahihi'),
                        actions: <Widget>[
                          FlatButton(
                            child: Text('Sawa'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 140,
                ),
                Text(
                  '©',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Masomo Mtandaoni',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
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

  Widget success() {
    try {
      return new HomePage(jsonDecode(data));
    } catch (e) {
      return new HomePage(data);
    }
  }

  logout() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    File file = File('$path/user.json');
    if (file.exists() != null) {
      file.delete();
    }
  }

  @override
  void initState() {
    read();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _globalKey = GlobalKey<_LoginPageState>();
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: isLogedIn
          ? success()
          : Container(
              color: const Color(0xFFB3590A),
              height: height,
              width: double.infinity,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Stack(
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
                                SizedBox(height: 4),
                                _submitButton(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  _loginSuccess(user) async {
    write(user);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(user),
      ),
    );
  }
}

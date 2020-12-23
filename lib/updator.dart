import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class Updator extends StatefulWidget {
  @override
  _UpdatorState createState() => _UpdatorState();
}

class _UpdatorState extends State<Updator> {
  AppUpdateInfo _updateInfo;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();

  bool _flexibleUpdateAvailable = false;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      print(info);
      setState(() {
        _updateInfo = info;
      });
    }).catchError((e) => _showError(e));
  }

  void _showError(dynamic exception) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(exception.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      home: Scaffold(
        key: _scaffoldKey,

        appBar: AppBar(
          title: const Text('MasomoMT'),
          backgroundColor: const Color(0xFFB3590A),
        leading: IconButton(
            padding: EdgeInsets.only(left: 10, right: 0.0),
            icon: Icon(
              Icons.arrow_back_ios,
              size: 20,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Center(
                child: Text('Update info: $_updateInfo'),
              ),
              RaisedButton(
                child: Text('Check for Update'),
                onPressed: () => checkForUpdate(),
              ),
              RaisedButton(
                child: Text('Perform immediate update'),
                onPressed: _updateInfo?.updateAvailable == true
                    ? () {
                        InAppUpdate.performImmediateUpdate().catchError((e) => _showError(e));
                      }
                    : null,
              ),
              RaisedButton(
                child: Text('Start flexible update'),
                onPressed: _updateInfo?.updateAvailable == true
                    ? () {
                        InAppUpdate.startFlexibleUpdate().then((_) {
                          setState(() {
                            _flexibleUpdateAvailable = true;
                          });
                        }).catchError((e) => _showError(e));
                      }
                    : null,
              ),
              RaisedButton(
                child: Text('Complete flexible update'),
                onPressed: !_flexibleUpdateAvailable
                    ? null
                    : () {
                        InAppUpdate.completeFlexibleUpdate().then((_) {
                          _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('Success!')));
                        }).catchError((e) => _showError(e));
                      },
              )
            ],
          ),
        ),
      ),
    );
  }
}
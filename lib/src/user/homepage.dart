import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:masomoMT/src/user/translator.dart';
import './fanyaMalipo.dart';
import './profilePage.dart';
import './savedVideos.dart';
import './selector.dart';
import 'package:http/http.dart' as http;
import 'package:bubble/bubble.dart';
import 'package:path_provider/path_provider.dart';
import '../../main.dart';
import '../../updator.dart';

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  static const routeName = '/homepage';
  var user;

  HomePage(
    this.user,
  );

  @override
  _HomePageState createState() => new _HomePageState(user);
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _smsController = new TextEditingController();

// Notifications
  var notifications;

// session

  String contents;
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
    file.writeAsStringSync(json.encode(user));
    return null;
  }

  // auto update on startup
  bool isUpdated = false;
  // THIS IS FORM SMS
  int count = 0;
  int smscount = 0;
  var weekList = [];
  Timer timer;
  Timer timerNotification;
  var messages = [];
  int smscountScroll = 0;
  var user;
  var isMessagePage = false;
  TabController tabController;
  _HomePageState(this.user);

  bool isUserUpdated = false;
  var userUpdated;
  Future<String> get _userlocalPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _userlocalFile async {
    final path = await _userlocalPath;
    return File('$path/user.json');
  }

  quitApp() {
    SystemNavigator.pop();
    exit(0);
  }

  Future<void> logout(bool option) async {
    try {
      final file = await _userlocalFile;
      if (file.exists() != null) {
        file.delete();
      }
      if (!option) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
      }
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> updateInfo(data) async {
    try {
      logout(true);
      write(data);
      setState(() {
        user = data;
        userUpdated = data;
        isUserUpdated = true;
      });
    } catch (e) {}
  }

  Future<http.Response> refresh() {
    String _phone = user['phone'];
    try {
      var response = http.post(
        'https://masomo.co.tz/Api',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body:
            jsonEncode(<String, String>{'phone': _phone, 'password': 'masomo'}),
      );
      return response.whenComplete(() => setState(() {}));
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUser() async {
    try {
      final http.Response response = await http.put(
        'https://jsonplaceholder.typicode.com/albums',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'phone': user['phone'], 'password': 'masomo'}),
      );

      if (response.statusCode == 200) {
        // Delete the existing file and place a new one
        logout(true);
        // write new file

        var newUser = jsonDecode(response.body);
        write(newUser);
        setState(() {
          user = newUser;
        });
      } else {
        // If the server did not return a 200 UPDATED response,
        // then throw an exception.
        throw Exception('Failed to load data');
      }
    } catch (e) {}
  }

  var formattedDate;
  bool isFetchinghSms = false;
  String sms;
  // For notifications

  FlutterLocalNotificationsPlugin flutternotification;

  @override
  void initState() {
    super.initState();
    updateUser();

    timer =
        Timer.periodic(Duration(seconds: 10), (Timer t) => loadNewMessages());
    timerNotification =
        Timer.periodic(Duration(hours: 1), (Timer t) => loadNotifications());

    var androidInitialize = new AndroidInitializationSettings('app_icon');
    var iosInitialize = new IOSInitializationSettings();
    var initializationSettings =
        new InitializationSettings(androidInitialize, iosInitialize);
    flutternotification = new FlutterLocalNotificationsPlugin();
    flutternotification.initialize(initializationSettings,
        onSelectNotification: notificationSelected);
  }

  _showNotification(title, body) async {
    var androidDetails = new AndroidNotificationDetails(
      "id",
      "Taarifa",
      "Kuna taarifa mpya",
      importance: Importance.Max,
      enableLights: true,
      enableVibration: true,
    );
    var iSODetails = new IOSNotificationDetails();
    var generalNotificationDetails =
        new NotificationDetails(androidDetails, iSODetails);

    await flutternotification.show(
        0, '$title', '$body', generalNotificationDetails);
  }

  @override
  void dispose() {
    timer?.cancel();
    timerNotification?.cancel();
    super.dispose();
  }

  bool scolled = false;
  Future<Object> parseSms(Object responseBody) {
    var isNew = jsonDecode(responseBody);

    if (isNew != null && isNew.length > 0) {
      _showNotification("Masomo SMS", isNew[0]['sms']);
    }
    setState(() {
      messages.addAll(jsonDecode(responseBody));
    });
    smsScroll();
    return null;
  }

  Future<Object> loadSmsOld() async {
    setState(() {
      isFetchinghSms = true;
    });
    count++;
    final response = await http
        .get('https://masomo.co.tz/api/load_sms_all?id=' + user['id']);
    // Use the compute function to run in a separate isolate.

    setState(() => messages.addAll(jsonDecode(response.body)));

    if (messages.length == 0) {
      setState(() {
        isFetchinghSms = true;
        messages.add(jsonDecode(sms));
      });
    }
    return null;
  }

  Future<Object> loadNewMessages() async {
    try {
      final response =
          await http.get('https://masomo.co.tz/api/load_sms?id=' + user['id']);
      // Use the compute function to run in a separate isolate.
      if (response.statusCode == 200) {
        var newSms = jsonDecode(response.body);
        if (newSms != null && newSms.length > 0) {
          parseSms(response.body);
          smsScroll();
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> loadNotifications() async {
    try {
      final response = await http.get(
          'https://masomo.co.tz/api/load_notifications?week=' + user['week']);
      // Use the compute function to run in a separate isolate.
      if (response.statusCode == 200) {
        setState(() {
          notifications = jsonDecode(response.body);
        });
      }
    } catch (e) {}
  }

  Future<Object> postNewMessages(text) async {
    try {
      if (text.length > 0) {
        final response = await http.post(
          'https://masomo.co.tz/api/post_sms',
          body: jsonEncode(<String, String>{'id': user['id'], 'sms': text}),
        );
        parseSms(response.body);
        smsScroll();
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void handleClick(String value) {
    switch (value) {
      case 'Logout':
        logout(false);
        break;

      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyProfile(
              user,
            ),
          ),
        );
        break;
      case 'Update APP':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Updator(),
          ),
        );
        break;
      case 'Exit':
        quitApp();
        break;
    }
  }

  Future<http.Response> loadWeeks() async {
    try {
      var response =
          await http.get('https://masomo.co.tz/api/new_weeks?id=' + user['id']);

      if (response.statusCode == 200) {
        if (weekList.length == 0) {
          setState(() => weekList.addAll(jsonDecode(response.body)));
        } else {
          weekList = jsonDecode(response.body);
          setState(() => weekList);
        }
      }
    } catch (e) {}
    return null;
  }

  bool autoLogout = false;
  Future<http.Response> userAgent() async {
    String os = Platform.operatingSystem;
    String vs = Platform.operatingSystemVersion;

    try {
      var response = await http.get('https://masomo.co.tz/api/isLogedIn?id=' +
          user['id'] +
          '&os=$os&vs=$vs');

      if (response.statusCode == 200) {
        var userId = jsonDecode(response.body);
        if (userId['status'] == 0) {
          setState(() {
            autoLogout = true;
          });
        }
      }
    } catch (e) {}
    return null;
  }

  Future<http.Response> badiliAccount() async {
    String os = Platform.operatingSystem;
    String vs = Platform.operatingSystemVersion;

    try {
      var response = await http.get(
          'https://masomo.co.tz/api/isLogedIn?badili&id=' +
              user['id'] +
              '&os=$os&vs=$vs');

      if (response.statusCode == 200) {
        var userId = jsonDecode(response.body);

        if (userId['status'] == '0') {
          setState(() {
            autoLogout = true;
          });
        } else {
          setState(() {
            autoLogout = false;
          });
        }
      }
    } catch (e) {}
    return null;
  }

  autoUpdate() async {
    var refreshing = await refresh();

    if (refreshing != null) {
      try {
        Map<String, dynamic> userUpated = jsonDecode(refreshing.body);

        updateInfo(userUpated);
        setState(() {
          isUpdated = true;
        });
      } catch (e) {
        // do nothing
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!autoLogout) {
      userAgent();
    }

    if (user['weeks'].length == 0) {
      loadWeeks();
    }
    if (!isUpdated) {
      autoUpdate();
    }
    if (count == 0) {
      loadSmsOld();
    }
    loadNotifications();
    return autoLogout
        ? MaterialApp(
            title: 'Akaunti yangu',
            color: const Color(0xFFB3590A),
            home: Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(0xFFB3590A),
                title: Text('Akaunti yangu'),
              ),
              body: Container(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  children: <Widget>[
                    Card(
                      child: ListTile(
                        title: Column(
                          children: [
                            Icon(
                              Icons.warning_amber_sharp,
                              color: Colors.red,
                              size: 40,
                            ),
                            Row(
                              children: [
                                Text('JINA :'),
                                Spacer(),
                                Text(widget.user['name'].toUpperCase())
                              ],
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              children: [
                                Text('NAMBA :'),
                                Spacer(),
                                Text(widget.user['phone'].toUpperCase())
                              ],
                            ),
                            SizedBox(
                              height: 40,
                            ),
                            Text(
                                'Akaunti hii tayari inatumika na kifaa kingine.'),
                            SizedBox(
                              height: 10,
                            ),
                            Center(
                              child: Text(
                                  'Kubadili kifaa bonyeza "Tumia hapa", Kubadili akaunti bonyeza Logout.'),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Row(
                              children: [
                                FlatButton(
                                  color: Colors.red,
                                  child: const Text('Logout'),
                                  shape: new RoundedRectangleBorder(
                                      borderRadius:
                                          new BorderRadius.circular(30.0)),
                                  textColor: Colors.white,
                                  onPressed: () {
                                    logout(false);
                                  },
                                ),
                                Spacer(),
                                FlatButton(
                                  color: const Color(0xFFB3590A),
                                  child: const Text('Tumia hapa'),
                                  shape: new RoundedRectangleBorder(
                                      borderRadius:
                                          new BorderRadius.circular(30.0)),
                                  textColor: Colors.white,
                                  onPressed: () {
                                    badiliAccount();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      shadowColor: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
          )
        : DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                toolbarHeight: 70,
                backgroundColor: const Color(0xFFB3590A),
                actions: <Widget>[
                  PopupMenuButton<String>(
                    onSelected: handleClick,
                    itemBuilder: (BuildContext context) {
                      return {'Profile', 'Logout', 'Exit', 'Update APP'}
                          .map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
                    },
                  ),
                ],
                leading: new Container(),
                bottom: TabBar(
                  tabs: <Widget>[
                    Icon(
                      Icons.home,
                      size: 30,
                    ),
                    Row(
                      children: [
                        // Center(
                        //   child: Icon(
                        //     Icons.switch_left_sharp,
                        //     size: 30,
                        //   ),
                        // ),
                        Text('Tafsiri'),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Chat'),
                      ],
                    ),
                    Icon(
                      Icons.notification_important,
                      size: 30,
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                controller: tabController,
                children: <Widget>[
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              color: Colors.blueGrey[50],
                              width: double.infinity,
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    widget.user['name'].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  Spacer(
                                    flex: 5,
                                  ),
                                  ClipOval(
                                    child: Material(
                                      color: Colors.green, // button color
                                      child: InkWell(
                                        splashColor:
                                            Colors.red, // inkwell color
                                        child: SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: Icon(
                                            Icons.refresh,
                                            color: Colors.white,
                                          ),
                                        ),
                                        onTap: () async {
                                          showDialog(
                                            barrierDismissible: false,
                                            useRootNavigator: false,
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
                                                      padding:
                                                          const EdgeInsets.all(
                                                              15),
                                                      child:
                                                          CircularProgressIndicator()),
                                                ),
                                              ),
                                            ),
                                          );
                                          var refreshing = await refresh();
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                          if (refreshing != null) {
                                            try {
                                              Map<String, dynamic> userUpated =
                                                  jsonDecode(refreshing.body);

                                              updateInfo(userUpated);
                                            } catch (e) {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    content: Text(
                                                      'Imeshindwa kufanya update, tafadali analia mtandao na jaribu tena',
                                                    ),
                                                    actions: <Widget>[
                                                      FlatButton(
                                                        child: Text('Ok'),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  content: Text(
                                                    'Taarifa zimefanyiwa updates!',
                                                  ),
                                                  actions: <Widget>[
                                                    FlatButton(
                                                      child: Text('Ok'),
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  content: Text(
                                                      'Mtandao umekosekana!'),
                                                  actions: <Widget>[
                                                    FlatButton(
                                                      child: Text('Ok'),
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
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
                                  ),
                                  Spacer(
                                    flex: 5,
                                  ),
                                  Text(
                                    widget.user['phone'].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ],
                              ),
                            ),
                            ListTile(
                              tileColor: Colors.blueGrey[50],
                              title: Row(
                                children: <Widget>[
                                  Expanded(
                                      flex: 5,
                                      child: RaisedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FanyaMalipo(user),
                                            ),
                                          );
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              WidgetSpan(
                                                child:
                                                    Icon(Icons.add, size: 14),
                                              ),
                                              TextSpan(
                                                text: " Fanya malipo",
                                              ),
                                            ],
                                          ),
                                        ),
                                        color: Colors.green,
                                        textColor: Colors.white,
                                      )),
                                  Spacer(
                                    flex: 2,
                                  ),
                                  Expanded(
                                      flex: 5,
                                      child: RaisedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  SavedVideos(user),
                                            ),
                                          );
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              WidgetSpan(
                                                child: Icon(
                                                    Icons.video_collection,
                                                    size: 14),
                                              ),
                                              TextSpan(
                                                text: " Saved videos",
                                              ),
                                            ],
                                          ),
                                        ),
                                        color: Colors.green,
                                        textColor: Colors.white,
                                      )),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        getTextWidgets(widget.user),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    color: Colors.white,
                    width: double.infinity,
                    child: tafsiri(widget.user),
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: Container(
                          child: messagges(widget.user, context),
                        ),
                      ),
                      TextFormField(
                        cursorColor: Colors.red,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        controller: _smsController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(
                              top: 12.0, left: 13.0, right: 13.0, bottom: 2.0),
                          hintText: "Type your message",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              FocusScope.of(context).requestFocus(FocusNode());
                              postNewMessages(_smsController.text);
                              _smsController.clear();
                            },
                            icon: Icon(Icons.send),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      listNotifications(),
                    ],
                  ),
                ],
              ),
            ),
          );
  }

  Widget getTextWidgets(user) {
    if (user['weeks'].length == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 150,
          ),
          Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.cyanAccent,
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
          Text('Inapakua taarifa'),
        ],
      );
    } else {
      var weekList = isUserUpdated ? userUpdated['weeks'] : user['weeks'];

      return new Expanded(
        child: Container(
          width: double.infinity,
          child: isUserUpdated
              ? ListView.builder(
                  reverse: false,
                  itemCount: isUserUpdated
                      ? userUpdated['weeks'].length
                      : user['weeks'].length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, index) {
                    int weekNumber = index + 1;
                    int weekPaid = weekList[index]['paid'];

                    if (weekPaid == 0) {
                      return Container(
                        width: double.infinity,
                        child: InkWell(
                          child: Card(
                            elevation: 2.0,
                            color: const Color(0xFFAD7D52),
                            child: Padding(
                              padding: const EdgeInsets.all(0.5),
                              child: Container(
                                height: 60,
                                child: Column(
                                  children: <Widget>[
                                    ListTile(
                                      leading: Icon(
                                        Icons.lock,
                                        size: 25,
                                        color: Colors.white60,
                                      ),
                                      title: new Text(
                                        'Week $weekNumber',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            return showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  content: Text(
                                      'Wiki hii haijalipiwa, fanya malipo sasa uendelee kujisomea'),
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
                          },
                        ),
                      );
                    } else {
                      return Container(
                        width: double.infinity,
                        child: InkWell(
                          child: Card(
                            shadowColor: Colors.black,
                            borderOnForeground: true,
                            color: const Color(0xFFB3590A),
                            child: Padding(
                              padding: const EdgeInsets.all(0.5),
                              child: Container(
                                height: 60,
                                child: Column(
                                  // mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      leading: Icon(
                                        Icons.lock_open,
                                        size: 25,
                                        color: Colors.white,
                                      ),
                                      title: new Text(
                                        'Week $weekNumber',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            var videoWeeks = isUserUpdated
                                ? userUpdated['videos'][index]
                                : user['videos'][index];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Selector(
                                  userUpdated,
                                  videoWeeks['videoWeeks'],
                                  index,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  },
                )
              : ListView.builder(
                  reverse: false,
                  itemCount: user['weeks'].length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, index) {
                    int weekNumber = index + 1;
                    int weekPaid = weekList[index]['paid'];

                    if (weekPaid == 0) {
                      return Container(
                        width: double.infinity,
                        child: InkWell(
                          child: Card(
                            elevation: 2.0,
                            color: const Color(0xFFAD7D52),
                            child: Padding(
                              padding: const EdgeInsets.all(0.5),
                              child: Container(
                                height: 60,
                                child: Column(
                                  children: <Widget>[
                                    ListTile(
                                      leading: Icon(
                                        Icons.lock,
                                        size: 25,
                                        color: Colors.white60,
                                      ),
                                      title: new Text(
                                        'Week $weekNumber',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            return showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  content: Text(
                                      'Wiki hii haijalipiwa, fanya malipo sasa uendelee kujisomea'),
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
                          },
                        ),
                      );
                    } else {
                      return Container(
                        width: double.infinity,
                        child: InkWell(
                          child: Card(
                            shadowColor: Colors.black,
                            borderOnForeground: true,
                            color: const Color(0xFFB3590A),
                            child: Padding(
                              padding: const EdgeInsets.all(0.5),
                              child: Container(
                                height: 60,
                                child: Column(
                                  // mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      leading: Icon(
                                        Icons.lock_open,
                                        size: 25,
                                        color: Colors.white,
                                      ),
                                      title: new Text(
                                        'Week $weekNumber',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            var videoWeeks = user['videos'][index];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Selector(
                                  user,
                                  videoWeeks['videoWeeks'],
                                  index,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  },
                ),
        ),
      );
    }
  }

  Widget tafsiri(user) {
    return Translator(user['id']);
  }

  ScrollController _scrollController = new ScrollController();

  Future notificationSelected(String payload) async {}

  smsScroll() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget messagges(user, context) {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    double px = 1 / pixelRatio;
    // BubbleStyle styleSomebody = BubbleStyle(
    //   nip: BubbleNip.leftTop,
    //   color: Colors.white,
    //   elevation: 1 * px,
    //   margin: BubbleEdges.only(top: 8.0, right: 50.0),
    //   alignment: Alignment.topLeft,
    // );
    // BubbleStyle styleMe = BubbleStyle(
    //   nip: BubbleNip.rightTop,
    //   color: Color.fromARGB(255, 225, 255, 199),
    //   elevation: 1 * px,
    //   margin: BubbleEdges.only(top: 8.0, left: 50.0),
    //   alignment: Alignment.topRight,
    // );
    var date = new DateTime.now().toString();
    var dateParse = DateTime.parse(date);
    var formattedDate = "${dateParse.year}-${dateParse.month}-${dateParse.day}";
    int today = 0;
    var todayDate;
    return messages == null
        ? Bubble(
            alignment: Alignment.center,
            color: Color.fromARGB(255, 212, 234, 244),
            elevation: 1 * px,
            margin: BubbleEdges.only(top: 8.0),
            child: Text('TODAY', style: TextStyle(fontSize: 10)),
          )
        : Container(
            color: Colors.yellow.withAlpha(64),
            child: Container(
              child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  shrinkWrap: true,
                  controller: _scrollController,
                  itemBuilder: (BuildContext context, index) {
                    var date = messages[index]['date'];
                    var type = messages[index]['type'];
                    var sms = messages[index]['sms'];
                    var time = messages[index]['time'];

                    if (today == 0 && date == formattedDate) {
                      today++;
                      todayDate = date;
                      return Bubble(
                        alignment: Alignment.center,
                        color: Color.fromARGB(255, 212, 234, 244),
                        elevation: 1 * px,
                        margin: BubbleEdges.only(top: 8.0),
                        child: Text('TODAY', style: TextStyle(fontSize: 10)),
                      );
                    } else {
                      if (date != todayDate && sms != null && time != null) {
                        todayDate = date;
                        return Bubble(
                          alignment: Alignment.center,
                          color: Color.fromARGB(255, 212, 234, 244),
                          elevation: 1 * px,
                          margin: BubbleEdges.only(top: 8.0),
                          child: Text('$date ${sms.length}',
                              style: TextStyle(fontSize: 10)),
                        );
                      }
                    }
                    if (type == 'to') {
                      return SendMessageBubble(
                        message: sms,
                        time: date + ' ' + time,
                      );
                    } else {
                      return ReceivedMessageBubble(
                        message: sms,
                        time: date + ' ' + time,
                      );
                    }
                    // }
                  }),
            ),
          );
  }

  Widget listNotifications() {
    if (notifications == null) {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
            ),
            Icon(
              Icons.warning,
              color: const Color(0xFFB3590A),
              size: 40,
            ),
            Text('Hakuna taarifa kwa sasa '),
          ],
        ),
      );
    } else {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: notifications.length,
          padding: const EdgeInsets.only(
            top: 10.0,
            bottom: 2,
          ),
          itemBuilder: (context, index) {
            var note = notifications[index]['message'];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.notification_important,
                      color: const Color(0xFFB3590A),
                      size: 40,
                    ),
                    title: const Text('Taarifa'),
                    subtitle: Text(
                      '$note',
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            );
          });
    }
  }
}

class SendMessageBubble extends StatelessWidget {
  final String message;
  final String time;

  const SendMessageBubble({
    Key key,
    this.message,
    this.time,
  })  : assert(message != null),
        assert(time != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxBubbleWidth = constraints.maxWidth * 0.7;
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(0.0),
                  bottomLeft: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                ),
              ),
              margin: const EdgeInsets.all(10.0),
              padding: const EdgeInsets.all(10.0),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(message),
                    const SizedBox(height: 5.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          time,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 8.0,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ReceivedMessageBubble extends StatelessWidget {
  final String message;
  final String time;

  const ReceivedMessageBubble({
    Key key,
    this.message,
    this.time,
  })  : assert(message != null),
        assert(time != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxBubbleWidth = constraints.maxWidth * 0.7;
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxBubbleWidth,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0.0),
                  topRight: Radius.circular(10.0),
                  bottomLeft: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                ),
              ),
              margin: const EdgeInsets.all(10.0),
              padding: const EdgeInsets.all(10.0),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      message,
                    ),
                    const SizedBox(height: 5.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          time,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 8.0,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

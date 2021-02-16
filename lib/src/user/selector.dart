import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:masomoMT/src/user/lessons.dart';
import 'package:http/http.dart' as http;
import 'package:masomoMT/src/user/new_video_player.dart';
import './pdf.dart';
import '../user/play_page.dart';

class Selector extends StatefulWidget {
  final user;
  final videoWeek;
  final weekNumber;
  Selector(
    this.user,
    this.videoWeek,
    this.weekNumber,
  );

  @override
  _SelectorState createState() => _SelectorState(user, videoWeek, weekNumber);
}

class _SelectorState extends State<Selector> {
  final user;
  final videoWeek;
  final weekNumber;

  _SelectorState(
    this.user,
    this.videoWeek,
    this.weekNumber,
  );
  bool isFetching = true;
  var weekLessons;

  Future<void> _lessons() async {
    var wkID = weekNumber + 1;
    try {
      var resposnse = await http.post(
        'https://masomo.co.tz/mazoezi/lessons',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
          <String, String>{'week': '$wkID'},
        ),
      );
      setState(() {
        var less = jsonDecode(resposnse.body);
        weekLessons = less;
        if (weekLessons != null && weekLessons.length > 0) {
          isFetching = false;
        }
      });
    } catch (e) {
      print(e);
      setState(() {
        isFetching = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _lessons();
  }

  @override
  Widget build(BuildContext context) {
    int week = weekNumber + 1;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          // toolbarHeight: 60,
          // bottomOpacity: 0.8,
          backgroundColor: const Color(0xFFB3590A),
          title: Text(
            'Week $week',
            style: TextStyle(fontSize: 15),
          ),
          leading: IconButton(
            padding: EdgeInsets.only(left: 10, right: 0.0),
            icon: Icon(
              Icons.arrow_back_ios,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: <Widget>[
              // Tab(
              //   text: 'Lessons',
              // ),
              Tab(
                text: 'Videos',
              ),
              Tab(
                text: 'Notes',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            // zoeziList(),
            videoList(),
            notesList(),
          ],
        ),
      ),
    );
  }

  Widget videoList() {
    if (widget.videoWeek.length == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
          ),
          Text('Hakuna video kwa sasa'),
        ],
      );
    } else {
      return Container(
        width: double.infinity,
        child: ListView.builder(
          // separatorBuilder: (context, state) => Divider(),
          reverse: false,
          itemCount: widget.videoWeek.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, index) {
            String titleVideo = widget.videoWeek[index]['title'];
            String videoSize = widget.videoWeek[index]['size'];

            return Card(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewVideoPlayer(user['name'],
                          videoWeek[index], (weekNumber + 1), videoWeek),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Image.asset(
                          "assets/resource/play.png",
                          width: 70,
                          height: 50,
                          fit: BoxFit.fill,
                        ),
                      ),
                      Expanded(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(titleVideo,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              Padding(
                                child: Text(videoSize,
                                    style: TextStyle(color: Colors.grey[500])),
                                padding: EdgeInsets.only(top: 3),
                              )
                            ]),
                      ),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.play_arrow)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget notesList() {
    var notes = user['notes'][weekNumber];
    var notesList = notes['notesWeeks'];

    if (notesList.length == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
          ),
          Text('Hakuna notes kwa sasa'),
        ],
      );
    } else {
      return Container(
        width: double.infinity,
        child: ListView.builder(
          reverse: false,
          itemCount: notesList.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, index) {
            String titleVideo = notesList[index]['title'];
            String videoSize = notesList[index]['size'];
            String type = notesList[index]['type'];

            return Card(
              child: InkWell(
                onTap: () {
                  if (type == 'application') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Pdf(
                          user['name'],
                          notesList[index],
                          (weekNumber + 1),
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayPage(
                          user['name'],
                          [],
                          weekNumber,
                          videoWeek,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: type == 'application'
                            ? Icon(Icons.picture_as_pdf_outlined)
                            : Image.asset(
                                "assets/resource/play.png",
                                width: 70,
                                height: 50,
                                fit: BoxFit.fill,
                              ),
                      ),
                      Expanded(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(titleVideo,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                              Padding(
                                child: Text(videoSize,
                                    style: TextStyle(color: Colors.grey[500])),
                                padding: EdgeInsets.only(top: 3),
                              )
                            ]),
                      ),
                      Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.read_more)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget zoeziList() {
    if (isFetching) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Container(
        height: double.maxFinite,
        decoration: new BoxDecoration(
          image: new DecorationImage(
            image: new AssetImage('assets/resource/bg2.jpg'),
            colorFilter: new ColorFilter.mode(
                Colors.black.withOpacity(0.8), BlendMode.dstATop),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView.builder(
            itemCount: weekLessons != null ? weekLessons.length : 0,
            padding: const EdgeInsets.only(top: 10.0),
            itemBuilder: (context, index) {
              var zoeziId = weekLessons[index]['id'];
              return new InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Lessons(
                        zoeziId,
                        weekNumber + 1,
                      ),
                    ),
                  );
                },
                child: new Card(
                  child: new Column(
                    children: <Widget>[
                      new Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Container(
                                child: Text(
                              '${weekLessons[index]['title']}',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            )),
                            Spacer(),
                            new FloatingActionButton(
                              backgroundColor: const Color(0xFFB3590A),
                              mini: true,
                              heroTag: new HeroController(),
                              child: Icon(Icons.play_arrow),
                              onPressed: () {
                                print(zoeziId);
                              },
                            ),
                          ],
                        ),
                      ),
                      weekLessons[index]['desc'].length > 0
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Text('${weekLessons[index]['desc']}'),
                                ],
                              ),
                            )
                          : Text(''),
                    ],
                  ),
                ),
              );
            }),
      );
    }
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../user/homepage.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class Video extends StatefulWidget {
  final user;
  final week;
  Video(this.user, this.week);

  @override
  _VideoState createState() => _VideoState(user, week);
}

class _VideoState extends State<Video> {
  final user;
  final week;
  _VideoState(this.user, this.week);

  Future<http.Response> weeksVideos() async {
    return http.get(
      'https://masomo.co.tz/Api/week_videos?week=' + widget.week,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.user['name'],
      debugShowCheckedModeBanner: false,
      home: VideoPlayerScreen(user, week),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final user;
  final week;
  VideoPlayerScreen(this.user, this.week);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState(user, week);
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  var user;
  var week;
  var isPlaying = false;
  _VideoPlayerScreenState(this.user, this.week);

  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  void playVideo(url) {
    isPlaying = true;
    _controller = VideoPlayerController.network(url)
      ..setVolume(1.0)
      ..initialize()
      ..play();
    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();
    super.dispose();
  }

  var videoList = [];

  void weekVideos() async {
    try {
      final response =
          await http.get('https://masomo.co.tz/api/week_videos?week=$week');
      print(response.body);
      if (videoList.length == 0) {
        setState(() => videoList.addAll(jsonDecode(response.body)));
      } else {
        videoList = jsonDecode(response.body);
        setState(() => videoList);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (videoList.length == 0) {
      weekVideos();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Week $week : " + user['name']),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(
                  user,
                ),
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFFB3590A),
      ),
      // Use a FutureBuilder to display a loading spinner while waiting for the
      // VideoPlayerController to finish initializing.
      body: Column(
        children: [
          showVideo(),
          Expanded(
            child: (videoList.length > 0)
                ? Container(
                    width: double.infinity,
                    child: ListView.builder(
                      reverse: false,
                      itemCount: videoList.length,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, index) {
                        String titleVideo = videoList[index]['title'];
                        String videoSize = videoList[index]['size'];
                        String url = videoList[index]['url'];

                        return Card(
                          child: InkWell(
                            onTap: () {
                              playVideo(url);
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(titleVideo,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold)),
                                          Padding(
                                            child: Text(videoSize,
                                                style: TextStyle(
                                                    color: Colors.grey[500])),
                                            padding: EdgeInsets.only(top: 3),
                                          )
                                        ]),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: isPlaying
                                        ? Icon(Icons.play_arrow)
                                        : Icon(
                                            Icons.play_arrow,
                                            color: Colors.grey.shade300,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.cyanAccent,
                          valueColor:
                              new AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ),
                      Text('Inapakua taarifa'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget showVideo() {
    if (isPlaying != true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
          ),
          Center(),
          Text(
            'Bonyeza Video kuanza kusoma',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
        ],
      );
    } else {
      return Container(
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // If the VideoPlayerController has finished initialization, use
              // the data it provides to limit the aspect ratio of the video.
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                // Use the VideoPlayer widget to display the video.
                child: VideoPlayer(_controller),
              );
            } else {
              // If the VideoPlayerController is still initializing, show a
              // loading spinner.
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      );
    }
  }
}
